function [plot1,plot2]=properErrorbar(x,median,medianErrs,color,Marker,ax)
plot1=plot(x,median,'Marker',Marker,'Color',color,'Parent',ax);
hold(ax,'on');
plot2=errorbar(x,medianErrs(1,:),medianErrs(3,:)-medianErrs(2,:),'.','Color',color,'Parent',ax);
set(plot1, 'LineStyle','none');
set(plot2, 'Marker','none');
legend(ax,'show','Location','best');
ylim(ax,[0 max(median)*1.2]);
end