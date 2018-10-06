classdef InteractiveGUI < AutoTipTrackDataClass
  properties
    UIFig; %figure handle for the GUI
    Interface = struct(); %structure containing handles to the individual gui elements
    Tabs; %Cellstring of tab names
  end
  methods
    
    
    function I = InteractiveGUI(Config)
      I@AutoTipTrackDataClass(Config);
      I.UIFig = figure('DockControls','off','IntegerHandle','off','MenuBar','none','Name',...
        'evaluateManyExperiments - Interactive UI','NumberTitle','off','Tag','InteractiveGUI');
      fPlaceFig(I.UIFig,'big');
      set(I.UIFig,'Units','pixels');
    end
    
    
    function I=setupInteractivePanel(I,varargin)
      p = inputParser;
      p.addParameter('Threshold', true, @islogical);
      p.addParameter('Patterns', false, @islogical);
      p.parse(varargin{:});
      I.Interface.TabGroup=uitabgroup('Parent',I.UIFig,...
        'Position',[0 0 1 1],...
        'Tag','TabGroup',...
        'SelectionChangedFcn',@I.refresh);
      if p.Results.Threshold
        I.setupThresholdTab;
        I.refreshThresholdTab;
      end
      if p.Results.Patterns
        I.setupPatternTab;
        I.refreshPatternTab;
      end
    end
    
    
    function refresh(I,~,~)
      TabName=get(I.Interface.TabGroup.SelectedTab,'Tag');
      if strcmp(TabName, 'PatternTab')
        I.refreshPatternTab;
      else
        I.refreshThresholdTab;
      end
    end
    
    
    %% pattern identification tab
    function I=setupPatternTab(I)
      I.Interface.PatternTab=struct();
      I.Interface.PatternTab.Rotation = 0;
      I.Interface.PatternTab.Flip = false;
      I.Interface.PatternTab.MainTab=uitab(I.Interface.TabGroup,...
        'Title','PatternIdentification','Tag','PatternTab');
      if isempty(I.Stack)
        h = waitbar(0,'Loading stack, please wait...');
        I.loadFile;
        close(h)
      end
      
      BtnH = 0.05;
      BtnW = 0.18;
      BtnSpacing = 0.06;
      BtnX = 0.81;
      
      I.Interface.PatternTab.SRScaleSlider = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'String','Scaling',...
        'Style','slider',...
        'Position',[0 0.5 0.05 0.5],...
        'Callback',@I.rescaleMaximumProjection,...
        'Tag','SRScaleSlider');
      I.labelSlider(I.Interface.PatternTab.SRScaleSlider,'PatternTab')
      
      I.Interface.PatternTab.MaximumProjPanel = uipanel(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'Title','Maximum projection',...
        'Position',[0.15 0.5 0.65 0.5],...
        'Tag','MaximumProjPanel');
      
      I.Interface.PatternTab.MaximumProjAxes = axes(...
        'Parent',I.Interface.PatternTab.MaximumProjPanel,...
        'Position',[0 0 1 1],...
        'Visible','off');
      
      I.Interface.PatternTab.CorrelationThreshSlider = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'Max',1,...
        'Min',0,...
        'Value',0.5,...
        'SliderStep',[0.01 0.1],...
        'String','Correlation Threshold',...
        'Style','slider',...
        'Position',[0 0 0.05 0.5],...
        'Callback',@I.updateRectangles,...
        'Tag','CorrelationThreshSlider');
      I.labelSlider(I.Interface.PatternTab.CorrelationThreshSlider,'PatternTab')
      
      I.Interface.PatternTab.RegionPanel = uipanel(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'Title','Junction Regions',...
        'Position',[0.15 0 0.65 0.5],...
        'Tag','RegionPanel');
      
      I.Interface.PatternTab.RegionImageAxes = axes(...
        'Parent',I.Interface.PatternTab.RegionPanel,...
        'Position',[0 0 1 1],...
        'Visible','off');
      
      I.Interface.PatternTab.ProjectionValue = 1;
      
      I.Interface.PatternTab.ProjectionMethod = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Style','popupmenu','Units','normalized',...
        'Position',[BtnX 16 * BtnSpacing - 0.02 BtnW BtnH],'Tag','ProjectionMethod','Fontsize',10,...
        'String',{'Maximum','Median','Standard Deviation'},...
        'Value', I.Interface.PatternTab.ProjectionValue,...
        'Callback',@I.changeProjection);
      
      I.Interface.PatternTab.RotateRightButton = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'String','Rotate Right',...
        'Style','pushbutton',...
        'Position',[BtnX 15 * BtnSpacing BtnW BtnH],...
        'Callback',@I.rotateMaxProjRight,...
        'Tag','SRCancelButton');
      
      I.Interface.PatternTab.RotateLeftButton = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'String','Rotate Left',...
        'Style','pushbutton',...
        'Position',[BtnX 14 * BtnSpacing BtnW BtnH],...
        'Callback',@I.rotateMaxProjLeft,...
        'Tag','SRCancelButton');
      
      I.Interface.PatternTab.FlipUDButton = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'String','Flip Up-Down',...
        'Style','pushbutton',...
        'Position',[BtnX 13 * BtnSpacing BtnW BtnH],...
        'Callback',@I.flipMaxProj,...
        'Tag','SRCancelButton');
      
      
      I.Interface.PatternTab.RegionTabGroup=uitabgroup('Parent',I.Interface.PatternTab.MainTab,...
        'Position',[0.8 2 * BtnSpacing .2 4 * BtnSpacing],...
        'Tag','TabGroup');
      
      
      I.Interface.PatternTab.GridTab=uitab(I.Interface.PatternTab.RegionTabGroup,...
        'Title','Grid','Tag','GridTab');
      
      TBtnH = 0.3;
      TBtnW = 1;
      TBtnSpacing = 0.33;
      TBtnX = 0;
      
      I.Interface.PatternTab.SelectLeftRegionButton = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','Select left anchor region',...
        'Style','pushbutton',...
        'Position',[TBtnX 2 * TBtnSpacing TBtnW TBtnH],...
        'Callback',@I.selectJunctionRegion,...
        'Tag','SelectLeftRegionButton');

      I.Interface.PatternTab.SelectRightRegionButton = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','Select right anchor region',...
        'Style','pushbutton',...
        'Position',[TBtnX 1 * TBtnSpacing TBtnW TBtnH],...
        'Callback',@I.selectJunctionRegion,...
        'Tag','SelectRightRegionButton');

      I.Interface.PatternTab.XSpacingL = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','X-Spacing (nm)',...
        'Style','text',...
        'Position',[TBtnX 0 * TBtnSpacing + TBtnH/2 TBtnW/2.1 TBtnH/2],...
        'Tag','XSpacingL');
      I.Interface.PatternTab.XSpacing = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','12000',...
        'Style','edit',...
        'Position',[TBtnX 0 * TBtnSpacing TBtnW/2.1 TBtnH/1.7],...
        'Callback',@I.updatePatternGrid,...
        'Tag','XSpacing');

      I.Interface.PatternTab.YSpacingL = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','Y-Spacing (nm)',...
        'Style','text',...
        'Position',[TBtnX + 0.525 0 * TBtnSpacing + TBtnH/2 TBtnW/2.1 TBtnH/2],...
        'Tag','YSpacingL');
      I.Interface.PatternTab.YSpacing = uicontrol(...
        'Parent',I.Interface.PatternTab.GridTab,...
        'Units','normalized',...
        'String','8805',...
        'Style','edit',...
        'Position',[TBtnX + 0.525 0 * TBtnSpacing TBtnW/2.1 TBtnH/1.7],...
        'Callback',@I.updatePatternGrid,...
        'Tag','YSpacing');

      
      I.Interface.PatternTab.CorrelationTab=uitab(I.Interface.PatternTab.RegionTabGroup,...
        'Title','Correlation','Tag','CorrelationTab');
      
      I.Interface.PatternTab.SelectRegionButton = uicontrol(...
        'Parent',I.Interface.PatternTab.CorrelationTab,...
        'Units','normalized',...
        'String','Select initial region',...
        'Style','pushbutton',...
        'Position',[TBtnX 2 * TBtnSpacing TBtnW TBtnH],...
        'Callback',@I.selectJunctionRegion,...
        'Tag','SelectRegionButton');
      
      I.Interface.PatternTab.CorrelateRegionButton = uicontrol(...
        'Parent',I.Interface.PatternTab.CorrelationTab,...
        'Units','normalized',...
        'String','Find Correlating Regions',...
        'Style','pushbutton',...
        'Position',[TBtnX 1 * TBtnSpacing TBtnW TBtnH],...
        'Callback',@I.correlateRegion,...
        'Tag','CorrelateRegionButton',...
        'Enable','off');
      
      I.Interface.PatternTab.EliminateOverlap = uicontrol(...
        'Parent',I.Interface.PatternTab.CorrelationTab,...
        'Units','normalized',...
        'String','Eliminate Overlapping Rectangles',...
        'Style','pushbutton',...
        'Position',[TBtnX 0 * TBtnSpacing TBtnW TBtnH],...
        'Callback',@I.eliminateRectanglesButton,...
        'Tag','EliminateOverlap');

      
      I.Interface.PatternTab.CancelButton = uicontrol(...
        'Parent',I.Interface.PatternTab.MainTab,...
        'Units','normalized',...
        'String','Done',...
        'Style','pushbutton',...
        'Position',[BtnX 0 * BtnSpacing BtnW BtnH],...
        'Callback',@I.closeFig,...
        'Tag','SRCancelButton');
    end
    
    
    function I=refreshPatternTab(I)
      I.Interface.PatternTab.FlatStack = [];
      I.maximumProject;
      I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
      I.selectJunctionRegion;
    end
    
    
    function I = changeProjection(I,~,~)
      I.Interface.PatternTab.ProjectionValue = get(I.Interface.PatternTab.ProjectionMethod, 'Value');
      I.maximumProject;
      I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
      I.selectJunctionRegion;
    end
    
    
    function I=maximumProject(I)
      if ~isfield(I.Interface.PatternTab, 'FlatStack') || isempty(I.Interface.PatternTab.FlatStack)
        if isfield(I.Interface,'ThresholdTab')
          BallRadius=I.Config.SubtractBackground.BallRadius;
          I.Config.SubtractBackground.BallRadius=0;
        end
        if isempty(I.Stack)
          h = waitbar(0,'Loading stack, please wait...');
          I.loadFile;
          close(h)
        end
        StackLen=length(I.Stack);
        if isfield(I.Interface,'ThresholdTab')
          I.Config.SubtractBackground.BallRadius=BallRadius;
          BallRadius=round(get(I.Interface.ThresholdTab.RadiusSlider,'Value'));
          Smoothe=get(I.Interface.ThresholdTab.SmootheSlider,'Value');
          if BallRadius > 0
            h = waitbar(0,'Calculating flattened stack...');
            FlatStack=zeros([size(I.Stack{1}),StackLen]);
            Stack=I.Stack;
            parfor n=1:StackLen
              FlatStack(:,:,n)=flattenImage(Stack{n},BallRadius,Smoothe);
            end
            I.Interface.PatternTab.FlatStack = FlatStack;
            close(h);
          end
        end
        if ~isfield(I.Interface.PatternTab, 'FlatStack') || isempty(I.Interface.PatternTab.FlatStack)
          I.Interface.PatternTab.FlatStack = zeros([size(I.Stack{1}),StackLen]);
          for n=1:StackLen
            I.Interface.PatternTab.FlatStack(:,:,n)=I.Stack{n};
          end
        end
      end
      I.Interface.PatternTab.Flip = false;
      I.Interface.PatternTab.Rotation = 0;
      switch I.Interface.PatternTab.ProjectionValue
        case 1
          I.Interface.PatternTab.MaxP=max(I.Interface.PatternTab.FlatStack,[],3);
        case 2
          h = waitbar(0,'Calculating median...');
          if size(I.Interface.PatternTab.FlatStack,3) > 100
            I.Interface.PatternTab.MaxP=median(I.Interface.PatternTab.FlatStack(:,:,1:100),3);
          else
            I.Interface.PatternTab.MaxP=median(I.Interface.PatternTab.FlatStack,3);
          end
          close(h);
        case 3
          h = waitbar(0,'Calculating standard deviation...');
          I.Interface.PatternTab.MaxP=std(I.Interface.PatternTab.FlatStack,0,3);
          close(h);
        otherwise
          I.Interface.PatternTab.MaxP=max(I.Interface.PatternTab.FlatStack,[],3);
      end
    end
    
    
    function I=rotateMaxProj(I, Angle)
      if mod(Angle,90) > 0
        error('MATLAB:AutoTiptrack:InteractiveGUI:RotateMaxProj','Angle must be a multiple of 90 degrees')
      end
      Angle = mod(Angle,360);
      if isstruct(I.Interface.PatternTab) && isfield(I.Interface.PatternTab, 'Rotation') && isfield(I.Interface.PatternTab, 'MaxP') && ~isempty(I.Interface.PatternTab.MaxP);
        I.Interface.PatternTab.MaxP = rot90(I.Interface.PatternTab.MaxP, Angle / 90);
        I.Interface.PatternTab.Rotation = I.Interface.PatternTab.Rotation + Angle;
        I.Interface.PatternTab.Rotation = mod(I.Interface.PatternTab.Rotation,360);
        if isfield(I.Interface.PatternTab, 'SelectedRegion') && ...
            isa(I.Interface.PatternTab.SelectedRegion, 'imrect') && ...
            ~isempty(I.Interface.PatternTab.SelectedRegion)&& ...
            isvalid(I.Interface.PatternTab.SelectedRegion)
          ImageSize = size(I.Interface.PatternTab.MaxP);
          RegionPos = I.Interface.PatternTab.SelectedRegion.getPosition;
          [RegionPos(1:2), RegionPos(3:4), ~] = I.rotateRegions(RegionPos(1:2), Angle, RegionPos(3:4), ImageSize);
          I.Interface.PatternTab.SelectedRegion.delete;
          I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
          I.Interface.PatternTab.SelectedRegion=imrect(I.Interface.PatternTab.MaximumProjAxes,RegionPos);
          I.selectJunctionRegion;
        else
          I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
        end
        if isfield(I.Interface.PatternTab, 'Correlation')
          I.Interface.PatternTab.Correlation = rot90(I.Interface.PatternTab.Correlation, Angle / 90);
          I.updateRectangles(I.Interface.PatternTab.CorrelationThreshSlider,'PatternTab');
        end
      end
    end
    
    
    function I=rotateMaxProjRight(I,~,~)
      if isstruct(I.Interface.PatternTab) && isfield(I.Interface.PatternTab, 'Flip') && I.Interface.PatternTab.Flip
        I.flipMaxProj();
        msgbox('Flipping has to be the last operation performed. Undoing previous flipping operation. Please rotate first and then perform any flipping required as the last operation.');
      end
      I.rotateMaxProj(-90);
    end
    
    
    function I=rotateMaxProjLeft(I,~,~)
      if isstruct(I.Interface.PatternTab) && isfield(I.Interface.PatternTab, 'Flip') && I.Interface.PatternTab.Flip
        I.flipMaxProj();
        msgbox('Flipping has to be the last operation performed. Undoing previous flipping operation. Please rotate first and then perform any flipping required as the last operation.');
      end
      I.rotateMaxProj(90);
    end
    
    
    function I=flipMaxProj(I,varargin)
      if isstruct(I.Interface.PatternTab) && isfield(I.Interface.PatternTab, 'Flip') && isfield(I.Interface.PatternTab, 'MaxP') && ~isempty(I.Interface.PatternTab.MaxP);
        I.Interface.PatternTab.MaxP = flipud(I.Interface.PatternTab.MaxP);
        I.Interface.PatternTab.Flip = ~I.Interface.PatternTab.Flip;
        if isfield(I.Interface.PatternTab, 'SelectedRegion') && ...
            isa(I.Interface.PatternTab.SelectedRegion, 'imrect') && ...
            ~isempty(I.Interface.PatternTab.SelectedRegion)&& ...
            isvalid(I.Interface.PatternTab.SelectedRegion)
          RegionPos = I.Interface.PatternTab.SelectedRegion.getPosition;
          RegionPos(2) = size(I.Interface.PatternTab.MaxP, 1) - RegionPos(2) - RegionPos(4);
          I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
          I.Interface.PatternTab.SelectedRegion=imrect(I.Interface.PatternTab.MaximumProjAxes,RegionPos);
          I.selectJunctionRegion;
        else
          I.rescaleMaximumProjection(I.Interface.PatternTab.SRScaleSlider);
        end
        if isfield(I.Interface.PatternTab, 'Correlation')
          I.Interface.PatternTab.Correlation = flipud(I.Interface.PatternTab.Correlation);
          I.updateRectangles(I.Interface.PatternTab.CorrelationThreshSlider,'PatternTab');
        end
      end
    end
    
    
    
    function selectJunctionRegion(I,hObj,~)
      Region = 'SelectedRegion';
      if nargin > 1
        if strcmp(hObj.Tag, 'SelectRightRegionButton')
          if ~(isfield(I.Interface.PatternTab, Region) && ...
              isa(I.Interface.PatternTab.(Region), 'imrect'))
            msgbox('Please select the left region first.');
            return;
          end
          Region = 'RightRegion';
          XSpacing = str2double(I.Interface.PatternTab.XSpacing.String) / I.Config.PixSize;
        end
      end
      if isfield(I.Interface.PatternTab, Region) && ...
          isa(I.Interface.PatternTab.(Region), 'imrect') && ...
          ~isempty(I.Interface.PatternTab.(Region))&& ...
          isvalid(I.Interface.PatternTab.(Region))
        RegionPos=I.Interface.PatternTab.(Region).getPosition;
        I.Interface.PatternTab.(Region).delete;
      else
        ImSize=size(I.Interface.PatternTab.MaxP);
        if strcmp(Region, 'RightRegion')
          RegionPos = I.Interface.PatternTab.SelectedRegion.getPosition;
          RegionPos(1) = (floor( (ImSize(1) - RegionPos(1)) / XSpacing) - 1) * XSpacing;
        else
          RegionPos=round([ImSize/2 ImSize/10]);
        end
      end
      I.Interface.PatternTab.(Region)=imrect(I.Interface.PatternTab.MaximumProjAxes,RegionPos);
      if strcmp(Region, 'RightRegion')
        I.Interface.PatternTab.(Region).setColor('r');
        I.Interface.PatternTab.(Region).setResizable(false);
        I.Interface.PatternTab.(Region).setPositionConstraintFcn(@I.constrainPositionToGrid);
      else
        I.Interface.PatternTab.(Region).setPositionConstraintFcn(@I.constrainPositionToImage);
      end
      RegionPos=I.Interface.PatternTab.(Region).getPosition;
      I.redrawRegionImage(RegionPos);
      I.Interface.PatternTab.(Region).addNewPositionCallback(@I.redrawRegionImage);
      set(I.Interface.PatternTab.CorrelateRegionButton,'Enable','on');
      I.updatePatternGrid;
    end
    
    
    function ConstrainedPos = constrainPositionToImage(I, Position)
      ImSize=size(I.Interface.PatternTab.MaxP);
      MaxX = ImSize(1) - Position(3);
      MaxY = ImSize(2) - Position(4);
      ConstrainedPos = Position;
      if Position(1) < 0
        ConstrainedPos(1) = 0;
      elseif Position(1) > MaxX
        ConstrainedPos(1) = MaxX;
      end
      if Position(2) < 0
        ConstrainedPos(2) = 0;
      elseif Position(2) > MaxY
        ConstrainedPos(2) = MaxY;
      end
    end
    
    
    function ConstrainedPos = constrainPositionToGrid(I, Position)
      ReferencePos = I.Interface.PatternTab.SelectedRegion.getPosition;
      XSpacing = str2double(I.Interface.PatternTab.XSpacing.String) / I.Config.PixSize;
      %YSpacing = str2double(I.Interface.PatternTab.YSpacing.String) / I.Config.PixSize;
      DiffPos = Position(1:2) - ReferencePos(1:2);
      if all(DiffPos == 0)
        ConstrainedPos = ReferencePos + [XSpacing 0 0 0];
        Angle = 0;
      else
        Angle = atan(DiffPos(2) / DiffPos(1));
        Distance = sqrt(sum(DiffPos .^ 2));
        ConstrainedDistance = round(Distance ./ XSpacing) .* XSpacing;
        ConstrainedX = cos(Angle) .* ConstrainedDistance;
        ConstrainedY = sin(Angle) .* ConstrainedDistance;
        ConstrainedPos = [ConstrainedX + ReferencePos(1) ConstrainedY + ReferencePos(2) ReferencePos(3:4)];
      end
      I.drawRectangleGrid(Angle);
    end
    
    
    function drawRectangleGrid(I,Angle)
      ReferencePos = I.Interface.PatternTab.SelectedRegion.getPosition;
      RightPos = I.Interface.PatternTab.RightRegion.getPosition;
      XSpacing = str2double(I.Interface.PatternTab.XSpacing.String) / I.Config.PixSize;
      YSpacing = str2double(I.Interface.PatternTab.YSpacing.String) / I.Config.PixSize;
      DiffPos = RightPos(1:2) - ReferencePos(1:2);
      if XSpacing <= 0
        NumCols = 1;
      else
        NumCols = ceil(DiffPos(1) / XSpacing);
      end
      if YSpacing <= 0
        NumRows = 1;
      else
        NumRows = floor(ReferencePos(2) / YSpacing);
      end
      X = ((0:NumCols) .* XSpacing)';
      Y = -((0:NumRows) .* YSpacing)';
      NumCols = NumCols + 1;
      NumRows = NumRows + 1;
      Coords = zeros(NumCols * NumRows,2);
      for n = 1:NumRows
        Coords((n - 1) * NumCols + 1 : n * NumCols, :)  = [X repmat(Y(n),NumCols,1)];
      end
      R = [cos(-Angle) -sin(-Angle);...
        sin(-Angle) cos(-Angle)];
      Coords = Coords * R;
      Coords(:, 1) = Coords(:, 1) + ReferencePos(1);
      Coords(:, 2) = Coords(:, 2) + ReferencePos(2);
      I.Interface.PatternTab.RectSize=ReferencePos(3:4);
      I.Interface.PatternTab.RectPos=Coords;
      I.drawRectangles;
   end
    
    
    function I = updatePatternGrid(I,~,~)
      if isfield(I.Interface.PatternTab, 'RightRegion') && isa(I.Interface.PatternTab.RightRegion, 'imrect')
        I.Interface.PatternTab.RightRegion.setPosition(I.constrainPositionToGrid(I.Interface.PatternTab.RightRegion.getPosition));
      end
    end
    
    
    function redrawRegionImage(I,RegionPos)
      RegionPos=round(RegionPos);
      I.Interface.PatternTab.RegionImage=I.Interface.PatternTab.MaxP(RegionPos(2):RegionPos(2)+RegionPos(4),RegionPos(1):RegionPos(1)+RegionPos(3));
      imshow(I.Interface.PatternTab.RegionImage,[0, get(I.Interface.PatternTab.SRScaleSlider,'Value') ],...
        'Parent',I.Interface.PatternTab.RegionImageAxes,'Border','tight');
    end
    
    
    function correlateRegion(I,~,~)
      ImSize=size(I.Interface.PatternTab.MaxP);
      RegionPos=I.Interface.PatternTab.SelectedRegion.getPosition;
      RegionPos=round(RegionPos);
      Correlation=zeros(ImSize-[RegionPos(4) RegionPos(3)]);
      NumRows=ImSize(1)-RegionPos(4);
      NumCols=ImSize(2)-RegionPos(3);
      Part=I.Interface.PatternTab.RegionImage;
      MaxP=I.Interface.PatternTab.MaxP;
      RegionHeight=RegionPos(4);
      RegionWidth=RegionPos(3);
      h = waitbar(0,'Searching image...');
      parfor r=1:NumRows
        for c=1:NumCols
          Correlation(r,c)=corr2(Part,MaxP(r:r+RegionHeight,c:c+RegionWidth)); %#ok<PFBNS>
        end
      end
      close(h);
      I.Interface.PatternTab.Correlation=Correlation;
      I.updateRectangles(I.Interface.PatternTab.CorrelationThreshSlider,'PatternTab');
    end
    
    
    function updateRectangles(I,hObj,~)
      I.syncSliders(get(hObj,'Tag'),'PatternTab');
      RegionPos=I.Interface.PatternTab.SelectedRegion.getPosition;
      RegionPos=round(RegionPos);
      Average=fspecial('average');
      Maxima=imregionalmax(imfilter(I.Interface.PatternTab.Correlation,Average,'replicate'));
      MaximaValues=I.Interface.PatternTab.Correlation.*Maxima;
      [R,C]=find(MaximaValues>get(I.Interface.PatternTab.CorrelationThreshSlider,'Value'));
      I.Interface.PatternTab.RectSize=RegionPos(3:4);
      I.Interface.PatternTab.RectPos=[C,R];
      I.drawRectangles;
    end
    
    
    function I=drawRectangles(I)
      if isfield(I.Interface.PatternTab,'Rect')
        I.Interface.PatternTab.Rect.delete;
      end
      for n=size(I.Interface.PatternTab.RectPos,1):-1:1
        I.Interface.PatternTab.Rect(n)=rectangle('Parent',I.Interface.PatternTab.MaximumProjAxes,...
          'Position',[I.Interface.PatternTab.RectPos(n,:) I.Interface.PatternTab.RectSize],'EdgeColor','w');
      end
      %drawnow;
    end
    
    
    function I = eliminateRectanglesButton(I,~,~)
      I.eliminateOverlappingRectangles;
      I.drawRectangles;
    end
    
    
    function [I, RectPos, RectSize, Rotation, Flip, ProjectionMethod] = eliminateOverlappingRectangles(I)
      RectPos=[];
      RectSize=[];
      Rotation = I.Interface.PatternTab.Rotation;
      Flip = I.Interface.PatternTab.Flip;
      ProjectionMethod = 1;
      if isfield(I.Interface,'PatternTab') && isfield(I.Interface.PatternTab,'RectPos') && isfield(I.Interface.PatternTab, 'ProjectionValue')
        ProjectionMethod = I.Interface.PatternTab.ProjectionValue;
        RectPos = I.Interface.PatternTab.RectPos;
        RectSize = I.Interface.PatternTab.RectSize;
        SD = squareform(pdist(RectPos));
        NSquares = size(RectPos,1);
        SD(1:NSquares + 1:end) = Inf(1, NSquares);
        [R, ~] = find(SD < min(RectSize));
        if length(R) > 1
          Delete = zeros(1,length(R));
          for n = 1:2:length(R) - 1
            N1 = sort(SD(R(n),:));
            N2 = sort(SD(R(n+1),:));
            %find out which of the two overlapping rectangles is better
            %centered within its 8 neighbors and delete the other one.
            if length(N1) > 8
              Dist1 = sum(N1(2:2:8) - N1(3:2:9));
              Dist2 = sum(N2(2:2:8) - N2(3:2:9));
            else
              Dist1 = sum(N1(2:2:end - 1) - N1(3:2:end - 1));
              Dist2 = sum(N1(2:2:end - 1) - N1(3:2:end - 1));
            end
            if Dist1 > Dist2
              Delete(n) = R(n+1);
            else
              Delete(n) = R(n);
            end
          end
          Delete(Delete == 0) = [];
          RectPos(Delete,:) = [];
        end
        I.Interface.PatternTab.RectPos = RectPos;
      end
    end
    
    
    function rescaleMaximumProjection(I,hObj,~)
      I.syncSliders(get(hObj,'Tag'),'PatternTab');
      I.rescaleSlider(I.Interface.PatternTab.SRScaleSlider,I.Interface.PatternTab.MaxP,'PatternTab')
      imshow(I.Interface.PatternTab.MaxP,[0, get(I.Interface.PatternTab.SRScaleSlider,'Value') ],...
        'Parent',I.Interface.PatternTab.MaximumProjAxes,'Border','tight');
    end
    
    %% threshold tab
    function I=setupThresholdTab(I)
      BtnH = 0.05;
      BtnW = 0.18;
      BtnSpacing = 0.06;
      BtnX = 0.81;
      
      I.Interface.ThresholdTab=struct();
      I.Interface.ThresholdTab.MainTab=uitab(I.Interface.TabGroup,...
        'Title','Threshold','Tag','ThresholdTab');
      
      I.Interface.ThresholdTab.FrameSlider = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Max',2,...
        'Min',1,...
        'Value',1,...
        'String','Frame',...
        'Style','slider',...
        'Position',[0 0.95 1 0.05],...
        'Callback',@I.updateFlattenedImage,...
        'Tag','FrameSlider');
      I.labelSlider(I.Interface.ThresholdTab.FrameSlider)
      
      I.Interface.ThresholdTab.ScaleSlider = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','Scaling',...
        'Style','slider',...
        'Position',[0 0.475 0.05 0.475],...
        'Callback',@I.updateThresholdImages,...
        'Tag','ScaleSlider');
      I.labelSlider(I.Interface.ThresholdTab.ScaleSlider)
      
      I.Interface.ThresholdTab.DisableBGButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','Disable background subtraction',...
        'Style','pushbutton',...
        'Enable', 'on',...
        'Visible', 'on',...
        'Position',[BtnX 0.80 BtnW BtnH],...
        'Callback',@I.disableBGSubtraction,...
        'Tag','DisableBGButton');
      
      I.Interface.ThresholdTab.EnableBGButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','Enable background subtraction',...
        'Style','pushbutton',...
        'Enable', 'off',...
        'Visible', 'off',...
        'Position',[BtnX 0.80 BtnW BtnH],...
        'Callback',@I.enableBGSubtraction,...
        'Tag','EnableBGButton');
      
      I.Interface.ThresholdTab.RadiusSlider = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Max',200,...
        'Min',5,...
        'Value',I.Config.SubtractBackground.BallRadius,...
        'SliderStep',[1 5]/195,...
        'String','BallRadius',...
        'Style','slider',...
        'Position',[0.05 0.475 0.05 0.475],...
        'Callback',@I.updateFlattenedImage,...
        'Tag','RadiusSlider');
      I.labelSlider(I.Interface.ThresholdTab.RadiusSlider)
      
      I.Interface.ThresholdTab.SmootheSlider = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Max',5,...
        'Min',0,...
        'Value',I.Config.SubtractBackground.Smoothe,...
        'SliderStep',[0.1 1]/5,...
        'String','Smoothe',...
        'Style','slider',...
        'Position',[0.1 0.475 0.05 0.475],...
        'Callback',@I.updateFlattenedImage,...
        'Tag','SmootheSlider');
      I.labelSlider(I.Interface.ThresholdTab.SmootheSlider)
      
      I.Interface.ThresholdTab.ThreshSlider = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Max',4000,...
        'Min',100,...
        'Value',imag(I.Config.Threshold.Value),...
        'SliderStep',[1 10]/3900,...
        'String','Threshold',...
        'Style','slider',...
        'Position',[0 0 0.05 0.475],...
        'Callback',@I.updateThreshold,...
        'Tag','ThreshSlider');
      I.labelSlider(I.Interface.ThresholdTab.ThreshSlider)
      
      I.Interface.ThresholdTab.FlattenedPanel = uipanel(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Title','Flattened image',...
        'Position',[0.15 0.475 0.65 0.475],...
        'Tag','FlattenedPanel');
      
      I.Interface.ThresholdTab.FlattenedAxes = axes(...
        'Parent',I.Interface.ThresholdTab.FlattenedPanel,...
        'Position',[0 0 1 1],...
        'Visible','off');
      
      I.Interface.ThresholdTab.ThresholdPanel = uipanel(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'Title','Threshold image',...
        'Position',[0.15 0 0.65 0.475],...
        'Tag','ThresholdPanel');
      
      I.Interface.ThresholdTab.ThresholdAxes = axes(...
        'Parent',I.Interface.ThresholdTab.ThresholdPanel,...
        'Position',[0 0 1 1],...
        'Visible','off');
      
      I.Interface.ThresholdTab.AnnotateTrainingButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','annotate training data',...
        'Style','pushbutton',...
        'Position',[BtnX 3 * BtnSpacing BtnW BtnH],...
        'Callback',@I.annotateTrainingData,...
        'Tag','CancelButton');
      
      I.Interface.ThresholdTab.CancelButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','cancel',...
        'Style','pushbutton',...
        'Position',[BtnX 2 * BtnSpacing BtnW BtnH],...
        'Callback',@I.close,...
        'Tag','CancelButton');
      
      I.Interface.ThresholdTab.SaveFileSpecificButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','save as file specific config',...
        'Style','pushbutton',...
        'Position',[BtnX 1 * BtnSpacing BtnW BtnH],...
        'Callback',@I.saveFileSpecificConfig,...
        'Tag','SaveFileSpecificButton');
      
      I.Interface.ThresholdTab.SaveGeneralButton = uicontrol(...
        'Parent',I.Interface.ThresholdTab.MainTab,...
        'Units','normalized',...
        'String','save as general config',...
        'Style','pushbutton',...
        'Position',[BtnX 0 BtnW BtnH],...
        'Callback',@I.saveGeneralConfig,...
        'Tag','SaveGeneralButton');
    end
    
        
    function disableBGSubtraction(I, ~, ~)
      I.Interface.ThresholdTab.RadiusSlider.Enable = 'off';
      I.Interface.ThresholdTab.RadiusSlider.Min = 0;
      I.Interface.ThresholdTab.RadiusSlider.Value = 0;
      I.Interface.ThresholdTab.SmootheSlider.Enable = 'off';
      I.Interface.ThresholdTab.DisableBGButton.Enable = 'off';
      I.Interface.ThresholdTab.DisableBGButton.Visible = 'off';
      I.Interface.ThresholdTab.EnableBGButton.Enable = 'on';
      I.Interface.ThresholdTab.EnableBGButton.Visible = 'on';
      I.updateFlattenedImage(I.Interface.ThresholdTab.FrameSlider);
    end
    
    
    function enableBGSubtraction(I, ~, ~)
      I.Interface.ThresholdTab.RadiusSlider.Enable = 'on';
      I.Interface.ThresholdTab.RadiusSlider.Min = 5;
      I.Interface.ThresholdTab.RadiusSlider.Value = 30;
      I.Interface.ThresholdTab.SmootheSlider.Enable = 'on';
      I.Interface.ThresholdTab.DisableBGButton.Enable = 'on';
      I.Interface.ThresholdTab.DisableBGButton.Visible = 'on';
      I.Interface.ThresholdTab.EnableBGButton.Enable = 'off';
      I.Interface.ThresholdTab.EnableBGButton.Visible = 'off';
      I.updateFlattenedImage(I.Interface.ThresholdTab.FrameSlider);
    end
    
    
    function refreshThresholdTab(I)
      BallRadius=I.Config.SubtractBackground.BallRadius;
      I.Config.SubtractBackground.BallRadius=0;
      if isempty(I.Stack)
        h = waitbar(0,'Loading stack, please wait...');
        I.loadFile;
        close(h)
      end
      I.Config.SubtractBackground.BallRadius=BallRadius;
      NumFrames=length(I.Stack);
      
      if NumFrames>1
        SliderStep=[1 round(NumFrames/10)]/(NumFrames-1);
        set(I.Interface.ThresholdTab.FrameSlider,'Enable','on');
        set(I.Interface.ThresholdTab.FrameNumber,'Enable','on');
      else
        SliderStep=[1 1];
        set(I.Interface.ThresholdTab.FrameSlider,'Enable','off');
        set(I.Interface.ThresholdTab.FrameNumber,'Enable','off');
      end
      set(I.Interface.ThresholdTab.FrameSlider,'Max',NumFrames,...
        'SliderStep',SliderStep,...
        'Value',1);
      I.syncSliders(get(I.Interface.ThresholdTab.FrameSlider,'Tag'),'ThresholdTab');
      if isfield(I.Interface.ThresholdTab,'FlatImage')
        I.Interface.ThresholdTab=rmfield(I.Interface.ThresholdTab,'FlatImage');
      end
      I.updateFlattenedImage(I.Interface.ThresholdTab.FrameSlider);
    end
    
    
    function ImageScaling=getImageScalingValue(I)
      ImageScaling = struct('Mode','auto','Black',0,'White',0);
      [~,White]=autoscale(I.Interface.ThresholdTab.FlatImage,0.2,0.05);
      ScaleSliderValue = get(I.Interface.ThresholdTab.ScaleSlider,'Value');
      if White ~= ScaleSliderValue
        ImageScaling.Mode = 'manual';
        ImageScaling.White = round(ScaleSliderValue);
      end
    end
    
    
    function saveGeneralConfig(I,~,~)
      ConfigPath=fullfile(I.FilePath,'config.mat');
      if exist(ConfigPath,'file')==2
        NewConf=ConfigClass;
        NewConf.loadConfig(ConfigPath);
      else
        NewConfStruct=I.Config.exportConfigStruct;
        
        NewConfStruct.FileName='';
        NewConfStruct.StackName='';
        NewConfStruct.Directory='';
        NewConfStruct.StackType='TIFF';
        NewConfStruct.LastFrame=1;
        NewConfStruct.Times=[];
        NewConfStruct.AcquisitionDate='';
        NewConf=ConfigClass;
        NewConf.importConfigStruct(NewConfStruct);
      end
      NewConf.SubtractBackground.BallRadius=get(I.Interface.ThresholdTab.RadiusSlider,'Value');
      NewConf.SubtractBackground.Smoothe=get(I.Interface.ThresholdTab.SmootheSlider,'Value');
      NewConf.Threshold.Value=I.getThresholdValue;
      NewConf.ImageScaling=I.getImageScalingValue;
      NewConf.save(ConfigPath);
      msgbox(sprintf('Configuration saved as: %s',ConfigPath));
    end
    
    
    function saveFileSpecificConfig(I,~,~)
      ConfigPath=fullfile(I.FilePath, [I.FileName '_conf.mat']);
      I.Config.SubtractBackground.BallRadius=get(I.Interface.ThresholdTab.RadiusSlider,'Value');
      I.Config.SubtractBackground.Smoothe=get(I.Interface.ThresholdTab.SmootheSlider,'Value');
      I.Config.Threshold.Value=I.getThresholdValue;
      I.Config.save(ConfigPath);
      msgbox(sprintf('Configuration saved as: %s',ConfigPath));
    end
    
    
    function labelSlider(I,hSlider,TabName)
      if nargin<3
        TabName='ThresholdTab';
      end
      SliderPosition=get(hSlider,'Position');
      if SliderPosition(3)>SliderPosition(4) %horizontal slider
        NewSliderPosition=SliderPosition;
        NewSliderPosition(3)=SliderPosition(3)-2*SliderPosition(4);
        NewSliderPosition(1)=SliderPosition(1)+SliderPosition(4);
        set(hSlider,'Position',NewSliderPosition);
        NumberPosition=[SliderPosition(1) SliderPosition(2) SliderPosition(4) SliderPosition(4)];
        LabelPosition=[SliderPosition(1)+SliderPosition(3)-SliderPosition(4) SliderPosition(2) SliderPosition(4) SliderPosition(4)];
        LabelAlign='center';
      else %vertical slider
        NewSliderPosition=SliderPosition;
        NewSliderPosition(4)=SliderPosition(4)-2*SliderPosition(3);
        NewSliderPosition(2)=SliderPosition(2)+SliderPosition(3);
        set(hSlider,'Position',NewSliderPosition);
        NumberPosition=[SliderPosition(1) SliderPosition(2) SliderPosition(3) SliderPosition(3)];
        LabelPosition=[SliderPosition(1) SliderPosition(2)+SliderPosition(4)-SliderPosition(3) SliderPosition(3) SliderPosition(3)];
        LabelAlign='center';
      end
      Tag=get(hSlider,'Tag');
      NumberName=[Tag(1:end-6) 'Number'];
      LabelName=[Tag(1:end-6) 'Label'];
      I.Interface.(TabName).(NumberName) = uicontrol(...
        'Parent',get(hSlider,'Parent'),...
        'Units',get(hSlider,'Units'),...
        'String',num2str(get(hSlider,'Value')),...
        'Style','edit',...
        'Position',NumberPosition,...
        'Callback',get(hSlider,'Callback'),...
        'Tag',NumberName);
      I.Interface.(TabName).(LabelName) = uicontrol(...
        'Parent',get(hSlider,'Parent'),...
        'Units',get(hSlider,'Units'),...
        'String',get(hSlider,'String'),...
        'Style','edit',...
        'Enable','off',...
        'HorizontalAlignment',LabelAlign,...
        'Position',LabelPosition,...
        'Tag',LabelName);
    end
    
    
    function syncSliders(I,Tag,TabName)
      if nargin < 3
        TabName='ThresholdTab';
      end
      if strendswith(Tag,'Number')
        TargetTag=[Tag(1:end-6) 'Slider'];
        Value=str2double(get(I.Interface.(TabName).(Tag),'String'));
        MaxVal=get(I.Interface.(TabName).(TargetTag),'Max');
        MinVal=get(I.Interface.(TabName).(TargetTag),'Min');
        if Value>MaxVal
          Value=MaxVal;
          set(I.Interface.(TabName).(Tag),'String',num2str(Value));
        elseif Value<MinVal
          Value=MinVal;
          set(I.Interface.(TabName).(Tag),'String',num2str(Value));
        end
        set(I.Interface.(TabName).(TargetTag),'Value',Value);
      elseif strendswith(Tag,'Slider')
        TargetTag=[Tag(1:end-6) 'Number'];
        set(I.Interface.(TabName).(TargetTag),'String',num2str(get(I.Interface.(TabName).(Tag),'Value')));
      end
    end
    
    
    function updateThreshold(I,hObj,~)
      I.syncSliders(get(hObj,'Tag'));
      I.updateThresholdImages(hObj);
    end
    
    
    function Thresh=getThresholdValue(I)
      Thresh=complex(0,get(I.Interface.ThresholdTab.ThreshSlider,'Value'));
    end
    
    
    function rescaleSlider(I,ScaleSlider,Image,TabName)
      if nargin<4
        TabName='ThresholdTab';
      end
      MaxScale=max(Image(:));
      MinScale=min(Image(:));
      Range=double(MaxScale-MinScale);
      if Range>100
        SliderStep=[1 round(Range/20)]/Range;
      elseif Range>50
        SliderStep=[1 round(Range/10)]/Range;
      elseif Range>5
        SliderStep=[1 round(Range/5)]/Range;
      else
        SliderStep=[1 1];
      end
      set(ScaleSlider,...
        'Max',MaxScale,...
        'Min',MinScale,...
        'SliderStep',SliderStep);
      if get(ScaleSlider, 'Value')==0
        [~,White]=autoscale(Image,0.2,0.05);
        set(ScaleSlider, 'Value',White);
        I.syncSliders(get(ScaleSlider,'Tag'),TabName);
      end
      if get(ScaleSlider, 'Value')>MaxScale
        set(ScaleSlider, 'Value', MaxScale);
      elseif get(ScaleSlider, 'Value')<MinScale
        set(ScaleSlider, 'Value', MinScale)
      end
    end
    
    
    function updateFlattenedImage(I,hObj,~)
      if isfield(I.Interface.ThresholdTab,'FlatImage')
        I.Interface.ThresholdTab=rmfield(I.Interface.ThresholdTab,'FlatImage');
      end
      I.updateThresholdImages(hObj);
    end
    
    
    function FlatImage = createFlatImage(I,Frame)
      BallRadius=round(get(I.Interface.ThresholdTab.RadiusSlider,'Value'));
      Smoothe=get(I.Interface.ThresholdTab.SmootheSlider,'Value');
      if BallRadius > 0
        FlatImage = flattenImage(I.Stack{Frame},BallRadius,Smoothe);
      else
        FlatImage = I.Stack{round(get(I.Interface.ThresholdTab.FrameSlider,'Value'))};
      end
    end
    
    
    function updateThresholdImages(I,hObj,~)
      I.syncSliders(get(hObj,'Tag'));
      if ~isfield(I.Interface.ThresholdTab,'FlatImage')
        I.Interface.ThresholdTab.FlatImage = I.createFlatImage(round(get(I.Interface.ThresholdTab.FrameSlider,'Value')));
      end
      I.rescaleSlider(I.Interface.ThresholdTab.ScaleSlider,I.Interface.ThresholdTab.FlatImage)
      imshow(I.Interface.ThresholdTab.FlatImage,[0, get(I.Interface.ThresholdTab.ScaleSlider,'Value') ],'Parent',I.Interface.ThresholdTab.FlattenedAxes,'Border','tight');
      ThreshImage=I.calculateThreshImage(I.Interface.ThresholdTab.FlatImage,I.getThresholdValue);
      imshow(ThreshImage,[0, 1 ],'Parent',I.Interface.ThresholdTab.ThresholdAxes,'Border','tight');
      drawnow;
    end
    
    
    function I = annotateTrainingData(I, ~, ~)
      Fig = figure('Units', 'normalized');
      Ax = axes(Fig);
      Fig.Units = 'normalized';
      Fig.Position = [0.05 0.05 0.9 0.9];
      Ax.Position = [0 0 1 1];
      MaxFrame = round(I.Interface.ThresholdTab.FrameSlider.Max);
      CurrentFrame = round(I.Interface.ThresholdTab.FrameSlider.Value);
      Width = size(I.Interface.ThresholdTab.FlatImage,2);
      Height = size(I.Interface.ThresholdTab.FlatImage,1);
      AnnotationFile = fullfile(I.Config.Directory, [I.Config.StackName '_Annotation.tif']);
      if ~ isfield(I.Interface.ThresholdTab, 'AnnotatedData')
        I.Interface.ThresholdTab.AnnotatedData = false(Height, Width, MaxFrame);
        if exist(AnnotationFile,'file') == 2
          TiffMeta=imfinfo(AnnotationFile);
          NumF=numel(TiffMeta);
          if NumF > MaxFrame
            NumF = MaxFrame;
          end
          for n = 1:NumF
            I.Interface.ThresholdTab.AnnotatedData(:,:,n) = imread(AnnotationFile,'tif','Info',TiffMeta,'Index',n);
          end
          delete(AnnotationFile);
          if CurrentFrame > 1
            if CurrentFrame < NumF
              MaxRestore = CurrentFrame;
            else
              MaxRestore = NumF;
            end
            for n=1:MaxRestore
              imwrite(I.Interface.ThresholdTab.AnnotatedData(:,:,n), AnnotationFile, 'writemode', 'append', 'Compression', 'none');
            end
          end
        end
      end
      while CurrentFrame <= MaxFrame
        I.Interface.ThresholdTab.AnnotatedData(:,:,CurrentFrame) = I.annotateThresholdImage(CurrentFrame,Ax,I.Interface.ThresholdTab.AnnotatedData(:,:,CurrentFrame));
        imwrite(I.Interface.ThresholdTab.AnnotatedData(:,:,CurrentFrame), AnnotationFile, 'writemode', 'append', 'Compression', 'none');
        CurrentFrame = CurrentFrame +1;
        if CurrentFrame <= MaxFrame
          I.Interface.ThresholdTab.FrameSlider.Value = CurrentFrame;
        end
        I.updateFlattenedImage(I.Interface.ThresholdTab.FrameSlider);
      end
      close(Fig);
    end
    
    
    function Annotation = annotateThresholdImage(I, CurrentFrame, Ax, InputRegion)
      Fig = Ax.Parent;
      ThreshImage = I.calculateThreshImage(I.Interface.ThresholdTab.FlatImage,I.getThresholdValue);
      Mask = ~ThreshImage;
      ColorIndex = [0.2, 0.2, 0.2; .5 .5 0; 0 0 .5; 1, 1, 1; 1, 0 0];
      if CurrentFrame > 1
        DisplayImage = uint16(I.calculateThreshImage(I.createFlatImage(CurrentFrame - 1),I.getThresholdValue));
      else
        DisplayImage = uint16(zeros(size(ThreshImage)));
      end
      if CurrentFrame < round(I.Interface.ThresholdTab.FrameSlider.Max)
        ThreshImage2 = I.calculateThreshImage(I.createFlatImage(CurrentFrame + 1),I.getThresholdValue);
        DisplayImage(ThreshImage2) = 2;
      end
      DisplayImage(ThreshImage) = 3;
      DisplayImage(InputRegion) = 4;
      X = 0;
      while ~isempty(X)
        imshow(DisplayImage, ColorIndex, 'Parent', Ax, 'Border', 'tight', 'InitialMagnification', 2);
        drawnow;
        [X, Y, Button] = ginput2(1, 'Figure', Fig);
        X = round(X);
        Y = round(Y);
        if ~isempty(X) && X>0 && Y>0 && ThreshImage(Y, X)
          NewRegion = xor(Mask, imfill(Mask, [Y, X]));
          if Button == 1
            DisplayImage(NewRegion) = 4;
          elseif Button == 3
            DisplayImage(NewRegion) = 3;
          else
            Mask(Y, X) = 1;
            DisplayImage(Y, X) = 0;
          end
        end
      end
      Annotation = DisplayImage == 4;
    end

    
    %% closing UI
    function close(I,~,~)
      if ishandle(I.UIFig)
        close(I.UIFig);
      end
      clear('I');
    end
    
    
    function closeFig(I,~,~)
      close(I.UIFig);
    end
    
    
  end
  methods (Static)
    
    
    function Coords = rotateCoordinates(Coords, Angle, ImageSize)
      R = [cosd(Angle) -sind(Angle);...
        sind(Angle) cosd(Angle)];
      Center = ImageSize ./ 2;
      Center = Center(ones(size(Coords,1),1),:);
      Coords = ((Coords-Center) * R) + Center;
    end
    
    
    function [Regions, RegionSize, ImageSize] = rotateRegions(Regions, Angle, RegionSize, ImageSize)
      Angle = mod(Angle,360);
      Regions = InteractiveGUI.rotateCoordinates(Regions, Angle, ImageSize);
      if mod(Angle, 180) > 45
        RegionSize = fliplr(RegionSize);
        ImageSize = fliplr(ImageSize);
      end
      switch round(Angle / 90)
        case 1
          Regions(:,2) = Regions(:,2) - RegionSize(2);
        case 2
          Regions = Regions - RegionSize(ones(size(Regions,1),1),:);
        case 3
          Regions(:,1) = Regions(:,1) - RegionSize(1);
      end
    end
    
    
    function output=calculateThreshImage(FlatImage,thresh)
      minIm=min(FlatImage(:));
      threshold = round( (median(FlatImage(:))-minIm)*(imag(thresh)/100) + minIm );
      FlatImage=conv2( double(FlatImage), fspecial( 'average', 3 ), 'same' );
      output = ( FlatImage > threshold );
    end
    
    
  end
end