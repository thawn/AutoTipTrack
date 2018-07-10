function [TiffInfo,MetaInfo,StackInfo, A] = stackRead(A)
%stackRead - read stack images and information (8bit and 16bit)
%   function stackRead(source) returns 2 structures
%  
%   Input:  Source - Path + Filename     
%
%   Output: [Stack,TiffInfo]
%
%   Stack   - image data
%   
%   TiffInfo - stack information, contains all relevent TIFF information (http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf)
%                                  may contain MetaMorph information (http://support.universal-imaging.com/docs/T10243.pdf)
%
%   Example: [Stack,Info] = stackRead('ZSER16.STK');
%            [Stack,Info] = stackRead('ZSER16.TIFF');
%
%   Copyright 2009 Felix Ruhnow 
%   $Revision: 1.2 $  $Date: 2009/04/16 20:10:37 
source=fullfile(A.FilePath ,A.FileName);

file = fopen(source, 'r', 'l');
%read TIFF-header

%read byte order first
order = fread(file, 1, 'uint16');
    
if (order ~= hex2dec('4949'))
    if (order == hex2dec('4D4D'))
        fclose(file);
        file = fopen(source, 'r' , 'b' );
        %read byte order first
        fread(file, 1, 'uint16');
    else
        fclose(file);
        error('No Stack File')
    end
end

%check tiff format
format = fread(file, 1, 'uint16');
if (format ~= 42)
    fclose(file);
    error('No Tiff File');
end

trackStatus(A.StatusFolder,'Reading Stack Info','',0,1,1)
D = fread(file, 1, 'uint32');
N = 0;
uic=[];
while D~=0
    N = N+1;
    fseek(file, D, 'bof');
    %number of directory entries
    B = fread(file, 1, 'uint16');
    %search tags
    for b = 0:B-1
        fseek(file, D + 2 + b * 12, 'bof');
        tag = fread(file, 1, 'uint16'); %read tag
        type = DefineType(fread(file, 1, 'uint16')); %read and define type
        count = fread(file, 1, 'uint32'); %read count
        switch tag
            case 256 %hex 100
                TiffInfo(N).ImageWidth = fread(file, 1, type); %#ok<*AGROW> %read Value
            case 257 %hex 101
                TiffInfo(N).ImageLength = fread(file, 1, type); %read Value
            case 258 %hex 102
                TiffInfo(N).BitsPerSample = fread(file, 1, type); %read Value
            case 259 %hex 103
                TiffInfo(N).Compression = fread(file, 1, type); %read Value
            case 262 %hex 106
                TiffInfo(N).PhotometricInterpretation = fread(file, 1, type); %read Value
            case 270 %hex 10E
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                TiffInfo(N).ImageDescription = ReadString(file); %read Value                
                DescriptionOffset=offset;
            case 273 %hex 111
                if count==1
                    TiffInfo(N).StripOffsets = fread(file, 1, type); %read Value
                else
                    offset = fread(file, 1, 'uint32'); %read Offset
                    fseek(file, offset, 'bof');
                    TiffInfo(N).StripOffsets = fread(file, count, type); %read Values
                end
            case 278 %hex 116
                TiffInfo(N).RowsPerStrip = fread(file, 1, type); %read Value
            case 279 %hex 117
                if count==1
                    TiffInfo(N).StripByteCounts = fread(file, 1, type); %read Value
                else
                    offset = fread(file, 1, 'uint32'); %read Offset
                    fseek(file, offset, 'bof');
                    TiffInfo(N).StripByteCounts = fread(file, count, type); %read Values
                end
            case 282 %hex 11A
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                if strcmp(type,'rational')
                    TiffInfo(N).XResolution = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %read Value
                elseif strcmp(type,'srational')
                    TiffInfo(N).XResolution = fread(file, 1, 'int32')/fread(file, 1, 'int32'); %read Value
                else
                    TiffInfo(N).XResolution = fread(file, 1, type); %read Value
                end
            case 283 %hex 11B
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                if strcmp(type,'rational')
                    TiffInfo(N).YResolution = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %read Value
                elseif strcmp(type,'srational')
                    TiffInfo(N).YResolution = fread(file, 1, 'int32')/fread(file, 1, 'int32'); %read Value
                else
                    TiffInfo(N).YResolution = fread(file, 1, type); %read Value
                end
            case 296 %hex 128
                TiffInfo(N).ResolutionUnit = fread(file, 1, type); %read Value
            %end for TIFF files
            
            %read private tags - MetaMorph UIC tags
            case 33628 %hex 835C - UIC1 tag
                uic(1).count=count; %store count
                uic(1).type=type; %store type
                uic(1).offset=fread(file, 1, 'uint32'); %read & store offset
            case 33629 %hex 835D - UIC2 tag
                uic(2).count=count; %store count
                uic(2).type=type; %store type
                uic(2).offset=fread(file, 1, 'uint32'); %read & store offset
             case 33630 %hex 835E - UIC3 tag
                uic(3).count=count; %store count
                uic(3).type=type; %store type
                uic(3).offset=fread(file, 1, 'uint32'); %read & store offset       
            case 33631 %hex 835F - UIC4 tag        
                uic(4).count=count; %store count
                uic(4).type=type; %store type
                uic(4).offset=fread(file, 1, 'uint32'); %read & store offset       
        end
    end
    fseek(file, D + 2 + B * 12, 'bof');
    D = fread (file, 1, 'uint32');
end

trackStatus(A.StatusFolder,'Reading Stack Info','',1,1,1);

if ~isempty(uic) %if file is MetaMorph stack
    MetaInfo=ReadUIC(file,uic);
    if isfield(MetaInfo,'ZDistance');
        N = length(MetaInfo.ZDistance);
    else
        N = 1;
    end
    stripsPerImage = length(TiffInfo.StripOffsets);
    planeOffset = (0:N-1) * (TiffInfo.StripOffsets(stripsPerImage) +...
                             TiffInfo.StripByteCounts(stripsPerImage) - ...
                             TiffInfo.StripOffsets(1)) + TiffInfo.StripOffsets(1);
    ImageWidth = ones(1,N)*TiffInfo.ImageWidth;
    ImageLength = ones(1,N)*TiffInfo.ImageLength;
    BitsPerSample = ones(1,N)*TiffInfo.BitsPerSample;    
    %read ImageDescription for all planes
    fseek(file, DescriptionOffset, 'bof');
    MetaInfo.ImageDescription=[];
    for n=1:N
        MetaInfo.ImageDescription{n} = ReadString(file);
    end
else %if file is multilayer TIFF
    planeOffset = [TiffInfo.StripOffsets];
    ImageWidth = [TiffInfo.ImageWidth];
    ImageLength = [TiffInfo.ImageLength];
    BitsPerSample = [TiffInfo.BitsPerSample];
    MetaInfo=[];
end

x = max(ImageWidth(1,:));
y = max(ImageLength(1,:));
if max(BitsPerSample(1,:))==8
    datatype = 'uint8';
else
    datatype = 'uint16';
end
StackInfo = struct( 'MaxImage', zeros(y,x,2,datatype), 'AverageImage', zeros(y,x),...
                    'PixMin', zeros(1,N), 'PixMax', zeros(1,N),...
                    'PixRedMin', zeros(1,N), 'PixRedMax',zeros(1,N),...
                    'PixGreenMin', zeros(1,N), 'PixGreenMax', zeros(1,N),...
                    'MeanStack', zeros(1,N), 'MeanRed', zeros(1,N), 'MeanGreen',zeros(1,N) );
%only read the part of the stack that we are actually going to use
if (A.Config.LastFrame>1)
  if A.Config.LastFrame > N %make sure that lastFrame is smaller or equal to the stack length
    A.Config.LastFrame = N;
  end
  N=A.Config.LastFrame-A.Config.FirstTFrame+1;
  planeOffset=planeOffset(:,A.Config.FirstTFrame:A.Config.LastFrame);
end
A.Stack = cell(1,N); 
frequency=ceil(N/5);
for n = 1:N
    trackStatus(A.StatusFolder,'Loading Stack','',n-1,N,frequency);
    x = ImageWidth(1,n);
    y = ImageLength(1,n);
    if BitsPerSample(1,n) == 8
        type = '*uint8';
    elseif BitsPerSample(1,n) == 16
        type = '*uint16';
    else
        fclose(file);
        error('Only 8bit or 16bit Stacks supported');
    end            
    fseek(file, planeOffset(1,n), 'bof');
    try
        Image = reshape(fread(file,x*y,type),x,y)';
        StackInfo.PixMin(n)=min(min(Image(:,:)));
        StackInfo.PixMax(n)=max(max(Image(:,:)));
        StackInfo.PixRedMin(n)=min(min(Image(:,1:fix(x/2))));
        StackInfo.PixRedMax(n)=max(max(Image(:,1:fix(x/2))));
        StackInfo.PixGreenMin(n)=min(min(Image(:,fix(x/2)+1:x)));
        StackInfo.PixGreenMax(n)=max(max(Image(:,fix(x/2)+1:x)));
        StackInfo.MeanStack(n)=mean2(Image(:,:));
        StackInfo.MeanRed(n)=mean2(Image(:,1:fix(x/2)));
        StackInfo.MeanGreen(n)=mean2(Image(:,fix(x/2)+1:x));
        StackInfo.MaxImage(:,:,2)=Image;
        StackInfo.MaxImage(:,:,1)=max(StackInfo.MaxImage,[],3);
        StackInfo.AverageImage=StackInfo.AverageImage+double(Image)*1/N;
        A.Stack{n} = Image;        
    catch   
        trackStatus(A.StatusFolder,'Loading Stack','',N,N,frequency);
        warning('MATLAB:outOfMemory','Out of memory - read %4.0f of %4.0f frames',n-1,N);
        break
    end
end
trackStatus(A.StatusFolder,'Loading Stack','',N,N,1);
StackInfo.MaxImage(:,:,2)=[];
if strcmp(datatype,'uint8')
    StackInfo.AverageImage=uint8(round(StackInfo.AverageImage));
elseif strcmp(datatype,'uint16')
    StackInfo.AverageImage=uint16(round(StackInfo.AverageImage));
end
fclose(file);

function [date_string] = JulianToYMD(julian)

matlabDate=datetime(julian+0.5,'ConvertFrom','juliandate');
date_string=sprintf('%02d-%02d-%04d',matlabDate.Month,matlabDate.Day,matlabDate.Year);

function [time_string] = format_time(creation_time)
hour=fix(creation_time/(60*60*1000));
min=fix((creation_time-hour*(60*60*1000) ) / (60*1000));
sec=fix((creation_time-hour*(60*60*1000)-min*(60*1000) ) / (1000));
msec=(creation_time-hour*(60*60*1000)-min*(60*1000) -sec*(1000)) ;
time_string=sprintf('%02d:%02d:%02d:%03d',hour,min,sec,msec);

function type=DefineType(num)
switch (num)
    case 1
        type='uint8';
    case 2
        type='char';
    case 3
        type='uint16';
    case 4
        type='uint32';
    case 5
        type='rational';       
    case 6
        type='int8';
    case 8
        type='int16';
    case 9
        type='int32';
    case 10
        type='srational';  
    case 11
        type='float32';
    case 12
        type='double';
end

function MetaInfo=ReadUIC(file,uic)

if length(uic)>1
    %read UIC2
    fseek(file, uic(2).offset, 'bof'); %set uic2 offset
    for n = 1:uic(2).count
        nom = fread(file, 1, 'uint32'); %read nominator
        denom = fread(file, 1, 'uint32'); %read denominator 
        MetaInfo.ZDistance(n) = nom/denom;
        MetaInfo.CreationDate{n} = JulianToYMD(fread(file, 1, 'uint32'));
        MetaInfo.CreationTime(n) = fread(file, 1, 'uint32');
        MetaInfo.CreationTimeStr{n} = format_time(MetaInfo.CreationTime(n));
        MetaInfo.ModificationDate(n) = fread(file, 1, 'uint32');
        MetaInfo.ModificationTime(n) = fread(file, 1, 'uint32');
    end
    
    if length(uic)>2

        %read UIC3
        fseek(file, uic(3).offset, 'bof'); %set uic3 offset
        for n = 1:uic(3).count
            MetaInfo.Wavelength(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');    
        end
        
        if length(uic)>3
            %read UIC4
            fseek(file, uic(4).offset, 'bof'); %set uic4 offset
            tagID = fread(file, 1, 'uint16');
            while (tagID~=0)
                switch tagID
                    case 28
                        for n = 1:uic(4).count
                            MetaInfo.StagePositionX(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %calculate Stage Position in X Direction
                            MetaInfo.StagePositionX(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %calculate Stage Position in X Direction
                        end
                    case 29
                        for n = 1:uic(4).count
                            MetaInfo.CameraChipOffsetX(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %calculate Camera Chip Offset in X Direction
                            MetaInfo.CameraChipOffsetY(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32'); %calculate Camera Chip Offset in Y Direction
                        end
                    case 37
                        for n = 1:uic(4).count
                            I = fread(file, 1, 'uint32');
                            MetaInfo.StageLabel{n} = fread(file, I, '*char'); 
                        end
                    case 40
                        for n = 1:uic(4).count
                            MetaInfo.AbsoluteZ(n) = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
                        end   
                    case 41
                        for n = 1:uic(4).count
                            MetaInfo.AbsoluteZValid(n) = fread(file, 1, 'uint32');
                        end      
                    case 46
                        for n = 1:uic(4).count
                            MetaInfo.CameraBinX(n) = fread(file, 1, 'uint32');
                            MetaInfo.CameraBinY(n) = fread(file, 1, 'uint32');
                        end                           
                    otherwise
                        fread(file, 2*uic(4).count, 'uint32');
                end
                tagID = fread(file, 1, 'uint16');
            end
        end
    end
end

%read UIC1
c_bytes = 0; %correction bytes if type/offset of tag is not LONG (uint32)
if strcmp(uic(1).type,'uint32')
    for n = 0:uic(1).count-1
        fseek(file, uic(1).offset + n*8 - c_bytes, 'bof'); %set uic1 offset
        tagID = fread(file, 1, 'uint32'); % read TagID
        switch tagID
            case 0
                MetaInfo.AutoScale = fread(file, 1, 'uint32'); 
            case 1
                MetaInfo.MinScale = fread(file, 1, 'uint32'); 
            case 2
                MetaInfo.MaxScale = fread(file, 1, 'uint32'); 
            case 3
                MetaInfo.SpatialCalibration = fread(file, 1, 'uint32');
            case 4
                offset = fread(file, 1, 'uint32'); 
                fseek(file, offset, 'bof');
                MetaInfo.XCalibration = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 5
                offset = fread(file, 1, 'uint32');
                fseek(file, offset, 'bof');
                MetaInfo.YCalibration = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 6
                offset = fread(file, 1, 'uint32');
                fseek(file, offset, 'bof');
                I = fread(file, 1, 'uint');
                MetaInfo.CalibrationUnits = fread(file, I, '*char')';
            case 7
                offset = fread(file, 1, 'uint'); 
                fseek(file, offset, 'bof');
                I = fread(file, 1, 'uint');
                MetaInfo.Name = fread(file, I, '*char')';
            case 8
                MetaInfo.ThreshState = fread(file, 1, 'uint32'); 
            case 9
                MetaInfo.ThreshStateRed = fread(file, 1, 'uint32'); 
            case 11
                MetaInfo.ThreshStateGreen = fread(file, 1, 'uint32'); 
            case 12
                MetaInfo.ThreshStateBlue = fread(file, 1, 'uint32'); 
            case 13
                MetaInfo.ThreshStateLo = fread(file, 1, 'uint32');
            case 14
                MetaInfo.ThreshStateHi = fread(file, 1, 'uint32'); 
            case 15
                MetaInfo.Zoom = fread(file, 1, 'uint32');
            case 16
                offset = fread(file, 1, 'uint32'); 
                fseek(file, offset, 'bof');
                MetaInfo.CreateTime= [JulianToYMD(fread(file, 1, 'uint32')) format_time(fread(file, 1, 'uint32'))];
            case 17
                offset = fread(file, 1, 'uint32');
                fseek(file, offset, 'bof');
                MetaInfo.LastSavedTime= sprintf('%s %s',JulianToYMD(fread(file, 1, 'uint32')),format_time(fread(file, 1, 'uint32')));
            case 18
                MetaInfo.currentBuffer = fread(file, 1, 'uint32'); 
            case 19
                MetaInfo.grayFit = fread(file, 1, 'uint32'); 
            case 20
                MetaInfo.grayPointCount = fread(file, 1, 'uint32');
            case 21
                offset = fread(file, 1, 'uint32');
                fseek(file, offset, 'bof');
                MetaInfo.grayX = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 22
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.grayY = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 23
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.grayMin = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 24
                offset = fread(file, 1, 'uint'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.grayMax = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 25
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                I = fread(file, 1, 'uint32');
                MetaInfo.grayUnitName = fread(file, I, '*char')';
            case 26
                MetaInfo.StandartLUT = fread(file, 1, 'uint32'); %read Value
            case 30
                MetaInfo.OverlayMask = fread(file, 1, 'uint32'); %read Value
            case 31
                MetaInfo.OverlayCompress = fread(file, 1, 'uint32'); %read Value
            case 32
                MetaInfo.Overlay = fread(file, 1, 'uint32'); %read Value
            case 33
                MetaInfo.SpecialOverlayMask = fread(file, 1, 'uint32'); %read Value
            case 34
                MetaInfo.SpecialOverlayCompress = fread(file, 1, 'uint32'); %read Value
            case 35
                MetaInfo.SpecialOverlay = fread(file, 1, 'uint32'); %read Value
            case 36
                MetaInfo.ImageProperty = fread(file, 1, 'uint32'); %read Value
            case 38
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.AutoScaleLoInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 39
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.AutoScaleHiInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');
            case 42
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.Gamma = fread(file, 1, 'uint');
            case 43
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.GammaRed = fread(file, 1, 'uint32');
            case 44
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.GammaGreen = fread(file, 1, 'uint32');
            case 45
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.GammaBlue = fread(file, 1, 'uint32');
            case 47
                MetaInfo.NewLUT = fread(file, 1, 'uint32'); %read Value                
            case 50
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.UserLutTable =  reshape(fread(file, 3*256, 'uint8'),256,3);
            case 51
                MetaInfo.RedAutoScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 52
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.RedAutoScaleLoInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                
            case 53
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.RedAutoScaleHiInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                                
            case 54
                MetaInfo.RedMinScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 55
                MetaInfo.RedMaxScaleInfo = fread(file, 1, 'uint32'); %read Value           
            case 56
                MetaInfo.GreenAutoScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 57
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.GreenAutoScaleLoInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                
            case 58
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.GreenAutoScaleHiInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                                
            case 59
                MetaInfo.GreenMinScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 60
                MetaInfo.GreenMaxScaleInfo = fread(file, 1, 'uint32'); %read Value                           
            case 61
                MetaInfo.BlueAutoScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 62
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.BlueAutoScaleLoInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                
            case 63
                offset = fread(file, 1, 'uint32'); %read Offset
                fseek(file, offset, 'bof');
                MetaInfo.BlueAutoScaleHiInfo = fread(file, 1, 'uint32')/fread(file, 1, 'uint32');                                
            case 64
                MetaInfo.BlueMinScaleInfo = fread(file, 1, 'uint32'); %read Value  
            case 65
                MetaInfo.BlueMaxScaleInfo = fread(file, 1, 'uint32'); %read Value           
%           case 66 OverlayPlaneColor missing
        end
    end
end

function str=ReadString(file)
c=fread(file,1,'char');
str='';
while c~=0
    str=[str c];
    c=fread(file,1,'char');
end
