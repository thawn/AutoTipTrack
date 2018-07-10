function pairs=findInterjectingFitboxes(object_rects)
interjecting=rectint(object_rects,object_rects);
[~,c]=find(interjecting);
numObj=length(object_rects(:,1));
if length(c)>numObj
  c_count=histc(c,1:numObj);
  pairs=zeros(sum(c_count-1),2);
  inters=find(c_count>1);
  count=1;
  for i=1:length(inters)
    ps=find(interjecting(inters(i),:));
    for n=1:length(ps)-1
      pairs(count,:)=ps(n:n+1);
      count=count+1;
    end
  end
  pairs=unique(pairs,'rows');
else
  pairs=zeros(0,2);
end


