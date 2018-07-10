function position=calcBarLabel(Config)
PixSize = Config.PixSize;
width=Config.Avi.BarSize*1000/PixSize;
height=0.01*Config.Height;
spacing=0.05*min([Config.Width Config.Height]);
if Config.Avi.mPosBar==1||Config.Avi.mPosBar==3
  x=spacing+width/2;
else
  x=Config.Width-spacing-width/2;
end
if Config.Avi.mPosBar==1||Config.Avi.mPosBar==2
  y=spacing+0.4*Config.Avi.mFontSize*Config.Width+height;
else
  y=Config.Height-spacing-0.4*Config.Avi.mFontSize*Config.Width-height;
end
position=[x y];
