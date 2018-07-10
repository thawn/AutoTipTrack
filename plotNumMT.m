function plotNumMT(Folder,varargin)
p=inputParser;
p.addParameter('TimeInterval',3,@isnumeric);
p.addParameter('TimeOffset',5,@isnumeric);
p.addParameter('WalkingAverageWindow',20,@isnumeric);
p.addParameter('YLim',[0 1100],@isnumeric);

p.parse(varargin{:});

Files=dir(fullfile(Folder,'*.mat'));
[~,Title,~]=fileparts(Folder);
NumFiles=length(Files);
NumMT=cell(1,NumFiles);
Time=cell(1,NumFiles);
AverageN=cell(1,NumFiles);
AverageT=cell(1,NumFiles);
fig1=figure();
ax1=axes(fig1,'FontSize',16,'LineWidth',1);
hold on
for n=1:NumFiles
  load(fullfile(Folder,Files(n).name))
  NumMT{n}=cellfun(@(x) length(x.data),Objects);
  AverageN{n}=walkingAverage(NumMT{n},p.Results.WalkingAverageWindow);
  Time{n}=p.Results.TimeOffset:p.Results.TimeInterval:p.Results.TimeInterval*(length(NumMT{n})-1)+p.Results.TimeOffset;
  AverageT{n}=walkingAverage(Time{n},p.Results.WalkingAverageWindow);
  plot(ax1,AverageT{n},AverageN{n},'LineWidth',1,'DisplayName',strrep(Files(n).name(1:end-4),'-','/'));
end
ylim(ax1,p.Results.YLim);
xlabel(ax1,'Time (s)');
ylabel(ax1,'Number of MT');
legend(ax1,'show','Location','northwest');
title(ax1,strrep(Title,'_',' '));
saveas(fig1,fullfile(Folder,[Title '.png']));