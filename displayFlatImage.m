function displayFlatImage(input,rad,sm)
if rad>0
  im=flattenImage(input,rad,sm);
else
  im=input;
end
[black, white]=autoscale(im);
figure
imshow(im,[black white]);