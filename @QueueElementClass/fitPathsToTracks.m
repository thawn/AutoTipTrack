function Q=fitPathsToTracks(Q)
%Fit Paths to tracks:
if isempty(Q.Molecule)
  %try to load Molecules from file
  Q.reloadResults('Molecule');
end
if ~isempty(Q.Molecule)
  hasPaths=false;
  for n=1:length(Q.Molecule)
    if ~isempty(Q.Molecule(n).PathData)
      hasPaths=true;
      break;
    end
  end
  %generate paths if desired and necessary
  if Q.Config.Path.Generate && ...
      (~hasPaths || ~strcmp(Q.Config.Path.Status,'Done'))
    Q.generatePaths;
  end
  Q.saveFiestaCompatibleFile;
end
