function S=calculateResults(S)
% Calculate Speeds from Molecule paths
%
% Takes the path and data from Molecules and time data from Config and calculates frame-to-frame
% speed along the path.
% 
% If no Molecule data is found, we try to load Molecule information from
% saved files. The saved files are searched in the directory stored in the
% Config property.

if isempty(S.Molecule)
  %try to load Molecules from file
  S.reloadResults('Molecule');
end
if ~isempty(S.Molecule) && ( ~isfield(S.Results, 'Speed') || isempty(S.Results.Speed) )
  numSpeeds=S.Config.LastFrame-1;
  speed=NaN(numSpeeds,length(S.Molecule));
  pathinfo=zeros(length(S.Molecule),1);
  numMol=length(S.Molecule);
  Molecule=S.Molecule;
  parfor n=1:numMol
    frames=Molecule(n).Results(:,1);
    times=Molecule(n).Results(:,2);
    xi=min(frames):max(frames);
    itimes=double(interp1(frames,times,xi))';
    if isempty(Molecule(n).PathData) %if the path was not calculated, we use frame-frame x-y distances
      x=Molecule(n).Results(:,3);
      y=Molecule(n).Results(:,4);
      ix=double(interp1(frames,x,xi))';
      iy=double(interp1(frames,y,xi))';
      idistances=sqrt((ix(1:end-1)-ix(2:end)).^2+(iy(1:end-1)-iy(2:end)).^2);
    else %if the path was calculated, we use the distance along the path
      dist=Molecule(n).PathData(:,3);
      idist=double(interp1(frames,dist,xi))';
      idistances=idist(2:end)-idist(1:end-1);
      [~,pathinfo(n)]=min(Molecule(n).PathData(1:3,5));
    end
    ideltat=itimes(2:end)-itimes(1:end-1);
    xi(end)=[];
    Sp=NaN(numSpeeds,1);
    Sp(xi,1)=idistances./ideltat;
    speed(:,n)=Sp;
  end
  S.Pathinfo=pathinfo;
  S.Results.Speed=speed;
  S.Results.MolIds=1:length(S.Molecule);
  S.saveFiestaCompatibleFile;
end
  function num=robustnumel(arg)
    if isfield(arg, 'length') && ~isempty(arg)
      num=numel(arg.length(1,:));
    else
      num=0;
    end
  end
if ~isempty(S.Objects) && ( ~isfield(S.Results, 'Length') || isempty(S.Results.Length) )
  numFrames=length(S.Objects);
  S.Results.Length=NaN(numFrames,max(cellfun(@robustnumel,S.Objects)));
  for n=1:numFrames
    if isfield(S.Objects{n}, 'length') && ~isempty(S.Objects{n})
      tmpL=S.Objects{n}.length(1,:);
      tmpL(tmpL==0)=[];
      S.Results.Length(n,1:length(tmpL))=tmpL;
    end
  end
end
end
