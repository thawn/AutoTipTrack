function makeImg(D, parent)
warning off Images:initSize:adjustingMag;
if ~isfield(D.Results, 'Image') || isempty(D.Results.Image)
  try
    D.setImage;
  catch ME
    ME.getReport;
    %fall back to blank image
    if ~isdeployed
      addpath('assets');
    end
    [D.Results.Image,map]=imread('blank.gif','gif');
  end
end
if exist('map','var'); %if we had to fall back to the blank image just show it
  image(D.Results.Image,'Parent',parent);
  colormap(parent,map);
  set(parent, 'XTick', [],'YTick',[],'Box','off','XColor','none','YColor','none');
else
  if D.Config.ImageScaling.ModeNo==1
    %calculate the pixel intensity for image scaling.
    %by default, autoscale defines the lowest 0.2% of pixels as black and
    %the brightest 0.2% of pixels as white
    [black, white]=autoscale(D.Results.Image);
  else
    black=D.Config.ImageScaling.Black;
    white=D.Config.ImageScaling.White;
  end
  imagesc(D.Results.Image,'Parent',parent,[black white]);
  colormap(parent,'gray');
  set(parent, 'XTick', [],'YTick',[],'Box','off','XColor','none','YColor','none','DataAspectRatioMode','manual','DataAspectRatio',[1 1 1]);
  rectangle('Position',calcBar(D.Config),'EdgeColor','none','FaceColor','w');
  text('Position',calcBarLabel(D.Config),'HorizontalAlignment','center','Color','w',...
    'String',sprintf('%g %cm',D.Config.Avi.BarSize,181),'FontUnits','normalized','FontSize',D.Config.Avi.mFontSize);
end
warning on Images:initSize:adjustingMag;