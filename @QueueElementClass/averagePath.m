function [X,Y,Dis,Side]=averagePath(Results,DisRegion)
nData=size(Results,1);

p=2;
n=1;
%b=true(1);
PosX = double(Results(:,3));
PosY = double(Results(:,4));
T = Results(:,2);
PosZ = zeros(size(PosX));
NRes(1,1:4)=[T(1) PosX(1) PosY(1) PosZ(1)];
while n<=nData
    IN = sqrt( ( PosX(n)-PosX ).^2 + ( PosY(n)- PosY).^2 + ( PosZ(n)- PosZ).^2 ) <DisRegion;
    if sum(IN)==1
        if n>1 && n<nData
            NRes(p,1:4) = [T(n) PosX(n) PosY(n) PosZ(n)];
            p = p+1;
        end
        n = n+1;
    else
        k = find(~IN);
        k_start = k(find(k<n,1,'last'))+1;
        k_end = k(find(k>n,1,'first'))-1;
        if isempty(k_start)
            k_start=1;
        end
        if isempty(k_end)
            k_end=nData;
        end
        NRes(p,1) = mean(T(k_start:k_end));
        NRes(p,2) = mean(PosX(k_start:k_end));
        NRes(p,3) = mean(PosY(k_start:k_end));
        NRes(p,4) = mean(PosZ(k_start:k_end));
        n = k_end+1;
        p=p+1;
    end
end
NRes(end+1,1:4)=[T(end) PosX(end) PosY(end) PosZ(end)];
%now make sure that we did not add the same point twice in a row otherwise
%spline will throw an error
for p=size(NRes,1):-1:2
  if all(NRes(p,2:4)==NRes(p-1,2:4))
    %spline chkxy
    NRes(p,:)=[];
  end
end
if size(NRes,1)==1
  %if we have just one point, we cannot fit a path (this can only happen
  %if all points are close together and the first and last point are
  %identical).
  X=[];Y=[];Dis=[];Side=[];
  return;
elseif size(NRes,1)==2
  %for extremely short tracks we fit a linear path
  method='linear';
elseif size(NRes,1)==3
  %for tracks with 3 points we fit a Piecewise Cubic Hermite Interpolating
  %Polynomial to work around a bug in distance2curve
  method='pchip';
else
  method='spline';
end
try
[XYZ,~,Dis] = distance2curve(NRes(:,2:4),[PosX PosY PosZ],method);
catch ME
  ME.getReport
end
  
X1 = [0; XYZ(2:end,1) - XYZ(1:end-1,1)];
Y1 = [0; XYZ(2:end,2) - XYZ(1:end-1,2)];
X2 = [0; PosX(2:end) - XYZ(2:end,1)];
Y2 = [0; PosY(2:end) - XYZ(2:end,2)];
Z = zeros(size(X1));
Side = sqrt(sum(abs([X2 Y2]).^2,2));
Side = -Side.*sum(sign(cross([X1 Y1 Z],[X2 Y2 Z])),2);
X=XYZ(:,1);
Y=XYZ(:,2);
