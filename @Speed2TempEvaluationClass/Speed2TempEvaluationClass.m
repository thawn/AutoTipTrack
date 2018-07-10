classdef Speed2TempEvaluationClass < SpeedEvaluation2Class 
  properties
  end
  methods
    %constructor
    function S=Speed2TempEvaluationClass(varargin)
      S@SpeedEvaluation2Class(varargin{:})
    end
    
    
   function S=filterResults(S)
      %%filter out speeds
      
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
      %% calculate temperatures from speeds
      % v(T)=A*exp(-Ea/(R*T)) from Victors Thesis (on silicon chips on
      % peltier): A=6.6*10^9 nm/s; Ea=40 000 J/mol; R=8.314 J/(mol*K)
      % T(v)=-Ea/(ln(v/A)*R)
      A=6.6*10^9;
      Ea=40000;
      R=8.314;
      S.Results.Temperature=abs(-Ea./(log(S.Results.Speed./A).*R))-273.15;
    end
    
    
  end
  methods (Static)
 
    
    % external methods
    makeOverviewFigure(Speed2TempEvaluationClasses,folder)
    
    
  end
end
