function n = norm( a, p )
%NORM calculates the p-norm of the vector a

  if nargin < 2
    p = 2;
  end

  if isvector( a )
    if p == 2
      n = double_error( norm( a.value ) );
      n.error = n.value ./ sum( abs( a.value ).^2 ) .* abs( a.value ) .* a.error;
    else
      n = double_error( norm( a.value, p ) );
      n.error = n.value ./ sum( abs( a.value ).^p ) .* abs( a.value ).^(p-1) .* a.error;
    end
  else
    error( 'MPICBG:FIESTA:UnsupportedMatrixShape', 'Norm of double_error values is only defined for vectors' );
  end
end