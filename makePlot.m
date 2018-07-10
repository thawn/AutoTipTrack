function [ax1,minN,maxN,numN,binnedY,binnedX,fig1]=makePlot(xData,yData,varargin)
%% Syntax
% makePlot(xData,yData)
% makePlot(xData,yData,'plottype','box'(default)|'medianIQR'|'meanSTD'|'meanSEM')
% makePlot(__,'Name','Value')
% ax=makePlot(__)
% [ax1,minN,maxN,numN,binnedY]=makePlot(__)
%
% Description
% makePlot creates one of four plot types
% 'plottype':
% 'box'(default): a box and whiskers plot. by default outliers are hidden,
% but they can be reactivated by adding the name value pair.
%
% 'medianIQR': the median and error bars corresponding to the interquartile
% range.
%
% 'meanSTD': the mean and error bars corresponding to the standard
% deviation.
%
% 'meanSEM': the mean and error bars corresponding to two times the
% standard error of the mean.
% 
% Parameters
% xData: the data along the x-axis. Datetime or column vector.
% yData: the data along the y-axis. Cell of numbers.
% 
% optional key-value pairs:
% 
% plottype: 'box'(default)|'medianIQR'|'meanSTD'|'meanSEM'
% the type of plot (see above)
% 
% 'binNumber': [](default), integer value of how many columns of x and y are
% to be binned. An empty value means no binning (See also BINDATA).
% 
% 'binInterval': [] (default), double value giving an interval of data to be
% binned. An empty value means no binning (See also BINDATA).
% 
% 'XLim': 'auto'(default), X-axis limits.
% 
% 'YLim': 'auto'(default), Y-axis limits.
% 
% 'marker': 'o' (default) marker string.
% 
% 'lineStyle': 'none' (default), line style string.
% 
% 'color': [0.2 0.1 0.9] (default), plot color.
% 
% 'xLabel': 'time (h)' (default), X-axis label string.
% 
% 'yLabel': 'velocity (nm/s)' (default), y-axis label string.
% 
% 'axishandle': [] (default), handle to an axis handle. If this parameter is
% given, the plot will be added to the corresponding axes.
%
% Output
% ax1: handle to the axis object.
% minN: minimum number of values in YData.
% maxN: maximum number of values in YData.
% numN: vector containting the number of values in each column of YData.
% binnedY: matrix containing the values of yData that were used for the
% plot.
%
% See also BINDATA, MAKEMANYPLOTS.

p=inputParser;
%define the parameters
p.addRequired('xData',@(x) isdatetime(x) || isnumeric(x));
p.addRequired('yData',@iscell);
p.addParameter('binNumber',[],@isnumeric);
p.addParameter('binInterval',[],@isnumeric);
p.addParameter('YLim','auto');
p.addParameter('XLim','auto');
p.addParameter('plotType','box',@ischar);
p.addParameter('marker','o',@ischar);
p.addParameter('lineStyle','none',@ischar);
p.addParameter('color',[0.2 0.1 0.9],@(x) length(x)==3 && min(x)>=0 && max(x)<=1);
p.addParameter('xLabel','Time (h)',@ischar);
p.addParameter('yLabel','Velocity (nm/s)',@ischar);
p.addParameter('axishandle',[],@ishandle);
p.addParameter('XOffset',0,@isnumeric);
p.addParameter('YScale',1,@isnumeric);
p.addParameter('XScale',1,@isnumeric);
p.addParameter('HeightScale',1,@isnumeric);
p.addParameter('DisplayName','',@(x) iscell(x) || ischar(x));
p.addParameter('FontSize',18,@isnumeric);
p.addParameter('BatchMode',false,@islogical);
p.KeepUnmatched=true;

p.parse(xData,yData,varargin{:});

tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
figArgs = reshape(tmp',[],1)';

[binnedX, binnedY]=binData(xData,yData,'binNumber',p.Results.binNumber,'binInterval',p.Results.binInterval);
binnedX=binnedX+p.Results.XOffset;
binnedX=binnedX*p.Results.XScale;
binnedY=binnedY*p.Results.YScale;
if isempty(binnedX)||isempty(binnedY)
  warning('no data to plot');
  ax1 = [];
  minN = [];
  maxN = [];
  numN = [];
  binnedY = [];
  binnedX = [];
  fig1 = [];
  return;
end

numN=sum(~isnan(binnedY));
minN=min(numN);
maxN=max(numN);
if isempty(p.Results.axishandle)
  fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
  pos=get(fig1,'Position');
  paperPos=get(fig1,'PaperPosition');
  pos(4)=pos(4)*p.Results.HeightScale;
  paperPos(4)=paperPos(4)*p.Results.HeightScale;
  set(fig1,'Position',pos);
  set(fig1,'PaperPosition',paperPos);
  ax1=axes('parent',fig1);
else
  ax1=p.Results.axishandle;
  fig1=get(ax1,'parent');
  hold on;
end
switch p.Results.plotType
  case 'box'
    boxplot(ax1,binnedY,'positions',binnedX,'labels','',...
      'symbol','','jitter',0.5,'medianstyle','target','colors',p.Results.color,figArgs{:}); %,'plotstyle','compact'
    set(ax1,'XTickMode','auto','XTickLabel','','XTickLabelMode','auto');
    set(findobj(fig1,'LineStyle','--'),'LineStyle','-');
  case 'medianIQR'
    interquartiles=iqr(binnedY)./2;
    plot1=errorbar(binnedX,prctile(binnedY,25)+interquartiles,interquartiles,'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',' ');
    hold on;
    plot2=plot(binnedX,nanmedian(binnedY),'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
    hold off;
  case 'meanSEM'
    plot1=errorbar(binnedX,nanmean(binnedY),nanstd(binnedY)./sqrt(sum(~isnan(binnedY)))*2,'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
  case 'meanSEM2'
    plot1=errorbar(binnedX,nanmean(binnedY),nanstd(binnedY)./sqrt(sum(~isnan(binnedY)))*2,'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
  case 'meanSTD'
    plot1=errorbar(binnedX,nanmean(binnedY),nanstd(binnedY),'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
  case 'prctile5'
    plot1=plot(binnedX,prctile(binnedY,5),'Parent',ax1,...
      'Color',p.Results.color,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
  case 'scatter'
    if isfield(p.Unmatched,'MarkerSize')
      MarkerSize=p.Unmatched.MarkerSize;
    else
      MarkerSize=6;
    end
    [binnedX, binnedY]=binData(xData,yData,'binNumber',p.Results.binNumber,'binInterval',p.Results.binInterval,'scatter',true);
    binnedX=binnedX+p.Results.XOffset;
    binnedX=binnedX*p.Results.XScale;
    binnedY=binnedY*p.Results.YScale;
    plot1=plot(binnedX,binnedY,'Parent',ax1,...
      'Color',p.Results.color,'MarkerSize',MarkerSize,figArgs{:},...
      'DisplayName',p.Results.DisplayName);
end
set(ax1,'TickLength',[0.005 0.01],'FontSize',p.Results.FontSize,'FontName','Arial','LabelFontSizeMultiplier',1.2);
ylim(p.Results.YLim);
xlim(p.Results.XLim);
xlabel(ax1,p.Results.xLabel);
ylabel(ax1,p.Results.yLabel);
if exist('plot1','var')
  set(plot1,'LineStyle',p.Results.lineStyle);
  set(plot1,'Marker',p.Results.marker);
  if exist('plot2','var')
    set(plot1,'Marker','none');
    set(plot2,'LineStyle','none');
    set(plot2,'Marker',p.Results.marker);    
  end
end
if ~p.Results.BatchMode
  set(fig1,'Visible','on')
end
