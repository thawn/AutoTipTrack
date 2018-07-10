function [X,Y,Dis,Side,Resnorm]=fitPath(Results)
Xdata = double(Results(:,3));
Ydata = double(Results(:,4));
warning('off','curvefit:fit:equationBadlyConditioned');
[param1,resnorm1] = PathFitLinear(Xdata,Ydata);
resnorm1=resnorm1/(length(Xdata)-2);
[X,Y,Dis,Side] = LinearPath(Xdata,Ydata,param1);
try
  [param2,resnorm2] = PathFitPoly2(X,Y,Side,param1);
  resnorm2=resnorm2/(length(Xdata)-3);
catch %#ok<CTCH>
  resnorm2=Inf;
end
% try
%   [param3,resnorm3] = PathFitPoly3(X,Y,Side,param1);
% catch
%   resnorm3=Inf;
% end
resnorm3=Inf;
Resnorm=[resnorm1;resnorm2;resnorm3];
if all(resnorm2<[resnorm1 resnorm3])
  [X,Y,Dis,Side]=Poly2Path(Xdata,Ydata,param2);
elseif all(resnorm3<[resnorm1 resnorm2])
  [X,Y,Dis,Side]=Poly3Path(Xdata,Ydata,param3);
end
warning('on','curvefit:fit:equationBadlyConditioned');

function res=LinearModel(param,X,Y)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
res=( X - (sin(param(3))*Proj+param(1)) ).^2 + ( Y - (cos(param(3))*Proj+param(2))).^2;

function [param,resnorm]=PathFitLinear(X,Y)
param0(1)=X(1)+(X(end)-X(1))/2;
param0(2)=Y(1)+(Y(end)-Y(1))/2;
param0(3)=atan( (X(end)-X(1))/(Y(end)-Y(1)));
options = optimset('Display','off');
try
  [param,resnorm,~,~,~]= lsqnonlin(@LinearModel,param0,[],[],options,X,Y); 
catch %#ok<CTCH>
  param=param0;
  resnorm=1e100;
end

function [PathX,PathY,Dis,Side]=LinearPath(X,Y,param)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
Dis=Proj-Proj(1);
v=[X-(sin(param(3))*Proj+param(1)) Y-(cos(param(3))*Proj+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+param(1))-(sin(param(3))*(min(Proj)-1)+param(1)) (cos(param(3))*Proj+param(2))-(cos(param(3))*(min(Proj)-1)+param(2)) zeros(length(Proj),1)];
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
Side(isnan(Side))=0;
PathX=(sin(param(3))*Proj+param(1));
PathY=(cos(param(3))*Proj+param(2));

function res=Poly2Model(param,X,Y)
c3 = 2*param(4)^2;
c2 = 0;
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1)/c3;
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)))/c3;
p = (3*c1-c2^2)/3;
q = (9*c1*c2-27*c0-2*c2^3)/27;
Q=(1/3)*p;
R=(1/2)*q;
D=Q.^3+R.^2;
k=find(D>=0);
S=zeros(length(D),1);
T=zeros(length(D),1);
S(k)=nthroot(R(k)+sqrt(D(k)),3);
T(k)=nthroot(R(k)-sqrt(D(k)),3);
root=zeros(length(D),1);
root(k,1) = -(1/3)*c2+(S(k)+T(k));
root(k,2) = -(1/3)*c2-(1/2)*(S(k)+T(k))+(1/2)*1i*sqrt(3)*(S(k)-T(k));
root(k,3) = -(1/3)*c2-(1/2)*(S(k)+T(k))-(1/2)*1i*sqrt(3)*(S(k)-T(k));
k=find(D<0);
phi=zeros(length(D),3);
phi(k)=acos(R(k)./sqrt(-Q(k).^3));
root(k,1) = 2*sqrt(-Q(k)).*cos(phi(k)/3)-(1/3)*c2;
root(k,2) = 2*sqrt(-Q(k)).*cos((phi(k)+2*pi)/3)-(1/3)*c2;
root(k,3) = 2*sqrt(-Q(k)).*cos((phi(k)+4*pi)/3)-(1/3)*c2;
root(imag(root)~=0)=NaN;
W=sqrt(([X X X]-(sin(param(3))*root+param(1)+root.^2*param(4)*cos(param(3)))).^2+([Y Y Y]-(cos(param(3))*root+param(2)-root.^2*param(4)*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(X) 3],(1:length(X))',lx));
res=( X - (sin(param(3))*Proj+param(1)+Proj.^2*param(4)*cos(param(3)))).^2 + ( Y - (cos(param(3))*Proj+param(2)-Proj.^2*param(4)*sin(param(3)))).^2;

function [param,resnorm]=PathFitPoly2(X,Y,Side,param)
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
fd=fit(Proj,Side,'poly2');
x0=-fd.p2/(2*fd.p1);
y0=fd.p1*x0^2+fd.p2*x0+fd.p3;
param0(1)=sin(param(3))*x0+param(1)+y0*cos(param(3));
param0(2)=cos(param(3))*x0+param(2)-y0*sin(param(3));
param0(3)=param(3);
param0(4)=fd.p1;
options = optimset('Display','off');%optimget('MaxFunEvals',400,'MaxIter',300,'TolFun',1e-3,'TolX',1e-3,'LargeScale','on');
[param,resnorm,~,~,~]= lsqnonlin(@Poly2Model,param0,[],[],options,X,Y); 


function [PathX,PathY,Dis,Side]=Poly2Path(X,Y,param)
c3 = 2*param(4)^2;
c2 = 0;
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1)/c3;
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)))/c3;
p = (3*c1-c2^2)/3;
q = (9*c1*c2-27*c0-2*c2^3)/27;
Q=(1/3)*p;
R=(1/2)*q;
D=Q.^3+R.^2;
k=find(D>=0);
S=zeros(length(D),1);
T=zeros(length(D),1);
S(k)=nthroot(R(k)+sqrt(D(k)),3);
T(k)=nthroot(R(k)-sqrt(D(k)),3);
root=zeros(length(D),1);
root(k,1) = -(1/3)*c2+(S(k)+T(k));
root(k,2) = -(1/3)*c2-(1/2)*(S(k)+T(k))+(1/2)*1i*sqrt(3)*(S(k)-T(k));
root(k,3) = -(1/3)*c2-(1/2)*(S(k)+T(k))-(1/2)*1i*sqrt(3)*(S(k)-T(k));
k=find(D<0);
phi=zeros(length(D),3);
phi(k)=acos(R(k)./sqrt(-Q(k).^3));
root(k,1) = 2*sqrt(-Q(k)).*cos(phi(k)/3)-(1/3)*c2;
root(k,2) = 2*sqrt(-Q(k)).*cos((phi(k)+2*pi)/3)-(1/3)*c2;
root(k,3) = 2*sqrt(-Q(k)).*cos((phi(k)+4*pi)/3)-(1/3)*c2;
root(imag(root)~=0)=NaN;
W=sqrt(([X X X]-(sin(param(3))*root+param(1)+root.^2*param(4)*cos(param(3)))).^2+([Y Y Y]-(cos(param(3))*root+param(2)-root.^2*param(4)*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(D) 3],(1:length(D))',lx));
Dis=zeros(length(X),1);
for i = 2:length(X)
  if i>1
    F = @(t)sqrt( (sin(param(3))+2*t*param(4)*cos(param(3))).^2+(cos(param(3))-2*t*param(4)*sin(param(3))).^2);
    Dis(i) = integral(F,Proj(1),Proj(i));
  end
end
v=[X-(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1)) Y-(cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1))-(sin(param(3))*(min(Proj)-1)+(min(Proj)-1).^2*param(4)*cos(param(3))+param(1))...
  (cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2))-(cos(param(3))*(min(Proj)-1)-(min(Proj)-1).^2*param(4)*sin(param(3))+param(2)) zeros(length(Proj),1)];
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
PathX=(sin(param(3))*Proj+Proj.^2*param(4)*cos(param(3))+param(1));
PathY=(cos(param(3))*Proj-Proj.^2*param(4)*sin(param(3))+param(2));

function res=Poly3Model(param,X,Y)
c5 = 3*param(5)^2;
c4 = 5*param(4)*param(5);
c3 = 2*param(4)^2;
c2 = (param(1)-X)*3*param(5)*cos(param(3))+(Y-param(2))*3*param(5)*sin(param(3));
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1);
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)));
root=zeros(length(X),5);
for i=1:length(X)
  root(i,:)=roots([c5 c4 c3 c2(i) c1(i) c0(i)])';
end
root(imag(root)~=0)=NaN;
W=sqrt(([X X X X X]-(sin(param(3))*root+param(1)+(root.^2*param(4)+root.^3*param(5))*cos(param(3)))).^2+([Y Y Y Y Y]-(cos(param(3))*root+param(2)-(root.^2*param(4)+root.^3*param(5))*sin(param(3)))).^2);
[~,lx]=min(W,[],2);
Proj=root(sub2ind([length(X) 5],(1:length(X))',lx));
res=( X - (sin(param(3))*Proj+param(1)+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3)))).^2 + ( Y - (cos(param(3))*Proj+param(2)-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3)))).^2;

function [param,resnorm]=PathFitPoly3(X,Y,Side,param) %#ok<DEFNU>
Proj=(X-param(1))*sin(param(3)) + (Y-param(2))*cos(param(3));
[p,~,m]=polyfit(Proj,Side,3);
x0=(-2*p(2)+[sqrt(4*p(2)^2-12*p(1)*p(3)) -sqrt(4*p(2)^2-12*p(1)*p(3))])/(6*p(1));
if (p(1)>0&&p(2)>=0)||(p(1)<0&&p(2)<=0)
  if isreal(max(x0))
    x0=max(x0);
  else
    x0=min(x0);
  end
else
  if isreal(min(x0))
    x0=min(x0);
  else
    x0=max(x0);
  end
end
y0=polyval(p,x0);
x0=x0*m(2)+m(1);
Side=Side-y0;
Proj=Proj-x0;
F=fittype('p1*x^3+p2*x^2','coefficients',{'p1','p2'});
fd=fit(Proj,Side,F,'Startpoint',[1 1]);
param0(1)=sin(param(3))*x0+param(1)+y0*cos(param(3));
param0(2)=cos(param(3))*x0+param(2)-y0*sin(param(3));
param0(3)=param(3);
param0(4)=fd.p2;
param0(5)=fd.p1;
options = optimset('Display','off');
[param,resnorm,~,~,~]= lsqnonlin(@Poly3Model,param0,[],[],options,X,Y); 


function [PathX,PathY,Dis,Side]=Poly3Path(X,Y,param)
c5 = 3*param(5)^2;
c4 = 5*param(4)*param(5);
c3 = 2*param(4)^2;
c2 = (param(1)-X)*3*param(5)*cos(param(3))+(Y-param(2))*3*param(5)*sin(param(3));
c1 = (2*(param(1)-X)*param(4)*cos(param(3))+2*(Y-param(2))*param(4)*sin(param(3))+1);
c0 = ((param(1)-X)*sin(param(3))+(param(2)-Y)*cos(param(3)));
Proj=zeros(length(X),1);
Dis=zeros(length(X),1);
for i=1:length(X)
  root=roots([c5 c4 c3 c2(i) c1(i) c0(i)])';
  root(imag(root)~=0)=NaN;
  W=sqrt(([X(i) X(i) X(i) X(i) X(i)]-(sin(param(3))*root+param(1)+(root.^2*param(4)+root.^3*param(5))*cos(param(3)))).^2+([Y(i) Y(i) Y(i) Y(i) Y(i)]-(cos(param(3))*root+param(2)-(root.^2*param(4)+root.^3*param(5))*sin(param(3)))).^2);
  [~,lx]=min(W);
  Proj(i)=root(lx);
  if i>1
    F = @(t)sqrt( (sin(param(3))+(2*t*param(4)+3*t.^2*param(5))*cos(param(3))).^2+(cos(param(3))-(2*t*param(4)+3*t.^2*param(5))*sin(param(3))).^2);
    Dis(i) = integral(F,Proj(1),Proj(i));
  end
end
v=[X-(sin(param(3))*Proj+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3))+param(1)) Y-(cos(param(3))*Proj-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3))+param(2)) zeros(length(Proj),1)];
u=[(sin(param(3))*Proj+(Proj.^2*param(4)+Proj.^3*param(5))*cos(param(3))+param(1))-(sin(param(3))*(min(Proj)-1)+((min(Proj)-1).^2*param(4)+(min(Proj)-1).^3*param(5))*cos(param(3))+param(1))...
  (cos(param(3))*Proj-(Proj.^2*param(4)+Proj.^3*param(5))*sin(param(3))+param(2))-(cos(param(3))*(min(Proj)-1)-((min(Proj)-1).^2*param(4)+(min(Proj)-1).^3*param(5))*sin(param(3))+param(2)) zeros(length(Proj),1)];
u(:,1)=u(:,1)./sqrt(u(:,1).^2+u(:,2).^2);
u(:,2)=u(:,2)./sqrt(u(:,1).^2+u(:,2).^2);
Side=sqrt( v(:,1).^2 + v(:,2).^2 ).*-sum(sign(cross(u,v)),2);
PathX=(sin(param(3))*sort(Proj)+(sort(Proj).^2*param(4)+sort(Proj).^3*param(5))*cos(param(3))+param(1));
PathY=(cos(param(3))*sort(Proj)-(sort(Proj).^2*param(4)+sort(Proj).^3*param(5))*sin(param(3))+param(2));
