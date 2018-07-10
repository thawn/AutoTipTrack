function [black, white]=autoscale(im,blackPercent,whitePercent)
if nargin<2
  blackPercent=0.2;
end
if nargin<3
  whitePercent=blackPercent;
end
%statistics for image scaling
  pixelValues=sort(im(:));
  %set the black value to the pixel intensity of the bottom 0.2% pixels
  BlackIndex=round(length(pixelValues)*blackPercent/100);
  if BlackIndex<1
    BlackIndex=1;
  end
  black=pixelValues(BlackIndex);
  %set the white value to the pixel intensity of the top 0.2% pixels
  white=pixelValues(round(length(pixelValues)-(length(pixelValues)*whitePercent/100)));
