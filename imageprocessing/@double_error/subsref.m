function b = subsref( a, index )
%SUBSREF handles references using subscripted expressions

  if numel(index) == 1 && strcmp( index(1).type, '.' )
    switch index.subs
      case 'value'
        b = a.value;
        return;
      case 'error'
        b = a.error;
        return;
    end
  elseif numel(index) == 2 && strcmp( index(2).type, '.' )
    switch index(2).subs
      case 'value'
        b = subsref( a.value, index(1) );
        return;
      case 'error'
        b = subsref( a.error, index(1) );
        return;
    end
  end
  
  % otherwise pass reference to both subarrays
  b = double_error( subsref( a.value, index ), subsref( a.error, index ) );
end