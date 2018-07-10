function hText = xticklabel_rotate(XTick,rot,varargin)
%hText = xticklabel_rotate(XTick,rot,XTickLabel,varargin)     Rotate XTickLabel
%
% Syntax: xticklabel_rotate
%
% Input:    
% {opt}     XTick       - vector array of XTick positions & values (numeric) 
%                           uses current XTick values or XTickLabel cell array by
%                           default (if empty) 
% {opt}     rot         - angle of rotation in degrees, 90 by default
% {opt}     XTickLabel  - cell array of label strings
% {opt}     [var]       - "Property-value" pairs passed to text generator
%                           ex: 'interpreter','none'
%                               'Color','m','Fontweight','bold'
%
% Output:   hText       - handle vector to text labels
%
% Example 1:  Rotate existing XTickLabels at their current position by 90
%    xticklabel_rotate
%
% Example 2:  Rotate existing XTickLabels at their current position by 45 and change
% font size
%    xticklabel_rotate([],45,[],'Fontsize',14)
%
% Example 3:  Set the positions of the XTicks and rotate them 90
%    figure;  plot([1960:2004],randn(45,1)); xlim([1960 2004]);
%    xticklabel_rotate([1960:2:2004]);
%
% Example 4:  Use text labels at XTick positions rotated 45 without tex interpreter
%    xticklabel_rotate(XTick,45,NameFields,'interpreter','none');
%
% Example 5:  Use text labels rotated 90 at current positions
%    xticklabel_rotate([],90,NameFields);
%
% Example 6:  Multiline labels
%    figure;plot([1:4],[1:4])
%    axis([0.5 4.5 1 4])
%    xticklabel_rotate([1:4],45,{{'aaa' 'AA'};{'bbb' 'AA'};{'ccc' 'BB'};{'ddd' 'BB'}})
%
% Note : you can not RE-RUN xticklabel_rotate on the same graph. 
%



% This is a modified version of xticklabel_rotate90 by Denis Gilbert
% Modifications include Text labels (in the form of cell array)
%                       Arbitrary angle rotation
%                       Output of text handles
%                       Resizing of axes and title/xlabel/ylabel positions to maintain same overall size 
%                           and keep text on plot
%                           (handles small window resizing after, but not well due to proportional placement with 
%                           fixed font size. To fix this would require a serious resize function)
%                       Uses current XTick by default
%                       Uses current XTickLabel is different from XTick values (meaning has been already defined)

% Brian FG Katz
% bfgkatz@hotmail.com
% 23-05-03
% Modified 03-11-06 after user comment
%	Allow for exisiting XTickLabel cell array
% Modified 03-03-2006 
%   Allow for labels top located (after user comment)
%   Allow case for single XTickLabelName (after user comment)
%   Reduced the degree of resizing
% Modified 11-jun-2010
%   Response to numerous suggestions on MatlabCentral to improve certain
%   errors.
% Modified 23-sep-2014
%   Allow for mutliline labels


% Other m-files required: cell2mat
% Subfunctions: none
% MAT-files required: none
%
% See also: xticklabel_rotate90, TEXT,  SET

% Based on xticklabel_rotate90
%   Author: Denis Gilbert, Ph.D., physical oceanography
%   Maurice Lamontagne Institute, Dept. of Fisheries and Oceans Canada
%   email: gilbertd@dfo-mpo.gc.ca  Web: http://www.qc.dfo-mpo.gc.ca/iml/
%   February 1998; Last revision: 24-Mar-2003

% check to see if xticklabel_rotate has already been here (no other reason for this to happen)
p=inputParser;
%define the parameters
p.addOptional('XTick',[],@isnumeric);
p.addOptional('rot',90,@isnumeric);
p.addParameter('xTickLabels',{},@iscellstr);

p.KeepUnmatched=true;

p.parse(XTick,rot,varargin{:});

tmp = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)];
textArgs = reshape(tmp',[],1)';


XTick=p.Results.XTick;
rot=p.Results.rot;
if isempty(p.Results.xTickLabels)% if no XTickLabel AND no XTick are defined use the current XTickLabel

  xTickLabels = get(gca,'XTickLabel');
  if isempty(xTickLabels)
    error('MATLAB:AutoTipTrack:xticklabel_rotate','could not find useable x tick labels');
  end
else
  xTickLabels = p.Results.xTickLabels;
end
% remove trailing spaces if exist (typical with auto generated XTickLabel)
for n = 1:length(xTickLabels),
  xTickLabels{n} = deblank(xTickLabels{n})  ;
end

% if no XTick is defined use the current XTick
if (~exist('XTick','var') || isempty(XTick)),
    XTick = get(gca,'XTick')        ; % use current XTick 
end

%Make XTick a column vector
XTick = XTick(:);

if length(XTick) ~= length(xTickLabels),
    error('MATLAB:AutoTipTrack:xticklabel_rotate', 'must have same number of elements in "XTick" and "XTickLabel"')  ;
end

%Set the Xtick locations and set XTicklabel to an empty string
set(gca,'XTick',XTick,'XTickLabel','')

% Determine the location of the labels based on the position
% of the xlabel
hxLabel = get(gca,'XLabel');  % Handle to xlabel
set(hxLabel,'Units','data');
xLabelPosition = get(hxLabel,'Position');
y = xLabelPosition(2);

%CODE below was modified following suggestions from Urs Schwarz
y=repmat(y,size(XTick,1),1);
% retrieve current axis' fontsize
%fs = get(gca,'fontsize');

% Place multi-line text approximately where tick labels belong
for n=1:length(XTick),
  hText(n) = text(XTick(n),y(n),xTickLabels{n},...
    'VerticalAlignment','top', 'UserData','xtick'); %#ok<AGROW>
end

% Rotate the text objects by ROT degrees
%set(hText,'Rotation',rot,'HorizontalAlignment','right',textArgs{:})
% Modified with modified forum comment by "Korey Y" to deal with labels at top
% Further edits added for axis position
xAxisLocation = get(gca, 'XAxisLocation');  
if strcmp(xAxisLocation,'bottom')  
    set(hText,'Rotation',rot,'HorizontalAlignment','right',textArgs{:})  
else  
    set(hText,'Rotation',rot,'HorizontalAlignment','left',textArgs{:})  
end

% Adjust the size of the axis to accomodate for longest label (like if they are text ones)
% This approach keeps the top of the graph at the same place and tries to keep xlabel at the same place
% This approach keeps the right side of the graph at the same place 

set(get(gca,'xlabel'),'units','data')           ;
    labxorigpos_data = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'ylabel'),'units','data')           ;
    labyorigpos_data = get(get(gca,'ylabel'),'position')  ;
set(get(gca,'title'),'units','data')           ;
    labtorigpos_data = get(get(gca,'title'),'position')  ;

set(gca,'units','pixel')                        ;
set(hText,'units','pixel')                      ;
set(get(gca,'xlabel'),'units','pixel')          ;
set(get(gca,'ylabel'),'units','pixel')          ;
% set(gca,'units','normalized')                        ;
% set(hText,'units','normalized')                      ;
% set(get(gca,'xlabel'),'units','normalized')          ;
% set(get(gca,'ylabel'),'units','normalized')          ;

origpos = get(gca,'position')                   ;

% textsizes = cell2mat(get(hText,'extent'))       ;
% Modified with forum comment from "Peter Pan" to deal with case when only one XTickLabelName is given. 
textsizes=getTextSizes(hText);

largest =  max(textsizes(:,3))                  ;
longest =  max(textsizes(:,4))                  ;

%laborigext = get(get(gca,'xlabel'),'extent')    ;
laborigpos = get(get(gca,'xlabel'),'position')  ;

%labyorigext = get(get(gca,'ylabel'),'extent')   ;
labyorigpos = get(get(gca,'ylabel'),'position') ;
%leftlabdist = labyorigpos(1) + labyorigext(1)   ;

% assume first entry is the farthest left
leftpos = get(hText(1),'position')              ;
leftext = get(hText(1),'extent')                ;
leftdist = leftpos(1) + leftext(1)              ;
if leftdist > 0,    leftdist = 0 ; end          % only correct for off screen problems

% botdist = origpos(2) + laborigpos(2)            ;
% newpos = [origpos(1)-leftdist longest+botdist origpos(3)+leftdist origpos(4)-longest+origpos(2)-botdist]  
%
% Modified to allow for top axis labels and to minimize axis resizing
if strcmp(xAxisLocation,'bottom')  
    newpos = [origpos(1)-(min(leftdist,labyorigpos(1)))+labyorigpos(1) ...
            origpos(2)+((longest+laborigpos(2))-get(gca,'FontSize')) ...
            origpos(3)-(min(leftdist,labyorigpos(1)))+labyorigpos(1)-largest ...
            origpos(4)-((longest+laborigpos(2))-get(gca,'FontSize'))]  ;
else
    newpos = [origpos(1)-(min(leftdist,labyorigpos(1)))+labyorigpos(1) ...
            origpos(2) ...
            origpos(3)-(min(leftdist,labyorigpos(1)))+labyorigpos(1)-largest ...
            origpos(4)-(longest)+get(gca,'FontSize')]  ;
end
set(gca,'position',newpos)                      ;

% readjust position of text labels after resize of plot
set(hText,'units','data')                       ;

% In case the x axis got rescaled during resize , we determine the 
% location of the labels after resize based on the yLim of the axis
ylim = get(gca,'YLim');
y = floor(ylim(1)-(ylim(2)-ylim(1))*0.01);
y=repmat(y,size(XTick,1),1);

%recalculate the x positions to center the text properly below the tick
set(hText,'Rotation',90)%in order to get the correct text height in data units we need to rotate the text 90 degrees
textsizes=getTextSizes(hText);
set(hText,'Rotation',rot)%rotate the text back
shiftFactor=sin((2*rot-90)/180*pi()); %the shiftFactor is calculated based on the rotation angle: at 90degree we want half a text heigth to the left, at 45 degree we want no shift and at 0 degree we want half a text height to the right 
xpos=XTick-(textsizes(:,3)./2).*shiftFactor;

for n= 1:length(hText),
    set(hText(n),'position',[xpos(n), y(n)])  ;
end

% adjust position of xlabel and ylabel
laborigpos = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'xlabel'),'position',[laborigpos(1) laborigpos(2)-longest 0])   ;

% switch to data coord and fix it all
set(get(gca,'ylabel'),'units','data')                   ;
set(get(gca,'ylabel'),'position',labyorigpos_data)      ;
set(get(gca,'title'),'position',labtorigpos_data)       ;

set(get(gca,'xlabel'),'units','data')                   ;
    labxorigpos_data_new = get(get(gca,'xlabel'),'position')  ;
set(get(gca,'xlabel'),'position',[labxorigpos_data(1) labxorigpos_data_new(2)])   ;


% Reset all units to normalized to allow future resizing
set(get(gca,'xlabel'),'units','normalized')          ;
set(get(gca,'ylabel'),'units','normalized')          ;
set(get(gca,'title'),'units','normalized')          ;
set(hText,'units','normalized')                      ;
set(gca,'units','normalized')                        ;

if nargout < 1,
    clear hText
end

function textsizes=getTextSizes(hText)
x = get( hText, 'extent' );  
if iscell( x ) == true  
    textsizes = cell2mat( x ) ;  
else  
    textsizes = x;  
end  
