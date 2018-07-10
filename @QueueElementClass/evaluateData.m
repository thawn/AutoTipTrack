function [DataEvaluator,Q]=evaluateData(Q,varargin)
p=inputParser;
p.addParameter('Manual',false,@islogical);
p.KeepUnmatched=true;
p.parse(varargin{:});
if ~Q.Aborted
  DataEvaluator=feval(Q.Config.EvaluationClassName, Q, 'Manual',p.Results.Manual);
  DataEvaluator.evaluate;
else
  DataEvaluator=feval(Q.Config.EvaluationClassName, Q);
end
DataEvaluator.testSuccess;
end
