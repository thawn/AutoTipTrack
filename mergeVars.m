function Merged = mergeVars(Var1, Var2, varargin)
p = inputParser;
p.addParameter('MergeDimensions', {}, @iscell);
p.addParameter('InputName', inputname(1), @ischar);
p.addParameter('HandleStrings', 'overwrite', @ischar);
p.addParameter('Debug', false, @isnumeric);
p.parse(varargin{:});
MergeDimensions = p.Results.MergeDimensions;
InputName1 = p.Results.InputName;
ClassName = class(Var1);
Merged = feval([ClassName '.empty']);
if isa(Var2, ClassName)
  if strcmp(ClassName, class(Var2))
    if ~isempty(MergeDimensions) && any(strcmp(MergeDimensions(:, 1), InputName1))
      MergeDim = MergeDimensions{find(strcmp(MergeDimensions(:, 1), InputName1), 1 ), 2};
    else
      MergeDim = 2;
    end
    if MergeDim == 0;
      if strcmpi(p.Results.HandleStrings,'overwrite')
        Merged = Var2;
      else
        Merged = {Var1; Var2};
      end
    else
      switch ClassName
        case 'char'
          Merged = Var2;
        case {'cell', 'struct', 'double', 'single', 'logical', 'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'}
          if ~iscell(Var1) && isscalar(Var1) && isscalar(Var2)
            if isstruct(Var1)
              FieldNames = unique([fieldnames(Var1); fieldnames(Var2)]);
              Merged = struct();
              for n = 1:length(FieldNames)
                if isfield(Var1, FieldNames{n})
                  if isfield(Var2, FieldNames{n})
                    Merged.(FieldNames{n}) = mergeVars(Var1.(FieldNames{n}), Var2.(FieldNames{n}), 'MergeDimensions', MergeDimensions, 'InputName', FieldNames{n}, 'HandleStrings', p.Results.HandleStrings, 'Debug', p.Results.Debug);
                  else
                    Merged.(FieldNames{n}) = Var1.(FieldNames{n});
                  end
                elseif isfield(Var2, FieldNames{n})
                  Merged.(FieldNames{n}) = Var2.(FieldNames{n});
                end
              end
            elseif islogical(Var1)
              Merged = Var1 || Var2;
            else
              Merged = Var1 + Var2;
            end
          else
            Size1 = size(Var1);
            Size2 = size(Var2);
            if length(Size1) == length(Size2) && sum(Size1) > 1 && sum(Size2) > 1
              NEqualSize = Size1 ~= Size2;
              if sum(NEqualSize) == 1
                MergeDim = find(NEqualSize, 1 );
              else
                if ~isempty(MergeDimensions) && any(strcmp(MergeDimensions(:, 1), InputName1))
                  MergeDim = MergeDimensions{find(strcmp(MergeDimensions(:, 1), InputName1), 1 ), 2};
                else
                  MergeDim = find(NEqualSize, 1 );
                  if isempty(MergeDim) || NEqualSize(2)
                    MergeDim = 2; %2 is the default dimension along which we like to merge
                  end
                  if p.Results.Debug > 0
                    warning('MATLAB:AuotTipTrack:DataEvaluationClass:mergeVars',...
                      'Found several dimensions I would like to merge for variable %s and no MergeDimension was defined. Merging along Dimension: %d.\n',InputName1, MergeDim);
                  end
                end
                MergeSize = max([Size1; Size2]);
                Var1Size = MergeSize;
                if MergeDim > 0
                  Var1Size(MergeDim) = Size1(MergeDim);
                  Var2Size = MergeSize;
                  Var2Size(MergeDim) = Size2(MergeDim);
                  if isstruct(Var1)
                    PadVal = 'replicate';
                  else
                    PadVal = NaN;
                  end
                  if any(Var1Size > Size1)
                    if iscell(Var1)
                      Var1Edge = num2cell(Var1Size);
                      Var1(Var1Edge{:}) = {[]};
                    else
                      SizeDiff = Var1Size - Size1;
                      SizeDiff(SizeDiff < 0) = 0;
                      Var1 = padarray(Var1, SizeDiff , PadVal, 'post');
                    end
                  end
                  if any(Var2Size > Size2)
                    if iscell(Var2)
                      Var2Edge = num2cell(Var2Size);
                      Var2(Var2Edge{:}) = {[]};
                    else
                      SizeDiff = Var2Size - Size2;
                      SizeDiff(SizeDiff < 0) = 0;
                      Var2 = padarray(Var2, SizeDiff , PadVal, 'post');
                    end
                  end
                end
              end
              if MergeDim == 0
                Merged = Var2;
              else
                Merged = cat(MergeDim, Var1, Var2);
              end
            else
              if sum(Size2) < 2
                Merged = Var1;
              elseif sum(Size1) < 2
                Merged = Var2;
              else
                warning('MATLAB:AuotTipTrack:DataEvaluationClass:mergeVars',...
                  'Could not merge variable: %s. Number of dimensions differs.', InputName1);
              end
            end
          end
        case 'ConfigClass'
          Merged = Var1.importConfigStruct(Var2.exportConfigStruct);
        otherwise
          Merged = Var1.merge(Var2);
      end
    end
  end
elseif isempty(Var2)
  Merged = Var1;
elseif isempty(Var1)
  Merged = Var2;
elseif ~strcmpi(p.Results.HandleStrings,'overwrite') && ((ischar(Var1) && iscell(Var2)) || (iscell(Var1) && ischar(Var2)))
  if ischar(Var1)
    Merged = [{Var1}; Var2];
  else
    Merged = [Var1; {Var2}];
  end
else
  warning('MATLAB:AuotTipTrack:DataEvaluationClass:mergeVars',...
    'Could not merge different datatypes for variable %s. Datatypes: %s and %s.', InputName1, ClassName, class(Var2));
end
