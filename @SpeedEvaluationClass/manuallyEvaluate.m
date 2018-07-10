function [S]=manuallyEvaluate(S)
like=false;
while ~like
  [success,S]=S.evaluateSpeeds;
  if success
    fig1=figure;
    pos=get(fig1,'Position');
    pos=pos-[pos(3) 0 0 0];
    if pos(1)<5
      pos(1)=5;
    end
    set(fig1,'Position',pos);
    axes1=axes('Parent',fig1,'FontSize',10,'FontName','Arial');
    S.plotSpeedHistogram(axes1,1);
    S.addResultAnnotation(fig1,axes1,1);
    drawnow;
  else
    return;
  end
  like=strcmpi(questdlg('did you like the fit','','Yes','No','Yes'),'Yes');
  if ~like
    [peak, num]=ginput(2);
    numPoints=length(peak);
    if numPoints>0
      S.Startpoints=[];
      S.slowresult=[NaN NaN];
      S.fastresult=[NaN NaN];
      for i=1:numPoints
        S.Startpoints=[S.Startpoints num(i) peak(i) 3*S.binSize];
      end
    end
  end
  close(fig1);
end
