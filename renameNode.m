function renameNode(node, hEvalGui, msg,success)
if success
  color='green';
  jImage = java.awt.Toolkit.getDefaultToolkit.createImage([pwd filesep 'assets' filesep 'Done_16px.png']);
else
  color='red';
  jImage = java.awt.Toolkit.getDefaultToolkit.createImage([pwd filesep 'assets' filesep 'warning_16px.png']);
end
node.setName(['<html>' char(node.getName) ' <font color="' color '">' msg '</font></html>']);
node.setIcon(jImage);
hEvalGui.mtree.reloadNode(node);
drawnow;
