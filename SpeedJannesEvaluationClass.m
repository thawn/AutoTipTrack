classdef SpeedJannesEvaluationClass < SpeedEvaluationClass
  properties
  end
  methods
    %constructor
    function S=SpeedJannesEvaluationClass(varargin)
      S@SpeedEvaluationClass(varargin{:})
    end
  end
  methods (Static)
    
    function makeOverviewFigure(SpeedEvaluationClasses,folder)
      if ~isempty(SpeedEvaluationClasses)
        numFiles=length(SpeedEvaluationClasses);
        slowresults=NaN(numFiles,2);
        fastresults=NaN(numFiles,2);
        meanresults=NaN(numFiles,2);
        numMTs=NaN(numFiles,1);
        lengthMTs=NaN(numFiles,4);
        labels=cell(numFiles,1);
        fileNames=cell(numFiles,1);
        allSpeeds=cell(numFiles,1);
        allLengths=cell(numFiles,1);
        acquisitionDates=[];
        for n=1:numFiles
          if isa(SpeedEvaluationClasses{n}.Config, 'ConfigClass')
            slowresults(n,:)=SpeedEvaluationClasses{n}.slowresult;
            fastresults(n,:)=SpeedEvaluationClasses{n}.fastresult;
            meanresults(n,:)=SpeedEvaluationClasses{n}.meanresult;
            numMTs(n)=SpeedEvaluationClasses{n}.numMT;
            lengthMTs(n,:)=SpeedEvaluationClasses{n}.lengthMT;
            labels{n}=ellipsize(SpeedEvaluationClasses{n}.Config.StackName,20);
            fileNames{n}=SpeedEvaluationClasses{n}.Config.StackName;
            acquisitionDates=[acquisitionDates; SpeedEvaluationClasses{n}.Config.AcquisitionDate]; %#ok<AGROW>
            if isfield(SpeedEvaluationClasses{n}.Results, 'Speed')
              allSpeeds{n}=SpeedEvaluationClasses{n}.Results.Speed;
            end
            if isfield(SpeedEvaluationClasses{n}.Results, 'Length')
              allLengths{n}=SpeedEvaluationClasses{n}.Results.Length;
            end
          end
        end
        try
          save(fullfile(folder,'Speed_jannes_summary.mat'),'folder','meanresults','slowresults','fastresults','numMTs','lengthMTs','labels','fileNames','acquisitionDates','allSpeeds','allLengths','SpeedEvaluationClasses')
        catch ME
          ME.getReport
        end
      end
      SpeedJannesEvaluationClass.jannesSummary(folder,allSpeeds,fileNames,SpeedEvaluationClasses);
    end
    
    
    function MedianIQRSpeeds=summarizeSpeeds(CombinedSpeeds,Alpha,CombinedFileNames)
      MedianSpeeds=nanmedian(CombinedSpeeds);
      MedianSpeeds(isnan(MedianSpeeds)) = [];
      MedianIQRSpeeds=NaN(1,3);
      fprintf('combining:\n');
      cellfun(@(x) fprintf('%s\n',x),CombinedFileNames)
      if length(MedianSpeeds)>1
        CI=bootci(100000,{@median,MedianSpeeds},'alpha',Alpha,'Options',statset('UseParallel',true));
        MedianIQRSpeeds(1,1)=CI(1); %prctile(MedianSpeeds,25);%25iqr
        MedianIQRSpeeds(1,2)=median(MedianSpeeds);%median
        MedianIQRSpeeds(1,3)=CI(2); %prctile(MedianSpeeds,75);%75iqr
      end
    end
    
    function jannesSummary(folder,allSpeeds,fileNames,SpeedEvaluationClasses)
      
      numFiles=length(allSpeeds);
      numSamples=floor(numFiles/4);
      x=1:numSamples;
      
      CombinedSpeeds=cell(numSamples,1);
      CombinedFileNames=cell(numSamples,1);
      Labels=cell(numSamples,1);
      MedianIQRSpeeds=zeros(numSamples,3);
      Alpha=0.0000003; % 5 sigma = 0.0000003, 3 sigma = 0.003
      CombinedControls=[];
      for n=1:numSamples
        CombinedSpeeds{n}=[allSpeeds{n*4-3} allSpeeds{n*4-2} allSpeeds{n*4-1} allSpeeds{n*4}];
        CombinedFileNames{n}={fileNames{n*4-3};fileNames{n*4-2};fileNames{n*4-1};fileNames{n*4}};
        Labels{n}=ellipsize(fileNames{n*4-3},20);
        if (any(cellfun(@any,strfind(CombinedFileNames{n},'control'))))
          CombinedControls=[CombinedControls CombinedSpeeds{n}]; %#ok<AGROW>
        end
        MedianIQRSpeeds(n,:)=SpeedJannesEvaluationClass.summarizeSpeeds(CombinedSpeeds{n},Alpha,CombinedFileNames{n});
        if ~all(isnan(MedianIQRSpeeds(n,:)))
          SpeedJannesEvaluationClass.sampleOverviewFigure(CombinedSpeeds{n}, MedianIQRSpeeds(n,:),SpeedEvaluationClasses(n*4-3:n*4));
        end
      end
      pRankSumDisplay=NaN(numSamples,1);
      % Assigning Values  according to the significance for display in the
      % plot later
      if ~isempty(CombinedControls)
        ControlMedianIQRSpeeds=SpeedJannesEvaluationClass.summarizeSpeeds(CombinedControls,Alpha);
        UpperControl=ControlMedianIQRSpeeds(1,3);
        LowerControl=ControlMedianIQRSpeeds(1,1);
        for n=1:numSamples
          if (UpperControl<MedianIQRSpeeds(n,1) || LowerControl>MedianIQRSpeeds(n,3))
            pRankSumDisplay(n,1)=100;
          end
        end
      end
      
      numFigs=ceil(numSamples/32);
      for n=1:numFigs
        startData=(n-1)*32+1;
        endData=n*32;
        if endData>length(x)
          endData=length(x);
        end
        %create an overview plot by stack name
        fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
        %set(fig1, 'Visible','on')
        ax1=axes('Parent',fig1);
        hold(ax1,'off');        
        
        plot1=bar(x(startData:endData),MedianIQRSpeeds(startData:endData,2),'Parent',ax1);
        TextY=ones(endData).*max(MedianIQRSpeeds(startData:endData,3))+50;
        text(x(startData:endData),TextY(startData:endData),num2str(MedianIQRSpeeds(startData:endData,2)),'HorizontalAlignment','center'); % display values of the medians
        hold(ax1,'on');
        if ~isempty(CombinedControls)
          plot4=bar(numSamples+1,ControlMedianIQRSpeeds(2),'Parent',ax1);
          plot4.FaceColor = 'red';
          text(numSamples+1,ControlMedianIQRSpeeds(3)+50,num2str(ControlMedianIQRSpeeds(2)),'HorizontalAlignment','center');
          plot6=errorbar(numSamples+1,ControlMedianIQRSpeeds(2),ControlMedianIQRSpeeds(2)-ControlMedianIQRSpeeds(1),ControlMedianIQRSpeeds(3)-ControlMedianIQRSpeeds(2),'Parent',ax1);
          set(plot6(1),'DisplayName','');
        end
        plot2=errorbar(x(startData:endData),MedianIQRSpeeds(startData:endData,2),...
            MedianIQRSpeeds(startData:endData,2)-MedianIQRSpeeds(startData:endData,1),...
            MedianIQRSpeeds(startData:endData,3)-MedianIQRSpeeds(startData:endData,2),'Parent',ax1);
        set(plot2,'LineStyle','none');
        plot3=plot(x(startData:endData),pRankSumDisplay(startData:endData));
        
        
        %Display significance of the statistical test with *
        
        plot3(1).LineStyle = 'none';
        plot3(1).Marker = '*';
        plot3(1).MarkerSize = 10;
        % Beschriftung der Daten im Fenster
        set(plot1(1),'DisplayName','median speeds (nm/s)');% set(Handle,'PropertyName',PropertyValue)
        set(plot2(1),'DisplayName','');
        xlim(ax1,[startData-0.5 endData+1.5]);
        set(ax1,'TickLabelInterpreter','none','XTick',(startData:endData+1),'XTickLabel',[Labels(startData:endData);{'combined controls'}]);
        xticklabel_rotate([],90,'interpreter','none');
        ylabel('median velocities (nm/s)','FontSize',14);
        figurename=fullfile(folder,['SpeedJannesResultsSummary', num2str(n), '.pdf']);
        saveas(fig1,figurename);
        close(fig1);
      end
      
    end
    
    
    function sampleOverviewFigure(CombinedSpeeds, MedianIQRSpeeds, SpeedEvaluationClasses)
      Fig1=createBasicFigure();
      %Fig1.Visible='on';
      NumWells=length(SpeedEvaluationClasses);
      S=SpeedJannesEvaluationClass;
      S.Results.Speed=CombinedSpeeds;
      S.Config=SpeedEvaluationClasses{1}.Config;
      S.evaluateSpeeds;
      %Create the subplot figure
      Ax=subplot(NumWells+2,3,[1,6],'Parent',Fig1);
      S.plotSpeedHistogram(Ax,1);
      title(Ax, 'Combined Velocity Histogram');
      %plot median and iqrs
      IqrY=[0 max(S.count)*1.1];
      hold(Ax,'on');
      Color=[0.2 0.8, 0.2];
      plot(Ax,[MedianIQRSpeeds(1) MedianIQRSpeeds(1)],IqrY,'--','LineWidth',1,'Color',Color);
      plot(Ax,[MedianIQRSpeeds(2) MedianIQRSpeeds(2)],IqrY,'-','LineWidth',2,'Color',Color);
      plot(Ax,[MedianIQRSpeeds(3) MedianIQRSpeeds(3)],IqrY,'--','LineWidth',1,'Color',Color);
      
      for n=1:NumWells
        SpeedEvaluationClasses{n}.speedFigure(Fig1,NumWells+2,3,n*3+4,n*3+5,n*3+6);
      end
      EvalName=fullfile(SpeedEvaluationClasses{1}.Config.Directory, [SpeedEvaluationClasses{1}.Config.StackName '_combined.pdf']);
      saveas(Fig1,EvalName);
     
      close(Fig1);
    end
  end
end

