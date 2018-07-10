function PlotRect( rect, c )
  if nargin == 1
    c = 'b';
  end
  if all( rect(3:4) > 0 )
    hold on;
    plot( [rect(1) rect(1) rect(1)+rect(3) rect(1)+rect(3) rect(1)], [rect(2) rect(2)+rect(4) rect(2)+rect(4) rect(2) rect(2)], [ c '-' ],'LineWidth',4 );
    hold off;
  end
end