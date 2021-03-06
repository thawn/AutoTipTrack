function plotMoleculePath(Molecule,number,varargin)
fig1=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
ax=axes('Parent',fig1);
XLimits=[min(Molecule(number).Results(:,3)) max(Molecule(number).Results(:,3))];
YLimits=[min(Molecule(number).Results(:,4)) max(Molecule(number).Results(:,4))];
plot(ax,Molecule(number).Results(:,3)-XLimits(1),flipud(Molecule(number).Results(:,4)-YLimits(1)),'g+-',varargin{:});
hold on;
plot(ax,Molecule(number).PathData(:,1)-XLimits(1),flipud(Molecule(number).PathData(:,2)-YLimits(1)),'bx-',varargin{:});
Ranges=[XLimits(2)-XLimits(1) YLimits(2)-YLimits(1)];
Boundary=max(Ranges)/10;
xlim(ax,XLimits+[-Boundary Boundary]-XLimits(1));
ylim(ax,YLimits+[-Boundary Boundary]-YLimits(1));
xlabel(ax,'x-position (nm)','FontSize',16);
ylabel(ax,'y-position (nm)','FontSize',16);
set(ax,'DataAspectRatio',[1 1 1],'DataAspectRatioMode','manual','FontSize',12);
set(fig1,'Visible','on');
fig2=createBasicFigure('Width', 29.7,'Aspect',29.7/21);
ax2=axes('Parent',fig2);
plot(ax2,Molecule(number).Results(:,2),Molecule(number).PathData(:,3),'bx-',varargin{:});
xlabel(ax2,'time (s)','FontSize',16);
ylabel(ax2,'distance along path (nm)','FontSize',16);
set(fig2,'Visible','on');
xlim(ax2,[min(Molecule(number).Results(:,2))-1 max(Molecule(number).Results(:,2))+1]);
ylim(ax2,YLimits+[-Boundary Boundary]-YLimits(1));
set(ax2,'DataAspectRatio',[1 1000 1],'DataAspectRatioMode','manual','FontSize',12);
