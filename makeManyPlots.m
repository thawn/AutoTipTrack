function [ax1,minN,maxN,numN,binnedYs]=makeManyPlots(xData,yData,varargin)
%% Syntax
% makeManyPlots(xData,yData1,xData2,yData2,...,xDataN,yDataN)
% makeManyPlots(__,'Name','Value')
% ax=makeManyPlots(__)
% [ax1,minN,maxN,numN,binnedY]=makeManyPlots(__)
%
% Description
% creates many plots using the makeplot function.
% 
% Parameters
% xData1,xData2,...,xDataN: the data along the x-axis. Datetime or column
% vectors.
% yData1,yData2,...,yDataN: The data along the y-axis. Cell arrays of
% numbers.
%
% Name value pairs following after xData and yData will be passed on to
% the makePlot function.
% 
% See also BINDATA, MAKEPLOT.

if ~iscell(yData)
  yData={num2cell(yData)};
else
  yData={yData};
end
xData={xData};
while ~ischar(varargin{1})
  xData=[xData varargin(1)]; %#ok<AGROW>
  if ~iscell(varargin{2})
    yData=[yData {num2cell(varargin{2})}]; %#ok<AGROW>
  else
    yData=[yData varargin(2)]; %#ok<AGROW>
  end
  varargin(1:2)=[];
end

%handle remaining varargin
p=inputParser;
%define the parameters
p.addParameter('startingColor',1,@isnumeric);
p.addParameter('displayNames',{},@iscell);
p.addParameter('SaveName','',@ischar);
p.addParameter('YAxisLocation','Left',@ischar);
p.addParameter('OriginalAxes',[],@ishandle);
p.KeepUnmatched=true;
p.parse(varargin{:});

%prepare remaining arguments for passing them down to MakeBoxPlot
plotArgs = unmatched2Args(p.Unmatched);
if isempty(p.Results.displayNames)
  DisplayNames=repmat({},1,length(yData));
else
  DisplayNames=[repmat({'DisplayName'},1,length(yData)); p.Results.displayNames];
end

if strcmpi(p.Results.YAxisLocation,'Right')
  if isempty(p.Results.OriginalAxes)
    originalaxes=gca;
  else
    originalaxes=p.Results.OriginalAxes;
  end
  hold on;
  box off;
  ax1 = axes('YAxisLocation', 'Right');
  set(ax1, 'color', 'none',...  
    'XTick', [],...
    'XLim',get(originalaxes,'XLim'));
end

colors={[0.1 0.1 0.8] [0 0.5 0.2],...
  [0.1 0.7 0.95] [0.5 0.9 0.1],...
  [0.8 0.1 0.1], [0 0 0]...
  [1 0.6 0.2], [0.6 0.6 0.6]};
markers={'o','s','v','d','x','^','h','>'};
minN=zeros(1,length(yData));
maxN=zeros(1,length(yData));
numN=cell(1,length(yData));
binnedYs=cell(1,length(yData));
for n=1:length(yData)
  c=n-1+p.Results.startingColor;
  repeat=0;
  while c>length(colors)
    repeat=repeat+1;
    c=c-length(colors)*repeat;
  end
  if exist('ax1','var')
    if ~any(cellfun(@(x) strcmp(x,'axishandle'),plotArgs))
      plotArgs=[plotArgs,{'axishandle',ax1}]; %#ok<AGROW>
    end
  end
  [ax1,minN(n),maxN(n),numN{n},binnedYs{n}]=makePlot(xData{n},yData{n},'color',colors{c},'marker',markers{c},DisplayNames{:,n},plotArgs{:});
end
if ~isempty(p.Results.displayNames)
  legend(ax1,'show');
end
if strcmpi(p.Results.YAxisLocation,'Right')
  xlabel(ax1,'');
end

if ~isempty(p.Results.SaveName)
  saveas(gcf,p.Results.SaveName);
end
