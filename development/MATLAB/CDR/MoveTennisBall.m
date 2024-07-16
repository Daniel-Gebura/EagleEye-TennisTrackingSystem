function errorCode = moveTennisBall(time, pathToDatFile)
    %clc;
    %clear all;
    close all;

    %Include source files in path
    addpath(genpath('../src'))

    %Initialization Parameters
    server_ip   = '129.21.151.125';     %IP address of the Unity Server
    server_port = 55001;               %Server Port of the Unity Sever
    client = tcpclient(server_ip,server_port);
    fprintf(1,"Connected to server\n");

    %Load in ball data .dat file 
    ballData = load(pathToDatFile);
    numRows = size(ballData, 1);
    errorCode = 0;
    if numRows < time
        errorCode = 1; %Ball position for requested time is out of bounds
    else
        x = ballData(time, 1);
        y = ballData(time, 2);
        z = ballData(time, 3);
        pitch = 90;
        roll = 0;
        yaw = 90;
        obj = 2; % 1 means camera, 2 means ball
        pose = [x,y,z,yaw,pitch,roll, obj];
        unityLink(client,pose);
    end

    %Close Gracefully
    fprintf(1,"Disconnected from server\n");
end