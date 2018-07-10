classdef DataEvaluationClass < AutoTipTrackDataClass
  properties
    Success=false;
    Manual = false;
    MergeDimensions = {...
      'MergeDimensions', 0;...
      'SavePath', 0};
  end
  methods
    
    
    function D=DataEvaluationClass(QueueElement, varargin)
      if nargin < 1
        QueueElement = ConfigClass;
      end
      D@AutoTipTrackDataClass(QueueElement)
      if isa(QueueElement,'AutoTipTrackDataClass')
        Props = properties(QueueElement);
        for n = 1:length(Props)
          if isprop(D,Props{n})
              D.(Props{n}) = QueueElement.(Props{n});
          end
        end
      end
      p=inputParser;
      p.addParameter('Manual',false,@islogical);
      p.KeepUnmatched=true;
      p.parse(varargin{:});
      if p.Results.Manual
        D.Manual = true;
      end
    end

    %external methods
    makeImg(S, parent)
    
    
    function D = evaluate(D)
      trackStatus(D.StatusFolder,'Evaluating data','Calculating...',0,4,1);
      D.calculateResults;
      trackStatus(D.StatusFolder,'Evaluating data','Filtering...',1,4,1);
      D.filterResults;
      trackStatus(D.StatusFolder,'Evaluating data','Making figure...',2,4,1);
      if D.Manual
        D.manuallyEvaluate;
      end
      D.makeFigure;
      trackStatus(D.StatusFolder,'Evaluating data','Saving file...',3,4,1);
      D.saveFiestaCompatibleFile;
      trackStatus(D.StatusFolder,'Evaluating data','Done',4,4,1);
   end
    
    
    function D=calculateResults(D)
      % calculateResults
      %
      % Function placeholder for calculating Results
    end
    
    
    function D=filterResults(D)
      % filterResults
      %
      % Function placeholder for calculating Results
    end
    
    
    function D=manuallyEvaluate(D)
      % manuallyEvaluate
      %
      % Function placeholder for user assisted manual evaluation of data
    end
    
    
    function makeFigure(D) %#ok<MANU>
      % makeFigure
      %
      % Function placeholder for creating and saving a plot of the Results
    end
    
    
    function D=testSuccess(D)
      % testSuccess
      %
      % Function placeholder for testing whether evaluation was successful
      D.Success=true;
    end
    
    
    function D = merge(D, Class2Merge)
      if isa(Class2Merge, class(D))
        Properties = properties(D);
        for n = 1:length(Properties)
          D.(Properties{n}) = D.mergeDataVars(D.(Properties{n}), Class2Merge.(Properties{n}), Properties{n});
        end
      else
        warning('MATLAB:AuotTipTrack:DataEvaluationClass:merge',...
          'Could not merge %s, not a %s.', class(Class2Merge), class(D));
      end
    end
    
    
    function Merged = mergeDataVars(D, Var1, Var2, Name)
      Merged = mergeVars(Var1, Var2, 'MergeDimensions', D.MergeDimensions, 'InputName', Name, 'Debug', D.Debug);
    end
    
    
    function D = getNeededPartOfStack(D)
      ImagesNeeded = D.Config.Evaluation.ImagesNeeded{D.Config.Evaluation.EvalClassNo};
      if isempty(D.Stack)
        if ImagesNeeded == 1
          D.loadMiddleImage;
        else
          LF = D.Config.LastFrame;
          D.Config.LastFrame = ImagesNeeded;
          D.loadFile;
          D.Config.LastFrame = LF;
        end
      elseif length(D.Stack) > ImagesNeeded
        Margin = (length(D.Stack) - ImagesNeeded) / 2;
        D.Stack = D.Stack(ceil(Margin) + 1:end - floor(Margin));
      end
    end
    
    
    function D = setImage(D)
      if ~isfield(D.Results, 'Image') || isempty(D.Results.Image)
        D.getNeededPartOfStack;
        D.Results.Image = D.Stack{1};
      end
    end
    
    
  end
  methods (Static)
    
    
    function makeOverviewFigure(SpeedEvaluationClasses,folder) %#ok<INUSD>
      % makeOverviewFigure
      %
      % Function placeholder for a function that goes through 
      % SpeedEvaluationClasses and makes an overview figure
    end
    
    
  end
end
