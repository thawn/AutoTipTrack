classdef MakeMovieEvaluationClass < DataEvaluationClass
  %MakeMovieEvaluationClass Makes movies with scalebar and timestamp out of stacks
  %   MakeMovieEvaluationClass Inherits from DataEvaluationClass. It is
  %   called by the evaluateData function in the QueueElementClass. It is
  %   configured through the ConfigClass.
  
  properties
  end
  
  methods
    %constructor
    function S=MakeMovieEvaluationClass(varargin)
      S@DataEvaluationClass(varargin{:})
    end
    
    
    function S=makeFigure(S)
      try
        S.getNeededPartOfStack;
      catch ME
        ME.getReport;
      end
      avifile=S.getAviName;
      if exist(avifile,'file')~=2 && S.Config.Avi.Make && ...
            ~isempty(S.Stack) && length(S.Stack)>1 && ~isempty(S.Stack{1})
          S.writeAvi(avifile);
      end
    end
    
    
    function S=testSuccess(S)
      % testSuccess
      %
      % Function placeholder for testing whether evaluation was successful
      if exist(S.getAviName,'file')==2
        S.Success=true;
      else
        S.Success=false;
      end
    end
    
    
    function avifile=getAviName(S)
      [~,sName,~] = fileparts(S.Config.StackName);
      avifile=fullfile(S.Config.Directory, [sName '.avi']);
    end
    
    
    function writeAvi(S,file)
      vidObj = VideoWriter(file,'Motion JPEG AVI');
      vidObj.Quality = 100;
      vidObj.FrameRate = 10;
      open(vidObj);
      if S.Config.ImageScaling.ModeNo==1
        %calculate the pixel intensity for image scaling.
        %make the darkest 1% of pixels black and the brightest 0.2% of pixels white.
        [black, white]=autoscale(S.Stack{floor(length(S.Stack)/2)},1,0.2);
      else
        black=S.Config.ImageScaling.Black;
        white=S.Config.ImageScaling.White;
      end
      creation_time_vector = (S.Config.Times-S.Config.Times(1));
      
      h=figure('InvertHardcopy','off','Visible','off');
      warning off Images:initSize:adjustingMag;
      set(h, 'PaperPositionMode', 'auto','Color','c','Position',[10 10 S.Config.Width+1 S.Config.Height+1]);
      ax=axes('Visible','off','Position',[0 0 1 1],'Parent',h);
      set(ax, 'XTick', [],'YTick',[],'Box','off','XColor','none','YColor','none','DataAspectRatioMode','manual','DataAspectRatio',[1 1 1]);
      maxframe=length(S.Stack);
      frequency=ceil(maxframe/5);
      StatusFolder = fullfile(S.Config.Directory,[S.Config.StackName '_status']);

      for n=1:maxframe
        trackStatus(StatusFolder,'Making avi','',n,maxframe,frequency);
        imagesc(S.Stack{n},'Parent',ax,[black white]);
        colormap(ax,'gray')
        rectangle('Position',calcBar(S.Config),'EdgeColor','none','FaceColor','w','Parent',ax);
        text('Position',calcBarLabel(S.Config),'HorizontalAlignment','center','Color','w','Parent',ax,...
          'String',sprintf('%g %cm',S.Config.Avi.BarSize,181),'FontUnits','normalized','FontSize',S.Config.Avi.mFontSize);
        text('Position',calcTimeStamp(S.Config),'HorizontalAlignment','left','Color','w','Parent',ax,...
          'String',sprintf('%3.1f s',creation_time_vector(n)),'FontUnits','normalized','FontSize',S.Config.Avi.mFontSize);
        if datenum(version('-date'))>datenum(2014,09,14)
          I = print(h, '-RGBImage');
        else
          I = hardcopy(h, '-Dzbuffer', '-r0');
        end
        I = imresize(I,[NaN 512],'bicubic');
        writeVideo(vidObj,I);
        %writeVideo(vidObj,imresize(frame2im(getframe(gca)),[NaN 640],'bicubic'));
      end
      trackStatus(StatusFolder,'Making avi','',maxframe,maxframe,1);
      warning on Images:initSize:adjustingMag;
      close(vidObj);
      close(h);
    end
    
  end
  
end

