function string=ellipsize(string,maxLength)
if length(string)>maxLength
  [~,string,~]=fileparts(string);
  if length(string)>maxLength
    halfLength=floor(maxLength/2-1);
    string=[string(1:halfLength),repmat('.',1,maxLength-(2*halfLength)),string(end-halfLength+1:end)];
  end
end
