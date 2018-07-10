function SpeedMat = allSpeedsCell2Mat(AllSpeeds)
  function Speeds = removeNaN(Speeds)
    Speeds = Speeds(:);
    Speeds(isnan(Speeds)) = [];
  end
  SingleSpeeds = cellfun(@removeNaN,AllSpeeds, 'UniformOutput', false);
  MaxLen = max(cellfun(@length, SingleSpeeds));
  NumSpeeds = length(AllSpeeds);
  SpeedMat = NaN(MaxLen, NumSpeeds);
  for n=1:NumSpeeds
    SpeedMat(1:length(SingleSpeeds{n}),n) = SingleSpeeds{n};
  end
end