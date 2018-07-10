function ViewStack( stack )
%UNTITLED1 Summary of this function goes here
%  Detailed explanation goes here
  size(stack)
  for i = 1:30%size(stack,4)
    imshow( stack(:,:,i), [] );
    title(i);
    pause(0.5)
  end
end