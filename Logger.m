classdef Logger < handle
  properties
    logfile=[];
    filestr='';
  end
  methods
    function L=Logger(filestr)
      if nargin>0
        L.filestr=filestr;
        L.logfile=fopen(filestr,'w');
      end
    end
    function Log(L, msg, display )
      %LOG handels all output of the algorithm
      % arguments:
      %  msg      a string representing the message that should be logged
      %  params   a struct containing the parameters for the program
      
      %logger does not reliably work inside a parallel worker so we only do
      %something if we are not inside a parallel worker
      if isempty(getCurrentTask())
        narginchk( 3, 3 ) ;
        if mod( display, 2 ) == 1 % do logging
          c = clock;
          if L.logfile > 0 % save text to file
            try
              fprintf( L.logfile, '%02u:%02u:%02u  %s\n' , c(4), c(5), fix(c(6)), msg );
            catch err
              if strcmp( err.identifier, 'MATLAB:badfid_mx' )
                L.logfile = [];
              else
                rethrow( err );
              end
            end
          else % output text to console
            fprintf( '%02u:%02u:%02u  %s' , c(4), c(5), fix(c(6)), msg );
          end
        end
      end
    end
    function delete(L)
      fclose(L.logfile);
    end
  end
end