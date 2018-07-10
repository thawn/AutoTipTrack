classdef SpeedEvaluationClass < DataEvaluationClass
  properties
    slowresult=[NaN NaN];
    fastresult=[NaN NaN];
    meanresult=[NaN NaN];
    numMT=NaN;
    lengthMT=[NaN NaN NaN NaN];
    histX=[];
    count=[];
    cfun=[];
    time=[];
    binSize=10;
    medianSpeeds=[];
    Pathinfo;
    Startpoints=[50 0 70 50 800 100];
end
  methods
    %constructor
    function S=SpeedEvaluationClass(varargin)
      S@DataEvaluationClass(varargin{:})
    end
    
    
    % external methods
    S=calculateResults(S)
    [success,S]=evaluateSpeeds(S,startpoints)
    S=makeFigure(S,startpoints)
    [startpoints, S]=manuallyEvaluate(S)
    S=speedFigure(S,parent,m,n,P,p1,p2,startpoints,image)
    
    
    function S=filterResults(S)
      %filter out speeds
      
      % make sure we have results
      if ~isstruct(S.Results) || ~isfield(S.Results,'Speed') || ~isfield(S.Results,'MolIds')
        S.reloadResults('Results');
      end
      if isstruct(S.Results) && isfield(S.Results,'Speed') && ...
          isfield(S.Results,'MolIds') && isa(S.Config,'ConfigClass') && ...
          ~isempty(S.Pathinfo)
        %Step 1:if we should have generated paths, we remove speeds that were not determined using paths
        if S.Config.Path.Generate
          S.Results.MolIds(S.Pathinfo<1)=[];
          S.Results.Speed(:,S.Pathinfo<1)=[];
        end
        %Step2:remove speeds that have too high fluctuations
        eliminate=nanstd(S.Results.Speed)>500;
        S.Results.MolIds(eliminate)=[];
        S.Results.Speed(:,eliminate)=[];
        S.saveFiestaCompatibleFile;
      end
    end
    
    
    function plotSpeedHistogram(S,axes,scale)
      %a histogram of the average speeds of the filaments
      box(axes,'on');
      bar(axes,S.histX,S.count,1,'b');
      hold on;
      plot(S.cfun);
      ylim([0 max(S.count)*1.1]);
      xlim([-300 1500]);
      set(gca,'XTick',[0 600 1200],'FontSize',10/scale);
      legend off;
      hold off;
      S.labelSpeedHistogram(axes,scale);
    end
    
    
    function addResultAnnotation(S,parent,targetPlot,scale)
      boxPos=S.calculateBoxPos(targetPlot);
      if isnan(S.slowresult)
        slowLabel = 'no useable slow pop found';
      else
        slowLabel = sprintf('slow pop: %4.0f %c %4.0f nm/s',S.slowresult(1),177,S.slowresult(2));
      end
      if isnan(S.fastresult)
        fastLabel = 'no useable fast pop found';
      else
        fastLabel = sprintf('fast pop: %4.0f %c %4.0f nm/s',S.fastresult(1),177,S.fastresult(2));
      end
      if all(isnan(S.lengthMT))
        lenStr='';
      else
        lenStr=sprintf('length of microtubules: 5^{th}: %4.0f %cm; 50^{th}: %4.0f %cm.',S.lengthMT(1)/1000,186,S.lengthMT(3)/1000,186);
      end
      % Create textbox
      annotation(parent,'textbox',...
        boxPos,...
        'String',{sprintf('number of microtubules: %4.0f',S.numMT),...
        lenStr,...
        sprintf('average speed: %0.1f %c %0.1f nm/s',S.meanresult(1),177,S.meanresult(2)),...
        fastLabel,...
        slowLabel},...
        'FontSize',10/scale,'FontName','Arial','Color','k',...
        'LineStyle','none','Margin',0,'VerticalAlignment','middle',...
        'FitBoxToText','off');
    end
    
    
    function S=testSuccess(S)
      if ~all(isnan(S.meanresult))
        S.Success=true;
      else
        S.Success=false;
      end
    end
    
    
  end
  methods (Static)
    
    
    % external methods
    makeOverviewFigure(SpeedEvaluationClasses,folder)

    
    function labelSpeedHistogram(axes,scale)
      xlabel(axes,'average speed per tip (nm/s)','FontSize',12/scale,'FontName','Arial');
      ylabel(axes,'# microtubule tips','FontSize',12/scale,'FontName','Arial');
    end
    
    
    function boxPos=calculateBoxPos(plotHandle)
      boxPos=get(plotHandle,'Position');
      rightShift=0.01;
      topShift=0.005;
      boxPos(1)=boxPos(1)+rightShift;
      boxPos(3)=boxPos(3)-rightShift*2;
      boxPos(4)=boxPos(4)*0.8;
      boxPos(2)=boxPos(2)+topShift;
    end
    
    
  end
end
