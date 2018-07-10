function Average=walkingAverage(Data,WindowSize)
NumAverage=length(Data)-WindowSize;
Average=zeros(1,NumAverage);
for n=1:NumAverage
  Average(n)=mean(Data(n:n+WindowSize));
end
  