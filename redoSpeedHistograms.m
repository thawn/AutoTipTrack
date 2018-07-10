function redoSpeedHistograms(folder)
if nargin < 1 || exist(folder, 'dir')~=7
  [folder] = uigetdir('', 'Select the folder that contains the experiment');
  if folder==0
    return;
  end
end
if ~isdeployed
  addpath('assets')
end
if strendswith(folder,filesep)
  folder=folder(1:end-1);
end
%define and clear the logfile
log=fullfile(folder, 'Monitor_log.txt');
warning off MATLAB:DELETE:FileNotFound
delete(log);
warning on MATLAB:DELETE:FileNotFound

%create an empty GUI handle
hEvalGui=EvalGui;
%create the root node here
rootNode=hEvalGui.createNode(folder,true);
% we need to explicitly use the data evaluation classes here for the
% compiler to properly recognize that we might call them using feval later.
%#function SpeedEvaluationClass SpeedEvaluation2Class BundlingEvaluationClass Speed2TempEvaluationClass SpeedJannesEvaluationClass MakeMovieEvaluationClass

%recursively scan the directory structure for stacks and add them to the
%queue
queue=enqueueManyExperiments(rootNode,'',hEvalGui);

%start the timer that watches the progress
hEvalGui.addTree(rootNode);
hEvalGui.expandAllNodes;
drawnow;
timer=hEvalGui.watchProgress;
hEvalGui.Log=log;

numFiles=length(queue);
%load one image from each stack for the figures
for n=1:numFiles
  try
    queue(n).loadMiddleImage;
  catch ME
    queue(n).abort(sprintf('%s | see %s for more details.',ME.message, log));
    appendLog(log, ME.getReport('extended','hyperlinks','off'));
  end
end


%evaluate the data
waitfor(helpdlg('For each of the following figures, click on the peak positions in the graph from left to right (press enter if there are no more peaks)'));
SpeedEvaluationClasses=cell(1,numFiles);
for n=1:numFiles
  try
    SpeedEvaluationClasses{n}=queue(n).evaluateData('WholeStack',queue(n).Config.Evaluation.NeedsWholeStack{queue(n).Config.Evaluation.EvalClassNo},'Manual',true);
    queue(n).finish;
  catch ME
    queue(n).abort(sprintf('%s | see %s for more details.',ME.message, log));
    appendLog(log, ME.getReport('extended','hyperlinks','off'));
  end
end
%Create overview figures
if queue(1).Config.Tasks.Overview
  C=ConfigClass;
  EvalTypes=cellfun(@(x) find(strcmp(class(x),C.Evaluation.EvalClassNames)),SpeedEvaluationClasses);
  EvalClassTypes=cell(1,length(C.Evaluation.EvalClassNames));
  for n=2:length(C.Evaluation.EvalClassNames)
    if n==2
      %we want to merge SpeedEvaluationClass and SpeedEvaluation2Class
      %because they have the same makeOverviewFigure function
      EvalClassTypes{n}=SpeedEvaluationClasses(EvalTypes==2|EvalTypes==1);
    else
      EvalClassTypes{n}=SpeedEvaluationClasses(EvalTypes==n);
    end
    try
      if ~isempty(EvalClassTypes{n})
        feval([class(EvalClassTypes{n}{1}) '.makeOverviewFigure'],EvalClassTypes{n},folder);
      end
    catch ME
      appendLog(log, ME.getReport('extended','hyperlinks','off'),false);
      ME.getReport
    end
  end
  clear('C');
end
%refresh the GUI to make sure all messages are displayed
hEvalGui.refresh;


uiwait(hEvalGui.fig);
delete(hEvalGui);
%clean up
if ~isdeployed
  rmpath('assets')
end
allMsg=[queue.Message];
queue.delete;
%make sure the timer is stopped
try
  stop(timer);
  delete(timer);
catch
end
if ~isempty(allMsg)
  warning(allMsg);
end
