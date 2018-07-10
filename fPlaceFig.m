function NewPos = fPlaceFig(hFig,mode)
Pos = get(0,'ScreenSize');
switch(mode)
    case 'small' 
        NewPos = [Pos(1)+0.4*Pos(3) Pos(2)+0.425*Pos(4) Pos(3)*0.2 Pos(4)*0.15];
        if NewPos(3)<300
            NewPos(3)=300;
        end
        if NewPos(4)<100
            NewPos(4)=100;
        end
    case 'medium'
        NewPos = [Pos(1)+0.6*Pos(3) Pos(2)+0.05*Pos(4) Pos(3)*0.35 Pos(4)*0.5];
    case 'big'
        NewPos = [Pos(1)+0.05*Pos(3) Pos(2)+0.03*Pos(4) Pos(3)*0.65 Pos(4)*0.92];
    case 'bigger'
        NewPos = [Pos(1)+0.05*Pos(3) Pos(2)+0.05*Pos(4) Pos(3)*0.9 Pos(4)*0.92];
    case 'speed'
        NewPos = [Pos(1)+0.4*Pos(3) Pos(2)+0.3*Pos(4) Pos(3)*0.2 Pos(4)*0.3];
    case 'export'
        NewPos = [Pos(1)+0.65*Pos(3) Pos(2)+0.15*Pos(4) Pos(3)*0.35 Pos(4)*0.7];
    case 'reposition'
        set(hFig,'Units','pixels');
        PosFig = get(hFig,'Position');
        NewPos = [Pos(1)+0.5*(Pos(3)-PosFig(3)) Pos(2)+0.5*(Pos(4)-PosFig(4)) PosFig(3) PosFig(4)];
end
if ~isempty(hFig)
    set(hFig,'Units','pixels');
    set(hFig,'Position',NewPos);
    set(hFig,'Units','normalized','Visible','on');
end