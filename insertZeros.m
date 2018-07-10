function concentrations=InsertZeros(concentrations, labels)
pos=strfind(labels,'ATP');
positions=find(not(cellfun('isempty', pos)));
for pos=positions
  concentrations(pos+1:end+1)=concentrations(pos:end);
  concentrations(pos)=0;
end