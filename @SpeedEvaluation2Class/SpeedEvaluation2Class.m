classdef SpeedEvaluation2Class < SpeedEvaluationClass
  properties
  end
  methods
    %constructor
    function S=SpeedEvaluation2Class(varargin)
      S@SpeedEvaluationClass(varargin{:})
    end
    
    
    % external methods
    [success,S]=evaluateSpeeds(S)
    
    
    function S=filterResults(S)
      %filter out speeds
      
      % make sure we have results
      if ~isstruct(S.Results) || ~isfield(S.Results,'Speed') || ~isfield(S.Results,'MolIds')
        S.reloadResults('Results');
      end
      if isstruct(S.Results) && isfield(S.Results,'Speed')
        S.numMT=size(S.Results.Speed,2)/2;
        if isfield(S.Results,'MolIds') && isa(S.Config,'ConfigClass') && ...
            ~isempty(S.Pathinfo)
          %Step 1:if we should have generated paths, we remove speeds that were not determined using paths
          if S.Config.Path.Generate
            S.Results.MolIds(S.Pathinfo<1)=[];
            S.Results.Speed(:,S.Pathinfo<1)=[];
          end
          %Step2:remove tracks where we have speeds that are higher than
          %the MaxVelocity allows. This usually happens because the path
          %calculation was wrong
          maxSpeed=S.Config.ConnectMol.MaxVelocity*1.1;
          tooSlow=find(min(S.Results.Speed)<-maxSpeed);
          tooFast=find(max(S.Results.Speed)>maxSpeed);
          eliminate=unique([tooSlow tooFast]);
          S.Results.Speed(:,eliminate)=[];
          S.Results.MolIds(:,eliminate)=[];
        end
      end
    end
    
    
  end
  methods (Static)
    
    
    function labelSpeedHistogram(axes,scale)
      xlabel(axes,'frame to frame velocity (nm/s)','FontSize',12/scale,'FontName','Arial');
      ylabel(axes,'occurrence','FontSize',12/scale,'FontName','Arial');
    end
    
    
  end
end
