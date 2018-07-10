function a = prod( b )
%PROD calculates the product of all the values in b
%WARNING: This function multiplies all entries, not just along one dimension and
%therefor returns a single double_error value instead of an array

  zeros = find( b(:).value == 0 ); % find zero entries
  if numel(zeros) == 0 % no zeros => standard procedure
    a = double_error( prod( b(:).value ) );
    a.error = a.value * sum( b(:).error ./ b(:).value );
  elseif numel(zeros) == 1 % one zero => special error calculation
    a = double_error( 0, prod( b.value(1:zeros(1)-1) ) * b.error(zeros(1)) * prod( b.value(zeros(1)+1:end) ) );
  else % many zeros => everything is zero :)
    a = double_error( 0 );
  end
end