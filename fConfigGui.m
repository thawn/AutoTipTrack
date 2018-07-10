function fConfigGui(func,varargin)
switch(func)
  case 'Create'
    if size(varargin)>0
      ConfigGuiCreate(varargin{1});
    else
      ConfigGuiCreate();
    end
  case 'OK'
    ConfigGuiOK(varargin{1});
  case 'cancel'
    close(hConfigGui);
  case 'MolPanel'
    MolPanel(varargin{1});
  case 'FilPanel'
    FilPanel(varargin{1});
  case 'OnlyTrack'
    OnlyTrack(varargin{1});
  case 'UseIntensity'
    UseIntensity(varargin{1});
  case 'UseServer'
    UseServer(varargin{1});
  case 'SetThreshold'
    SetThreshold(varargin{1});
  case 'SetFilter'
    SetFilter(varargin{1});
  case 'SetPath'
    SetPath(varargin{1});
  case 'SetRefPoint'
    SetRefPoint(varargin{1});
  case 'ShowModel'
    ShowModel(varargin{1});
  case 'UpdateParams'
    UpdateParams(varargin{1});
  case 'LimitFrames'
    LimitFrames(varargin{1});
  case 'makeAvi'
    makeAvi(varargin{1});
  case 'imageScalingMode'
    imageScalingMode(varargin{1});
  case 'checkPixSize'
    checkPixSize(varargin{1});
  case 'enableTasks'
    enableTasks(varargin{1});
  case 'Help'
    Help;
end

function ConfigGuiCreate(savePath)
%% create a new configuration window
if nargin<1
  savePath='';
end

Config=ConfigClass; %create the config object
if exist(savePath, 'file')==2
  %if we were passed a file, check if we want to create a file specific
  %config file
  if strendswith(savePath,'_conf.mat')
    config_file=savePath;
  elseif strendswith(savePath,'.stk') || strendswith(savePath,'.tif') || ...
      strendswith(savePath,'.tiff') || strendswith(savePath,'.nd2')
    config_file=[savePath,'_conf.mat'];
  else
    warning('MATLAB:AutoTipTrack:ConfigGuiCreate','Unsupported file type detected %s. Creating config.mat for whole directory.',savePath);
    config_file=fullfile(fileparts(savePath),'config.mat');
  end
else
  config_file=fullfile(savePath, 'config.mat');
end
if exist(config_file, 'file')==2
  %load the configuration from the existing config file
  Config.loadConfig(config_file);
end
hConfigGui.Config=Config.exportConfigStruct;
h=findobj('Tag','hConfigGui');
close(h)

hConfigGui.savePath=savePath;
hConfigGui.fig = figure('Units','normalized','DockControls','off','IntegerHandle','off','MenuBar','none','Name','FIESTA - Configuration',...
  'NumberTitle','off','HandleVisibility','callback','Tag','hConfigGui','Renderer', 'painters',...
  'Visible','off','WindowStyle','normal');

fPlaceFig(hConfigGui.fig,'bigger');

if ispc
  set(hConfigGui.fig,'Color',[236 233 216]/255);
end

c = get(hConfigGui.fig,'Color');

%% positioning variables
colBottom=.04;
colHeight=.88;
colHeight2=.83;

t1st7=[.025 .815 .475 .120];
e1st7=[.525 .865 .300 .120];
u1st7=[.850 .815 .125 .120];

t2nd7=[.025 .675 .475 .120];
e2nd7=[.525 .725 .300 .120];
u2nd7=[.850 .675 .125 .120];

t3rd7=[.025 .530 .475 .120];
e3rd7=[.525 .580 .300 .120];
u3rd7=[.850 .530 .125 .120];

t4th7=[.025 .385 .475 .120];
e4th7=[.525 .435 .300 .120];
u4th7=[.850 .385 .125 .120];

t5th7=[.025 .265 .475 .120];
e5th7=[.525 .315 .300 .120];
u5th7=[.850 .265 .125 .120];

t6th7=[.025 .125 .475 .120];
e6th7=[.525 .170 .300 .120];
u6th7=[.850 .125 .125 .120];

t7th7=[.025 .000 .475 .100];
e7th7=[.525 .025 .300 .120];
u7th7=[.850 .000 .125 .100];

t1st6=[.025 .795 .475 .140];
e1st6=[.525 .845 .300 .140];
u1st6=[.850 .795 .125 .140];

t2nd6=[.025 .635 .475 .140];
e2nd6=[.525 .685 .300 .140];
u2nd6=[.850 .635 .125 .140];

t3rd6=[.025 .470 .475 .140];
e3rd6=[.525 .520 .300 .140];
u3rd6=[.850 .470 .125 .140];

t4th6=[.025 .305 .475 .140];
e4th6=[.525 .355 .300 .140];
u4th6=[.850 .305 .125 .140];

t5th6=[.025 .145 .475 .140];
e5th6=[.525 .190 .300 .140];
u5th6=[.850 .145 .125 .140];

t6th6=[.025 .000 .475 .120];
e6th6=[.525 .025 .300 .140];
u6th6=[.850 .000 .125 .120];

t1st5=[.025 .745 .475 .170];
c1st5=[.025 .835 .950 .170];
e1st5=[.525 .805 .300 .170];
u1st5=[.850 .745 .125 .170];

t2nd5=[.025 .550 .475 .170];
e2nd5=[.525 .610 .300 .170];
u2nd5=[.850 .550 .125 .170]; %#ok<*NASGU>

t3rd5=[.025 .355 .475 .170];
e3rd5=[.525 .415 .300 .170];
u3rd5=[.850 .355 .125 .170];

t4th5=[.025 .160 .475 .170];
r4th5=[.025 .160 .950 .170];
m4th5=[.525 .180 .450 .170];
e4th5=[.525 .220 .300 .170];
u4th5=[.850 .160 .125 .170];

t5th5=[.025 .000 .475 .140];
m5th5=[.525 .000 .450 .135];
e5th5=[.525 .025 .300 .165];
u5th5=[.850 .000 .125 .140];

t1st3=[.025 .600 .475 .300];
m1st3=[.525 .610 .450 .300];

t2nd3=[.025 .370 .475 .200];
e2nd3=[.525 .370 .300 .310];

t3rd3=[.025 .000 .475 .200];
e3rd3=[.525 .025 .300 .310];

t1st2=[.025 .490 .475 .350];
e1st2=[.525 .500 .300 .450];

t2nd2=[.025 .000 .475 .350];
e2nd2=[.525 .025 .300 .450];

t1th1=[.025 .000 .475 .700];
m1th1=[.525 .000 .450 .750];
e1th1=[.525 .025 .300 .775];
u1th1=[.850 .000 .125 .700];

%% create general options panel
hConfigGui.mHelpContext = uicontextmenu('Parent',hConfigGui.fig);

hConfigGui.mHelp = uimenu('Parent',hConfigGui.mHelpContext,'Callback','fConfigGui(''Help'');',...
  'Label','Help','Tag','mHelp');

hConfigGui.pGeneral.panel = uipanel('Parent',hConfigGui.fig,'Units','normalized','Fontsize',10,'Bordertype','none',...
  'Position',[0 0.5 1 0.5],'Tag','pGeneral','Visible','on','BackgroundColor',c);


hConfigGui.pGeneral.tGeneralOptions = uicontrol('Parent',hConfigGui.pGeneral.panel,'Style','text','Units','normalized',...
  'Position',[.0 .96 1 .04],'Tag','tGeneralOptions','Fontsize',10,...
  'String','General options','HorizontalAlignment','center','FontWeight','bold','Enable','on',...
  'BackgroundColor',[0 0 1],'ForegroundColor','white');

%% Stack configuration
hConfigGui.pGeneral.pOptions = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.025 colBottom .25 colHeight],'Tag','pOptions','Visible','on','Title','Stack Options');


hConfigGui.pGeneral.tPixSize = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',t1st7,'Tag','tPixSize','Fontsize',10,...
  'String','Pixel size:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.ePixSize = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','edit','Units','normalized',...
  'Position',e1st7,'Tag','ePixSize','Fontsize',10,'UserData','General options.htm#pixel_size',...
  'String',num2str(hConfigGui.Config.PixSize),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext, ...
  'Callback','fConfigGui(''checkPixSize'',getappdata(0,''hConfigGui''));');

hConfigGui.pGeneral.tNM(1) = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',u1st7,'Tag','tNM','Fontsize',10,'BackgroundColor',c,...
  'String','nm','HorizontalAlignment','left','TooltipString','Right click for Help');

hConfigGui.pGeneral.cPreferStackPixSize = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','checkbox','BackgroundColor',c,'Units','normalized',...
  'Position',[.025 .735 .95 .1],'Tag','cAvi','Fontsize',10,'Value',hConfigGui.Config.PreferStackPixSize,...
  'String','Use pixel size stored in stack, if possible.','HorizontalAlignment','left',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#avi');

hConfigGui.pGeneral.tTimeDiff = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',t3rd7,'Tag','TimeDiff','Fontsize',10,'Enable','off',...
  'String','Time difference:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eTimeDiff = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','edit','Units','normalized',...
  'Position',e3rd7,'Tag','eTimeDiff','Fontsize',10,'Enable','off',...
  'String','','BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#time_difference');

hConfigGui.pGeneral.tMS = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',u3rd7,'Tag','tS','Fontsize',10,'Enable','off',...
  'String','ms','HorizontalAlignment','left','BackgroundColor',c);

if strcmp(hConfigGui.Config.StackType,'TIFF')==1
  set(hConfigGui.pGeneral.eTimeDiff,'String',num2str(hConfigGui.Config.Time),'Enable','on');
  set(hConfigGui.pGeneral.tTimeDiff,'Enable','on');
  set(hConfigGui.pGeneral.tMS,'Enable','on');
end

hConfigGui.pGeneral.tMaxObjects = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',t4th7,'Tag','tMaxObjects','Fontsize',10,'Enable','on',...
  'String','Maximum number of objects:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eMaxObjects = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','edit','Units','normalized',...
  'Position',e4th7,'Tag','eMaxObjects','Fontsize',10,'Enable','on',...
  'String',num2str(hConfigGui.Config.maxObjects),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#time_difference');

hConfigGui.pGeneral.cLimitFrames = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','checkbox','BackgroundColor',c,'Units','normalized',...
  'Position',[.025 .265 .95 .140],'Tag','cAvi','Fontsize',10,'Value',hConfigGui.Config.LastFrame>1,...
  'String','Limit number of frames to track','HorizontalAlignment','left',...
  'Callback','fConfigGui(''LimitFrames'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#avi');
if hConfigGui.Config.LastFrame>1
  enable='on';
else
  enable='off';
end

hConfigGui.pGeneral.tFirstFrame = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',t6th7,'Tag','tFirstFrame','Fontsize',10,...
  'String','First Frame:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eFirstFrame = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','edit','Units','normalized',...
  'Position',e6th7,'Tag','eFirstFrame','Fontsize',10,'Enable',enable,...
  'String',num2str(hConfigGui.Config.FirstTFrame),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#frame');

hConfigGui.pGeneral.tLastFrame = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','text','Units','normalized',...
  'Position',t7th7,'Tag','tLastFrame','Fontsize',10,...
  'String','Last Frame:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eLastFrame = uicontrol('Parent',hConfigGui.pGeneral.pOptions,'Style','edit','Units','normalized',...
  'Position',e7th7,'Tag','eLastFrame','Fontsize',10,'Enable',enable,...
  'String',num2str(hConfigGui.Config.LastFrame),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#frame');

%% Threshold configuration
hConfigGui.pGeneral.pThreshold = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.3 colBottom .2 colHeight],'Tag','pThreshold','Visible','on','Title','Threshold');


hConfigGui.pGeneral.tValueThreshold = uicontrol('Parent',hConfigGui.pGeneral.pThreshold,'Style','text','Units','normalized',...
  'Position',[.025 .795 .4  .14],'Tag','tValueThreshold','Fontsize',10,...
  'String','Value:','HorizontalAlignment','left','BackgroundColor',c);

if strcmp(hConfigGui.Config.Threshold.Mode,'relative')
  ThresholdValue=imag(hConfigGui.Config.Threshold.Value);
  ThresholdUnit='%';
else
  ThresholdValue=real(hConfigGui.Config.Threshold.Value);
  ThresholdUnit='';
end
if strcmp(hConfigGui.Config.Threshold.Mode,'variable')
  enable='off';
else
  enable='on';
end

hConfigGui.pGeneral.eValueThreshold = uicontrol('Parent',hConfigGui.pGeneral.pThreshold,'Style','edit','Units','normalized',...
  'Position',[.45 .845 .375  .14],'Tag','eValueThreshold','Fontsize',10,'Enable',enable,...
  'String',num2str(ThresholdValue),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#area');

hConfigGui.pGeneral.tUnitThreshold = uicontrol('Parent',hConfigGui.pGeneral.pThreshold,'Style','text','Units','normalized',...
  'Position',[.85 .795 .125 .14],'Tag','tUnitThreshold','Fontsize',10,...
  'String',ThresholdUnit,'HorizontalAlignment','left','BackgroundColor',c);

% Threshold Mode
hConfigGui.pGeneral.pThresholdMode = uipanel('Parent',hConfigGui.pGeneral.pThreshold,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.025 .435 .95 .38],'Tag','pThreshold','Visible','on','Title','Threshold Mode');

Value=0;
if strcmp(hConfigGui.Config.Threshold.Mode,'constant')
  Value=1;
end

hConfigGui.pGeneral.rConstant = uicontrol('Parent',hConfigGui.pGeneral.pThresholdMode,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.03 .67 .94  .3],'Tag','rVariable','Fontsize',10,...
  'String','Constant Intensity','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetThreshold'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');



Value=0;
if strcmp(hConfigGui.Config.Threshold.Mode,'relative')
  Value=1;
end

hConfigGui.pGeneral.rRelative = uicontrol('Parent',hConfigGui.pGeneral.pThresholdMode,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.03 .36 .94  .3],'Tag','rRelative','Fontsize',10,'Enable','on',...
  'String','Relative Intensity','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetThreshold'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

Value=0;
if strcmp(hConfigGui.Config.Threshold.Mode,'variable')
  Value=1;
end

hConfigGui.pGeneral.rVariable = uicontrol('Parent',hConfigGui.pGeneral.pThresholdMode,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.03 .05 .94  .3],'Tag','rVariable','Fontsize',10,...
  'String','Variable Intensity','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetThreshold'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

% filter for thresholding
hConfigGui.pGeneral.pFilter = uipanel('Parent',hConfigGui.pGeneral.pThreshold,'Units','normalized','Fontsize',9,'BackgroundColor',c,...
  'Position',[.025 .025 .95 .38],'Tag','pThreshold','Visible','on','Title','Filter (for relative & constant mode)');

Value=0;
if strcmp(hConfigGui.Config.Threshold.Filter,'none')==1
  Value=1;
end

hConfigGui.pGeneral.rFilterNone = uicontrol('Parent',hConfigGui.pGeneral.pFilter,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.03 .67 .94  .3],'Tag','rFilterNone','Fontsize',10,...
  'String','none','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetFilter'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

Value=0;
if strcmp(hConfigGui.Config.Threshold.Filter,'average')==1
  Value=1;
end

hConfigGui.pGeneral.rFilterAverage = uicontrol('Parent',hConfigGui.pGeneral.pFilter,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.03 .36 .94  .3],'Tag','rFilterAverage','Fontsize',10,'Enable','on',...
  'String','average before','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetFilter'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');
Value=0;
if strcmp(hConfigGui.Config.Threshold.Filter,'smooth')==1
  Value=1;
end

hConfigGui.pGeneral.rFilterSmooth = uicontrol('Parent',hConfigGui.pGeneral.pFilter,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',[.025 .025 .95 .38],'Tag','rFilterSmooth','Fontsize',10,...
  'String','smooth after','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetFilter'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

%% object filtering
hConfigGui.pGeneral.pObjFilter = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.525 colBottom .225 colHeight],'Tag','pThreshold','Visible','on','Title','Object Filter');


hConfigGui.pGeneral.tAreaThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t1st6,'Tag','tAreaThreshold','Fontsize',10,...
  'String','Min. Area:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eAreaThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e1st6,'Tag','eAreaThreshold','Fontsize',10,...
  'String',num2str(hConfigGui.Config.Threshold.Area),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#area');

hConfigGui.pGeneral.tPix = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',u1st6,'Tag','tPix','Fontsize',10,...
  'String','pixel','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.tHeightThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t2nd6,'Tag','tHeightThreshold','Fontsize',10,...
  'String','Heigth (SNR):','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eHeightThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e2nd6,'Tag','eHeightThreshold','Fontsize',10,...
  'String',num2str(hConfigGui.Config.Threshold.Height),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#cod');

hConfigGui.pGeneral.tFitThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t3rd6,'Tag','tFitThreshold','Fontsize',10,...
  'String','Fit(CoD):','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eFitThreshold = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e3rd6,'Tag','eFitThreshold','Fontsize',10,...
  'String',num2str(hConfigGui.Config.Threshold.Fit),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#cod');

hConfigGui.pGeneral.tFWHM = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t4th6,'Tag','tCurvatureThreshold','Fontsize',10,...
  'String','FWHM(Est.):','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eFWHM = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e4th6,'Tag','eCurvatureThreshold','Fontsize',10,...
  'String',num2str(hConfigGui.Config.Threshold.FWHM),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#fwhm');

hConfigGui.pGeneral.tNM(2) = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',u4th6,'Tag','tNM','Fontsize',10,...
  'String','nm','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.tBorderMargin = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t5th6,'Tag','tBorderMargin','Fontsize',10,...
  'String','Border Margin:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eBorderMargin = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e5th6,'Tag','eBorderMargin','Fontsize',10,...
  'String',num2str(hConfigGui.Config.BorderMargin),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#border_margin');

hConfigGui.pGeneral.tPixel = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',u5th6,'Tag','tPixel','Fontsize',10,...
  'String','pixel','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.tMinFilLength = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',t6th6,'Tag','tBorderMargin','Fontsize',10,...
  'String','Min Filament Length:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eMinFilLength = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','edit','Units','normalized',...
  'Position',e6th6,'Tag','eBorderMargin','Fontsize',10,...
  'String',num2str(hConfigGui.Config.Threshold.MinFilamentLength),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#border_margin');

hConfigGui.pGeneral.tPixell = uicontrol('Parent',hConfigGui.pGeneral.pObjFilter,'Style','text','Units','normalized',...
  'Position',u6th6,'Tag','tPixel','Fontsize',10,...
  'String','pixel','HorizontalAlignment','left','BackgroundColor',c);

%% makeAvi configuration
hConfigGui.pGeneral.pAvi = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.525 colBottom .225 colHeight],'Tag','pAvi','Visible','on','Title','Avi Options');

hConfigGui.pGeneral.cAvi = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','checkbox','BackgroundColor',c,'Units','normalized',...
  'Position',c1st5,'Tag','cAvi','Fontsize',10,'Value',hConfigGui.Config.Avi.Make,...
  'String','Make an avi file','HorizontalAlignment','left',...
  'Callback','fConfigGui(''makeAvi'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#avi');
if hConfigGui.Config.Avi.Make
  enable='on';
else
  enable='off';
end

hConfigGui.pGeneral.tAviFontSize = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','text','Units','normalized',...
  'Position',t2nd5,'Tag','tAviFontSize','Fontsize',10,...
  'String','Font size:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eAviFontSize = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','edit','Units','normalized',...
  'Position',e2nd5,'Tag','eAviFontSize','Fontsize',10,'Enable',enable,...
  'String',num2str(hConfigGui.Config.Avi.mFontSize),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#avi');

hConfigGui.pGeneral.tAviBarSize = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','text','Units','normalized',...
  'Position',t3rd5,'Tag','tAviBarSize','Fontsize',10,...
  'String','ScaleBar size:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eAviBarSize = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','edit','Units','normalized',...
  'Position',e3rd5,'Tag','eAviBarSize','Fontsize',10,'Enable',enable,...
  'String',num2str(hConfigGui.Config.Avi.BarSize),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#avi');

hConfigGui.pGeneral.tAviBarUnit = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','text','Units','normalized',...
  'Position',u3rd5,'Tag','tAviBarUnit','Fontsize',10,...
  'String',sprintf('%cm',181),'HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.tAviBarPos = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','text','Units','normalized',...
  'Position',t4th5,'Tag','tAviBarPos','Fontsize',10,...
  'String','ScaleBar position:','HorizontalAlignment','left','BackgroundColor',c);

%define available Positions
pos={'Top-left',...
  'Top-right',...
  'Bottom-left',...
  'Bottom-right'};

hConfigGui.pGeneral.mAviBarPos = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','popupmenu','Units','normalized',...
  'Position',m4th5,'Tag','mAviBarPos','Fontsize',10,'String',pos,'Enable',enable,...
  'Value',hConfigGui.Config.Avi.mPosBar,...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,...
  'UserData','Tracking options.htm#avi','BackgroundColor','white');

hConfigGui.pGeneral.tAviTimePos = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','text','Units','normalized',...
  'Position',t5th5,'Tag','tAviTimePos','Fontsize',10,...
  'String','TimeStamp position:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.mAviTimePos = uicontrol('Parent',hConfigGui.pGeneral.pAvi,'Style','popupmenu','Units','normalized',...
  'Position',m5th5,'Tag','mAviTimePos','Fontsize',10,'String',pos,'Enable',enable,...
  'Value',hConfigGui.Config.Avi.mPosTime,...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,...
  'UserData','Tracking options.htm#avi','BackgroundColor','white');

%% Image configuration
hConfigGui.pGeneral.pImage = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.775 colBottom+0.22*colHeight .2 0.8*colHeight],'Tag','pImage','Visible','on','Title','Image Processing');

%Background Subtraction
hConfigGui.pGeneral.pImageBG = uipanel('Parent',hConfigGui.pGeneral.pImage,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.025 .6 .95 .39],'Tag','pImageBG','Visible','on','Title','Background Subtraction');

hConfigGui.pGeneral.tBGRadius = uicontrol('Parent',hConfigGui.pGeneral.pImageBG,'Style','text','Units','normalized',...
  'Position',t1st2,'Tag','tBGRadius','Fontsize',10,...
  'String','Ball radius:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eBGRadius = uicontrol('Parent',hConfigGui.pGeneral.pImageBG,'Style','edit','Units','normalized',...
  'Position',e1st2,'Tag','eBGRadius','Fontsize',10,...
  'String',num2str(hConfigGui.Config.SubtractBackground.BallRadius),'BackgroundColor','white','HorizontalAlignment','center');

hConfigGui.pGeneral.tBGSmoothe = uicontrol('Parent',hConfigGui.pGeneral.pImageBG,'Style','text','Units','normalized',...
  'Position',t2nd2,'Tag','tBGSmoothe','Fontsize',10,...
  'String','Smoothe:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eBGSmoothe = uicontrol('Parent',hConfigGui.pGeneral.pImageBG,'Style','edit','Units','normalized',...
  'Position',e2nd2,'Tag','eBGSmoothe','Fontsize',10,...
  'String',num2str(hConfigGui.Config.SubtractBackground.Smoothe),'BackgroundColor','white','HorizontalAlignment','center');

%Image Scaling
hConfigGui.pGeneral.pImageScaling = uipanel('Parent',hConfigGui.pGeneral.pImage,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.025 .005 .95 .59],'Tag','pImageScaling','Visible','on','Title','Image Scaling');

hConfigGui.pGeneral.tImageScalingMode = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','text','Units','normalized',...
  'Position',t1st3,'Tag','tImageScalingMode','Fontsize',10,...
  'String','Scaling mode:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.mImageScalingMode = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','popupmenu','Units','normalized',...
  'Position',m1st3,'Tag','mImageScalingMode','Fontsize',10,'String',hConfigGui.Config.ImageScaling.Modes,...
  'Value',hConfigGui.Config.ImageScaling.ModeNo,'BackgroundColor','white',...
  'Callback','fConfigGui(''imageScalingMode'',getappdata(0,''hConfigGui''));');

hConfigGui.pGeneral.tImageScalingBlack = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','text','Units','normalized',...
  'Position',t2nd3,'Tag','tImageScalingBlack','Fontsize',10,...
  'String','Black:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eImageScalingBlack = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','edit','Units','normalized',...
  'Position',e2nd3,'Tag','eImageScalingBlack','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ImageScaling.Black),'BackgroundColor','white','HorizontalAlignment','center');

hConfigGui.pGeneral.tImageScalingWhite = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','text','Units','normalized',...
  'Position',t3rd3,'Tag','tImageScalingWhite','Fontsize',10,...
  'String','White:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.eImageScalingWhite = uicontrol('Parent',hConfigGui.pGeneral.pImageScaling,'Style','edit','Units','normalized',...
  'Position',e3rd3,'Tag','eImageScalingWhite','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ImageScaling.White),'BackgroundColor','white','HorizontalAlignment','center');

imageScalingMode(hConfigGui);

%% Evaluation configuration
hConfigGui.pGeneral.pEval = uipanel('Parent',hConfigGui.pGeneral.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.775 colBottom .2 0.2*colHeight],'Tag','pEval','Visible','on','Title','Evaluation Options');

hConfigGui.pGeneral.tEvalClass = uicontrol('Parent',hConfigGui.pGeneral.pEval,'Style','text','Units','normalized',...
  'Position',t1th1,'Tag','tAviTimePos','Fontsize',10,...
  'String','Evaluation class:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pGeneral.mEvalClass = uicontrol('Parent',hConfigGui.pGeneral.pEval,'Style','popupmenu','Units','normalized',...
  'Position',m1th1,'Tag','mAviTimePos','Fontsize',10,'String',hConfigGui.Config.Evaluation.EvalClassNames,...
  'Value', hConfigGui.Config.Evaluation.EvalClassNo,...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,...
  'UserData','Tracking options.htm#avi','BackgroundColor','white',...
  'Callback','fConfigGui(''enableTasks'',getappdata(0,''hConfigGui''));');

%% create track options panel
hConfigGui.pMolecules.panel = uipanel('Parent',hConfigGui.fig,'Units','normalized','Fontsize',10,'Bordertype','none',...
  'Position',[0 .05 1 0.44],'Tag','pNorm','Visible','on','BackgroundColor',c);


hConfigGui.pMolecules.tTrackingOptions = uicontrol('Parent',hConfigGui.pMolecules.panel,'Style','text','Units','normalized',...
  'Position',[.0 .955 1 .045],'Tag','ConfigGui.TrackingOptions','Fontsize',10,...
  'String','Track options','HorizontalAlignment','center','FontWeight','bold','Enable','on',...
  'BackgroundColor',[0 0 1],'ForegroundColor','white');

hConfigGui.pMolecules.tMoleculesM = uicontrol('Parent',hConfigGui.pMolecules.panel,'Style','text','Units','normalized',...
  'Position',[.0 .91 1 .045],'Tag','ConfigGui.tMoleculesM','Fontsize',10,...
  'String','Filament Tips','HorizontalAlignment','center','FontWeight','bold','Enable','on',...
  'BackgroundColor',[.5 .5 1],'ForegroundColor','white');

%% Connecting options
hConfigGui.pMolecules.pConnect = uipanel('Parent',hConfigGui.pMolecules.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.025 colBottom .3 colHeight2],'Tag','pConnect','Visible','on','Title','Connecting');

hConfigGui.pMolecules.tMaxVelocity = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',t1st5,'Tag','tMaxVelocity','Fontsize',10,...
  'String','Max. Velocity:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eMaxVelocity = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','edit','Units','normalized',...
  'Position',e1st5,'Tag','eMaxVelocity','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.MaxVelocity),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#max_velocity');

hConfigGui.pMolecules.tNMpS = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',u1st5,'Tag','tNMpS','Fontsize',10,...
  'String','nm/s','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.tNumVerification = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',t2nd5,'Tag','tNumVerification','Fontsize',10,...
  'String','Verification Steps:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eNumVerification = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','edit','Units','normalized',...
  'Position',e2nd5,'Tag','eNumVerification','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.NumberVerification),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#num_verification');

hConfigGui.pMolecules.tWeightPosition = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',t3rd5,'Tag','tWeightMolecule','Fontsize',10,...
  'String','Weight Position:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eWeightPos = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','edit','Units','normalized',...
  'Position',e3rd5,'Tag','eWeightMolPos','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.Position*100),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#weights');

hConfigGui.pMolecules.tPercent(1) = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',u3rd5,'Tag','tPercent','Fontsize',10,'BackgroundColor',c,...
  'String','%','HorizontalAlignment','left');

hConfigGui.pMolecules.tWeightDirection = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',t4th5,'Tag','tWeightDirection','Fontsize',10,...
  'String','Weight Direction:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eWeightDir = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','edit','Units','normalized',...
  'Position',e4th5,'Tag','eWeightMolDir','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.Direction*100),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#weights');

hConfigGui.pMolecules.tPercent(2) = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',u4th5,'Tag','tPercent','Fontsize',10,...
  'String','%','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.tWeightSpeed = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',t5th5,'Tag','tWeightSpeed','Fontsize',10,...
  'String','Weight Speed:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eWeightSpd = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','edit','Units','normalized',...
  'Position',e5th5,'Tag','eWeightMolSpd','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.Speed*100),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#weights');

hConfigGui.pMolecules.tPercent(3) = uicontrol('Parent',hConfigGui.pMolecules.pConnect,'Style','text','Units','normalized',...
  'Position',u5th5,'Tag','tPercent','Fontsize',10,...
  'String','%','HorizontalAlignment','left','BackgroundColor',c);


%% Track options
hConfigGui.pMolecules.pTracks = uipanel('Parent',hConfigGui.pMolecules.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[0.35 colBottom .3 colHeight2],'Tag','pConnect','Visible','on','Title','Tracks');

hConfigGui.pMolecules.tMinLength = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',t1st5,'Tag','tMinLength','Fontsize',10,'BackgroundColor',c,...
  'String','Minimum Length:','HorizontalAlignment','left');

hConfigGui.pMolecules.eMinLength = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','edit','Units','normalized',...
  'Position',e1st5,'Tag','eMinLength','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.MinLength),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#min_length');

hConfigGui.pMolecules.tFramesMin = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',u1st5,'Tag','tFrames','Fontsize',10,'BackgroundColor',c,...
  'String','frames','HorizontalAlignment','left');

hConfigGui.pMolecules.tMaxBreak = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',t3rd5,'Tag','tMaxBreak','Fontsize',10,...
  'String','Maximum Break:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eMaxBreak = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','edit','Units','normalized',...
  'Position',e3rd5,'Tag','eMaxBreak','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.MaxBreak),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#max_break');

hConfigGui.pMolecules.tFramesMax = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',u3rd5,'Tag','tFrames','Fontsize',10,'BackgroundColor',c,...
  'String','frames','HorizontalAlignment','left');

hConfigGui.pMolecules.tMaxAngle = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',t5th5,'Tag','tMaxAngle','Fontsize',10,...
  'String','Maximum Angle:','HorizontalAlignment','left','BackgroundColor',c);

hConfigGui.pMolecules.eMaxAngle = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','edit','Units','normalized',...
  'Position',e5th5,'Tag','eMaxAngle','Fontsize',10,...
  'String',num2str(hConfigGui.Config.ConnectMol.MaxAngle),'BackgroundColor','white','HorizontalAlignment','center',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#max_angle');

hConfigGui.pMolecules.tDeg = uicontrol('Parent',hConfigGui.pMolecules.pTracks,'Style','text','Units','normalized',...
  'Position',u5th5,'Tag','tDeg','Fontsize',14,...
  'String',sprintf('%c',176),'HorizontalAlignment','left','BackgroundColor',c);

%% path options
hConfigGui.pMolecules.pPaths = uipanel('Parent',hConfigGui.pMolecules.panel,'Units','normalized','Fontsize',10,'BackgroundColor',c,...
  'Position',[.675 colBottom .3 colHeight2],'Tag','pThreshold','Visible','on','Title','Calculate Paths');

Value=0;
if ~hConfigGui.Config.Path.Generate
  Value=1;
end
hConfigGui.pMolecules.rPathsNone = uicontrol('Parent',hConfigGui.pMolecules.pPaths,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',t1st5,'Tag','rPathsNone','Fontsize',10,...
  'String','disable','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetPath'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

Value=0;
if hConfigGui.Config.Path.Generate && strcmp(hConfigGui.Config.Path.Method,'Fit')==1
  Value=1;
end
hConfigGui.pMolecules.rPathsFit = uicontrol('Parent',hConfigGui.pMolecules.pPaths,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',t2nd5,'Tag','rPathsFit','Fontsize',10,'Enable','on',...
  'String','fit','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetPath'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

Value=0;
if hConfigGui.Config.Path.Generate && strcmp(hConfigGui.Config.Path.Method,'Average')==1
  Value=1;
end
hConfigGui.pMolecules.rPathsAverage = uicontrol('Parent',hConfigGui.pMolecules.pPaths,'Style','radiobutton','BackgroundColor',c,'Units','normalized',...
  'Position',t3rd5,'Tag','rPathsAverage','Fontsize',10,...
  'String','average','HorizontalAlignment','left','Value',Value,...
  'Callback','fConfigGui(''SetPath'',getappdata(0,''hConfigGui''));',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','General options.htm#intensity');

hConfigGui.pMolecules.cPathsRedo = uicontrol('Parent',hConfigGui.pMolecules.pPaths,'Style','checkbox','BackgroundColor',c,'Units','normalized',...
  'Position',r4th5,'Tag','cPathsRedo','Fontsize',10,'Value',strcmp(hConfigGui.Config.Path.Status,'Done'),...
  'String','recalculate paths (for reevaluation)','HorizontalAlignment','left',...
  'TooltipString','Right click for Help','UIContextMenu',hConfigGui.mHelpContext,'UserData','Tracking options.htm#avi');


%% save and cancel buttons
hConfigGui.pButtons = uipanel('Parent',hConfigGui.fig,'Units','normalized','Fontsize',10,'Bordertype','none',...
  'Position',[0 0 1 0.06],'Tag','pNorm','Visible','on','BackgroundColor',c);

hConfigGui.bApply = uicontrol('Parent',hConfigGui.pButtons,'Style','pushbutton','Units','normalized',...
  'Position',[.5 .2 .2 .7],'Tag','bOkay','Fontsize',10,...
  'String','Save','Callback','fConfigGui(''OK'',getappdata(0,''hConfigGui''));');

hConfigGui.bCancel= uicontrol('Parent',hConfigGui.pButtons,'Style','pushbutton','Units','normalized',...
  'Position',[.75 .2 .2 .7],'Tag','bCancel','Fontsize',10,...
  'String','Cancel','Callback','close(findobj(0,''Tag'',''hConfigGui''));');

set(hConfigGui.fig, 'CloseRequestFcn',@Close);
setappdata(0,'hConfigGui',hConfigGui);
hConfigGui.Config=enableTasks(hConfigGui);

uiwait(hConfigGui.fig);



function Close(hObject,eventdata) %#ok<INUSD>
delete(findobj('Tag','hConfigGui'));
% fShared('ReturnFocus');


function LimitFrames(hConfigGui)
if get(gcbo,'Value')==1
  set(hConfigGui.pGeneral.eFirstFrame,'Enable','on');
  set(hConfigGui.pGeneral.eLastFrame,'Enable','on');
else
  set(hConfigGui.pGeneral.eFirstFrame,'Enable','off','String','1');
  set(hConfigGui.pGeneral.eLastFrame,'Enable','off','String','1');
end

function makeAvi(hConfigGui)
setAviControlState(hConfigGui,get(gcbo,'Value'))

function setAviControlState(hConfigGui,enable)
if enable
  set(hConfigGui.pGeneral.eAviFontSize,'Enable','on');
  set(hConfigGui.pGeneral.eAviBarSize,'Enable','on');
  set(hConfigGui.pGeneral.mAviBarPos,'Enable','on');
  set(hConfigGui.pGeneral.mAviTimePos,'Enable','on');
else
  set(hConfigGui.pGeneral.eAviFontSize,'Enable','off');
  set(hConfigGui.pGeneral.eAviBarSize,'Enable','off');
  set(hConfigGui.pGeneral.mAviBarPos,'Enable','off');
  set(hConfigGui.pGeneral.mAviTimePos,'Enable','off');
end

function imageScalingMode(hConfigGui)
if get(hConfigGui.pGeneral.mImageScalingMode,'Value')==1
  set(hConfigGui.pGeneral.eImageScalingBlack,'Enable','off');
  set(hConfigGui.pGeneral.eImageScalingWhite,'Enable','off');
else
  set(hConfigGui.pGeneral.eImageScalingBlack,'Enable','on');
  set(hConfigGui.pGeneral.eImageScalingWhite,'Enable','on');
end

function MolPanel(hConfigGui)
set(hConfigGui.pMolecules.panel,'Visible','on');
set(hConfigGui.pFilaments.panel,'Visible','off');


function FilPanel(hConfigGui)
set(hConfigGui.pMolecules.panel,'Visible','off');
set(hConfigGui.pFilaments.panel,'Visible','on');


function UseIntensity(hConfigGui)
if get(gcbo,'Value')==1
  set(hConfigGui.pMolecules.eWeightInt,'Enable','on');
else
  set(hConfigGui.pMolecules.eWeightInt,'Enable','off');
end


function UseServer(hConfigGui)
if get(gcbo,'Value')==1
  set(hConfigGui.pGeneral.tServerName,'Enable','on');
  set(hConfigGui.pGeneral.eServerName,'Enable','on');
else
  set(hConfigGui.pGeneral.tServerName,'Enable','off');
  set(hConfigGui.pGeneral.eServerName,'Enable','off');
end

function SetThreshold(hConfigGui)

if gcbo==hConfigGui.pGeneral.rVariable
  set(hConfigGui.pGeneral.rVariable,'Value',1);
  set(hConfigGui.pGeneral.rConstant,'Value',0);
  set(hConfigGui.pGeneral.rRelative,'Value',0);
  set(hConfigGui.pGeneral.tUnitThreshold,'String','');
  set(hConfigGui.pGeneral.eValueThreshold,'Enable','off');
elseif gcbo==hConfigGui.pGeneral.rConstant
  set(hConfigGui.pGeneral.rVariable,'Value',0);
  set(hConfigGui.pGeneral.rConstant,'Value',1);
  set(hConfigGui.pGeneral.rRelative,'Value',0);
  set(hConfigGui.pGeneral.tUnitThreshold,'String','');
  set(hConfigGui.pGeneral.eValueThreshold,'Enable','on','String',num2str(real(hConfigGui.Config.Threshold.Value)));
else
  set(hConfigGui.pGeneral.rVariable,'Value',0);
  set(hConfigGui.pGeneral.rConstant,'Value',0);
  set(hConfigGui.pGeneral.rRelative,'Value',1);
  set(hConfigGui.pGeneral.tUnitThreshold,'String','%');
  set(hConfigGui.pGeneral.eValueThreshold,'Enable','on','String',num2str(imag(hConfigGui.Config.Threshold.Value)));
end

function SetFilter(hConfigGui)
if gcbo==hConfigGui.pGeneral.rFilterNone
  set(hConfigGui.pGeneral.rFilterNone,'Value',1);
  set(hConfigGui.pGeneral.rFilterAverage,'Value',0);
  set(hConfigGui.pGeneral.rFilterSmooth,'Value',0);
elseif gcbo==hConfigGui.pGeneral.rFilterAverage
  set(hConfigGui.pGeneral.rFilterNone,'Value',0);
  set(hConfigGui.pGeneral.rFilterAverage,'Value',1);
  set(hConfigGui.pGeneral.rFilterSmooth,'Value',0);
else
  set(hConfigGui.pGeneral.rFilterNone,'Value',0);
  set(hConfigGui.pGeneral.rFilterAverage,'Value',0);
  set(hConfigGui.pGeneral.rFilterSmooth,'Value',1);
end

function SetPath(hConfigGui)
if gcbo==hConfigGui.pMolecules.rPathsFit
  set(hConfigGui.pMolecules.rPathsNone,'Value',0);
  set(hConfigGui.pMolecules.rPathsFit,'Value',1);
  set(hConfigGui.pMolecules.rPathsAverage,'Value',0);
elseif gcbo==hConfigGui.pMolecules.rPathsAverage
  set(hConfigGui.pMolecules.rPathsNone,'Value',0);
  set(hConfigGui.pMolecules.rPathsFit,'Value',0);
  set(hConfigGui.pMolecules.rPathsAverage,'Value',1);
else
  set(hConfigGui.pMolecules.rPathsNone,'Value',1);
  set(hConfigGui.pMolecules.rPathsFit,'Value',0);
  set(hConfigGui.pMolecules.rPathsAverage,'Value',0);
end

function SetRefPoint(hConfigGui)
if gcbo==hConfigGui.pRefPoint.rStart
  set(hConfigGui.pRefPoint.rStart,'Value',1);
  set(hConfigGui.pRefPoint.rCenter,'Value',0);
  set(hConfigGui.pRefPoint.rEnd,'Value',0);
elseif gcbo==hConfigGui.pRefPoint.rCenter
  set(hConfigGui.pRefPoint.rStart,'Value',0);
  set(hConfigGui.pRefPoint.rCenter,'Value',1);
  set(hConfigGui.pRefPoint.rEnd,'Value',0);
else
  set(hConfigGui.pRefPoint.rStart,'Value',0);
  set(hConfigGui.pRefPoint.rCenter,'Value',0);
  set(hConfigGui.pRefPoint.rEnd,'Value',1);
end

function ConfigGuiOK(hConfigGui)
uiresume(hConfigGui.fig);
err=[];
tempConfig = hConfigGui.Config;
tempConfig.PixSize=str2double(get(hConfigGui.pGeneral.ePixSize,'String'));
if tempConfig.PixSize<=0||isnan(tempConfig.PixSize)
  err{length(err)+1}='Wrong pixel size input';
end

tempConfig.PreferStackPixSize=get(hConfigGui.pGeneral.cPreferStackPixSize, 'Value');

if strcmp(tempConfig.StackType,'TIFF')==1
  tempConfig.Time = str2double(get(hConfigGui.pGeneral.eTimeDiff,'String'));
  if tempConfig.Time<=0||isnan(tempConfig.Time)
    err{length(err)+1}='Wrong time difference input for TIFF file';
  end
end

tempConfig.maxObjects=str2double(get(hConfigGui.pGeneral.eMaxObjects,'String'));
if tempConfig.maxObjects<=0||isnan(tempConfig.maxObjects)
  err{length(err)+1}='Wrong maximum number of objects input';
end

tempConfig.FirstTFrame=round(str2double(get(hConfigGui.pGeneral.eFirstFrame,'String')));
if tempConfig.FirstTFrame<0||isnan(tempConfig.FirstTFrame) %||tempConfig.FirstTFrame>hMainGui.Values.MaxIdx
    err{length(err)+1}='First frame input wrong or out of range';
else
    tempConfig.FirstCFrame=tempConfig.FirstTFrame;
end

tempConfig.LastFrame=str2double(get(hConfigGui.pGeneral.eLastFrame,'String'));
if tempConfig.LastFrame<0||isnan(tempConfig.LastFrame) %||tempConfig.LastFrame>hMainGui.Values.MaxIdx
    err{length(err)+1}='Last frame input wrong or out of range';
elseif tempConfig.FirstTFrame<0||isnan(tempConfig.FirstTFrame)
    err{length(err)+1}='First frame input wrong or out of range';
end


%%
tempConfig.Avi.Make = get(hConfigGui.pGeneral.cAvi,'Value');

tempConfig.Avi.mFontSize = str2double(get(hConfigGui.pGeneral.eAviFontSize,'String'));
if tempConfig.Avi.mFontSize<=0||tempConfig.Avi.mFontSize>1||isnan(tempConfig.Avi.mFontSize)
  err{length(err)+1}='Wrong avi label font size input';
end

tempConfig.Avi.BarSize = str2double(get(hConfigGui.pGeneral.eAviBarSize,'String'));
if tempConfig.Avi.BarSize<=0||isnan(tempConfig.Avi.BarSize)
  err{length(err)+1}='Wrong avi scale bar size input';
end

tempConfig.Avi.mPosBar = get(hConfigGui.pGeneral.mAviBarPos,'Value');
tempConfig.Avi.mPosTime = get(hConfigGui.pGeneral.mAviTimePos,'Value');

tempConfig.SubtractBackground.BallRadius=str2double(get(hConfigGui.pGeneral.eBGRadius,'String'));
tempConfig.SubtractBackground.Smoothe=str2double(get(hConfigGui.pGeneral.eBGSmoothe,'String'));
tempConfig.ImageScaling.ModeNo=get(hConfigGui.pGeneral.mImageScalingMode,'Value');
tempConfig.ImageScaling.Black=str2double(get(hConfigGui.pGeneral.eImageScalingBlack,'String'));
tempConfig.ImageScaling.White=str2double(get(hConfigGui.pGeneral.eImageScalingWhite,'String'));

tempConfig.Evaluation.EvalClassNo=get(hConfigGui.pGeneral.mEvalClass,'Value');
tempConfig.EvaluationClassName=hConfigGui.Config.Evaluation.EvalClassNames{tempConfig.Evaluation.EvalClassNo};

Threshold=str2double(get(hConfigGui.pGeneral.eValueThreshold,'String'));
if Threshold<=0||isnan(Threshold)
  err{length(err)+1}='Wrong threshold value input';
end

tempConfig.Threshold.Area=str2double(get(hConfigGui.pGeneral.eAreaThreshold,'String'));
if tempConfig.Threshold.Area<=0||isnan(tempConfig.Threshold.Area)
  err{length(err)+1}='Wrong area threshold input';
end

tempConfig.Threshold.Height=str2double(get(hConfigGui.pGeneral.eHeightThreshold,'String'));
if tempConfig.Threshold.Height<=0||isnan(tempConfig.Threshold.Height)
  err{length(err)+1}='Wrong height threshold input';
end

tempConfig.Threshold.Fit=str2double(get(hConfigGui.pGeneral.eFitThreshold,'String'));
if tempConfig.Threshold.Fit<-1||isnan(tempConfig.Threshold.Area)||tempConfig.Threshold.Fit>1
  err{length(err)+1}='Coefficient of determination must be between -1 and 1';
end

tempConfig.Threshold.FWHM=str2double(get(hConfigGui.pGeneral.eFWHM,'String'));
if tempConfig.Threshold.FWHM<=0||isnan(tempConfig.Threshold.FWHM)
  err{length(err)+1}='Wrong FWHM estimate input';
end

if tempConfig.Threshold.FWHM<2*tempConfig.PixSize
  err{length(err)+1}='FWHM estimate is smaller than 2 pixels';
end

tempConfig.BorderMargin=str2double(get(hConfigGui.pGeneral.eBorderMargin,'String'));
if tempConfig.BorderMargin<0||isnan(tempConfig.BorderMargin)
  err{length(err)+1}='Wrong border margin input';
end

tempConfig.Threshold.MinFilamentLength=str2double(get(hConfigGui.pGeneral.eMinFilLength,'String'));
if tempConfig.Threshold.MinFilamentLength<2||isnan(tempConfig.BorderMargin)
  err{length(err)+1}='Filaments must be at least 2 pixels long';
end


if get(hConfigGui.pGeneral.rConstant,'Value')==1
  tempConfig.Threshold.Mode='constant';
  tempConfig.Threshold.Value=Threshold;
end
if get(hConfigGui.pGeneral.rRelative,'Value')==1
  tempConfig.Threshold.Mode='relative';
  tempConfig.Threshold.Value=Threshold*1i;
end
if get(hConfigGui.pGeneral.rVariable,'Value')==1
  tempConfig.Threshold.Mode='variable';
  tempConfig.Threshold.Value=[];
end

r=get(hConfigGui.pGeneral.pFilter,'Children');
k=find(cell2mat(get(r,'Value'))==1,1);
tag=get(r(k),'Tag');
if strcmp( tag, 'rFilterAverage' )
  tempConfig.Threshold.Filter='average';
elseif strcmp( tag, 'rFilterSmooth' )
  tempConfig.Threshold.Filter='smooth';
else
  tempConfig.Threshold.Filter='none';
end

tempConfig.ConnectMol.MaxVelocity=str2double(get(hConfigGui.pMolecules.eMaxVelocity,'String'));
if tempConfig.ConnectMol.MaxVelocity<=0||isnan(tempConfig.ConnectMol.MaxVelocity)
  err{length(err)+1}='Wrong maximum velocity input for molecules';
end

tempConfig.ConnectMol.NumberVerification=str2double(get(hConfigGui.pMolecules.eNumVerification,'String'));
if tempConfig.ConnectMol.NumberVerification<=0||isnan(tempConfig.ConnectMol.NumberVerification)
  err{length(err)+1}='Wrong number fo verification input for molecules';
end

tempConfig.ConnectMol.Position=str2double(get(hConfigGui.pMolecules.eWeightPos,'String'))/100;
if tempConfig.ConnectMol.Position<0||isnan(tempConfig.ConnectMol.Position)
  err{length(err)+1}='Wrong position weight input for molecules';
end

tempConfig.ConnectMol.Direction=str2double(get(hConfigGui.pMolecules.eWeightDir,'String'))/100;
if tempConfig.ConnectMol.Direction<0||isnan(tempConfig.ConnectMol.Direction)
  err{length(err)+1}='Wrong direction weight input for molecules';
end

tempConfig.ConnectMol.Speed=str2double(get(hConfigGui.pMolecules.eWeightSpd,'String'))/100;
if tempConfig.ConnectMol.Speed<0||isnan(tempConfig.ConnectMol.Speed)
  err{length(err)+1}='Wrong speed weight input for molecules';
end

if abs(tempConfig.ConnectMol.Position+tempConfig.ConnectMol.Direction+tempConfig.ConnectMol.Speed+tempConfig.ConnectMol.IntensityOrLength-1.0)>1e-8
  err{length(err)+1}='Connecting weights for molecules do not equal 100%';
end

tempConfig.ConnectMol.MinLength=str2double(get(hConfigGui.pMolecules.eMinLength,'String'));
if tempConfig.ConnectMol.MinLength<=0||isnan(tempConfig.ConnectMol.MinLength)
  err{length(err)+1}='Wrong minimum length input for molecules';
end

tempConfig.ConnectMol.MaxBreak=str2double(get(hConfigGui.pMolecules.eMaxBreak,'String'));
if tempConfig.ConnectMol.MaxBreak<0||isnan(tempConfig.ConnectMol.MaxBreak)
  err{length(err)+1}='Wrong maximum break input for molecules';
end

tempConfig.ConnectMol.MaxAngle=str2double(get(hConfigGui.pMolecules.eMaxAngle,'String'));
if tempConfig.ConnectMol.MaxAngle<=0||isnan(tempConfig.ConnectMol.MaxAngle)
  err{length(err)+1}='Wrong maximum angle input for molecules';
end

if get(hConfigGui.pMolecules.rPathsFit,'Value')==1
  tempConfig.Path.Method='Fit';
  tempConfig.Path.Generate=true;
elseif get(hConfigGui.pMolecules.rPathsAverage,'Value')==1
  tempConfig.Path.Method='Average';
  tempConfig.Path.Generate=true;
else
  tempConfig.Path.Generate=false;
end

if get(hConfigGui.pMolecules.cPathsRedo,'Value')==1
  tempConfig.Path.Status='Redo';
else
  tempConfig.Path.Status='TBD';
end

tempConfig.Tasks=hConfigGui.Config.Evaluation.TasksNeeded{get(hConfigGui.pGeneral.mEvalClass,'Value')};

warn='continue';

if isempty(err)&&strcmp(warn,'continue')
  Config = ConfigClass('ConfigStructure',tempConfig);
  if isempty(hConfigGui.savePath)
    hConfigGui.savePath=uigetdir('', 'Select the folder where you want to save the configuration (i.e. the experiment folder)');
  end
  if exist(hConfigGui.savePath,'file')==7
    file=fullfile(hConfigGui.savePath , 'config.mat');
  elseif exist(hConfigGui.savePath,'file')==2
    file=[hConfigGui.savePath '_conf.mat'];
  else
    error('MATLAB:AutoTipTrack:fConfigGui','Cannot create config file, save path: %s is invalid.',hConfigGui.savePath)
  end
  Config.save(file);
  clear('Config');
  close(findobj('Tag','hConfigGui'));

else
  if ~isempty(err);
    fMsgDlg(err,'error');
  end
end

function CheckServer(Config) %#ok<DEFNU>
%check if FIESTA tracking server is available
if ispc
  %for PC just access the tracking server directory
  DirServer = ['\\' Config.TrackingServer '\FIESTASERVER\'];
elseif ismac
  %for MAC ask user if he wants to connect to tracking server
  DirServer = '/Volumes/FIESTASERVER/';
else
  %error message for users of Linux version of MatLab
  errordlg('Your Operating System is not yet supported','FIESTA Installation Error','modal');
  return;
end

%try to access tracking server
if isempty(dir(DirServer))
  if ispc
    fMsgDlg({'Could not connect to the server','Make sure that you permission to access the server'},'error');
  elseif ismac
    fMsgDlg({'Could not connect to the server','Make sure that you are connected to',['smb://' Config.TrackingServer '/FIESTASERVER/']},'warning');
  end
end

function Help
openhelp(sprintf('content\\GUI\\Configuration\\%s',get(gco,'UserData')));

function UpdateParams(hConfigGui)
n=round(str2double(get(hConfigGui.pMolecules.eMaxFunc,'String')));
set(hConfigGui.pMolecules.eMaxFunc,'String',num2str(n));
if n>0
  switch(get(hConfigGui.pMolecules.mModel,'Value'))
    case 1
      params=n*4;
    case 2
      params=n*6;
    case 3
      params=n*7;
    case 4
      params=n*10;
  end
  set(hConfigGui.pMolecules.eParams,'String',num2str(params));
  if params>20
    set(hConfigGui.pMolecules.eParams,'BackgroundColor','red');
  else
    set(hConfigGui.pMolecules.eParams,'BackgroundColor',get(hConfigGui.pMolecules.pModel,'BackgroundColor'));
  end
else
  set(hConfigGui.pMolecules.eParams,'String','','BackgroundColor','red');
  set(hConfigGui.pMolecules.eMaxFunc,'String','');
end

function ShowModel(hConfigGui)
set(gcf, 'Renderer', 'painters')
n=str2double(get(hConfigGui.pMolecules.eMaxFunc,'String'));
[X,Y] = meshgrid(-10:1:10);
if n>0
  label=[];
  label2=[];
  label{1}='\(h\) ... Height of Peak';
  label{2}='\(\hat{x}\) ... X Position of Center';
  label{3}='\(\hat{y}\) ... Y Position of Center';
  switch(get(hConfigGui.pMolecules.mModel,'Value'))
    case 1
      equation='\(I(x,y) = \frac{h}{2\pi\sigma^2} \cdot \exp \left[ -\frac{\left(x-\hat{x}\right)^2+\left(y-\hat{y}\right)^2 }{2\sigma^2} \right]\)';
      label{4}='\(\sigma\) ... Width of Peak';
      Z=Calc2DPeakCircle(X,Y);
    case 2
      label{4}='\(\sigma_x\) ... Width in X Direction';
      label{5}='\(\sigma_y\) ... Width in Y Direction';
      label{6}='\(\rho\) ... Orientation';
      equation='\(I(x,y) = \frac{h}{2\pi\sigma_x\sigma_x\sqrt{1-\rho^2}} \cdot \exp \left[-\frac{1}{(1-\rho^2)} \left( \frac{\left(x-\hat{x}\right)^2}{2\sigma^2_x} -\rho\,\frac{\left(x-\hat{x}\right)}{\sigma_x}\,\frac{\left(y-\hat{y}\right)}{\sigma_y}+ \frac{\left(y-\hat{y}\right)^2}{2\sigma^2_y}\right) \right]\)';
      Z=Calc2DPeakEllipses(X,Y);
    case 3
      label{4}='\(\sigma\) ... Width of Peak';
      label2{1}='\(h_r\) ... Height of Ring';
      label2{2}='\(r\) ... Radius of Ring';
      label2{3}='\(\sigma_r\) ... Width of Ring';
      equation='\(I(x,y) = \frac{h}{2\pi\sigma^2} \cdot \exp \left[-\frac{\left(x-\hat{x}\right)^2+\left(y-\hat{y}\right)^2}{2\sigma^2}  \right]+\frac{h_r}{2\pi\sigma^2} \cdot \exp\left[ -\frac{\left(\sqrt{ \left(x-\hat{x}\right)^2+\left(y-\hat{y}\right)^2}-r\right)^2}{2\sigma^2_r} \right]\)';
      Z=Calc2DPeakRing(X,Y);
    case 4
      label{4}='\(\sigma\) ... Width of Peak';
      label2{1}='\(h_{r,1}\) ... Height of first Ring';
      label2{2}='\(r_1\) ... Radius of first Ring';
      label2{3}='\(\sigma_{r,1}\) ... Width of first Ring';
      label2{4}='\(h_{r,2}\) ... Height of second Ring';
      label2{5}='\(r_2\) ... Radius of second Ring';
      label2{6}='\(\sigma_{r,2}\) ... Width of second Ring';
      equation='\(I(x,y) = \frac{h}{2\pi\sigma^2} \cdot \exp \left[-\frac{(x-\hat{x})^2+(y-\hat{y})^2}{2\sigma^2}  \right]+\sum_{n=1}^{2}\frac{(-1)^n h_{r,n}}{2\pi\sigma^2_{r,n}} \cdot \exp\left[-\frac{\left (\sqrt{(x-\hat{x})^2+(y-\hat{y})^2}-r_n  \right )^2}{2\sigma^2_{r,n}} \right]\)';
      Z=Calc2DPeak2Rings(X,Y);
  end
  
  cla(hConfigGui.pMolecules.aModelLabel);
  text('Parent',hConfigGui.pMolecules.aModelLabel,'Interpreter','latex','Position',[0.01 0.99],...
    'FontSize',14,'BackgroundColor',get(hConfigGui.pMolecules.pModel,'BackgroundColor'),'String',label,'VerticalAlignment','top');
  if ~isempty(label2)
    text('Parent',hConfigGui.pMolecules.aModelLabel,'Interpreter','latex','Position',[0.6 0.99],...
      'FontSize',14,'BackgroundColor',get(hConfigGui.pMolecules.pModel,'BackgroundColor'),'String',label2,'VerticalAlignment','top');
  end
  set(hConfigGui.pMolecules.aModelLabel,'Visible','off');
  
  cla(hConfigGui.pMolecules.aModelPreview);
  surf(X,Y,Z,'Parent',hConfigGui.pMolecules.aModelPreview);
  set(hConfigGui.pMolecules.aModelPreview,{'XLim','YLim','ZLim'},{[-10 10],[-10 10],[0 1]},'CameraViewAngle',22,'CameraPosition',[-10 -30 2],'CameraTarget',[0 0 0])
  set(hConfigGui.pMolecules.aModelPreview,'Visible','off');
  
  cla(hConfigGui.pMolecules.aModelEquation);
  text('Parent',hConfigGui.pMolecules.aModelEquation,'Interpreter','latex','Position',[0.01 0.6],...
    'FontSize',16,'BackgroundColor',get(hConfigGui.pMolecules.pModel,'BackgroundColor'),'String',equation);
  
  set(hConfigGui.pMolecules.aModelEquation,'Visible','off');
  UpdateParams(hConfigGui)
end
function checkPixSize(hConfigGui)
PixSize = str2double(get(hConfigGui.pGeneral.ePixSize,'String'));
FWHM = str2double(get(hConfigGui.pGeneral.eFWHM,'String'));
if PixSize>FWHM/2
  set(hConfigGui.pGeneral.eFWHM,'String',num2str(PixSize*2));
end

function Config=enableTasks(hConfigGui)
Config.Tasks=hConfigGui.Config.Evaluation.TasksNeeded{get(hConfigGui.pGeneral.mEvalClass,'Value')};
set(hConfigGui.pGeneral.pImage,'Position',[0.775 .04+0.22*.88 .2 0.8*.88]);
if Config.Tasks.Track
  set(hConfigGui.pGeneral.pOptions,'Visible','on')
  set(hConfigGui.pGeneral.pThreshold,'Visible','on')
  set(hConfigGui.pGeneral.pObjFilter,'Visible','on')
else
  set(hConfigGui.pGeneral.pOptions,'Visible','off')
  set(hConfigGui.pGeneral.pThreshold,'Visible','off')
  set(hConfigGui.pGeneral.pObjFilter,'Visible','off')
end
if Config.Tasks.Connect
  set(hConfigGui.pMolecules.pConnect,'Visible','on');
  set(hConfigGui.pMolecules.pTracks,'Visible','on');
else
  set(hConfigGui.pMolecules.pConnect,'Visible','off');
  set(hConfigGui.pMolecules.pTracks,'Visible','off');
end
if Config.Tasks.Fit
  set(hConfigGui.pMolecules.pPaths,'Visible','on');
else
  set(hConfigGui.pMolecules.pPaths,'Visible','off');
end
if Config.Tasks.Avi
  set(hConfigGui.pGeneral.pImage,'Position',[0.3 .04 .2 .88]);
  set(hConfigGui.pGeneral.pOptions,'Visible','on')
  set(hConfigGui.pGeneral.pAvi,'Visible','on');
  hConfigGui.Config.Avi.Make=true;
  set(hConfigGui.pGeneral.cAvi,'Value',true,'Enable','off');
  setAviControlState(hConfigGui,true);
else
  set(hConfigGui.pGeneral.pAvi,'Visible','off');
end

function Z=Calc2DPeakCircle(X,Y)
x=[-0.3 0.2 8 1];
Z = x(4) * exp( -( (X-x(1)).^2 + (Y-x(2)).^2 ) / x(3) );

function Z=Calc2DPeakEllipses(X,Y)
x=[0.3 0.2 3.9 2.8 0.08 1];
Z = x(6) * exp( - ( (X-x(1)) ./ x(3) ).^2  - ( (Y-x(2)) ./ x(4) ).^2 + x(5) .* (X-x(1)) .* (Y-x(2)));

function Z=Calc2DPeakRing(X,Y)
x=[0.3 0.2 8 1 4 0.3 7];
Z = x(4) * exp( -( (X-x(1)).^2 + (Y-x(2)).^2 ) / x(3) ) + x(6) .* exp( -( ( sqrt( (X-x(1)).^2 + (Y-x(2)).^2) - x(7) ).^2 ) / x(5) );

function Z=Calc2DPeak2Rings(X,Y)
x=[0.3 0.2 8 0.6 4 0.3 4 4 0.2 8];
Z = x(4) * exp( -( (X-x(1)).^2 + (Y-x(2)).^2 ) / x(3) ) - x(6) .* exp( -( (sqrt( (X-x(1)).^2 + (Y-x(2)).^2) - x(7)).^2) / x(5) ) + x(9) .* exp( -( ( sqrt( (X-x(1)).^2 + (Y-x(2)).^2) - x(10) ).^2) / x(8) );
