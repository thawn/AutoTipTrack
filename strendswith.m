function b = strendswith(s, pat)
sl = length(s);
pl = length(pat);

b = (sl >= pl && strcmpi(s(sl-pl+1:sl), pat)) || isempty(pat);
