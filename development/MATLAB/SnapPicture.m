function [unityImageLeft, unityImageRight] = snapPicture(time, isWind)
  clc;
  clear all;
  close all;
  
  %Include source files in path
  addpath(genpath('../src'))
  
  %Initialization Parameters
  server_ip   = '127.0.0.1';     %IP address of the Unity Server
  server_port = 55001;           %Server Port of the Unity Sever
  
  client = tcpclient(server_ip,server_port);
  fprintf(1,"Connected to server\n");
  
  xShift = 0;
  yShift = 0;
  zShift = 0;

  if isWind
      windData = load('datFiles/wind.dat');
      [xShift, yShift, zShift] = windData(time);
  end
  
  % Move stereo cameras into position above the court
  x = 0 + xShift;
  y = 9 + yShift;
  z = -0.050 + zShift;
  pitch = 90;
  roll = 0;
  yaw = 90;
  obj = 1; % 1 means camera, 2 means ball
  pose = [x,y,z,yaw,pitch,roll, obj];
  unityImageLeft = unityLink(client,pose);
  
  x2 = 0 + xShift;
  y2 = 9 + yShift;
  z2 = 0.050 + zShift;
  pitch2 = 90;
  roll2 = 0;
  yaw2 = 90;
  obj2 = 1;
  pose2 = [x2,y2,z2,yaw2,pitch2,roll2, obj2];
  unityImageRight = unityLink(client,pose2);
  
  fprintf(1,"Disconnected from server\n");
end