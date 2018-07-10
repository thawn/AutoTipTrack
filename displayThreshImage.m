function displayThreshImage(input,params,rad,sm)
im=flattenImage(input,rad,sm);
minIm=min(min(im));
threshold = round( (median(im(:))-minIm)*imag(params.threshold.Value)/100 + minIm );
figure
im=conv2( im, fspecial( 'average', 3 ), 'same' );
output = ( im > threshold );
imshow(output);