function evaluateLengthsOnly(Config, Objects)
EvaluationClass=SpeedEvaluation2Class;
EvaluationClass.Config=Config;
EvaluationClass.Objects=Objects;
%fool calculateResults to think that the speeds are already calculated and
%proceed to the lengths
EvaluationClass.Molecule='not empty';
EvaluationClass.Results.Speed='not empty';
EvaluationClass.calculateResults;
EvaluationClass.numMT=cell2mat(cellfun(@(x) round(size(x.data,2)/2),Objects,'UniformOutput',false));
figure;
p5=prctile(EvaluationClass.Results.Length',5);
p10=prctile(EvaluationClass.Results.Length',10);
p25=prctile(EvaluationClass.Results.Length',25);
plot(EvaluationClass.Config.Times,[EvaluationClass.numMT;p5;p10;p25]);
disp(nanmedian(p5));
disp(nanmedian(p10));
disp(nanmedian(p25));

