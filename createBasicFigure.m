function figure1=createBasicFigure(varargin)
%createBasicFigure creates a figure that fits on an a4 page sets figure
%parameters such that printing and pdf generation works without the usual
%matlab printing quirks. 
%
% Configuration parameters:
%  createBasicFigure('Width',21.0); Width of the figure in cm
%  createBasicFigure('Aspect',21/29.7); aspect ratio of the figure
% further parameters are passed on to the figure command
%
% See also: figure

p=inputParser;
p.addParameter('Width',21.0,@isnumeric);
p.addParameter('Aspect',21/29.7,@isnumeric);
p.KeepUnmatched=true;
p.parse(varargin{:});
Tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
FigArgs = reshape(Tmp',[],1)';
Width=p.Results.Width;
Height=Width/p.Results.Aspect;
if p.Results.Aspect>1
  Orientation='landscape';
else
  Orientation='portrait';
end
Units=get(0,'Units');
set(0,'Units','centimeters');
ScreenPos=get(0,'screensize');
set(0,'Units',Units);
Screenfill=[Width/ScreenPos(3) Height/ScreenPos(4)];
if any(Screenfill>1)
  if find(Screenfill==max(Screenfill))==1
    SWidth=Width/Screenfill(1)*0.95;
    SHeight=SWidth/p.Results.Aspect;
  else
    SHeight=Width/Screenfill(2)*0.95;
    SWidth=SHeight*p.Results.Aspect;
  end
else
  SWidth=Width;
  SHeight=Height;
end
figure1 = figure('Units','centimeters','PaperType','A4',...
  'PaperOrientation',Orientation,'PaperUnits','centimeters',...
  'InvertHardcopy','off','Color','w','Visible','off');
set(figure1,'Position',[1 1 SWidth SHeight],...
  'PaperPosition',[0 0 Width Height],...
  'PaperSize',[Width Height],...
  FigArgs{:});
end
