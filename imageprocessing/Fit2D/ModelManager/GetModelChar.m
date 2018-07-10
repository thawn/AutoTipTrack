function model_char = GetModelChar(model)
global MolModels;
if isempty(MolModels)
    pathstr = fileparts( mfilename('fullpath') );
    filestr = [pathstr filesep 'MolModels.mat'];
    load(filestr,'MolModels');
end
k=find(strcmp(model,MolModels(:).model)==1);
if isempty(k)
    model_char=[];
else
    model_char=MolModels(k).char;
end
