function s = CoD2String( CoD )
%CODSTRING returns a string containing the meaning of the 'CoD' value returned
%by the function Fit2D
%
%See also: FIT2D
%
% Arguments:
%  CoD    a numeric value for the Coefficient of Determination returned by Fit2D
% Results:
%  s      a string containing the message

  s = [];
  if 0 < CoD && CoD <= 1 % normal meaning
    s = sprintf( 'The Coefficient of Determination is %0.5g', CoD );
  elseif isnumeric(CoD) % special meaning
    switch CoD
      % user defined abort conditions
      case -10
        s = 'Resulting parameters were out of bounds.';
      case -11
        s = 'Both end points of the filament lie exactly on top of each other';
      % exitcode of lsqnonlin minus 100
      case -100
        s = 'Number of iterations exceeded options.MaxIter or number of function evaluations exceeded options.FunEvals.';
      case -101
        s = 'Algorithm was terminated by the output function.';
      case -102
        s = 'Problem is infeasible: the bounds lb and ub are inconsistent.';
      case -104
        s = 'Line search could not sufficiently decrease the residual along the current search direction.';
    end
  end
  
  if isempty( s )
    s = sprintf( 'The value CoD = %0.5g has no meaning for this program', CoD );
  end
end