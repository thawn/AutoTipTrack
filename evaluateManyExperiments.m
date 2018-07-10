function evaluateManyExperiments(folder,varargin)
if nargin < 1 || exist(folder, 'dir')~=7
  [folder] = uigetdir('', 'Select the folder that contains the experiment');
  if folder==0
    return;
  end
end
p=inputParser;
if feature('ShowFigureWindows')
  p.addParameter('Gui',true,@(x) islogical(x) || ischar(x));
else
  p.addParameter('Gui',false,@(x) islogical(x) || ischar(x));
end
p.addParameter('NumCPUs',feature('numcores'),@(x) isnumeric(x) || ischar(x));
p.addParameter('Config',fullfile(folder,'config.mat'),@ischar);
p.addParameter('EvaluateManually',false,@(x) islogical(x) || ischar(x));
p.addParameter('Debug',false,@(x) isnumeric(x) || ischar(x));
p.KeepUnmatched=true;
p.parse(varargin{:});

if ischar(p.Results.Gui)
  useGUI=str2num(p.Results.Gui); %#ok<ST2NM>
else
  useGUI=p.Results.Gui;
end
if ischar(p.Results.NumCPUs)
  poolsize=round(str2double(p.Results.NumCPUs));
else
  poolsize=p.Results.NumCPUs;
end
if ischar(p.Results.Debug)
  dbg=str2num(p.Results.Debug); %#ok<ST2NM>
else
  dbg=p.Results.Debug;
end
if ischar(p.Results.EvaluateManually)
  Manual=strcmpi(p.Results.EvaluateManually,'true');
else
  Manual=p.Results.EvaluateManually;
end
%define and clear the logfile
log=fullfile(folder, 'AutoTipTrack_log.txt');
warning off MATLAB:DELETE:FileNotFound
delete(log);
warning on MATLAB:DELETE:FileNotFound

if exist(p.Results.Config, 'file')~=2
  %try to read experiment default config
  config_file=fullfile(folder,'config.mat');
  if exist(config_file, 'file')~=2
    %create a config file if none exists
    if useGUI
      fConfigGui('Create',folder);
    else
      warning('MATLAB:AutoTipTrack:evaluateManyExperiments:FileNotFound', 'File not found: "%s". Using default configuration',config_file);
      appendLog(log,lastwarn,useGUI);
      Conf=ConfigClass;
      Conf.save(config_file);
      delete(Conf);
    end
  end
else
  config_file=p.Results.Config;
end
if useGUI
  if ~isdeployed
    addpath('assets')
  end
  if strendswith(folder,filesep)
    folder=folder(1:end-1);
  end
  %create an empty GUI handle
  hEvalGui=EvalGui;
  %create the root node here
  rootNode=hEvalGui.createNode(folder,true);
else
  hEvalGui=[];
  rootNode=struct('getValue',folder);
end
% we need to explicitly use the data evaluation classes here for the
% compiler to properly recognize that we might call them using feval later.
%#function SpeedEvaluationClass SpeedEvaluation2Class BundlingEvaluationClass Speed2TempEvaluationClass SpeedJannesEvaluationClass MakeMovieEvaluationClass BioCompEvaluationClass DilutionSeriesEvaluationClass

%recursively scan the directory structure for stacks and add them to the
%queue
queue=enqueueManyExperiments(rootNode,config_file,hEvalGui);
if useGUI
  %start the timer that watches the progress
  hEvalGui.addTree(rootNode);
  hEvalGui.expandAllNodes;
  drawnow;
  timer=hEvalGui.watchProgress;
  hEvalGui.Log=log;
end
%Make sure we have a matlabpool available
if poolsize>0
  if isempty(gcp('nocreate'))
    pool=parpool(poolsize); %#ok<NASGU>
  else
    pool=gcp; %#ok<NASGU>
  end
end
%Evaluate all stacks in the queue
numFiles=length(queue);
if numFiles>0
  %enable debugging, if  required
  if dbg
    for n=1:numFiles
      queue(n).Debug=dbg;
    end
  end
  %first we track the tips for each file separately
  %trackTips uses the parpool to process the images in the stack in parallel
  for n=1:numFiles
    if queue(n).Config.Tasks.Track
      try
        appendLog(log,sprintf('Tracking Tips: %s',queue(n).Config.StackName),useGUI);
        queue(n).trackTips;
      catch ME
        queue(n)=handleError(queue(n),ME,log);
      end
    end
  end
  %then we connect the objects to tracks.
  if useGUI
    hEvalGui.refresh;
  end
  for n=1:numFiles
    if queue(n).Config.Tasks.Connect
      temp=queue(n);
      try
        appendLog(log,sprintf('Connecting Tracks: %s',temp.Config.StackName),useGUI);
        temp.connectTracks;
      catch ME
        temp=handleError(temp,ME,log);
      end
      queue(n)=temp;
    end
  end
  for n=1:numFiles
    if queue(n).Config.Tasks.Fit
      try
        %Now we fit the paths to the tracks
        appendLog(log,sprintf('Fitting Paths: %s',queue(n).Config.StackName),useGUI);
        queue(n).fitPathsToTracks;
      catch ME
        queue(n)=handleError(queue(n),ME,log);
      end
    end
  end
  tic
  %initialize data storage for the overview figure
  EvaluationClasses=cell(1,numFiles);
  for n=1:numFiles
    if queue(n).Config.Tasks.Evaluate
      temp=queue(n);
      try
        %Finally, we evaluate the data
        appendLog(log,sprintf('Evaluating Data: %s',temp.Config.StackName),useGUI);
        EvaluationClasses{n}=temp.evaluateData('Manual',Manual);
        appendLog(log,sprintf('Deleting duplicate result files for: %s',temp.Config.StackName),useGUI);
        temp.deleteDuplicateResults;
        if EvaluationClasses{n}.Success
          temp.finish;
        else
          temp.abort(sprintf('Could not evaluate speeds. If the stack is not empty, check %s and configuration for errors',log));
        end
      catch ME
        temp=handleError(temp,ME,log);
      end
      queue(n)=temp;
    end
  end
  toc
  if useGUI
    hEvalGui.refresh;
  end
  %Create overview figures
  if queue(1).Config.Tasks.Overview
    C=ConfigClass;
    EvaluationClasses(cellfun(@isempty, EvaluationClasses)) = [];
    EvalTypes=cellfun(@(x) find(strcmp(class(x),C.Evaluation.EvalClassNames)),EvaluationClasses);
    EvalClassTypes=cell(1,length(C.Evaluation.EvalClassNames));
    for n=2:length(C.Evaluation.EvalClassNames)
      if n==2
        %we want to merge SpeedEvaluationClass and SpeedEvaluation2Class
        %because they have the same makeOverviewFigure function
        EvalClassTypes{n}=EvaluationClasses(EvalTypes==2|EvalTypes==1);
      else
        EvalClassTypes{n}=EvaluationClasses(EvalTypes==n);
      end
      if ~isempty(EvalClassTypes{n})
        try
          feval([class(EvalClassTypes{n}{1}) '.makeOverviewFigure'],EvalClassTypes{n},folder);
        catch ME
          appendLog(log, ME.getReport('extended','hyperlinks','off'),false);
          ME.getReport
        end
      end
    end
    clear('C');
  end
else
  warning('MATLAB:AutoTipTrack:evaluateManyExperiments:NoData','No suitable Stacks found in %s.',folder);
end
%clean up
if ~isdeployed && useGUI
  rmpath('assets')
end
allMsg=[queue.Message];
queue.delete;
if useGUI
  %make sure the timer is stopped
  try
    stop(timer);
    delete(timer);
  catch
  end
  %   uiwait(hEvalGui.fig);
  %   delete(hEvalGui);
end
appendLog(log,'All done!',false);
if ~isempty(allMsg)
  warning(allMsg);
else
  appendLog(log,'Success!',false);
end
end
function queueEl=handleError(queueEl,ME,log)
queueEl.deleteDuplicateResults;
queueEl.abort(sprintf('%s | see %s for more details.',ME.message, log));
appendLog(log, ME.getReport('extended','hyperlinks','off'),false);
end
