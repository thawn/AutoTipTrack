function makeOverviewFigure(Speed2TempEvaluationClasses,folder)
if ~isempty(Speed2TempEvaluationClasses)
  numFiles=length(Speed2TempEvaluationClasses);
  speeds=NaN(numFiles,3);
  temperatures=NaN(numFiles,3);
  numMTs=NaN(numFiles,1);
  lengthMTs=NaN(numFiles,4);
  labels=cell(numFiles,1);
  fileNames=cell(numFiles,1);
  allSpeeds=cell(numFiles,1);
  allLengths=cell(numFiles,1);
  allTemperatures=cell(numFiles,1);
  x=1:numFiles;
  acquisitionDates=[];
  medianSpeeds=[];
  medianSpeedErrs=[];
  medianTemperatures=[];
  medianTempErrs=[];
  times=[];
  Offset=0;
  for n=1:numFiles
    if isa(Speed2TempEvaluationClasses{n}.Config, 'ConfigClass')
      numMTs(n)=Speed2TempEvaluationClasses{n}.numMT;
      lengthMTs(n,:)=Speed2TempEvaluationClasses{n}.lengthMT;
      labels{n}=ellipsize(Speed2TempEvaluationClasses{n}.Config.StackName,20);
      fileNames{n}=Speed2TempEvaluationClasses{n}.Config.StackName;
      acquisitionDates=[acquisitionDates; Speed2TempEvaluationClasses{n}.Config.AcquisitionDate]; %#ok<AGROW>
      if isfield(Speed2TempEvaluationClasses{n}.Results, 'Speed')
        allSpeeds{n}=Speed2TempEvaluationClasses{n}.Results.Speed;
        speeds(n,:)=[nanmedian(allSpeeds{n}(:)) prctile(allSpeeds{n}(:),25) prctile(allSpeeds{n}(:),75)];
        medianSpeeds=[medianSpeeds nanmedian(allSpeeds{n},2)']; %#ok<AGROW>
        p25=prctile(allSpeeds{n},25,2)';
        p75=prctile(allSpeeds{n},75,2)';
        center=p25+(p75-p25)./2;
        medianSpeedErrs=[medianSpeedErrs [center; p25; p75]]; %#ok<AGROW>
      end
      if isfield(Speed2TempEvaluationClasses{n}.Results, 'Length')
        allLengths{n}=Speed2TempEvaluationClasses{n}.Results.Length;
      end
      if isfield(Speed2TempEvaluationClasses{n}.Results, 'Temperature')
        allTemperatures{n}=Speed2TempEvaluationClasses{n}.Results.Temperature;
        temperatures(n,:)=[nanmedian(allTemperatures{n}(:)) prctile(allTemperatures{n}(:),25) prctile(allTemperatures{n}(:),75)];
        medianTemperatures=[medianTemperatures nanmedian(allTemperatures{n},2)']; %#ok<AGROW>
        p25=prctile(allTemperatures{n},25,2)';
        p75=prctile(allTemperatures{n},75,2)';
        center=p25+(p75-p25)./2;
        medianTempErrs=[medianTempErrs [center; p25; p75]]; %#ok<AGROW>
      end
      if n>1
        Offset=Speed2TempEvaluationClasses{n-1}.Config.Time/1000*length(times);
      end
      times=[times Speed2TempEvaluationClasses{n}.time+Offset]; %#ok<AGROW>
    end
  end
  times=times-times(1);
  try
    save(fullfile(folder,'Temperature_summary.mat'),'numMTs','lengthMTs','labels','fileNames','acquisitionDates','allSpeeds','speeds','medianSpeeds','medianSpeedErrs','allLengths','allTemperatures','temperatures','medianTemperatures','medianTempErrs','times')
  catch ME
    ME.getReport
  end
  DataName=fullfile(folder,[class(Speed2TempEvaluationClasses{1}) '_Data.mat']);
  SpeedData=cellfun(@(x) x.exportData,Speed2TempEvaluationClasses,'UniformOutput',false); %#ok<NASGU>
  try
    save(DataName,'SpeedData');
  catch ME
    ME.getReport
  end
  numFigs=ceil(numFiles/32);
  for n=1:numFigs
    startData=(n-1)*32+1;
    endData=n*32;
    if endData>length(x)
      endData=length(x);
    end
    %create an overview plot by stack name
    fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
    ax1=axes('Parent',fig1);
    hold(ax1,'off');
    plot1=errorbar(x(startData:endData),speeds(startData:endData,1),speeds(startData:endData,2),'-sr','Parent',ax1);
    hold(ax1,'on');
    plot2=errorbar(x(startData:endData),temperatures(startData:endData,1),temperatures(startData:endData,2),'-dg','Parent',ax1);
    plot3=errorbar(x(startData:endData),numMTs(startData:endData),sqrt(numMTs(startData:endData)),'-vm','Parent',ax1);
    plot4=plot(x(startData:endData),lengthMTs(startData:endData,1),'-^c','Parent',ax1);
    set(plot1(1),'DisplayName','velocity');
    set(plot2(1),'DisplayName','temperature');
    set(plot3(1),'DisplayName','number of MT');
    set(plot4(1),'DisplayName','5^{th} precentile of MT length');
    set(ax1,'TickLabelInterpreter','none','XTick',(startData:endData),'XTickLabel',labels(startData:endData));
    xticklabel_rotate([],90,'interpreter','none');
    legend(ax1,'show','Location','best');
    ylabel('mean velocities (nm/s)','FontSize',14);
    figurename=fullfile(folder,['TemperatureResultsSummary', num2str(n), '.pdf']);
    saveas(fig1,figurename);
    close(fig1);
  end
  % plotting median and errorbars properly
  if size(times)~=size(medianSpeeds)
    %if the sizes don't match try to remove NaN values and check again
    [~,c]=find(isnan(medianSpeeds));
    c=unique(c);
    times(:,c)=[];
    medianSpeeds(:,c)=[];
    medianSpeedErrs(:,c)=[];
  end

  %create an overview plot by acquisition time
  fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
  ax1=axes('Parent',fig1);
  [plot1]=properErrorbar(times,medianSpeeds,medianSpeedErrs,[0.1 0.1 0.8],'s',ax1);
  set(plot1(1),'DisplayName','slow population');
  ylabel(ax1,'median velocities (nm/s)','FontSize',14);
  xlabel(ax1,'Time (s)','FontSize',14);
  
  figurename=fullfile(folder,'VelocityResultsByTime.pdf');
  saveas(fig1,figurename);
  close(fig1);

  %create a second figure for the temperature
  fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
  ax2=axes('Parent',fig1);
  [plot3]=properErrorbar(times,medianTemperatures,medianTempErrs,[0.8 0.1 0.1],'o',ax2);
  set(plot3(1),'DisplayName','slow population');
  ylabel(ax2,'Temperature (?C)','FontSize',14);
  
  figurename=fullfile(folder,'TemperatureResultsByTime.pdf');
  saveas(fig1,figurename);
  close(fig1);
end
end

function [plot1,plot2]=properErrorbar(x,median,medianErrs,color,Marker,ax)
hold(ax,'off');
plot1=plot(x,median,'Marker',Marker,'Color',color,'Parent',ax);
hold(ax,'on');
plot2=errorbar(x,medianErrs(1,:),medianErrs(3,:)-medianErrs(2,:),'.','Color',color,'Parent',ax);
set(plot1, 'LineStyle','none');
set(plot2, 'Marker','none');
legend(ax,'show','Location','best');
ylim(ax,[0 max(median)*1.2]);
end
