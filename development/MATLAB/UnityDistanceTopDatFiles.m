clc;
clear all;
close all;

%Include source files in path
addpath(genpath('../src'))

%Initialization Parameters
server_ip   = '129.21.91.42';     %IP address of the Unity Server
server_port = 55001;           %Server Port of the Unity Sever

client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");

%Load in ball position function
data = load('datFiles/serve1.dat');

for i = 1 : 5 : 2000
    % Moves tennis ball to associated position
    x = data(i, 1);
    y = data(i, 2);
    z = data(i, 3);
    pitch = 90;
    roll = 0;
    yaw = 90;
    obj = 2; % 1 means camera, 2 means ball
    pose = [x,y,z,yaw,pitch,roll, obj];
    unityImageLeft = unityLink(client,pose);
    pause(0.1);

    % Move stereo cameras into position above the court
    x = 0;
    y = 9;
    z = -0.050;
    pitch = 90;
    roll = 0;
    yaw = 90;
    obj = 1; % 1 means camera, 2 means ball
    pose = [x,y,z,yaw,pitch,roll, obj];
    unityImageLeft = unityLink(client,pose);
    %subplot(1, 2, 1);
    %imshow(unityImageLeft);
    %imwrite(unityImageLeft, 'left.jpg');

    x2 = 0;
    y2 = 9;
    z2 = 0.050;
    pitch2 = 90;
    roll2 = 0;
    yaw2 = 90;
    obj2 = 1;
    pose2 = [x2,y2,z2,yaw2,pitch2,roll2, obj2];
    unityImageRight = unityLink(client,pose2);
    %subplot(1, 2, 2);
    %imshow(unityImageRight);
    %imwrite(unityImageRight, 'right.jpg');
end

%Close Gracefully
fprintf(1,"Disconnected from server\n");