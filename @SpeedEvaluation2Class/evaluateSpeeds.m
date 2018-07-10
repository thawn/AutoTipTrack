function [success,S]=evaluateSpeeds(S)
success=false;
if length(S.Config.Times)>1 && isfield(S.Results, 'Speed') && ~isempty(S.Results.Speed)
  S.time=S.Config.Times(1:end-1);
  startpoints=S.Startpoints;
  averageSpeeds=S.Results.Speed(:);
  averageSpeeds(isnan(averageSpeeds))=[];
  if length(averageSpeeds)>2
    S.meanresult=[mean(averageSpeeds),std(averageSpeeds)];
    %create histogram subplot
    nBins=round(length(averageSpeeds)/25)*5; %we want on average 5 speeds per bar
    if nBins<7 %make sure we have at least 7 bins so that confint works can calculate the confidence intervals
      nBins=7;
    end
    S.binSize=ceil((max(averageSpeeds)-min(averageSpeeds))/(nBins*10))*10;
    minS=floor(min(averageSpeeds)/S.binSize)*S.binSize;
    maxS=ceil(max(averageSpeeds)/S.binSize)*S.binSize;
    S.histX=minS:S.binSize:maxS;
    [S.count,S.histX]=hist(averageSpeeds,S.histX);
    numFunctions=floor(length(startpoints)/3);
    for n=1:numFunctions
      if startpoints(n*3)<3*S.binSize
        startpoints(n*3)=3*S.binSize;
      end
    end
    modelName=sprintf('gauss%d',numFunctions);
    options=fitoptions(modelName,'StartPoint', startpoints);
    S.cfun=fit(S.histX',S.count',modelName,options);
    conf=confint(S.cfun);
    if ~isinf(conf(2,2)) && ~isnan(conf(2,2)) && conf(2,2)>-2000 && conf(2,2)<2000
      S.slowresult = [S.cfun.b1,S.cfun.c1/2^0.5]; %slowresult(1) is the mean and slowresult(2) is the standard deviation
    end
    if size(conf,2)>3 && ~isinf(conf(2,5)) && ~isnan(conf(2,5)) && conf(2,5)>-2000 && conf(2,5)<2000
      S.fastresult = [S.cfun.b2,S.cfun.c2/2^0.5]; %fastresult(1) is the mean and fastresult(2) is the standard deviation
    end
    %check if fast and slow result got mixed up
    if S.slowresult(1)>S.fastresult(1)
      temp=S.fastresult;
      S.fastresult=S.slowresult;
      S.slowresult=temp;
    elseif isnan(S.fastresult(1)) && S.slowresult(1)>200
      S.fastresult=S.slowresult;
      S.slowresult=[NaN NaN];
    end
    S.medianSpeeds=nanmedian(S.Results.Speed,2);
    success=true;
  end
  if isfield(S.Results, 'Length') && ~isempty(S.Results.Length) && ~all(isnan(S.Results.Length(:)))
    S.lengthMT=[prctile(S.Results.Length(:),5) prctile(S.Results.Length(:),25) prctile(S.Results.Length(:),50) prctile(S.Results.Length(:),75)];
  end
end
