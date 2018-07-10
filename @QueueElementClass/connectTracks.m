
function Q = connectTracks(Q)
if ~Q.Aborted
  if isempty(Q.Objects)
    %try to load objects from file
    Q.reloadResults('Objects');
  end
  if ~isempty(Q.Objects) && isempty(Q.Molecule)
    if ~isdeployed
      addpath('imageprocessing');
      if Q.Debug>1
        addpath(['imageprocessing' filesep 'debug']);
      end
    end
    [MolTrack,FilTrack]=Q.featureConnect; %#ok<ASGLU>
    nMolTrack=length(MolTrack);
    if nMolTrack>0
      Molecule=struct();
      Molecule(nMolTrack)=struct();
      Molecule=fDefStructure(Molecule,'Molecule');
      %     frequency=ceil(nMolTrack/5);
      %     StackName=Q.Config.StackName;
      %     Directory=Q.Config.Directory;
      %     PixSize=Q.Config.PixSize;
      %     Objects=Q.Objects;
      for n = 1:nMolTrack
        nData=size(MolTrack{n},1);
        Molecule(n).Name = ['Molecule ' num2str(n)];
        Molecule(n).File = Q.Config.StackName;
        Molecule(n).Directory = Q.Config.Directory;
        Molecule(n).Selected = 0;
        Molecule(n).Visible = 1;
        Molecule(n).Drift = 0;
        Molecule(n).PixelSize = Q.Config.PixSize;
        Molecule(n).Color = [0 0 1];
        for j = 1:nData
          f = MolTrack{n}(j,1);
          m = MolTrack{n}(j,2);
          Molecule(n).Results(j,1) = single(f);
          Molecule(n).Results(j,2) = Q.Objects{f}.time;
          Molecule(n).Results(j,3) = Q.Objects{f}.center_x(m);
          Molecule(n).Results(j,4) = Q.Objects{f}.center_y(m);
          Molecule(n).Results(j,5) = single(norm([Molecule(n).Results(j,3)-Molecule(n).Results(1,3) Molecule(n).Results(j,4)-Molecule(n).Results(1,4)]));
          Molecule(n).Results(j,6) = Q.Objects{f}.width(1,m);
          Molecule(n).Results(j,7) = Q.Objects{f}.height(1,m);
          Molecule(n).Results(j,8) = 0;
          Molecule(n).Type = 'symmetric';
        end
      end
      Q.Molecule=Molecule;
    else
      Q.Molecule=[];
      Q.Molecule=fDefStructure(Q.Molecule,'Molecule');
    end
    Q.Filament=[];
    Q.Filament=fDefStructure(Q.Filament,'Filament'); %#ok<*NASGU>
    %clean up
    if ~isdeployed
      rmpath('imageprocessing');
      if Q.Debug>1
        rmpath(['imageprocessing' filesep 'debug']);
      end
    end
    Q.saveFiestaCompatibleFile;
  end
end
end
