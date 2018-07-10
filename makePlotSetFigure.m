function Stats=makePlotSetFigure(xData,allSpeeds,allLengths,numMTs,savePath,varargin)
p=inputParser;
p.addRequired('xData',@(x) isdatetime(x) || isnumeric(x));
p.addRequired('allSpeeds',@iscell);
p.addRequired('allLengths',@iscell);
p.addRequired('numMTs',@iscell);
p.addRequired('savePath',@isstr);
p.addParameter('WidthScale',2,@isnumeric);
p.addParameter('HeightScale',0.727,@isnumeric);
p.addParameter('SpeedLim',[0 990],@isnumeric);
p.addParameter('NumLim',[0 0.02],@isnumeric);
p.addParameter('LengthLim',[0 14.9],@isnumeric);
p.addParameter('Bundling',{},@iscell);
p.addParameter('BundlingLim',[0 0.69],@isnumeric);
p.addParameter('FileName','combined',@isstr);
p.addParameter('XPadding',0.5,@isnumeric);
p.KeepUnmatched=true;

p.parse(xData,allSpeeds,allLengths,numMTs,savePath,varargin{:});

tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
figArgs = reshape(tmp',[],1)';
if ~isfield(p.Unmatched, 'XLim')
  figArgs=[figArgs {'XLim', [min(xData)-p.Results.XPadding, max(xData)+p.Results.XPadding] 'BatchMode', true}];
end
Bundling=p.Results.Bundling;
Fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
scaleFigure(Fig1, p.Results.WidthScale, p.Results.HeightScale);
Cols=3;
SubPlotArgs={'Parent',Fig1,'box','on'};
Stats=struct('Bundling',struct(),...
  'Speeds',struct(),...
  'NumMT',struct(),...
  'Length',struct());
if (~isempty(Bundling))
  Cols=4;
  scaleFigure(Fig1, 1, 3/4);
  BundlingAx=subplot(1,Cols,4,SubPlotArgs{:});
  [~,Stats.Bundling.minN,Stats.Bundling.maxN,Stats.Bundling.numN,Stats.Bundling.binned_Y,Stats.Bundling.binned_X,~]=makePlot(xData,Bundling,...
    'yLabel','Bundling ratio','YLim',p.Results.BundlingLim,...
    'marker','s','color',[0.2 0.6 0.6],'plotType','medianIQR',...
    'axishandle',BundlingAx,figArgs{:});
end
SpeedAx=subplot(1,Cols,1,SubPlotArgs{:});
[~,Stats.Speeds.minN,Stats.Speeds.maxN,Stats.Speeds.numN,Stats.Speeds.binned_Y,Stats.Speeds.binned_X,~]=makePlot(xData,allSpeeds,'YLim',p.Results.SpeedLim,...
  'marker','o','color',[0.2 0.1 0.9],'plotType','medianIQR',...
  'axishandle',SpeedAx,figArgs{:});
NumMTAx=subplot(1,Cols,2,SubPlotArgs{:});
[~,Stats.NumMT.minN,Stats.NumMT.maxN,Stats.NumMT.numN,Stats.NumMT.binned_Y,Stats.NumMT.binned_X,~]=makePlot(xData,numMTs,...
  'yLabel',sprintf('Microtubule density (%sm^{-2})',181),'YLim',p.Results.NumLim,...
  'marker','.','color',[0.2 0.8 0.1],'plotType','scatter',...
  'axishandle',NumMTAx,figArgs{:});
LengthAx=subplot(1,Cols,3,SubPlotArgs{:});
[~,Stats.Length.minN,Stats.Length.maxN,Stats.Length.numN,Stats.Length.binned_Y,Stats.Length.binned_X,~]=makePlot(xData,allLengths,'YScale',0.001,...
  'yLabel',sprintf('Microtubule length (%sm)',181),'YLim',p.Results.LengthLim,...
  'marker','x','color',[0.8 0.1 0.2],'plotType','medianIQR',...
  'axishandle',LengthAx,figArgs{:});
saveas(Fig1,fullfile(savePath,[p.Results.FileName '.pdf']));
close(Fig1);
end

function scaleFigure(Fig1, WidthFactor,HeightFactor)
pos=get(Fig1,'Position');
paperPos=get(Fig1,'PaperPosition');
paperSize=get(Fig1,'PaperSize');
paperSize(1)=paperSize(1)*WidthFactor;
paperSize(2)=paperSize(2)*HeightFactor;
pos(3)=pos(3)*WidthFactor;
pos(4)=pos(4)*HeightFactor;
paperPos(3)=paperPos(3)*WidthFactor;
paperPos(4)=paperPos(4)*HeightFactor;
set(Fig1,'PaperSize',paperSize);
set(Fig1,'Position',pos);
set(Fig1,'PaperPosition',paperPos);
end