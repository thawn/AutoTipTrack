function a = atan2( y, x )
%ATAN2 returns the arcustangens of two double_error variable with estimated errors
  if x.value == 0 % special case with vanishing denominator
    if y.value == 0 % totally undetermined
      a = double_error( 0, pi );
    else
      % calculate value
      if y.value > 0 
        a = double_error( pi/2 );
      else % if y.value < 0
        a = double_error( -pi/2 );
      end
      % calculate error
      if x.error == 0
        a.error = 0;
      else
        a.error = atan( y.value / x.error );
      end
    end
  else % ordinary case
    q = y ./ x; %<< quotient for argument of atan()
    a = double_error( atan2( y.value, x.value ), q.error ./ (1 + q.value.^2) );
    a.error( a.error > pi ) = pi;
  end
end
