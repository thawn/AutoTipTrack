function Stats=makeSeparateInhibitorGraphs(Folder,varargin)
Files=dir(fullfile(Folder,['*' filesep]));
if isempty(varargin)
  CommonArgs={'binInterval',10,'xLabel','Concentration (µM)',...
    'XLim',[-20 620],'FontSize',12};
else
  CommonArgs=varargin;
end
EvaluateBundling=false;
c=1;
for n=1:length(Files)
  isDot=strcmp(Files(n).name,{'.','..','.git','eval','ignore','eval_old','done','names'});
  if Files(n).isdir && ~any(isDot)
    if exist(fullfile(Folder,Files(n).name,'Dilution_series_summary.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'Dilution_series_summary.mat'),'concentrations','allSpeeds','allLengths','numMTs','labels');
    elseif exist(fullfile(Folder,Files(n).name,'summary2.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary2.mat'),'concentrations','allSpeeds','allLengths','numMTs','labels','AllBundling');
      EvaluateBundling=true;
    elseif exist(fullfile(Folder,Files(n).name,'summary1.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary1.mat'),'concentrations','allSpeeds','allLengths','numMTs','labels');
    elseif exist(fullfile(Folder,Files(n).name,'summary.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary.mat'),'allSpeeds','allLengths','numMTs','labels','acquisitionDates');
      ConcCsvFile=fullfile(Folder,Files(n).name,'concentrations.csv');
      if exist(ConcCsvFile, 'file') == 2
        Summary.concentrations=load(ConcCsvFile);
      else
        Summary.concentrations=Summary.acquisitionDates;
      end
    elseif exist(fullfile(Folder,Files(n).name,'Speed_summary.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'Speed_summary.mat'),'allSpeeds','allLengths','numMTs','labels','acquisitionDates');
      ConcCsvFile=fullfile(Folder,Files(n).name,'concentrations.csv');
      if exist(ConcCsvFile, 'file') == 2
        Summary.concentrations=load(ConcCsvFile);
      else
        Summary.concentrations=Summary.acquisitionDates;
      end
    else
      error('Could not find speed summary matlab file in %s.',fullfile(Folder,Files(n).name));
    end
    Conc{c}=Summary.concentrations; %#ok<*AGROW>
    Sp{c}=Summary.allSpeeds;
    Len{c}=Summary.allLengths;
    NumMTs{c}=Summary.numMTs;
    if EvaluateBundling
      Bundl{c}=Summary.AllBundling;
    end
    DisplayNames{c}=Files(n).name;
    c=c+1;
  end
end
Control=find(cellfun(@(x) ~isempty(regexpi(x,'Control')),DisplayNames));
if ~isempty(Control)
  [~, BinnedSP]=binData(Conc{Control},Sp{Control},CommonArgs{1:2});
  [~, BinnedLen]=binData(Conc{Control},Len{Control},CommonArgs{1:2});
  [~, BinnedNumMTs]=binData(Conc{Control},num2cell(NumMTs{Control}),CommonArgs{1:2});
  if EvaluateBundling
    [~, BinnedBundl]=binData(Conc{Control},Bundl{Control},CommonArgs{1:2});
  end
end
Stats(c-1)=struct('DisplayName','','Stats',struct());
for n=1:c-1
  if n~=Control
    Conc{n}=[0;Conc{n}];
    Sp{n}=[{BinnedSP(:,1)};Sp{n}];
    Len{n}=[{BinnedLen(:,1)};Len{n}];
    NumMTs{n}=[{BinnedNumMTs(:,1)};num2cell(NumMTs{n})];
  else
    NumMTs{n}=num2cell(NumMTs{n});
  end
  Stats(n).DisplayName=DisplayNames{n};
  if EvaluateBundling
    if n~=Control
      Bundl{n}=[{BinnedBundl(:,1)};Bundl{n}];
    end
    Stats(n).Stats=makePlotSetFigure(Conc{n},Sp{n},Len{n},NumMTs{n},...
      fullfile(Folder,DisplayNames{n}),'Bundling',Bundl{n},...
      CommonArgs{:});
  else
    Stats(n).Stats=makePlotSetFigure(Conc{n},Sp{n},Len{n},NumMTs{n},...
      fullfile(Folder,DisplayNames{n}),...
      CommonArgs{:});
  end
end