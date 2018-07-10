function ShowResults( objects, stack )
  if nargin < 2
    stack = [];
  end
  
  colors = [ 'b', 'k', 'r' 'g' 'b' 'c' 'm' 'y' ];
  color_idx = 1;
  if isempty( stack )
    high = numel(objects)
    dim = [ 600 600 ];
  else
    high = min( [ size( stack, 4 ) numel(objects) ] );
    dim = size( stack( :,:,1,1 ) );
  end
  
  fig = figure();
  j = 1
  while 1
    if isempty( objects{j} )
      continue;
    end
    disp( sprintf( 'SHOWING FRAME %d', j ) );
    %objects{j} = ScanImage( stack(:,:,:,j) );
    if ~isempty( stack )
      imshow( stack(:,:,:,j), [100 1000] );
    end
    hold on;
    axis([0 dim(1) 0 dim(2)]);
    for i = 1:size( objects{j}, 2 )
      o = objects{j}(i);
      for k = 1 : size( o.x_coeff, 1 )
        x_c = o.x_coeff(k,:);
        y_c = o.y_coeff(k,:);
        t = 0:.1:1;
        x = x_c(1)*t.^3 + x_c(2)*t.^2 + x_c(3)*t;
        y = y_c(1)*t.^3 + y_c(2)*t.^2 + y_c(3)*t;
        %y = c(1)*x.^3 + c(2)*x.^2 + c(3)*x;
        plot( x + o.p(k,1), y + o.p(k,2), colors( color_idx ), 'LineWidth', 2 );
      end
      color_idx = mod( color_idx, numel( colors ) ) + 1;
      %plot( o.p(:,1), o.p(:,2), 'kx', 'MarkerSize', 5 );
    end
    hold off;

    title( j );
    w = waitforbuttonpress;
    
    if w == 1
      key = get( fig, 'CurrentCharacter' );
      switch key
        case 'b'
          j = j - 1;
        case 'v'
          j = j - 10;
        case 'm'
          j = j + 10;
        otherwise
          j = j + 1;
      end
      if j < 1 
        j = 1
      end
      if j > high 
        j = high
      end
    end
    
    clf
  end % while
end