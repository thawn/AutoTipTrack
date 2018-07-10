function testRedoSpeedHistograms(testType,forceErrors)
if nargin<1
  testType='quick';
end
if nargin<2
  forceErrors=false;
end
testdir=[pwd filesep 'current_test' filesep];
try
  rmdir(testdir,'s');
catch ME %#ok<NASGU>
end
copyfile([pwd filesep 'AutoTipTrack_testcases'],testdir);
if forceErrors
  createError(testdir);
end
switch(testType)
  case 'quick'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    %rmdir(fullfile(testdir, 'one_MM_tiffstack'),'s');
    %rmdir(fullfile(testdir, 'no_mts'),'s');
    runTest(testdir);
  case 'quickavi'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    delete(fullfile(testdir, 'many_tiffs', 'eval','A4.avi'));
    runTest(testdir);
  case 'fast'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    rmdir([testdir 'many_tiffs' filesep 'eval'],'s');
    runTest(testdir);
  case 'standard'
    %we delete the eval folders of each testType of stack to test the tracking
    %as well as the reevaluation
    rmdir([testdir 'one_mm_stack' filesep 'eval'],'s');
    rmdir([testdir 'two_nd2s' filesep 'eval'],'s');
    rmdir([testdir 'many_tiffs' filesep 'eval'],'s');
    %also remove the config for the nd2 stack to test usage of the main
    %config file
    delete([testdir 'one_nd2' filesep 'config.mat']);
    runTest(testdir);
  case 'full'
    deleteAllEval(testdir);
    runTest(testdir);
    %evaluate again to test reevaluation
    runTest(testdir);
    %create an error and evaluate again to test error handling
    createError(testdir);
    runTest(testdir);
  otherwise
    newDir=[testdir testType filesep];
    if forceErrors
      rmdir([newDir 'eval'], 's');
    end
    runTest(newDir)
end
h=findobj('Tag','hEvalGui');
if length(h)>1
  uiwait(h(1));
else
  uiwait(h)
end
rmdir(testdir,'s');

function runTest(testdir)
tic;
try
  redoSpeedHistograms(testdir);
catch ME
  ME.getReport
end
toc
type([testdir 'AutoTipTrack_log.txt']);

function createError(testdir)
delete(fullfile(testdir, 'two_nd2s', 'eval', '2015-03-20_D2_045*.mat'));
delete(fullfile(testdir, 'nested', 'many_tiffs', 'eval', '*.mat'));

function deleteAllEval(testdir)
children=dir(testdir);
for i=1:length(children)
  if children(i).isdir
    isDot=strcmp(children(i).name,{'.','..','eval','ignore','eval_old','done'});
    if ~any(isDot) %if we don't ignore the directory, check if it is an eval folder
      deleteAllEval([testdir filesep children(i).name]);
    elseif strcmp(children(i).name,'eval')
      rmdir([testdir filesep children(i).name],'s');
    end
  end
end
