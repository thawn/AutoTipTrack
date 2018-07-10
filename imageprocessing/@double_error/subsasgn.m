function a = subsasgn( a, s, b )
%SUBSASGN handles the assignment of values using a subscripted expression

  a = double_error( a );
  
  if isa( b, 'double_error' )
    a.value = subsasgn( a.value, s, b.value );
    a.error = subsasgn( a.error, s, b.error );
  else
    a.value = subsasgn( a.value, s, b );
    a.error = subsasgn( a.error, s, zeros( size(b) ) );
  end
end