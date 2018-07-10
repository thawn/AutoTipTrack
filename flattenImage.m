function FlatImg=flattenImage(Image, ballR,smoothe)
if nargin<3
  smoothe=0;
end
%SE=strel('ball',ballR,ballR,ballR*2);
SE=strel('disk',ballR);
FlatImg=imtophat(Image,SE);
if smoothe>0
  bg=Image-FlatImg;
  Gauss=fspecial('gaussian',round([ballR*smoothe*3 ballR*smoothe*3]),ballR*smoothe);
  bgBlur=imfilter(bg,Gauss,'replicate');
  FlatImg=Image-bgBlur;
end
end