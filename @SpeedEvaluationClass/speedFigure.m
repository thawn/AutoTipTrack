function S=speedFigure(S,parent,m,n,P,p1,p2)
%plot the first image of the stack
scale=n/2;
subplot0=subplot(m,n,P,'Parent',parent);
S.makeImg(subplot0);
ImageTitle=strrep(S.Config.StackName,'_',' ');
title(ImageTitle,'FontSize',16/scale,'FontName','Arial');
[success,S]=S.evaluateSpeeds;
if success
  subplot1 = subplot(m,n,p1,'Parent',parent,'FontSize',10/scale,'FontName','Arial');
  
  %a histogram of the average speeds of the filaments
  S.plotSpeedHistogram(subplot1,scale)
  
  % Create speeds vs time subplot
  subplot2 = subplot(m,n,p2,'Parent',parent,'FontSize',10/scale,'FontName','Arial');
  box(subplot2,'on');
  plot(S.time,S.medianSpeeds)
  ylim([0 max(S.medianSpeeds)*1.1]);
  set(gca,'FontSize',10/scale)
  xlabel('time (s)','FontSize',12/scale);
  ylabel('average velocity per frame (nm/s)','FontSize',12/scale,'FontName','Arial');
  
  S.addResultAnnotation(parent,subplot2,scale)
else  subplot1=subplot(m,n,[p1 p2],'Parent',parent,'FontSize',10/scale,'FontName','Arial');
  set(gca, 'Visible','off')
  boxPos=S.calculateBoxPos(subplot1);
  % Create textbox
  annotation(parent,'textbox',...
    boxPos,...
    'String',{'No microtubule tips could be tracked.','Check stack and configuration for errors.'},...
    'FontSize',12/scale,'FontName','Arial','Color','k',...
    'LineStyle','none','Margin',0,'VerticalAlignment','middle',...
    'FitBoxToText','off');
end
