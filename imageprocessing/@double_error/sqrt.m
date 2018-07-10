function a = sqrt( b )
%SQRT returnes the square root of b with an error estimation

  a = double_error( sqrt( b.value ) );
  a.error = 0.5 ./ a.value .* b.error; 
end
