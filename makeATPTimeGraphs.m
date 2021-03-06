function makeATPTimeGraphs(Folder)
if nargin <1
  Folder='/Users/korten/Documents/Doktorarbeit/Daten-temp/Elena/flowcell vs wells/';
end
File=fullfile(Folder,'summary2.mat');
CommonArgs={'binInterval',0.17,'FontSize',12,'XLim',[-0.1 3.9],...
  'SpeedLim',[0 1150]};
if exist(File,'file')==2
  load(File);
else
  error(['file not found: ' File]);
end
makePlotSetFigure(atp_dates,atp_speeds,atp_lengths,num2cell(atp_numMTs),...
    Folder,'Bundling',atp_bundling,...
    'NumLim',[0 280],'BundlingLim',[0 0.09],...
    'FileName','wells',CommonArgs{:});
makePlotSetFigure(flowcell_acquisitionDates(1:81),...
  flowcell_allSpeeds(1:81),flowcell_allLengths(1:81),...
  num2cell(flowcell_numMTs(1:81)),...
    Folder,'Bundling',flowcell_AllBundling(1:81),...
    'NumLim',[0 44],'BundlingLim',[0 0.009],...
    'FileName','flowcell',CommonArgs{:});
