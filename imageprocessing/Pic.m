classdef Pic < handle
  properties
    pic = [];
  end
  methods
    function P=Pic(image)
      if nargin>0
        P.pic=double(image);
      end
    end
  end
end