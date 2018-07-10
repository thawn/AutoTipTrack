function Q=generatePaths(Q)
nPathStats=length(Q.Molecule);
frequency=ceil(nPathStats/10);
StatusFolder=Q.StatusFolder;
Molecule=Q.Molecule;
Method=Q.Config.Path.Method;
%PixSize=Q.Config.PixSize;
MaxVel=Q.Config.ConnectMol.MaxVelocity;
parfor n=1:nPathStats
  trackStatus(StatusFolder,'Calculating Paths','',n-1,nPathStats,frequency)
  if size(Molecule(n).Results,1)>3
    Resnorm=zeros(3,1);
    switch Method
      case 'Average'
        DisRegion=MaxVel;
        [Molecule(n).PathData(:,1),Molecule(n).PathData(:,2),Molecule(n).PathData(:,3),Molecule(n).PathData(:,4)] = QueueElementClass.averagePath(Molecule(n).Results(:,1:4),DisRegion);
      otherwise
        %disp(n);
        [Molecule(n).PathData(:,1),Molecule(n).PathData(:,2),Molecule(n).PathData(:,3),Molecule(n).PathData(:,4),Resnorm] = QueueElementClass.fitPath(Molecule(n).Results(:,1:4));
    end
    if Molecule(n).PathData(1,3)>mean(Molecule(n).PathData(:,3))
      Molecule(n).PathData(:,3)=Molecule(n).PathData(:,3)*-1;
      Molecule(n).PathData(:,4)=Molecule(n).PathData(:,4)*-1;
    end
    Molecule(n).PathData(1:3,5)=Resnorm;
  end
end
Q.Molecule=Molecule;
trackStatus(Q.StatusFolder,'Calculating Paths','',nPathStats,nPathStats,1)
Q.Config.Path.Status='Done'; %once paths are generated, we do not need to do so again
