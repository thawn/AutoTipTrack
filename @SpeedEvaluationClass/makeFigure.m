function S=makeFigure(S)
figure1=createBasicFigure();
S.speedFigure(figure1,3,2,[1 4],5,6);
evalName=fullfile(S.Config.Directory, S.Config.StackName);
saveas(figure1,[evalName '.pdf']);
close(figure1);
end
