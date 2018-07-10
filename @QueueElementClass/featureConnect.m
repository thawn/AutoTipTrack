function [MolTrack,FilTrack]=featureConnect(Q)

Mol=[];
Fil=[];

MolTrack=[];
FilTrack=[];

StartFrame=Q.Config.FirstCFrame;
EndFrame=Q.Config.LastFrame;
if ~isempty(Q.Objects)
  EndFrame=min([EndFrame length(Q.Objects)]);
end

if StartFrame==0
  nObj=Q.Config.FirstTFrame;
  lObjects=Q.Objects{nObj}.length(1,:);
  pMol=1;
%  pFil=1;
  for n=1:length(lObjects)
      MolTrack{pMol}(1)=nObj; %#ok<*AGROW>
      MolTrack{pMol}(2)=n;
      pMol=pMol+1;
%     if lObjects(n)==0
%       MolTrack{pMol}(1)=nObj; %#ok<*AGROW>
%       MolTrack{pMol}(2)=n;
%       pMol=pMol+1;
%     else
%       FilTrack{pFil}(1)=nObj;
%       FilTrack{pFil}(2)=n;
%       pFil=pFil+1;
%     end
  end
  EndFrame=-1;
else
  StartFrame=1;
end

Data = cell(1,EndFrame-StartFrame+1);
NumObj = cellfun(@objectNumber,Q.Objects);
RmaxProblem = [0 checkRmax(NumObj,Q.Config) 0];
numF=(EndFrame+1)-StartFrame+1;
for k=StartFrame:EndFrame+1
  trackStatus(Q.StatusFolder,'Connecting Tracks','',k-StartFrame,numF,1);
  if k<=EndFrame
    if isempty(Q.Objects{k})
      Mol(k,:)=0;
      Fil(k,:)=0;
      Data{k}=[];
    else
      lObjects = Q.Objects{k}.length(1,:);
      nObj = length(lObjects);
      if k==StartFrame
        Mol(k,1:nObj)=-Inf;
        Fil(k,nObj)=0;
      else
        Mol(k,1:nObj)=Inf;
        Fil(k,nObj)=0;
      end
      Data{k}=zeros(nObj,5);
      Data{k}(:,1)=k;
      Data{k}(:,2)=Q.Objects{k}.time*ones(nObj,1);
      Data{k}(:,3)=Q.Objects{k}.center_x';
      Data{k}(:,4)=Q.Objects{k}.center_y';
      int=Q.Objects{k}.height(1,:)';
      len=Q.Objects{k}.length(1,:)';
      if ~isempty(abs(Mol(k,:))==Inf)
        Data{k}(abs(Mol(k,:))==Inf,5)=int(abs(Mol(k,:))==Inf);
      end
      if ~isempty(abs(Fil(k,:))==Inf)
        Data{k}(abs(Fil(k,:))==Inf,5)=len(abs(Fil(k,:))==Inf);
      end
    end
  end
  if k>StartFrame+2 && ~RmaxProblem(k) && ~RmaxProblem(k - 1) && ~RmaxProblem(k - 2)
    Q.Config.Connect=Q.Config.ConnectMol;
    [MolTrack,Mol]=ConnectTrack(Data,MolTrack,Mol,k-2,Q.Config);
    
    Q.Config.Connect=Q.Config.ConnectFil;
    [FilTrack,Fil]=ConnectTrack(Data,FilTrack,Fil,k-2,Q.Config);
  elseif RmaxProblem(k)
    warning('The number of objects within the search radius is too large. Did not connect tracks for frame %d and the two following frames. Try reducing the value for maximum velocity or increasing the frame rate of imaging.',k);
  end
end
trackStatus(Q.StatusFolder,'Connecting Tracks','',numF,numF,1);
Mol=abs(Mol);
Fil=abs(Fil);

%postprocessing
numF=(EndFrame-1)-(StartFrame+1)+1;
for k=StartFrame+1:EndFrame-1
  trackStatus(Q.StatusFolder,'Postprocessing','',k-(StartFrame+1),numF,1);
  if ~isempty(MolTrack)
    Q.Config.Connect=Q.Config.ConnectMol;
    [MolTrack,Mol]=ProcessTrack(MolTrack,Mol,k,Q.Config);
  end
  if ~isempty(FilTrack)
    Q.Config.Connect=Q.Config.ConnectFil;
    [FilTrack,Fil]=ProcessTrack(FilTrack,Fil,k,Q.Config);
  end
end
trackStatus(Q.StatusFolder,'Postprocessing','',numF,numF,1);
if EndFrame>0
  for i=length(MolTrack):-1:1
    if size(MolTrack{i},1)<Q.Config.ConnectMol.MinLength
      MolTrack(i)=[];
    end
  end
  for i=length(FilTrack):-1:1
    if size(FilTrack{i},1)<Q.Config.ConnectFil.MinLength
      FilTrack(i)=[];
    end
  end
end


function [Track,Obj]=ConnectTrack(Data,Track,Obj,k,Config)
Obj(k:k+1,:)=abs(Obj(k:k+1,:));
for i=1:size(Obj,2)
  current=find(Obj(k,:)>0,1);
  if isempty(current)
    break
  end
  %find all possible quintuples for current object
  quadruples=FindQuadruples(Data,Obj,k,Config,current);
  
  if ~isempty(quadruples)
    
    %compute and find best cost for all quadruples
    quadruple=ComputeCost(quadruples,Data,Track,Obj,k,Config);
    
    %choose best out of all possible quadruples
    best=0;
    for j=1:4
      if quadruple(j)~=0
        best(j)=Obj(k-2+j,quadruple(j));
      else
        best(j)=0;
      end
    end
    
    quad=quadruple;
    lastT=[];
    lastX=[];
    lastY=[];
    mIntLen=[];
    if ~isinf(best(1))&&isinf(best(2)) && isinf(best(3)) && isinf(best(4))
      
      %if second, third and forth point not in track mark point as
      %used for next frame
      Obj(k,quad(2))=-Inf;
      Obj(k+1,quad(3))=-Inf;
      if isinf(best(4))
        Obj(k+2,quad(4))=-Inf;
      end
      
    elseif isinf(best(1)) && isinf(best(2)) && ~isinf(best(3))
      
      %if no point in third or forth colum, connect the 2 frames to track and close track
      
      %get X,Y, time and intensity/length values from best quadruple
      T=[Data{k-1}(quad(1),2) Data{k}(quad(2),2)];
      X=[Data{k-1}(quad(1),3) Data{k}(quad(2),3)];
      Y=[Data{k-1}(quad(1),4) Data{k}(quad(2),4)];
      IntLen=[Data{k-1}(quad(1),5) Data{k}(quad(2),5)];
      
      %calculate track history
      nTrack=length(T);
      lastT(1:2)=T(nTrack)+mean((T(1:nTrack-1)-T(nTrack))./(nTrack-1:-1:1));
      lastX(1:2)=X(nTrack)+mean((X(1:nTrack-1)-X(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      lastY(1:2)=Y(nTrack)+mean((Y(1:nTrack-1)-Y(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      mIntLen(1:2)=mean(IntLen);
      
      %open new track
      Track{length(Track)+1}=[(k-1:k)' quad(1:2)' T' X' Y' IntLen' lastT' lastX' lastY' mIntLen'];
      
      %mark objects from best quadruple as used
      Obj(k-1,quad(1))=-length(Track);
      Obj(k,quad(2))=-length(Track);
      
    elseif isinf(best(1))&&isinf(best(2))
      
      %if first three or four points not in track, start new track with 3 points
      
      %get X,Y, time and intensity/length values from best quadruple
      T=[Data{k-1}(quad(1),2) Data{k}(quad(2),2) Data{k+1}(quad(3),2)];
      X=[Data{k-1}(quad(1),3) Data{k}(quad(2),3) Data{k+1}(quad(3),3)];
      Y=[Data{k-1}(quad(1),4) Data{k}(quad(2),4) Data{k+1}(quad(3),4)];
      IntLen=[Data{k-1}(quad(1),5) Data{k}(quad(2),5) Data{k+1}(quad(3),5)];
      
      %calculate track history
      nTrack=length(T);
      lastT(1:3)=T(nTrack)+mean((T(1:nTrack-1)-T(nTrack))./(nTrack-1:-1:1));
      lastX(1:3)=X(nTrack)+mean((X(1:nTrack-1)-X(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      lastY(1:3)=Y(nTrack)+mean((Y(1:nTrack-1)-Y(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      mIntLen(1:3)=mean(IntLen);
      
      %open new track
      Track{length(Track)+1}=[(k-1:k+1)' quad(1:3)' T' X' Y' IntLen' lastT' lastX' lastY' mIntLen'];
      
      %mark objects from best quintuple as used
      Obj(k-1,quad(1))=-length(Track);
      Obj(k,quad(2))=-length(Track);
      Obj(k+1,quad(3))=length(Track);
      
    elseif ~isinf(best(2)) && best(3)>0
      
      %if point belongs to track add next point to track
      
      nTrack=best(2);
      %get X,Y, time and intensity/length values from best quintuple
      T=Data{k+1}(quad(3),2);
      X=Data{k+1}(quad(3),3);
      Y=Data{k+1}(quad(3),4);
      IntLen=Data{k+1}(quad(3),5);
      
      %calculate track history
      nData=size(Track{nTrack},1);
      lastT=T+mean((Track{nTrack}(:,3)-T)./(nData:-1:1)');
      lastX=X+mean((Track{nTrack}(:,4)-X)./(Track{nTrack}(:,4)-T));
      lastY=Y+mean((Track{nTrack}(:,5)-Y)./(Track{nTrack}(:,4)-T));
      mIntLen=mean([Track{nTrack}(:,6);IntLen]);
      
      %add to track
      Track{nTrack}=[Track{nTrack}; (k+1) quad(3) T' X' Y' IntLen' lastT' lastX' lastY' mIntLen'];
      
      %mark objects from best quintuple as used
      Obj(k,quad(2))=-nTrack;
      Obj(k+1,quad(3))=nTrack;
      
    elseif k==Config.LastFrame-1 && best(3)>0
      
      %get X,Y, time and intensity/length values from best quadruple
      T=[Data{k}(quad(2),2) Data{k+1}(quad(3),2)];
      X=[Data{k}(quad(2),3) Data{k+1}(quad(3),3)];
      Y=[Data{k}(quad(2),4) Data{k+1}(quad(3),4)];
      IntLen=[Data{k}(quad(2),5) Data{k+1}(quad(3),5)];
      
      %calculate track history
      nTrack=length(T);
      lastT(1:2)=T(nTrack)+mean((T(1:nTrack-1)-T(nTrack))./(nTrack-1:-1:1));
      lastX(1:2)=X(nTrack)+mean((X(1:nTrack-1)-X(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      lastY(1:2)=Y(nTrack)+mean((Y(1:nTrack-1)-Y(nTrack))./(T(nTrack)-T(1:nTrack-1)));
      mIntLen(1:2)=mean(IntLen);
      
      %open new track
      Track{length(Track)+1}=[(k:k+1)' quad(2:3)' T' X' Y' IntLen' lastT' lastX' lastY' mIntLen'];
      
      %mark objects from best quadruple as used
      Obj(k,quad(2))=-length(Track);
      Obj(k+1,quad(3))=-length(Track);
    else
      if isinf(Obj(k,current))
        Obj(k,current)=-Inf;
      else
        Obj(k,current)=-Obj(k,current);
      end
    end
  else
    if isinf(Obj(k,current))
      Obj(k,current)=-Inf;
    else
      Obj(k,current)=-Obj(k,current);
    end
  end
end

function quadruples=FindQuadruples(Data,Obj,k,Config,current)
f2=current;
for n=1:Config.Connect.NumberVerification
  f3=[];
  for i=1:length(f2)
    %look for points in F3 that satisfy speed restriction
    temp3=FindWithinNext(Data,k,Obj,Config,f2(i));
    for j=length(temp3):-1:1
      if ~isempty(find(temp3(j)==f3,1))
        temp3(j)=[];
      end
    end
    f3=[f3;temp3];
  end
  
  f4=[];
  for i=1:length(f3)
    
    %look for points in F4 for every point in F3 that satisfy speed restriction
    temp4=FindWithinNext(Data,k+1,Obj,Config,f3(i));
    
    %sort out already found points
    for j=length(temp4):-1:1
      if ~isempty(find(temp4(j)==f4,1))
        temp4(j)=[];
      end
    end
    f4=[f4;temp4];
    
  end
  
  if ~isempty(f4)
    f3=[];
    for i=1:length(f4)
      
      %look for points in F3 for every point in F4 that satisfy speed restriction
      temp3=FindWithinPrev(Data,k+2,Obj,Config,f4(i),0);
      
      %sort out already found points
      for j=length(temp3):-1:1
        if ~isempty(find(temp3(j)==f3,1))
          temp3(j)=[];
        end
      end
      f3=[f3;temp3];
    end
  end
  
  if ~isempty(f3)
    f2=[];
    if isempty(f4)
      f3(Obj(k+1,f3)~=Inf)=[];
    end
    for i=1:length(f3)
      
      %look for points in F2 for every point in F3 that satisfy speed restriction
      temp2=FindWithinPrev(Data,k+1,Obj,Config,f3(i),1);
      
      %sort out already found points
      for j=length(temp2):-1:1
        if ~isempty(find(temp2(j)==f2,1))
          temp2(j)=[];
        end
      end
      f2=[f2;temp2];
      
    end
    if isempty(f2)
      f2=current;
    end
  else
    f1=[];
    for i=1:length(f2)
      
      %look for points in F1 for every point in F2 that satisfy speed restriction
      temp1=FindWithinPrev(Data,k,Obj,Config,f2(i),0);
      
      %sort out already found points
      for j=length(temp1):-1:1
        if ~isempty(find(temp1(j)==f1,1))
          temp1(j)=[];
        end
      end
      f1=[f1;temp1];
    end
    if ~isempty(f1)
      f2=[];
      for i=1:length(f1)
        %look for points in F3 that satisfy speed restriction
        temp2=FindWithinNext(Data,k-1,Obj,Config,f1(i));
        for j=length(temp2):-1:1
          if ~isempty(find(temp2(j)==f2,1))
            temp2(j)=[];
          end
        end
        f2=[f2;temp2];
      end
    end
  end
end
%create quadruple
if isempty(f4)
  quad3=zeros(size(f3,1),2);
  if ~isempty(f3)
    quad3(:,1)=f3;
  end
  quad3(:,2)=0;
else
  quad4=f4;
  quad3=[];
  %go backwards for all points in F3
  for i=1:length(quad4)
    temp3=FindWithinPrev(Data,k+2,Obj,Config,quad4(i),0);
    if ~isempty(temp3)
      addquad=zeros(size(temp3,1),2);
      addquad(:,1)=temp3;
      addquad(:,2)=quad4(i);
      quad3=[quad3;addquad];
    end
  end
end
if isempty(f3)
  quad2=zeros(size(f2,1),2);
  quad2(:,1)=f2;
  quad2(:,2)=0;
  quad2(:,3)=0;
else
  quad2=[];
  %go backwards for all points in F2
  for i=1:size(quad3,1)
    temp2=FindWithinPrev(Data,k+1,Obj,Config,quad3(i,1),1);
    if ~isempty(temp2)
      addquad=zeros(size(temp2,1),3);
      addquad(:,1)=temp2;
      for j=1:size(temp2,1)
        addquad(j,2:3)=quad3(i,1:2);
      end
      quad2=[quad2;addquad];
    end
  end
end
quad1=[];
%go backwards for all points in F1
for i=1:size(quad2,1)
  if isinf(Obj(k,quad2(i,1)))
    temp1=FindWithinPrev(Data,k,Obj,Config,quad2(i,1),0);
    if ~isempty(temp1)
      addquad=zeros(size(temp1,1),4);
      addquad(:,1)=temp1;
      for j=1:size(temp1,1)
        addquad(j,2:4)=quad2(i,1:3);
      end
      quad1=[quad1;addquad];
    else
      addquad=zeros(1,4);
      addquad(:,1)=0;
      addquad(:,2:4)=quad2(i,1:3);
      quad1=[quad1;addquad];
    end
  else
    addquad=zeros(1,4);
    addquad(:,1)=0;
    addquad(:,2:4)=quad2(i,1:3);
    quad1=[quad1;addquad];
  end
end
if size(quad1,1)==1 && (quad1(1,1)==0 && quad1(1,3)==0 && quad1(1,4)==0)
  quadruples=[];
else
  quadruples=quad1;
end

function [CostPos,CostDir,CostSpeed,CostIntLen]=CostFunc(StartTrack,EndTrack,Config)
CostPos=0;
CostDir=0;
CostSpeed=0;
CostIntLen=0;
nEndTrack=size(StartTrack,1);
nStartTrack=size(EndTrack,1);

c1=fix((EndTrack(1,1)-StartTrack(nEndTrack,1))/2)-1;
c2=fix((EndTrack(1,1)-StartTrack(nEndTrack,1))/2);
c3=ceil((EndTrack(1,1)-StartTrack(nEndTrack,1))/2)-1;
c4=ceil((EndTrack(1,1)-StartTrack(nEndTrack,1))/2)-2;

I=StartTrack(:,1);
T=StartTrack(:,3);
X=StartTrack(:,4);
Y=StartTrack(:,5);

t(1)=T(nEndTrack)-c1*mean((T(1:nEndTrack-1)-T(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1)));
x1=[X(nEndTrack)-c1*mean((X(1:nEndTrack-1)-X(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1))) Y(nEndTrack)-c1*mean((Y(1:nEndTrack-1)-Y(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1)))];
n1=mean(StartTrack(:,6));

t(2)=T(nEndTrack)-c2*mean((T(1:nEndTrack-1)-T(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1)));
x2=[X(nEndTrack)-c2*mean((X(1:nEndTrack-1)-X(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1))) Y(nEndTrack)-c2*mean((Y(1:nEndTrack-1)-Y(nEndTrack))./(I(nEndTrack)-I(1:nEndTrack-1)))];
n2=mean(StartTrack(:,6));


I=EndTrack(:,1);
T=EndTrack(:,3);
X=EndTrack(:,4);
Y=EndTrack(:,5);

t(3)=T(1)-c3*mean((T(2:nStartTrack)-T(1))./(I(2:nStartTrack)-I(1)));
x3=[X(1)-c3*mean((X(2:nStartTrack)-X(1))./(I(2:nStartTrack)-I(1))) Y(1)-c3*mean((Y(2:nStartTrack)-Y(1))./(I(2:nStartTrack)-I(1)))];
n3=mean(EndTrack(:,6));

t(4)=T(1)-c4*mean((T(2:nStartTrack)-T(1))./(I(2:nStartTrack)-I(1)));
x4=[X(1)-c4*mean((X(2:nStartTrack)-X(1))./(I(2:nStartTrack)-I(1))) Y(1)-c4*mean((Y(2:nStartTrack)-Y(1))./(I(2:nStartTrack)-I(1)))];
n4=mean(EndTrack(:,6));

if Config.Connect.Position>0
  CostPos=PositionArea(x1,x2,x3,x4);
end
if Config.Connect.Direction>0
  CostDir=DirectionArea(x1,x2,x3,x4);
  if abs(acosd(dot(x2-x1,x4-x3)/(norm(x2-x1)*norm(x4-x3))))>Config.Connect.MaxAngle
    if norm(x2-x3)>Config.PixSize
      CostDir=NaN;
    end
  end
end
if Config.Connect.Speed>0
  CostSpeed=SpeedArea(x1,x2,x3,x4,t);
  if (norm(x1-x2)+norm(x2-x3)+norm(x3-x4))/(t(4)-t(1))>Config.Connect.MaxVelocity
    CostSpeed=NaN;
  end
end
if Config.Connect.IntensityOrLength>0
  CostIntLen=IntLenArea(n1,n2,n3,n4);
end

function [Track,Obj]=ProcessTrack(Track,Obj,k,Config)
while ~isempty(find(Obj(k,:)>0 & Obj(k,:)~=Inf,1))
  current=find(Obj(k,:)>0 & Obj(k,:)~=Inf,1);
  %check if track end in frame k
  if isempty(find(Obj(k+1,:)==Obj(k,current),1))
    %find 2 tracks that could fit together
    pairs=FindTracks(Track,Obj,k,Config,Obj(k,current));
    if ~isempty(pairs)
      CostPos=zeros(size(pairs,1),1);
      CostDir=zeros(size(pairs,1),1);
      CostSpeed=zeros(size(pairs,1),1);
      CostIntLen=zeros(size(pairs,1),1);
      for j=1:size(pairs,1)
        [CostPos(j),CostDir(j),CostSpeed(j),CostIntLen(j)]=CostFunc(Track{pairs(j,1)},Track{pairs(j,2)},Config);
      end
      if max(CostPos)>0
        CostPos=CostPos/max(CostPos);
      end
      if max(CostDir)>0
        CostDir=CostDir/max(CostDir);
      end
      if max(CostSpeed)>0
        CostSpeed=CostSpeed/max(CostSpeed);
      end
      if max(CostIntLen)>0
        CostIntLen=CostIntLen/max(CostIntLen);
      end
      Cost=CostPos*Config.Connect.Position+CostDir*Config.Connect.Direction+CostSpeed*Config.Connect.Speed+CostIntLen*Config.Connect.IntensityOrLength;
      pairs=[pairs Cost];
      pairs=sortrows(pairs,3);
      if ~isnan(pairs(1,3))
        %                check if there is a possible track inbetween the twotracks
        if size(pairs,1)>1
          best=CheckPairs(Track,pairs,Config);
        else
          best=pairs(1,:);
        end
        Obj(abs(Obj)==best(1,1))=-best(1,1); %set all frames to negative number of track
        Obj(abs(Obj)==best(1,2))=-best(1,1); %set all frames to negative number of track
        Obj(Track{best(1,1)}(1,1),Track{best(1,1)}(1,2))=best(1,1); %set first frame to positive number of track
        nStartTrack=size(Track{best(1,2)},1);
        Obj(Track{best(1,2)}(nStartTrack,1),Track{best(1,2)}(nStartTrack,2))=best(1,1); %set last frame to positive number of track
        Track{best(1,1)}=[Track{best(1,1)};Track{best(1,2)}];
        Track{best(1,2)}=[];
      else
        Obj(k,current)=-Obj(k,current);
      end
    else
      Obj(k,current)=-Obj(k,current);
    end
  else
    Obj(k,current)=-Obj(k,current);
  end
end

function best=CheckPairs(Track,pairs,Config)
best=pairs(1,:);
col1=pairs(:,1);
col2=pairs(:,2);
first=col1(1);
last=col2(1);
between=first;
while last~=between
  between=last;
  p1=col1==first;
  p2=col2==last;
  t1=col2.*p1;
  t2=col1.*p2;
  t1(t1==0)=NaN;
  t2(t2==0)=NaN;
  k1=ismember(t1,t2);
  k2=ismember(t2,t1);
  s1=p1&k1;
  s2=p2&k2;
  k=ismember(col1(s2),col2(s1));
  temp=ones(sum(k),1)*first;
  temp=[temp col1(s2)];
  if ~isempty(temp)
    n=size(temp,1);
    if n>1
      CostPos=zeros(n,1);
      CostDir=zeros(n,1);
      CostSpeed=zeros(n,1);
      CostIntLen=zeros(n,1);
      for k=1:size(temp,1)
        [CostPos(k,1),CostDir(k,1),CostSpeed(k,1),CostIntLen(k,1)]=CostFunc([Track{temp(k,1)};Track{temp(k,2)}] ,Track{last},Config);
      end
      if max(CostPos)>0
        CostPos=CostPos/max(CostPos);
      end
      if max(CostDir)>0
        CostDir=CostDir/max(CostDir);
      end
      if max(CostSpeed)>0
        CostSpeed=CostSpeed/max(CostSpeed);
      end
      if max(CostIntLen)>0
        CostIntLen=CostIntLen/max(CostIntLen);
      end
      Cost=CostPos*Config.Connect.Position+CostDir*Config.Connect.Direction+CostSpeed*Config.Connect.Speed+CostIntLen*Config.Connect.IntensityOrLength;
      temp=[temp Cost];
      temp=sortrows(temp,3);
      last=temp(1,2);
    end
    best=temp(1,:);
  end
end



function pairs=FindTracks(Track,Obj,k,Config,idx)
pairs=[];
End_Track{1}=idx;
for n=1:Config.Connect.NumberVerification
  Start_Track=[];
  for m=1:length(End_Track)
    first=k+m;
    last=min([k+m+Config.Connect.MaxBreak Config.LastFrame-1 size(Obj,1)]);
    for i=first:last
      for b=1:size(Obj,2)
        if Obj(i,b)>0&&Obj(i,b)~=Inf
          if ~isempty(find(abs(Obj(i+1,:))==Obj(i,b),1))&&isempty(find(abs(Obj(i-1,:))==Obj(i,b),1));
            for j=1:length(End_Track{m})
              nEndTrack=size(Track{End_Track{m}(j)},1);
              tEndTrack=Track{End_Track{m}(j)}(nEndTrack-1,3);
              tStartTrack=Track{Obj(i,b)}(2,3);
              x1=[Track{End_Track{m}(j)}(nEndTrack-1,4) Track{End_Track{m}(j)}(nEndTrack-1,5)];
              x2=[Track{End_Track{m}(j)}(nEndTrack,4) Track{End_Track{m}(j)}(nEndTrack,5)];
              x3=[Track{Obj(i,b)}(1,4) Track{Obj(i,b)}(1,5)];
              x4=[Track{Obj(i,b)}(2,4) Track{Obj(i,b)}(2,5)];
              rmax=Config.Connect.MaxVelocity*(tStartTrack-tEndTrack);
              if norm(x1-x2)+norm(x2-x3)+norm(x3-x4)<max([rmax Config.PixSize])
                try
                  if isempty(find(Obj(i,b)==Start_Track{i-k+1},1))
                    Start_Track{i-k+1}=[Start_Track{i-k+1};Obj(i,b)];
                  end
                catch
                  Start_Track{i-k+1}=Obj(i,b);
                end
              end
            end
          end
        end
      end
    end
  end
  End_Track=[];
  for m=2:length(Start_Track)
    first=k;
    last=k+m-2;
    for i=first:last
      for b=1:size(Obj,2)
        if Obj(i,b)>0&&Obj(i,b)~=Inf
          if ~isempty(find(abs(Obj(i-1,:))==Obj(i,b),1))&&isempty(find(abs(Obj(i+1,:))==Obj(i,b),1));
            for j=1:length(Start_Track{m})
              nEndTrack=size(Track{Obj(i,b)},1);
              tEndTrack=Track{Obj(i,b)}(nEndTrack-1,3);
              tStartTrack=Track{Start_Track{m}(j)}(2,3);
              x1=[Track{Obj(i,b)}(nEndTrack-1,4) Track{Obj(i,b)}(nEndTrack-1,5)];
              x2=[Track{Obj(i,b)}(nEndTrack,4) Track{Obj(i,b)}(nEndTrack,5)];
              x3=[Track{Start_Track{m}(j)}(1,4) Track{Start_Track{m}(j)}(1,5)];
              x4=[Track{Start_Track{m}(j)}(2,4) Track{Start_Track{m}(j)}(2,5)];
              rmax=Config.Connect.MaxVelocity*(tStartTrack-tEndTrack);
              if norm(x1-x2)+norm(x2-x3)+norm(x3-x4)<max([rmax Config.PixSize])
                try
                  if isempty(find(Obj(i,b)==End_Track{i-k+1},1))
                    End_Track{i-k+1}=[End_Track{i-k+1};Obj(i,b)];
                  end
                catch
                  End_Track{i-k+1}=Obj(i,b);
                end
                if n==Config.Connect.NumberVerification
                  if m-(i-k+1)<Config.Connect.MaxBreak && Obj(i,b)~=Start_Track{m}(j)
                    pairs=[pairs;Obj(i,b) Start_Track{m}(j)];
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

function quadruple=ComputeCost(quad,Data,Track,Obj,k,Config)
CostPos=zeros(size(quad,1),1);
CostDir=zeros(size(quad,1),1);
CostSpeed=zeros(size(quad,1),1);
CostIntLen=zeros(size(quad,1),1);
for i=1:size(quad,1)
  t=[];
  x2=[Data{k}(quad(i,2),3) Data{k}(quad(i,2),4)];
  n2=Data{k}(quad(i,2),5);
  t(2)=Data{k}(quad(i,2),2);
  if quad(i,1)==0
    nTrack=Obj(k,quad(i,2));
    if ~isinf(nTrack)
      nData=size(Track{nTrack},1);
      x1=[Track{nTrack}(nData,8) Track{nTrack}(nData,9)];
      n1=Track{nTrack}(nData,10);
      t(1)=Track{nTrack}(nData,7);
    else
      x1=[];
      n1=[];
    end
  else
        nTrack=abs(Obj(k-1,quad(i,1)));
        if ~isinf(nTrack)    
            nData=size(Track{nTrack},1);
            x1=[Track{nTrack}(nData,8) Track{nTrack}(nData,9)];
            n1=Track{nTrack}(nData,10);
            t(1)=Track{nTrack}(nData,7);
        else
            x1=[Data{k-1}(quad(i,1),3) Data{k-1}(quad(i,1),4)];
            n1=Data{k-1}(quad(i,1),5);
            t(1)=Data{k-1}(quad(i,1),2);
        end
  end
  if quad(i,3)==0
    x3=[];
    n3=[];
  else
    x3=[Data{k+1}(quad(i,3),3) Data{k+1}(quad(i,3),4)];
    n3=Data{k+1}(quad(i,3),5);
    t(3)=Data{k+1}(quad(i,3),2);
  end
  if quad(i,4)==0
    x4=[];
    n4=[];
  else
    x4=[Data{k+2}(quad(i,4),3) Data{k+2}(quad(i,4),4)];
    n4=Data{k+2}(quad(i,4),5);
    t(4)=Data{k+2}(quad(i,4),2);
  end
  if isempty(x3)&&isempty(x4)
    if isempty(x1)
      CostPos(i)=NaN;
    else
      CostPos(i)=norm(x2-x1);
    end
    CostDir(i)=NaN;
    CostSpeed(i)=NaN;
    CostIntLen(i)=NaN;
  elseif ~(isempty(x1)&&isempty(x4))
    if Config.Connect.Position>0
      CostPos(i)=PositionArea(x1,x2,x3,x4);
    end
    if Config.Connect.Direction>0
      CostDir(i)=DirectionArea(x1,x2,x3,x4);
    end
    if Config.Connect.Speed>0
      CostSpeed(i)=SpeedArea(x1,x2,x3,x4,t);
    end
    if Config.Connect.IntensityOrLength>0
      CostIntLen(i)=IntLenArea(n1,n2,n3,n4);
    end
  else
    CostPos(i)=norm(x3-x2);
    CostDir(i)=NaN;
    CostSpeed(i)=NaN;
    CostIntLen(i)=NaN;
  end
end
if max(CostPos)>0
  CostPos=CostPos/sum(CostPos(~isnan(CostPos)));
  CostPos=CostPos/max(CostPos);
else
  CostPos=zeros(size(quad,1),1);
end
if max(CostDir)>0
  CostDir=CostDir/sum(CostDir(~isnan(CostDir)));
  CostDir=CostDir/max(CostDir);
else
  CostDir=zeros(size(quad,1),1);
end
if max(CostSpeed)>0
  CostSpeed=CostSpeed/sum(CostSpeed(~isnan(CostSpeed)));
  CostSpeed=CostSpeed/max(CostSpeed);
else
  CostSpeed=zeros(size(quad,1),1);
end
if max(CostIntLen)>0
  CostIntLen=CostIntLen/sum(CostIntLen(~isnan(CostIntLen)));
  CostIntLen=CostIntLen/max(CostIntLen);
else
  CostIntLen=zeros(size(quad,1),1);
end
Cost=CostPos*Config.Connect.Position+CostDir*Config.Connect.Direction+CostSpeed*Config.Connect.Speed+CostIntLen*Config.Connect.IntensityOrLength;
while size(quad,1)>1
  k=find(isnan(Cost),1);
  if isempty(k)
    [~,k]=max(Cost);
  end
  CostPos(k)=[];
  CostDir(k)=[];
  CostSpeed(k)=[];
  CostIntLen(k)=[];
  quad(k,:)=[];
  if max(CostPos)>0
    CostPos=CostPos/sum(CostPos(~isnan(CostPos)));
    CostPos=CostPos/max(CostPos);
  else
    CostPos=zeros(size(quad,1),1);
  end
  if max(CostDir)>0
    CostDir=CostDir/sum(CostDir(~isnan(CostDir)));
    CostDir=CostDir/max(CostDir);
  else
    CostDir=zeros(size(quad,1),1);
  end
  if max(CostSpeed)>0
    CostSpeed=CostSpeed/sum(CostSpeed(~isnan(CostSpeed)));
    CostSpeed=CostSpeed/max(CostSpeed);
  else
    CostSpeed=zeros(size(quad,1),1);
  end
  if max(CostIntLen)>0
    CostIntLen=CostIntLen/sum(CostIntLen(~isnan(CostIntLen)));
    CostIntLen=CostIntLen/max(CostIntLen);
  else
    CostIntLen=zeros(size(quad,1),1);
  end
  Cost=CostPos*Config.Connect.Position+CostDir*Config.Connect.Direction+CostSpeed*Config.Connect.Speed+CostIntLen*Config.Connect.IntensityOrLength;
end
quadruple=[quad Cost];


function N = objectNumber(Object)
if isstruct(Object) && isfield(Object,'data') && ~isempty(Object)
  N = length(Object.data);
else
  N = 0;
end  


function RmaxProblem = checkRmax(NObj,Config)
TotArea = Config.Width * Config.PixSize * Config.Height * Config.PixSize;
MaxArea = (50 ./ NObj) .* TotArea;
MaxRmax = sqrt(MaxArea ./ (2 * pi()));
DeltaT = Config.Times(2:end) - Config.Times(1:end-1);
Rmax = DeltaT .* Config.Connect.MaxVelocity;
MaxRmax = MaxRmax(end-length(Rmax)+1:end);
RmaxProblem = Rmax > MaxRmax;



function inside=FindWithinNext(Data,k,Obj,Config,idx)
t=Data{k}(idx,2);
x=Data{k}(idx,3);
y=Data{k}(idx,4);
try
  unused=find(Obj(k+1,:)==Inf|Obj(k+1,:)>0);
  T=Data{k+1}(unused,2);
  X=Data{k+1}(unused,3);
  Y=Data{k+1}(unused,4);
  rmax=(T-t)*Config.Connect.MaxVelocity;
  rmax(rmax<Config.PixSize)=Config.PixSize;
  temp=sqrt( (X-x).^2 + (Y-y).^2)<rmax;
  inside=unused(temp)';
catch
  inside=[];
end


function inside=FindWithinPrev(Data,k,Obj,Config,idx,mode)
t=Data{k}(idx,2);
x=Data{k}(idx,3);
y=Data{k}(idx,4);
try
  if mode==1
    unused=find(Obj(k-1,:)>0);
  else
    unused=find(isinf(Obj(k-1,:))|Obj(k-1,:)<0);
  end
  T=Data{k-1}(unused,2);
  X=Data{k-1}(unused,3);
  Y=Data{k-1}(unused,4);
  rmax=(t-T)*Config.Connect.MaxVelocity;
  rmax(rmax<Config.PixSize)=Config.PixSize;
  temp=sqrt( (X-x).^2 + (Y-y).^2)<rmax;
  inside=unused(temp)';
catch
  inside=[];
end


function A=PositionArea(x1,x2,x3,x4)
x2=[x2 2];
x3=[x3 3];
if ~isempty(x1) && ~isempty(x4)
  x1=[x1 1];
  x4=[x4 4];
  v1=[x2-x1;x3-x2;x4-x3;x1-x4];
  v2=[x3-x1;x4-x2;x1-x3;x2-x4];
else
  if isempty(x1)
    x1=[x4 4];
    h1=[x1(1:2) 1];
    h2=[x2(1:2) 1];
    h3=[x3(1:2) 1];
  else
    x1=[x1 1];
    h1=[x1(1:2) 4];
    h2=[x2(1:2) 4];
    h3=[x3(1:2) 4];
  end
  v1=[x3-x2;h3-h2;x2-h2;h3-h2;x3-h3;h1-h3;x1-h1;h2-h1;];
  v2=[x1-x2;h1-h2;x3-h2;x3-h2;x1-h3;x1-h3;x2-h1;x2-h1;];
end
v3=cross(v1,v2,2);
a=1/2*sqrt( v3(:,1).^2 + v3(:,2).^2 + v3(:,3).^2 );
A=sum(a);

function A=DirectionArea(x1,x2,x3,x4)
x2=[x2 0];
x3=[x3 0];
if ~isempty(x1) && ~isempty(x4)
  x1=[x1 0];
  x4=[x4 0];
  v1=(x2-x1)/norm((x2-x1));
  v2=(x3-x2)/norm((x3-x2));
  v3=(x4-x3)/norm((x4-x3));
  h=1/2*(v3+v2);
  h=h/norm(h);
  v3(3)=norm(v1-h)/sqrt(2);
  v3=v3/norm(v3);
else
  if isempty(x1)
    x4=[x4 0];
    v1=(x3-x2)/norm((x3-x2));
    v2=(x4-x3)/norm((x4-x3));
  else
    x1=[x1 0];
    v1=(x2-x1)/norm((x2-x1));
    v2=(x3-x2)/norm((x3-x2));
  end
  v3=cross(v1,v2);
  v3=v3/norm(v3);
end
A=1/2*norm(cross(v2-v1,v3-v1));

function A=SpeedArea(x1,x2,x3,x4,t)
s2=[norm(x3-x2)/(t(3)-t(2)) 2];
if ~isempty(x1) && ~isempty(x4)
  s1=[norm(x2-x1)/(t(2)-t(1)) 1];
  s3=[norm(x4-x3)/(t(4)-t(3)) 3];
  v=[s1;s2;s3;];
else
  if isempty(x1)
    s1=[norm(x4-x3)/(t(4)-t(3)) 3];
    h1=[s1(1) 1];
    h2=[s2(1) 1];
  else
    s1=[norm(x2-x1)/(t(2)-t(1)) 1];
    h1=[s1(1) 3];
    h2=[s2(1) 3];
  end
  v=[s1;s2;h1;h2;];
end
p=[v;v(1,:)];
A=polyarea(p(:,1),p(:,2));

function A=IntLenArea(n1,n2,n3,n4)
n2=[n2(1) 2];
n3=[n3(1) 3];
if ~isempty(n1) && ~isempty(n4)
  n1=[n1(1) 1];
  n4=[n4(1) 4];
  v=[n1;n2;n3;n4;];
else
  if isempty(n1)
    n1=[n4(1) 4];
    h1=[n4(1) 1];
    h2=[n2(1) 1];
    h3=[n3(1) 1];
  else
    n1=[n1(1) 1];
    h1=[n1(1) 4];
    h2=[n2(1) 4];
    h3=[n3(1) 4];
  end
  v=[n1;n2;n3;h1;h2;h3;];
end
[~,t]=min(v(:,1));
p=v(t,:);
[~,t]=min(v(:,2));
p=[p;v(t,:);];
[~,t]=max(v(:,1));
p=[p;v(t,:);];
[~,t]=max(v(:,2));
p=[p;v(t,:);];
p=[p;p(1,:);];
A=polyarea(p(:,1),p(:,2));
