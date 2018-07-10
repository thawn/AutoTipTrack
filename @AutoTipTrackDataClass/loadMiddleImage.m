function A=loadMiddleImage(A)
%first save the configuration in a temporary file
tempConf=A.Config.exportConfigStruct;
%If the stack is empty, load an image from the middle of the stack
middleFrame=ceil((A.Config.LastFrame-A.Config.FirstTFrame+1)/2);
A.Config.FirstTFrame=middleFrame;
A.Config.LastFrame=middleFrame;
A.loadFile;
%if isempty(tempConf.AcquisitionDate) && ~isempty(Q.Config.AcquisitionDate)
  tempConf.AcquisitionDate=A.Config.AcquisitionDate;
%end
A.Config.importConfigStruct(tempConf);
end
