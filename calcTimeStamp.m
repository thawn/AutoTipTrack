function position=calcTimeStamp(Config)
spacing=0.05*min([Config.Width Config.Height]);
if Config.Avi.mPosTime==1||Config.Avi.mPosTime==3
  x=spacing-0.1*Config.Avi.mFontSize*Config.Width;
else
  x=Config.Width-spacing+0.1*Config.Avi.mFontSize*Config.Width;
end
if Config.Avi.mPosTime==1||Config.Avi.mPosTime==2
  y=spacing;
else
  y=Config.Height-spacing;
end
position=[x y];
