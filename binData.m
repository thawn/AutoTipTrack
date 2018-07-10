function [binnedX, binnedY]=binData(xData,yData,varargin)
%% Syntax
% [binnedX, binnedY]=binData(xData,yData,'binNumber',number)
% [binnedX, binnedY]=binData(xData,yData,'binInterval',interval)
%
% Description
% bins x and y data
%
% Parameters
% xData: the data along the x-axis. Either a numerical array or a datetime
% array. xData is sorted before binning and yData is rearranged accordingly
% before binning.
% yData: the data along the y-axis. A Cell array of numbers.
%
% optional Key-value pairs:
% 'binNumber': numeric, number of columns from xData and yData that should
% be combined. The length of xData and yData must be an integer multiple of
% binNumber
% 'binInterval': numeric, interval along xData that should be combined.
% Starting from the first value in xData, the function checks how many
% values of xData fall within the interval and calculates the mean of those
% xData and puts it into binnedX. The corresponding columns of yData are
% combined into the corresponding column of binnedY
% 'scatter': the data is prepared for a scatter plot. I.e. it is not
% binned, but for each y value a corresponding x value is generated and
% binnedX and binnedY are made to contain an equal number of elements.
%
% Output
% binnedX: vector of mean of binned x values (datetime is converted to datenum)
% binnedY: matrix of binned y values the number of columns corresponds to
% the length of binnedX, the number of rows corresponds to the maximum
% number of values in each binned Y dataset. The rest of the values are
% filled with NaN.
%
% Examples
% xData=[1; 2; 3; 4; 5; 6]
% yData={[1 2];[3 4 5]; [5 6]; [7 8]; [9 10]; [11 12]}
%
% [binnedX, binnedY]=binData(xData,yData,'binNumber',2)
% binnedX =
%     1.5000    3.5000    5.5000
% binnedY =
%      1     5     9
%      2     6    10
%      3     7    11
%      4     8    12
%      5   NaN   NaN
%
% [binnedX, binnedY]=binData(xData,yData,'binInterval',3)
% binnedX =
%      2
%      5
% binnedY =
%      1     7
%      2     8
%      3     9
%      4    10
%      5    11
%      5    12
%      6   NaN
% See also MAKEPLOT,MAKEMANYPLOTS.

p=inputParser;
p.addRequired('xData',@(x) isdatetime(x) || isnumeric(x));
p.addRequired('yData',@iscell);
p.addParameter('binNumber',[],@isnumeric);
p.addParameter('binInterval',[],@isnumeric);
p.addParameter('scatter',false,@islogical);

p.parse(xData,yData,varargin{:});

allY=cellfun(@reduce,yData,'UniformOutput',false);
if isdatetime(xData)
  binnedX=datenum(xData);
  binnedX=(binnedX-min(binnedX))*24; %convert datenum to hours
else
  binnedX=xData;
end
[binnedX,I]=sort(binnedX);
allY=allY(I);
l=length(allY);

if p.Results.scatter
  AllLengths=cellfun('length',allY);
  TotLen=sum(AllLengths);
  NewY=NaN(1,TotLen);
  NewX=NaN(1,TotLen);
  C=1;
  for n=1:l
    NewY(C:C-1+AllLengths(n))=allY{n};
    NewX(C:C-1+AllLengths(n))=binnedX(n);
    C=C+AllLengths(n);
  end
  binnedX=NewX;
  binnedY=NewY;
elseif ~isempty(p.Results.binNumber)
  if mod(l,p.Results.binNumber)>0
    warning('MATLAB:AutoTipTrack:MakeBoxPlot:wrongBinsize','The length:, %d has to be a multiple of the binning size: %d. Continuing without binning.',l,p.Results.binning);
  else
    bin=p.Results.binNumber;
    newL=l/bin;
    tmpS=cell(1,newL);
    tmpT=NaN(1,newL);
    for n=1:newL
      tmpS{n}=cell2mat(allY(n*bin-bin+1:n*bin));
      tmpT(n)=mean(binnedX(n*bin-bin+1:n*bin));
    end
    allY=tmpS;
    binnedX=tmpT;
  end
elseif ~isempty(p.Results.binInterval)
  interval=p.Results.binInterval;
  current=1;
  offset=0;
  while current<l
    while current+offset+1<=l && binnedX(current+offset+1)-binnedX(current)<interval
      offset=offset+1;
    end
    if offset>0
      binnedX(current)=mean(binnedX(current:current+offset));
      binnedX(current+1:current+offset)=[];
      allY{current}=vertcat(allY{current:current+offset});
      allY(current+1:current+offset)=[];
      offset=0;
    end
    current=current+1;
    l=length(allY);
  end
end
if ~p.Results.scatter
  maxLen=max(cellfun('length',allY));
  binnedY=NaN(maxLen,length(allY));
  for n=1:length(allY)
    binnedY(1:length(allY{n}),n)=allY{n};
  end
end
end

function x=reduce(x)
  x=x(:);
  x(isnan(x))=[];
end

