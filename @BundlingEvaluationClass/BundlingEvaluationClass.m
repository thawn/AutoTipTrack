classdef BundlingEvaluationClass < DataEvaluationClass
  properties
    Intensities=cell(0);
    Bundling=[];
    BundleThreshold=[];
    AreaRatio=[];
    Background=[];
    LineHeight=[];
    %StatusFolder;
  end
  methods
    %constructor
    function B=BundlingEvaluationClass(varargin)
      B@DataEvaluationClass(varargin{:})
      B.getNeededPartOfStack;
      numFrames=length(B.Stack);
      B.Intensities=cell(1,numFrames);
      B.Bundling=zeros(1,numFrames);
      B.BundleThreshold=zeros(1,numFrames);
    end
    
    
    function B=calculateResults(B)
      if isempty(B.Objects)
        B.manuallyEvaluate;
      else
        B.autoEvaluateBundling;
      end
    end
    
    
    function B=autoEvaluateBundling(B,ThresholdFactor)
      if nargin<2
        ThresholdFactor=1.6;
      end
      for n=1:length(B.Stack)
        if ~isempty(B.Objects{n})
          B.Background(n)=median(B.Objects{n}.background(1,:));
          B.LineHeight(n)=median(B.Objects{n}.height(1,:));
          B.BundleThreshold(n)=B.Background(n)+B.LineHeight(n)*ThresholdFactor;
          B.Intensities{n}=double(B.Stack{n}(B.Stack{n}>B.BundleThreshold(n)))-B.Background(n);
          Threshold=QueueElementClass.calculateThreshold(B.Config,B.Stack(n));
          %smoothe the image for thresholding
          Im=conv2( single(B.Stack{n}), fspecial( 'average', 3 ), 'same' );
          BW=Im>Threshold;
          %thin the threshold image so that the value of the threshold does
          %not affect the area too much
          BW=bwmorph(BW,'thin',Inf);
          % ignore circular objects and noise for area comparison
          BW=bwmorph(BW,'clean');
          BWBundle=Im>B.BundleThreshold(n);
          %for the bundling we apply the same filters as above
          BWBundle=bwmorph(BWBundle,'thin',Inf);
          BWBundle=bwmorph(BWBundle,'clean');
          B.AreaRatio(n)=sum(BWBundle(:))/sum(BW(:));
          B.Bundling(n)=B.AreaRatio(n);%*mean(B.Intensities{n})/B.LineHeight(n);
        end
      end
    end
    
    
    function B=manuallyEvaluate(B)
      for n=1:length(B.Stack)
        FlatImg=flattenImage(B.Stack{n},20,0);
        MedianImg=median(FlatImg(:));
        BgThresh=round(MedianImg*2);
        Bg=mean(FlatImg(FlatImg<BgThresh));
        FlatImg=int32(FlatImg)-Bg;
        LineScan=B.interactiveLineScan(FlatImg);
        XPos=1:length(LineScan);
        FitRes=fit(XPos',LineScan','gauss1');
        B.LineHeight(n)=FitRes.a1;
        fig1=figure;
        plot(XPos,LineScan);
        hold('on');
        plot(FitRes);
        pause(1);
        close(fig1);
        B.BundleThreshold(n)=B.LineHeight(n)*(imag(B.Config.Threshold.Value)/100);
        %Threshold=round( (mean2(FlatImg)-MinImg)*(p.Results.Threshold) + MinImg );
        B.Intensities{n}=FlatImg(FlatImg>B.BundleThreshold(n));
        B.Bundling(n)=mean(B.Intensities{n})/B.BundleThreshold(n);
      end
      disp(B.Bundling);
    end
    
    
    function B=makeFigure(B)
      figure1=createBasicFigure();
      subplot0=subplot(3,2,[1 4],'Parent',figure1);
      B.makeImg(subplot0);
      ImageTitle=strrep(B.Config.StackName,'_',' ');
      title(ImageTitle,'FontSize',16,'FontName','Arial');
      subplot1 = subplot(3,2,[5 6],'Parent',figure1,'FontSize',10,'FontName','Arial');
      plot1=plot(subplot1,1:length(B.Stack),B.Bundling);
      set(plot1,'DisplayName','Bundling');
      xlabel(subplot1,'frame #');
      ylabel(subplot1,'mean relative intensity of bundles');
      evalName=fullfile(B.Config.Directory, B.Config.StackName);
      saveas(figure1,[evalName '.pdf']);
      close(figure1);
    end

    
    
    function B=testSuccess(B)
      if ~isempty(B.Intensities) && ~all(cellfun(@isempty,B.Intensities))
        B.Success=true;
      else
        B.Success=false;
      end
    end
    
    
  end
  methods (Static)
    
    
     %external methods
     makeOverviewFigure(BundlingEvaluationClasses,folder,ManualAcquisitionDates)
    
    
    function LineScan=interactiveLineScan(Stack,varargin)
      p=inputParser;
      p.addParameter('Scaling',[],@isnumeric);
      p.KeepUnmatched=true;
      p.parse(varargin{:});
      LineScan=[];
      function drawLineScan(pos)
        Width=3;
        Span=round((Width-1)/2);
        LUnit=pos(2,:)-pos(1,:);
        NormLength=norm(LUnit);
        PixelLength=round(NormLength);
        OrthoVector=[-LUnit(2), LUnit(1)];
        NormalizedOrtho=OrthoVector/norm(OrthoVector);
        LineScan=zeros(Span*2+1,PixelLength);
        for k=1:PixelLength
          for j=-Span:Span
            CurPos=round(pos(1,:)+((LUnit+(NormalizedOrtho*j)).*(k/PixelLength)));
            LineScan(j+Span+1,k)=Stack(CurPos(1),end-CurPos(2));
          end
        end
        LineScan=mean(LineScan);
        XPos=(1:PixelLength);
        plot(GuiAx2,XPos,LineScan);
      end
      function finishLineScan(caller,~)
        close(get(caller,'Parent'));
      end
      FontSize=8;
      ImageSize=size(Stack)+[100 50];
      AspectRatio=ImageSize(1)/ImageSize(2);
      LineScanAspect=1.5;
      ButtonSize=[50 20];
      if AspectRatio>1.5
        %The structure is in landscape format
        LineScanSize=round([ImageSize(1) ImageSize(1)/LineScanAspect]);
        FigPosition=[ImageSize(1) ImageSize(2)+LineScanSize(2)];
        Pane1Position=[0 LineScanSize(2)+1 ImageSize(1) ImageSize(2)];
        Pane2Position=[0 0 LineScanSize(1) LineScanSize(2)];
      else
        %The structure is in portrait format
        LineScanSize=round([ImageSize(2)*LineScanAspect ImageSize(2)]);
        FigPosition=[ImageSize(1)+LineScanSize(1) ImageSize(2)];
        Pane1Position=[0 0 ImageSize(1) ImageSize(2)];
        Pane2Position=[ImageSize(1)+1 0 LineScanSize(1) LineScanSize(2)];
      end
      CombinedAspect=FigPosition(1)/FigPosition(2);
      if CombinedAspect>1.5
        %The combined figure is in landscape format
        GuiPosition=[FigPosition(1) FigPosition(2)+ButtonSize(2)];
        GuiPane1Position=Pane1Position+[0 ButtonSize(2)+1 0 0];
        GuiPane2Position=Pane2Position+[0 ButtonSize(2)+1 0 0];
      else
        GuiPosition=[FigPosition(1)+ButtonSize(1)+1 FigPosition(2)];
        GuiPane1Position=Pane1Position;
        GuiPane2Position=Pane2Position;
      end
      SaveButtonPosition=[1-ButtonSize(1)/GuiPosition(1) 0 ButtonSize(1)/GuiPosition(1) ButtonSize(2)/GuiPosition(2)];
      Gui=figure('Units','pixels','Position',[10 10 GuiPosition(1)+1 GuiPosition(2)+1]);
      Pane1=uipanel(Gui,'Units','pixels','Position',GuiPane1Position);
      Pane2=uipanel(Gui,'Units','pixels','Position',GuiPane2Position);
      set(Gui,'Units','normalized');
      SaveButton=uicontrol(...
        'Parent',Gui,...
        'String','done',...
        'Style','pushbutton',...
        'Units','normalized',...
        'Position',SaveButtonPosition,...
        'UserData',LineScan,...
        'Callback',@finishLineScan,...
        'Tag','doneButton');
      GuiAx1Label=axes('Parent',Pane1);
      set(Pane1,'Units','normalized');
      set(Pane2,'Units','normalized');
      set(GuiAx1Label,'Layer','bottom','Visible','on','Color','none','Position',[0.05 0.05 0.95 0.95],...
        'FontSize',FontSize,'DataAspectRatioMode','manual','DataAspectRatio',[1 1 1]);
      GuiAx1=axes('Parent',Pane1);
      if length(p.Results.Scaling)~=2
        imagesc(flipud(Stack'),'Parent',GuiAx1);
      else
        imagesc(flipud(Stack'),'Parent',GuiAx1,p.Results.Scaling);
      end
      set(GuiAx1,'Layer','top','Visible','off','Position',[0.05 0.05 0.95 0.95],...
        'FontSize',FontSize,'DataAspectRatioMode','manual','DataAspectRatio',[1 1 1]);
      GuiAx2=axes('Parent',Pane2);
      uicontrol(SaveButton);
      ScanLine=imline(GuiAx1);
      ScanLine.addNewPositionCallback(@drawLineScan);
      drawLineScan(ScanLine.getPosition);
      set(Gui,'PaperUnits','centimeter','PaperSize',[32 18],...
        'PaperPosition',[0 0 32 18]);
      uiwait(Gui);
    end
    
    
  end
end
