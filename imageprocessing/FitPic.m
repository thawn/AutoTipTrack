classdef FitPic < handle
  properties
    fit_pic=[];
    xg=[];
    yg=[];
  end
  methods
    function F=FitPic(params,rect)
      if nargin>0
        F.fit_pic=imcrop(params.pic.pic, rect);
        % calculate meshgrid once and store it in global variables
        [ F.xg, F.yg ] = meshgrid( 1:size( F.fit_pic, 2 ), 1:size( F.fit_pic, 1 ) );
      end
    end
  end
end