function Threshold=calculateThreshold(Config,Stack)
if strcmp(Config.Threshold.Mode,'constant')
  Threshold = Config.Threshold.Value;
end
if isreal(Config.Threshold.Value)
  Threshold = Config.Threshold.Value;
elseif ~strcmp(Config.Threshold.Value,'variable')
  minStack = Inf;
  for n = 1:length(Stack)
    Threshold(n) = mean2(Stack{n});
    minStack(n) =min(min(Stack{n}));
  end
  Threshold = round( (Threshold-mean(minStack))*(imag(Config.Threshold.Value)/100) + mean(minStack) );
end