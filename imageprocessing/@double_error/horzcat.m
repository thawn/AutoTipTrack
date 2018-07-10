function c = horzcat( varargin )
%HORZCAT horizontally concatenates all given arrays
  
  c = double_error();
  for i = 1 : length( varargin )
    v = double_error( varargin{i} );
    c.value = [ c.value v.value ];
    c.error = [ c.error v.error ];
  end
end