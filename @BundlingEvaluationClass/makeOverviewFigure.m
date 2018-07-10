function makeOverviewFigure(BundlingEvaluationClasses,folder,ManualAcquisitionDates)
if nargin<3
  ManualAcquisitionDates=[];
end
if ~isempty(BundlingEvaluationClasses)
  NumFiles=length(BundlingEvaluationClasses);
  MeanBundling=NaN(NumFiles,1);
  StdBundling=NaN(NumFiles,1);
  AllBundling=cell(NumFiles,1);
  AcquisitionDates=[];
  for n=1:NumFiles
    if isa(BundlingEvaluationClasses{n}.Config, 'ConfigClass')
      MeanBundling(n)=mean(BundlingEvaluationClasses{n}.Bundling);
      AcquisitionDates=[AcquisitionDates; BundlingEvaluationClasses{n}.Config.AcquisitionDate]; %#ok<AGROW>
      StdBundling(n)=std(BundlingEvaluationClasses{n}.Bundling);
      AllBundling{n}=BundlingEvaluationClasses{n}.Bundling;
      BundlingEvaluationClasses{n}.Stack=[];
    end
  end
  if ~isempty(ManualAcquisitionDates)
    AcquisitionDates=ManualAcquisitionDates;
  end
  if length(AcquisitionDates)~=length(MeanBundling)
    warning('MATLAB:AutoTipTrack:makeBundlingFigure','Could not get acquisition dates for all stacks. Time axis will not be correct.')
    AcquisitionDates=1:length(MeanBundling);
  end
  try
    save(fullfile(folder,'Bundling_summary.mat'),'MeanBundling','AcquisitionDates','StdBundling','AllBundling')
  catch ME
    ME.getReport
  end
  DataName=fullfile(folder,[class(BundlingEvaluationClasses{1}) '_Data.mat']);
  BundlingData=cellfun(@(x) x.exportData,BundlingEvaluationClasses,'UniformOutput',false); %#ok<NASGU>
  try
    save(DataName,'BundlingData');
  catch ME
    ME.getReport
  end
  fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
  ax1=axes('Parent',fig1);
  hold(ax1,'off');
  plot1=plot(AcquisitionDates,MeanBundling,'-ob');
  hold(ax1,'on');
  if all(isdatetime(AcquisitionDates))
    errorbar(datenum(AcquisitionDates),MeanBundling,StdBundling,'.b','Parent',ax1);
  elseif isnumeric(AcquisitionDates)
    errorbar(AcquisitionDates,MeanBundling,StdBundling,'.b','Parent',ax1);
  end
  %set(plot1(1),'DisplayName','relative bundle intensity');
  leg1=legend(plot1);
  set(leg1,'Location','best');
  ylabel(ax1,'bundles/single microtubules','FontSize',14);
  xlabel(ax1,'acquisition time','FontSize',14);
  figurename=fullfile(folder,'BundlingResultsByTime.pdf');
  saveas(fig1,figurename);
  close(fig1);
end
end
