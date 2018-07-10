function monitorProgress(folder)
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

%recursively scan the directory structure for stacks and add them to the
%queue
queue=enqueueManyExperiments(rootNode,'',hEvalGui);

%start the timer that watches the progress
hEvalGui.addTree(rootNode);
hEvalGui.expandAllNodes;
drawnow;
timer=hEvalGui.watchProgress;
hEvalGui.Log=log;

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
