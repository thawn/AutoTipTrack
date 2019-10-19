function copyResults(folder, varargin)
if nargin < 1 || exist(folder, 'dir')~=7
  [folder] = uigetdir('', 'Select the folder that contains the experiment');
  if folder == 0
    return;
  end
end
p = inputParser;
p.addParameter('Config', fullfile(folder,'config.mat'), @ischar);
p.addParameter('TargetResultField', 'RectPos', @ischar);
p.addParameter('DeleteResultField', '', @ischar);
p.addParameter('AddResultFields', {}, @iscellstr);
p.addParameter('AddResultFieldValues', struct(), @isstruct);
p.parse(varargin{:});

%define and clear the logfile
log = fullfile(folder, 'AutoTipTrack_log.txt');
warning off MATLAB:DELETE:FileNotFound
delete(log);
warning on MATLAB:DELETE:FileNotFound
if exist(p.Results.Config, 'file') ~= 2
  %try to read experiment default config
  config_file = fullfile(folder,'config.mat');
  if exist(config_file, 'file') ~= 2
    %create a config file if none exists
    fConfigGui('Create', folder);
  end
else
  config_file = p.Results.Config;
end
if ~isdeployed
  addpath('assets')
end
if strendswith(folder, filesep)
  folder = folder(1:end - 1);
end
%create an empty GUI handle
hEvalGui = EvalGui;
%create the root node here
rootNode = hEvalGui.createNode(folder, true);

%recursively scan the directory structure for stacks and add them to the
%queue
queue = enqueueManyExperiments(rootNode, config_file, hEvalGui);

%start the timer that watches the progress
hEvalGui.addTree(rootNode);
hEvalGui.expandAllNodes;
drawnow;
timer = hEvalGui.watchProgress;
hEvalGui.Log = log;

numFiles = length(queue);
%load one image from each stack for the figures
for n = 1:numFiles
  try
    trackStatus(queue(n).StatusFolder, 'Loading old data', '', 0, 1, 1);
    queue(n).reloadResults('Results', p.Results.TargetResultField);
    if ~isfield(queue(n).Results, p.Results.TargetResultField)
      queue(n).abort('Did not find suitable results');
      break
    end
    OldResults = queue(n).Results;
    if ~isempty(p.Results.DeleteResultField) && isfield(OldResults, p.Results.DeleteResultField)
      OldResults = rmfield(OldResults, p.Results.DeleteResultField);
    end
    if ~isempty(p.Results.AddResultFields)
        for k = 1:length(p.Results.AddResultFields)
            OldResults.(p.Results.AddResultFields{k}) = p.Results.AddResultFieldValues.(p.Results.AddResultFields{k});
        end
    end
    trackStatus(queue(n).StatusFolder, 'Loading old data', '', 1, 1, 1);
    trackStatus(queue(n).StatusFolder, 'Copying results', '', 0, 1, 1);
    queue(n).reloadResults;
    queue(n).Results = OldResults;
    queue(n).saveFiestaCompatibleFile;
    trackStatus(queue(n).StatusFolder, 'Copying results', '', 1, 1, 1);
    queue(n).deleteDuplicateResults;
    trackStatus(queue(n).StatusFolder, 'All done', '', 1, 1, 1);
    queue(n).finish;
  catch ME
    queue(n).abort(sprintf('%s | see %s for more details.', ME.message, log));
    appendLog(log, ME.getReport('extended', 'hyperlinks', 'off'));
  end
end


uiwait(hEvalGui.fig);
hEvalGui.close;
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
