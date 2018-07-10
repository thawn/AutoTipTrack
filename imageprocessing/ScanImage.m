% SCANIMAGE scans a picture taken by a microscope for bright objects.
% ==============================================================================
% 
% @author: David Zwicker, MPI CBG Dresden
% @modified: 2007-10-14
%
% ==============================================================================
%
% This modul uses global variables for speeding up the calculation. Those should
% not be used in any outer code, because the might be overwritten:
% xg, yg, fit_pic, fit_model, pic, bw
% ==============================================================================

function [objects, bw] = ScanImage( image, params, idx )
%SCANIMAGE does the whole scanning process.
% arguments:
%   image       picture to scan
%   params      parameters struct influencing the algorithm
% returns:
%   objects     array of all objects with calculated data
 
  % check arguments
   narginchk( 1, 3 ) ;
   
   params = CheckParameters( params );
  
  % apply scaling to input parameters
  params.fwhm_estimate = params.fwhm_estimate / params.scale; 
  params.creation_time = params.creation_time_vector(real(idx));
  if numel( params.threshold ) >1
    params.threshold = params.threshold(real(idx));
  end

  %{
   if params.display > 1 % graphical debug enabled
    % add debug directory
    addpath( [ pathstr filesep 'debug' ] );
    close all; % close all old windows 
  end
  %}
  if params.display>0
    params.logger.Log( 'START SCANNING', params.display );
  end
  
  % here we create the handle object for the input image
  % in the Pic class, the image is converted to double, because our model
  % should have double precision and MatLAB cant compare the model to the
  % image otherwise.
  params.pic = Pic( image ); 
  
  % rough scan
  [ objects, params, bw ] = RoughScan( params );
  
  % fine scan
  if numel( objects ) > 0 && isreal(idx) && params.error_events.abort == 0

    % do fine scan where complicated areas and middle parts are fitted
    if params.display>0
      params.logger.Log( 'start fine scan', params.display );
    end
    objects = FineScan( objects, params );
    
    % interpolate data
    if params.display>0
      params.logger.Log( 'interpolate data between points', params.display );
    end
    objects = InterpolateData( objects, params );
    
    objects = orderfields(objects);
  end
  
 % params.logger.Log( 'FINISHED SCANNING', params.display );

  % delete object handles to clean up
  clear params.pic;
  clear params.objectIDs;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HELPER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function params = CheckParameters( params )
%CHECKPARAMETERS verifies all parameters passed to ScanImg and sets default
%values if some fields are not given at all.

  % check parameters struct
  if nargin < 1
    params = struct('default',{true});
  else
    params.default = false;
  end

  % necessary parameters
  
  if ~isfield( params, 'fwhm_estimate' )
    error( 'MPICBG:FIESTA:FWHMnotGiven', 'An estimate for the FWHM of the objects has to be given' );
  end
  
  % optional parameters
  
  if ~isfield( params, 'area_threshold' )
    params.area_threshold = 30; % objects with lower area are handled as beads
  end
  
  if ~isfield( params, 'bead_model' )
    params.bead_model = 'GaussSymmetric'; % model used for fitting beads ( 'circle' or 'ellipses' are accepted values )
  end
  
  if ~isfield( params, 'binary_image_processing' )
    params.binary_image_processing = 'none'; % methode for processing binary images ( 'none', 'average' or 'smooth')
  end
  
  if ~isfield( params, 'border_margin' )
    params.border_margin = 0; % minimum distance of accepted objects to the border
  end

  if strcmp( params.bead_model, 'GaussSymmetric' )
    params.bead_model_char = 'p';
  elseif strcmp( params.bead_model, 'GaussStreched' )
    params.bead_model_char = 'b';
  elseif strcmp( params.bead_model, 'GaussPlusRing' )
    params.bead_model_char = 'r';
  elseif strcmp( params.bead_model, 'GaussPlus2Rings' )
    params.bead_model_char = 'f';    
  else
    error( 'MPICBG:FIESTA:unknownModel', 'The bead model "%s" is unknown', params.bead_model );
  end
  
  if ~isfield( params, 'ridge_model' )
    params.ridge_model = 'linear'; % model for middle part of elognated objects 
    % 'lineaer' or 'quadratic' are supported
  end
  
  if ~isfield( params, 'creation_time' )
    params.creation_time = NaN; % time information on the currently processed frame
  end
  
  if ~isfield( params, 'display' )
    params.display = 0; % level of output
  end

  if ~isfield( params, 'find_molecules' )
    params.find_molecules = true; % determines, if the algorithm should look for molecules
  end
  
  if ~isfield( params, 'find_beads' )
    params.find_beads = true; % determines, if the algorithm should look for beads
  end
  
  if ~isfield( params, 'height_threshold' )
    params.height_threshold = 2; % used to determine a height threshold for the bead
  end
  
  if ~isfield( params, 'max_beads_per_region' )
    params.max_beads_per_region = Inf; % maximum number of beads, that should be found in one region
  end
  
  if ~isfield( params, 'min_cod' )
    params.min_cod = 0.5; % minimum coefficient of determination - worse fits will be disregarded
  end
  
  if ~isfield( params, 'scale' )
    params.scale = 1.0; % scale of the image
  end
  
  if ~isfield( params, 'short_object_threshold' )
    params.short_object_threshold = 4 * params.reduce_fit_box * params.fwhm_estimate / params.scale / (2*sqrt(2*log(2)));;
  end
    
%   if ~isfield( params, 'eccentricity_threshold' )
%     params.eccentricity_threshold = 0.85; % objects with lower eccentricity are disregarded, if they are small
%   end
%  
%   if ~isfield( params, 'peak_model' )
%     params.peak_model = 'gauss'; % funktion used to model peaks
%   end

end