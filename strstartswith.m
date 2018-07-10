function b = strstartswith(s, pat) %#ok<DEFNU>
sl = length(s);
pl = length(pat);

b = (sl >= pl && strcmpi(s(1:pl), pat)) || isempty(pat);
