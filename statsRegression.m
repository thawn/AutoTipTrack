function [slope,CI]=statsRegression(Stats,varargin)
p=inputParser;
p.addParameter('Param','Speeds',@isstr);
p.addParameter('NumConc',0,@isnumeric);
p.addParameter('LowerCutoff',0,@isnumeric);
p.parse(varargin{:});
Param=p.Results.Param;

if strcmp(Param,'NumMT')
  X=Stats.Stats.(Param).binned_X';
  Y=Stats.Stats.(Param).binned_Y';
else
  NumCols=size(Stats.Stats.(Param).binned_Y,2);
  YCell=cell(1,NumCols);
  for n=1:NumCols
    YCell{n}=Stats.Stats.(Param).binned_Y(:,n);
  end
  [X, Y]=binData(Stats.Stats.(Param).binned_X,YCell,'binInterval',1,'scatter',true);
end
if p.Results.NumConc>0
  Cutoff=Stats.Stats.Speeds.binned_X(p.Results.NumConc);
  UsedValues=(X<=Cutoff);
  X=X(UsedValues);
  Y=Y(UsedValues);
end
Y(X<p.Results.LowerCutoff)=[];
X(X<p.Results.LowerCutoff)=[];
[p,S]=polyfit(X,Y,1);
slope=p(1);
CI=polyparci(p,S);
CI=CI(1)-slope;