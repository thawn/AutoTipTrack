classdef Bw < handle
  properties
    bw = [];
  end
  methods
    function B=Bw(params)
      if nargin>0
        B.bw=B.Image2Binary( params );
      end
    end
  end
  methods(Static)
    function output = Image2Binary( params )
      %IMAGE2BINARY takes a grey image and performes some basic feature detection,
      %returning a binary image with 1s at the positions, where it assumes an object
      % arguments:
      %   input   the grey input image
      %   params  a strcut containing parameters or a number being a threshold value
      % results:
      %   output  the binary result having the same dimensions as the input image
      
      input = params.pic.pic; %<< already converted to double
      %  input = wiener2(input);
      
      % check, if a direct threshold methode is requested
      if isfield( params, 'threshold' )
        threshold = params.threshold;
      else
        threshold =[];
      end
      
      % average grey image, if requested
      if strcmp( params.binary_image_processing, 'average' )
        input = conv2( input, fspecial( 'average', 3 ), 'same' );
      end
      
      if ~isempty(threshold) % apply simple threshold
        % appply threshold
        output = ( input > threshold );
        
      else % apply automatic threshold
        automatic_threshold = mean2( input ) + 0.5 * std2( input );
        
        %     % gaussian deconvolution
        %     sigma = params.fwhm_estimate / 2.35;
        %     PSF = fspecial( 'gaussian', ceil(4*params.fwhm_estimate), sigma );
        %     input = edgetaper( input, PSF );
        %     output = deconvlucy( input, PSF );
        %     figure; imshow( output, [] );
        
        % find edges of objects
        output = edge( input, 'sobel', [], 'both', 'nothinning' );
        %     test = edge( input, 'log', [], 'both' );
        %     test = edge( input, 'log', [], 'both' );
        %     output = output .* ( 1 - test );
        %     figure; imshow( output, [] );
        %     output( logical( test ) ) = 0;
        %     figure; imshow( test, [] );
        % close small gaps
        output = bwmorph( output, 'bridge' );
        % fill one-pixel holes
        output = bwmorph( output, 'fill' );
        % fill bigger holes in each object
        l = logical( imcomplement( output ) );
        l_props = regionprops( l, 'Area', 'Image', 'BoundingBox', 'PixelIdxList' );
        f = find( [ l_props.Area ] < 50 );
        for i = f
          region_grey = imcrop( double( input ), l_props(i).BoundingBox - [ 0 0 1 1 ] ) .* l_props(i).Image;
          if mean2( region_grey ) > automatic_threshold
            output( l_props(i).PixelIdxList ) = 1;
          end
        end
        
        % multiply with low threshold image to rule out very dark areas
        input = double( input );
        output = output .* ( input > automatic_threshold );
        %     output = bwmorph( output, 'erode', 1 );
      end
      
      % smooth binary image, if requested
      if strcmp( params.binary_image_processing, 'smooth' )
        output = bwmorph( output, 'close' );
        output = bwmorph( output, 'open' );
      end
      
    end
  end
end