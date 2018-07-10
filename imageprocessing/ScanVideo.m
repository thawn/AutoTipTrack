function ScanVideo( stack, obj_str )
%SCANVIDEO scans a whole stack with parameters definied in this function

  params.error_events = ErrorEvents();

%   global logfile
%   logfile = fopen( 'console.txt', 'wt' );
  
  if nargin > 1 && ~isempty(obj_str)
    try
      load( obj_str );
    catch
    end
  end
  start = clock;
  frames = [];
  
%   params = struct( 'display', 3, 'fwhm_estimate', 3.3 );
  params = struct( 'display', 3, 'fwhm_estimate', 580/100 );
%   params = struct( 'display', 3, 'fwhm_estimate', 2.0 );
%   params.bead_model = 'ring';
%   params.max_beads_per_region = 1;
%   params.threshold = 844;
%   params.area_threshold = Inf;
  params.min_cod = 0.0;
  
%   params.scale = 1.0;
%   params.find_molecules = false;
  params.find_beads = false;
  params.bead_model = 'circle';
  params.ridge_model = 'quadratic';
%   params.ridge_model = 'linear';
  params.binary_image_processing = 'smooth';
%   params.scanareas = 23;
%   params.scanareas = [25 27 ];
  params.scanareas = [11 13];
%  params.scanareas = 12;
%   frames = 300;
%   frames = 7:146;%:40;
  frames = 1;
%   params.threshold = 2.3 * mean2( stack(256:end,:,1,671) );
  if isempty( frames )
    frames = 1 : max( size( stack, 3 ), size( stack, 4 ) );
  end

  for j = frames %size(stack,4)
    disp( sprintf( '\n\nPROCESSING FRAME %d at %s', j, datestr(now) ) );
    if ndims( stack ) < 4
      objects{j} = ScanImage( stack(:,:,j), params );
    else
      objects{j} = ScanImage( stack(:,:,1,j), params );
    end
    if  nargin > 1 && ~isempty(obj_str)
      save( obj_str, 'objects' );
    end
    if params.display > 1
      figure;
      if ndims( stack ) < 4
        imshow( stack(:,:,j), [] );
      else
        imshow( stack(:,:,:,j), [] );
      end
      PlotTubules( objects{j} );
      title( j );
      drawnow;
      pause(0.1);
    end
%     pause;
  end
  fprintf( 'finished. scanning took %0.2f seconds', etime( clock, start ) );
  disp(params.error_events);
%   fclose( logfile );
  
end