function combinedHistogram(allSpeeds)
averageSpeeds=[];
for n=1:length(allSpeeds)
  averageSpeeds=[averageSpeeds; allSpeeds{n}(:)];
end
averageSpeeds(isnan(averageSpeeds))=[];
nBins=round(length(averageSpeeds)/100)*5;
binSize=ceil((max(averageSpeeds)-min(averageSpeeds))/(nBins*10))*10;
minS=floor(min(averageSpeeds)/binSize)*binSize;
maxS=ceil(max(averageSpeeds)/binSize)*binSize;
histX=minS:binSize:maxS;
hist(averageSpeeds,histX);
xlim([-200 1500]);
ylim([0 200]);
end