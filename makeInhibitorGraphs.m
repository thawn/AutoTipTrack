function makeInhibitorGraphs(Folder)
Files=dir(fullfile(Folder,['*' filesep]));
EvaluateBundling=false;
c=1;
for n=1:length(Files)
  isDot=strcmp(Files(n).name,{'.','..','.git','eval','ignore','eval_old','done','names'});
  if Files(n).isdir && ~any(isDot)
    if exist(fullfile(Folder,Files(n).name,'summary2.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary2.mat'),'concentrations','allSpeeds','allLengths','numMTs','labels','AllBundling');
      EvaluateBundling=true;
    elseif exist(fullfile(Folder,Files(n).name,'summary1.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary1.mat'),'concentrations','allSpeeds','allLengths','numMTs','labels');
    elseif exist(fullfile(Folder,Files(n).name,'summary.mat'),'file')==2
      Summary=load(fullfile(Folder,Files(n).name,'summary.mat'),'allSpeeds','allLengths','numMTs','labels');
      Summary.concentrations=load(fullfile(Folder,Files(n).name,'concentrations.csv'));
    else
      Summary=load(fullfile(Folder,Files(n).name,'Speed_summary.mat'),'allSpeeds','allLengths','numMTs','labels');
      Summary.concentrations=load(fullfile(Folder,Files(n).name,'concentrations.csv'));
    end
    Conc{c}=Summary.concentrations; %#ok<*AGROW>
    Sp{c}=Summary.allSpeeds;
    Len{c}=Summary.allLengths;
    numMTs{c}=Summary.numMTs;
    if isfield(Summary, 'AllBundling')
      Bundl{c}=Summary.AllBundling;
    end
    DisplayNames{c}=Files(n).name;
    c=c+1;
  end
end
ConcSp=reshape([Conc; Sp],[],1);
ConcLen=reshape([Conc; Len],[],1);
ConcMT=reshape([Conc; numMTs],[],1);
[~,minN,maxN,numN,binnedYs]=makeManyPlots(ConcSp{:},'displayNames',DisplayNames,'HeightScale',0.8,'plotType','medianIQR','binInterval',0.05,'XLabel','concentration (然)','XLim',[-20 1150],'SaveName',fullfile(Folder,'velocity.pdf'));
[~,minN,maxN,numN,binnedYs]=makeManyPlots(ConcLen{:},'displayNames',DisplayNames,'HeightScale',0.8,'plotType','medianIQR','binInterval',0.05,'XLabel','concentration (然)','XLim',[-20 1150],'YLabel','microtubule length (痠)','YScale',0.001,'SaveName',fullfile(Folder,'Len.pdf'));
[~,minN,maxN,numN,binnedYs]=makeManyPlots(ConcMT{:},'displayNames',DisplayNames,'HeightScale',0.8,'plotType','medianIQR','binInterval',0.05,'XLabel','concentration (然)','XLim',[-20 1150],'YLim',[0 250],'YLabel','number of microtubules','SaveName',fullfile(Folder,'numMTs.pdf'));
[~,minN,maxN,numN,binnedYs]=makeManyPlots(ConcLen{:},'displayNames',DisplayNames,'HeightScale',0.8,'plotType','prctile5','binInterval',0.05,'XLabel','concentration (然)','XLim',[-20 1150],'YLabel','microtubule length (痠)','YScale',0.001,'SaveName',fullfile(Folder,'5th_Len.pdf'));
if EvaluateBundling
  ConcBundl=reshape([Conc; Bundl],[],1);
  [~,minN,maxN,numN,binnedYs]=makeManyPlots(ConcBundl{:},'displayNames',DisplayNames,'HeightScale',0.8,'plotType','medianIQR','binInterval',0.05,'XLabel','concentration (然)','XLim',[-20 1150],'YLabel','%bundles','SaveName',fullfile(Folder,'Bundling.pdf'));
end
