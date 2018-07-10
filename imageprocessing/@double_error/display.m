function [] = display( e )
%DISPLAY displays the string representation of the variable on the command line

  disp(' ');
  disp([inputname(1),' = ']);
  disp(' ');
  disp(['   ' char(e)]);
  disp(' ');
end