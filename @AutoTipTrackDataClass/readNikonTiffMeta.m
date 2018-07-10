function [tempCalib, Times,Date]=readNikonTiffMeta(TiffMeta, tempCalib, UseChannel)
XMLMeta=parseXMLString(strrep(TiffMeta(1).ImageDescription,'UTF-8','Windows-1252'));
numPlanes=0;
numChannels=0;
Date=datetime.empty;
for j=1:length(XMLMeta.Children)
  if isfield(XMLMeta.Children(j),'Name') && ...
      strcmp(XMLMeta.Children(j).Name,'Image') && ...
      isfield(XMLMeta.Children(j),'Children') &&...
      isfield(XMLMeta.Children(j).Children,'Name') && ...
      isfield(XMLMeta.Children(j).Children,'Attributes')
    for i=1:length(XMLMeta.Children(j).Children)
      if strcmp(XMLMeta.Children(j).Children(i).Name,'AcquisitionDate') && ...
          isfield(XMLMeta.Children(j).Children(i).Children, 'Data') && ...
          ischar(XMLMeta.Children(j).Children(i).Children.Data)
        for k=1:length(XMLMeta.Children(j).Children(i).Children)
          if strfind(XMLMeta.Children(j).Children(i).Children(k).Data,':')
            Date=datetime(XMLMeta.Children(j).Children(i).Children(k).Data,'InputFormat','yyyy-MM-dd''T''HH:mm:ss');
          end
        end
      elseif strcmp(XMLMeta.Children(j).Children(i).Name,'Pixels') && ...
          ~isempty(XMLMeta.Children(j).Children(i).Attributes) && ...
          isfield(XMLMeta.Children(j).Children(i).Attributes, 'Name') && ...
          isfield(XMLMeta.Children(j).Children(i).Attributes, 'Value')
        for k=1:length(XMLMeta.Children(j).Children(i).Attributes)
          if strcmp(XMLMeta.Children(j).Children(i).Attributes(k).Name,'PhysicalSizeX')
            tempCalib.x=str2double(XMLMeta.Children(j).Children(i).Attributes(k).Value);
            tempCalib.unit='um';
          elseif strcmp(XMLMeta.Children(j).Children(i).Attributes(k).Name,'PhysicalSizeY')
            tempCalib.y=str2double(XMLMeta.Children(j).Children(i).Attributes(k).Value);
          elseif strcmp(XMLMeta.Children(j).Children(i).Attributes(k).Name,'SizeT')
            numPlanes=str2double(XMLMeta.Children(j).Children(i).Attributes(k).Value);
          elseif strcmp(XMLMeta.Children(j).Children(i).Attributes(k).Name,'SizeC')
            numChannels=str2double(XMLMeta.Children(j).Children(i).Attributes(k).Value);
          end
        end
        if numPlanes>0 && isfield(XMLMeta.Children(j).Children, 'Children') && ...
            isfield(XMLMeta.Children(j).Children(i).Children, 'Name') && ...
            isfield(XMLMeta.Children(j).Children(i).Children, 'Attributes')
          Times=nan(1,numPlanes);
          for k=1:length(XMLMeta.Children(j).Children(i).Children)
            if strcmp(XMLMeta.Children(j).Children(i).Children(k).Name,'Plane') && ...
                isfield(XMLMeta.Children(j).Children(i).Children(k).Attributes, 'Name') && ...
                isfield(XMLMeta.Children(j).Children(i).Children(k).Attributes, 'Value')
              PlaneInfo=struct('time',[],'channel',[],'frame',[]);
              for  m=1:length(XMLMeta.Children(j).Children(i).Children(k).Attributes)
                if strcmp(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Name,'DeltaT')
                  PlaneInfo.time=str2double(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Value);
                elseif strcmp(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Name,'TheC')
                  PlaneInfo.channel=str2double(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Value);
                elseif strcmp(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Name,'TheT')
                  PlaneInfo.frame=str2double(XMLMeta.Children(j).Children(i).Children(k).Attributes(m).Value)+1;
                end
              end
              if numChannels>1 && PlaneInfo.channel~=UseChannel
                continue;
              end
              Times(PlaneInfo.frame)=PlaneInfo.time/1000;
            end
          end
          Times(isnan(Times))=[];
        end
      end
    end
  end
end
end
