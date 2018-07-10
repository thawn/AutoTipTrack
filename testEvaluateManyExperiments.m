function testEvaluateManyExperiments(varargin)
p=inputParser;
p.addParameter('TestType','standard',@isstr);
p.addParameter('ClearEval', false, @islogical);
p.KeepUnmatched=true;
p.parse(varargin{:});
tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
EvalArgs = reshape(tmp',[],1)';

testdir=[pwd filesep 'current_test' filesep];
try
  rmdir(testdir,'s');
catch ME %#ok<NASGU>
end
copyfile([pwd filesep 'AutoTipTrack_testcases'],testdir);
switch(p.Results.TestType)
  case 'fastest'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    %rmdir(fullfile(testdir, 'one_MM_tiffstack'),'s');
    %rmdir(fullfile(testdir, 'no_mts'),'s');
    runTest(testdir,EvalArgs{:});
  case 'movie'
    %test movie generation only
    %rmdir(fullfile(testdir, 'one_mm_stack_movie', 'eval'),'s');
    runTest(fullfile(testdir,'one_mm_stack_movie'),EvalArgs{:});
  case 'fast'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    rmdir([testdir 'many_tiffs' filesep 'eval'],'s');
    runTest(testdir,EvalArgs{:});
  case 'nd2'
    %the test directory already contains evaluated data, so only
    %reevaluation is tested
    delete(fullfile(testdir, 'two_nd2', 'eval','2015-03-20_D2_045*'));
    runTest(testdir,EvalArgs{:});
  case 'standard'
    %we delete the eval folders of each testType of stack to test the tracking
    %as well as the reevaluation
    rmdir([testdir 'one_mm_stack' filesep 'eval'],'s');
    rmdir([testdir 'two_nd2s' filesep 'eval'],'s');
    rmdir([testdir 'many_tiffs' filesep 'eval'],'s');
    %also remove the config for the nd2 stack to test usage of the main
    %config file
    delete([testdir 'one_nd2' filesep 'config.mat']);
    runTest(testdir,EvalArgs{:});
  case 'full'
    deleteAllEval(testdir);
    runTest(testdir,EvalArgs{:});
    %evaluate again to test reevaluation
    runTest(testdir,EvalArgs{:});
    %create an error and evaluate again to test error handling
    %createError(testdir);
    %runTest(testdir,useGUI,dbg);
  case 'biocomp'
    %test biocomp evaluation only
    if p.Results.ClearEval
      fclose all;
      rmdir(fullfile(testdir, 'biocomp_eval', 'eval'),'s');
      delete(fullfile(testdir, 'biocomp_eval', 'flip*.tif'), ...
        fullfile(testdir, 'biocomp_eval', 'no_flip_180deg.tif'), ...
        fullfile(testdir, 'biocomp_eval', 'no_flip_270deg.tif'));
    end
    runTest(fullfile(testdir,'biocomp_eval'),EvalArgs{:});
  otherwise
    newDir=[testdir p.Results.TestType filesep];
    if dbg
      rmdir([newDir 'eval'], 's');
    end
    runTest(newDir,EvalArgs{:})
end
h=findobj('Tag','hEvalGui');
if ~isempty(h)
  uiwait(h(1));
else
  input('press enter key to continue...','s');
end
fclose all;
rmdir(testdir,'s');

function runTest(testdir,varargin)
tic;
try
  evaluateManyExperiments(testdir,varargin{:});
catch ME
  ME.getReport
end
toc
type(fullfile(testdir,'AutoTipTrack_log.txt'));

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
