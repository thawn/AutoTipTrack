classdef AngleEvaluationClass < SpeedEvaluation2Class
  properties
  end
  methods
    %constructor
    function S=AngleEvaluationClass(varargin)
      S@SpeedEvaluation2Class(varargin{:})
    end
    
    function Angles=anglesFromTrack(S)
        Window = 5;
        Angles=cell(length(S.Molecule),1);
        for n = 1:length(S.Molecule)
            %     Distances = Molecule(n).PathData(2:end,1:2) - Molecule(n).PathData(1:end-1,1:2);
            Distances = S.Molecule(n).Results(2:end,3:4) - S.Molecule(n).Results(1:end-1,3:4);
            Angles{n} = movmean(atan2(-Distances(:, 2), Distances(:,1)), Window);
        end
        Angles=cell2mat(Angles);
    end

    function S=speedFigure(S,parent,m,n,P,p1,p2)
        %plot the first image of the stack
        scale=n/2;
        subplot0=subplot(m,n,P,'Parent',parent);
        S.makeImg(subplot0);
        ImageTitle=strrep(S.Config.StackName,'_',' ');
        title(ImageTitle,'FontSize',16/scale,'FontName','Arial');
        [success,S]=S.evaluateSpeeds;
        if success
            subplot1 = subplot(m,n,p1,'Parent',parent,'FontSize',10/scale,'FontName','Arial');
            
            %a histogram of the average speeds of the filaments
            S.plotSpeedHistogram(subplot1,scale)
            
            % Create speeds vs time subplot
            subplot2 = subplot(m,n,p2,'Parent',parent,'FontSize',10/scale,'FontName','Arial');
            box(subplot2,'on');
            Angles = S.anglesFromTrack();
            NBins = length(Angles) / 20;
            if NBins > 36
                NBins = 36;
            end
            polarhistogram(Angles,NBins)
            set(gca,'FontSize',10/scale)
            
            S.addResultAnnotation(parent,subplot1,scale);
        else
            subplot1=subplot(m,n,[p1 p2],'Parent',parent,'FontSize',10/scale,'FontName','Arial');
            set(gca, 'Visible','off')
            boxPos=S.calculateBoxPos(subplot1);
            % Create textbox
            annotation(parent,'textbox',...
                boxPos,...
                'String',{'No microtubule tips could be tracked.','Check stack and configuration for errors.'},...
                'FontSize',12/scale,'FontName','Arial','Color','k',...
                'LineStyle','none','Margin',0,'VerticalAlignment','middle',...
                'FitBoxToText','off');
        end
    end
   
    
  end
end
