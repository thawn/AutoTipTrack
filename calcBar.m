function position=calcBar(Config)
PixSize = Config.PixSize;
width=Config.Avi.BarSize*1000/PixSize;
height=0.01*Config.Height;
spacing=0.05*min([Config.Width Config.Height]);
if Config.Avi.mPosBar==1||Config.Avi.mPosBar==3
  x=spacing;
else
  x=Config.Width-spacing-width;
end
if Config.Avi.mPosBar==1||Config.Avi.mPosBar==2
  y=spacing;
else
  y=Config.Height-spacing;
end
position=[x y width height];
