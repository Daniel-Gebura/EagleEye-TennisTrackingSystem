function image = unityLink(TCP_Handle,pose)
% x,y,z,yaw[z],pitch[y],roll[x]

width  = 752;
height = 480;

x = pose(1);
y = pose(2);
z = pose(3);
yaw = pose(4);
pitch = pose(5);
roll = pose(6);
obj = pose(7);

%Set Position
write(TCP_Handle,single([width,height,x,y,z,yaw,pitch,roll,obj]));

%Get image data
data = read(TCP_Handle,width*height*3);

temp = reshape(data,[3,width*height]);
image = imrotate(reshape(temp',[width,height,3]),90);