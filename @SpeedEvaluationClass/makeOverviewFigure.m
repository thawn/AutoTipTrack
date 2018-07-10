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
  x=1:numFiles;
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
    save(fullfile(folder,'Speed_summary.mat'),'meanresults','slowresults','fastresults','numMTs','lengthMTs','labels','fileNames','acquisitionDates','allSpeeds','allLengths')
  catch ME
    ME.getReport
  end
  DataName=fullfile(folder,[class(SpeedEvaluationClasses{1}) '_Data.mat']);
  SpeedData=cellfun(@(x) x.exportData,SpeedEvaluationClasses,'UniformOutput',false); %#ok<NASGU>
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
    plot1=errorbar(x(startData:endData),meanresults(startData:endData,1),meanresults(startData:endData,2),'-ob','Parent',ax1);
    hold(ax1,'on');
    plot2=errorbar(x(startData:endData),slowresults(startData:endData,1),slowresults(startData:endData,2),'-sr','Parent',ax1);
    plot3=errorbar(x(startData:endData),fastresults(startData:endData,1),fastresults(startData:endData,2),'-dg','Parent',ax1);
    plot4=errorbar(x(startData:endData),numMTs(startData:endData),sqrt(numMTs(startData:endData)),'-vm','Parent',ax1);
    plot5=plot(x(startData:endData),lengthMTs(startData:endData,1),'-^c','Parent',ax1);
    set(plot1(1),'DisplayName','mean speeds (nm/s)');
    set(plot2(1),'DisplayName','slow population (nm/s)');
    set(plot3(1),'DisplayName','fast population (nm/s)');
    set(plot4(1),'DisplayName','number of MT');
    set(plot5(1),'DisplayName','5^{th} precentile of MT length (nm)');
    set(gca,'TickLabelInterpreter','none','XTick',(startData:endData),'XTickLabel',labels(startData:endData));
    xticklabel_rotate([],90,'interpreter','none');
    legend(gca,'show','Location','best');
    ylabel('mean velocities (nm/s)','FontSize',14);
    figurename=fullfile(folder,['SpeedResultsSummary', num2str(n), '.pdf']);
    saveas(fig1,figurename);
    close(fig1);
  end
  if size(acquisitionDates)~=size(meanresults)
    %if the sizes don't match try to remove NaN values and check again
    [r,~]=find(isnan(meanresults));
    r=unique(r);
    meanresults(r,:)=[];
    fastresults(r,:)=[];
    slowresults(r,:)=[];
    numMTs(r,:)=[];
  end
  if size(acquisitionDates,1)==size(meanresults,1) && ~all(isnat(acquisitionDates))
    %create an overview plot by acquisition date
    fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
    ax1=axes('Parent',fig1);
    hold(ax1,'off');
    plot1=plot(acquisitionDates,meanresults(:,1),'-ob','Parent',ax1);
    hold(ax1,'on');
    plot2=plot(acquisitionDates,slowresults(:,1),'-sr','Parent',ax1);
    plot3=plot(acquisitionDates,fastresults(:,1),'-dg','Parent',ax1);
    plot4=plot(acquisitionDates,numMTs,'-vm','Parent',ax1);
    plot5=plot(acquisitionDates,lengthMTs(:,1),'-^c','Parent',ax1);
    set(plot1(1),'DisplayName','mean speeds');
    set(plot2(1),'DisplayName','slow population');
    set(plot3(1),'DisplayName','fast population');
    set(plot4(1),'DisplayName','number of MT');
    set(plot5(1),'DisplayName','5^{th} precentile of MT length');
    legend(gca,'show','Location','best');
    ylabel(ax1,'mean velocities (nm/s)','FontSize',14);
    xlabel(ax1,'Acquisition Time','FontSize',14);
    figurename=fullfile(folder,'SpeedResultsByTime.pdf');
    saveas(fig1,figurename);
    close(fig1);
  end
end
