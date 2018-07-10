function s = char( e )
%CHAR returns a string representation of the double_error variable

  if numel( e.value ) == 1
    s = [ num2str( e.value ) sprintf(' %c ',177) num2str( e.error ) ];
  else
    s = [ mat2str( e.value ) sprintf(' %c ',177) mat2str( e.error ) ];
  end
end