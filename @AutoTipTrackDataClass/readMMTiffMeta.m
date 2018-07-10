function [tempCalib,Times]=readMMTiffMeta(TiffMeta, tempCalib)
Times=zeros(1,length(TiffMeta));
CalibX = NaN(1,length(TiffMeta));
CalibY = NaN(1,length(TiffMeta));
CalibUnit = cell(1,length(TiffMeta));
parfor n=1:length(TiffMeta)
  XMLMeta=parseXMLString(['<?xml version="1.0" encoding="Windows-1252"?>' strrep(TiffMeta(n).ImageDescription,'> <','><')]);
  for j=1:length(XMLMeta.Children)
    if isfield(XMLMeta.Children(j),'Name') && ...
        strcmp(XMLMeta.Children(j).Name,'PlaneInfo')
      for i=1:length(XMLMeta.Children(j).Children)
        if isfield(XMLMeta.Children(j).Children(i),'Attributes') && ...
            length(XMLMeta.Children(j).Children(i).Attributes)>2 && ...
            isfield(XMLMeta.Children(j).Children(i).Attributes(1),'Value')
          switch(XMLMeta.Children(j).Children(i).Attributes(1).Value)
            case 'spatial-calibration-x'
              CalibX(n)=str2double(XMLMeta.Children(j).Children(i).Attributes(3).Value);
            case 'spatial-calibration-y'
              CalibY(n)=str2double(XMLMeta.Children(j).Children(i).Attributes(3).Value);
            case 'spatial-calibration-units'
              CalibUnit{n}=XMLMeta.Children(j).Children(i).Attributes(3).Value;
            case 'acquisition-time-local'
              Times(n)=datenum(XMLMeta.Children(j).Children(i).Attributes(3).Value,'yyyymmdd HH:MM:SS.FFF')*(3600*24);
          end
        end
      end
    end
  end
end
CalibX(isnan(CalibX)) = [];
CalibY(isnan(CalibY)) = [];
Lengths = cellfun(@length,CalibUnit);
CalibUnit(Lengths < 1) = [];
if ~isempty(CalibX) && ~isempty(CalibY) && ~isempty(CalibUnit)
  tempCalib.x = CalibX(end);
  tempCalib.y = CalibY(end);
  tempCalib.unit = CalibUnit{end};
end
end
