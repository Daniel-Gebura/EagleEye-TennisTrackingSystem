% MatlabClient_Final performs the following:
% - Waits for the GUI to initialize its parameters
% - Once GUI initiates process, connects to server over wifi
% - Sends INIT PARAMETERS protocol to server
% - Enters REQUEST-RETRIEVE-RESPOND LOOP to send frames to the server
% - Once told to stop, requests results
% - Receives results to diaply on GUI including some debugging graphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTANTS AND SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Image Transfer Dimensions
width = 752.0;
height = 480.0;

% Server IP address
%server_ip   = '129.21.42.146'; % Debug Computer
server_ip   = '129.21.42.10'; % Board

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLIENT INITIALIZATION (GUI PASS PARAMETERS/START)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preprocess images (convert to grayscale)
preprocessImage = @(img) rgb2gray(img);
% Get and save Empty Court images (Left/Right) ONCE. 
emptyLeftImage = imread("../../testImages/LeftEmptyCourt.jpg");
emptyRightImage = imread("../../testImages/rightEmptyCourt.jpg");
emptyLeftGray = preprocessImage(emptyLeftImage);
emptyRightGray = preprocessImage(emptyRightImage);

% Get these parameters from GUI
MODE = '2';       % 1 -> coefficient of restitution, 2 -> ball is inside or out
MATCH_TYPE = '1'; % 1 -> singles mode, -> 2 doubles mode
SHOT_TYPE = '1';  % 1 -> serve mode, 2 -> volley mode
path = '../datFiles/serve1.dat'; % Path to .dat file being used
ITERATION = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONNECT TO SERVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Connect to sever;
server_port = 9999;                % Server Port of the sever
client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SEND SERVER INIT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tell server to prepare to receive init parameters
write(client,'0'); %Transfer Protocol
flush(client);

% Send mode
write(client, MODE);
flush(client);
% Send match type
write(client, MATCH_TYPE);
flush(client);
% Send shot type
write(client, SHOT_TYPE);
flush(client);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REQUEST-RETRIEVE-RESPOND LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tell Server to begin processing a shot
write(client,'1'); %Transfer Protocol
flush(client);

% Loop until Server sends special value
while 1
    % 1. REQUEST - Wait for request from server (t value), exit if special value
    request = read(client, 1, 'uint32');
    request;
    if request == 99999 % Check if received STOP CMD
        break % Leaving Request-retrieve-respond Loop
    end

    % 2. RETRIEVE - Get Left/Right Unity images at time t
    errorCode = MoveTennisBall(request, path); % Move Tennis ball to desired location based on .dat file
    % Check if a request frame is valid (shot hasn't ended yet)
    if errorCode == 0 % Valid request: Send the frame
        % Get the image from UNITY
        [leftImage, rightImage] = MoveCamera(request, 0);
        % SAVE FIGURE 1
        if (ITERATION == 30)
            imwrite(leftImage, 'UNITY_Image.jpg');
        end
        % Grayscale Left/Right
        BallLeftGray  = preprocessImage(leftImage);
        % SAVE FIGURE 2
        if (ITERATION == 30)
            imwrite(BallLeftGray, 'MATLAB_GRAY_Image.jpg');
        end
        BallRightGray = preprocessImage(rightImage);
        % Package all four images
        imageStack = uint8(ones(height,width,8));
        imageStack(:,:,1) = BallLeftGray;
        imageStack(:,:,2) = emptyLeftGray;
        imageStack(:,:,3) = BallRightGray;
        imageStack(:,:,4) = emptyRightGray;
        imageStack(:,:,5) = emptyRightGray;
        imageStack(:,:,6) = BallRightGray;
        imageStack(:,:,7) = emptyLeftGray;
        imageStack(:,:,8) = BallLeftGray;
    else % Invalid request: Shot ended. Send dummy frames
        %Package all four images (Empty Frames)
        disp('Requested Invalid Frames')
        imageStack = uint8(ones(height,width,8));
        imageStack(:,:,1) = ones(480, 752) * 0;
        imageStack(:,:,2) = ones(480, 752) * 0;
        imageStack(:,:,3) = ones(480, 752) * 0;
        imageStack(:,:,4) = ones(480, 752) * 0;
        imageStack(:,:,5) = ones(480, 752) * 0;
        imageStack(:,:,6) = ones(480, 752) * 0;
        imageStack(:,:,7) = ones(480, 752) * 0;
        imageStack(:,:,8) = ones(480, 752) * 0;
    end
    
    % 3. RESPOND - Send retrieved image stack
    imageStack = permute(imageStack,[3 2 1]);
    write(client,imageStack(:)); %SEND
    flush(client);
    ITERATION = ITERATION +1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RECEIVE RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tell server to send requested results
write(client,'2'); %Transfer Protocol
flush(client);

% RECEIVE FIGURE 4
Fig4NumFrames = read(client, 1, 'uint32');
Fig4XValues = read(client,Fig4NumFrames, 'double');
Fig4YValues = read(client,Fig4NumFrames, 'double');
Fig4ZValues = read(client,Fig4NumFrames, 'double');
Fig4TValues = read(client,Fig4NumFrames, 'uint32');

% RECEIVE FIGURE 5/6
Fig5NumFrames = read(client, 1, 'uint32');
Fig5XValues = read(client,Fig5NumFrames, 'double');
Fig5YValues = read(client,Fig5NumFrames, 'double');
Fig5ZValues = read(client,Fig5NumFrames, 'double');
Fig5TValues = read(client,Fig5NumFrames, 'uint32');

% Verify result format
receiveMode = read(client, 1, 'uint32');

% Get Mode-Specific Results
if receiveMode == 1 % Coefficient of restitution
    restitutionCoeff = read(client, 1, 'double');

else % In/Out Decison or DEBUGGING
    if receiveMode == 2 % In/Out decision
        isShotIn = read(client, 1, 'double'); % 1.0 = TRUE, 0.0 = FALSE
    end 

    % Receive calculated X,Y,Z trajectories
    xCoeff = read(client, 2, 'double');
    yCoeff = read(client, 2, 'double');
    zLen = read(client, 1, 'uint32');
    zCoeff = read(client, zLen, 'double');
    bounceT = read(client, 1, 'double');
end

% CLOSE SERVER
write(client,'9999');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FORMAT RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPLEMENTATION NOTE:
% - Prep top down plot of court as described below

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI RESULTS DISPLAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPLEMENTATION NOTE: 
% - If Coeff mode, gui only needs to state coefficient
%   of restitution
% - If In/Out Mode, gui displays In/Out decison and shows a top down plot
%   of the court with the calc X,Y trajectory plotted ontop. Then put a
%   special marker on he line at bounce(x,y) [x and y trajectories evaluated
%   at bounceT]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADDITIONAL INFO DISPLAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if receiveMode == 2
    % FIGURE 4 - Unfiltered Data
    % Populate actual correct results
    ballData = load(path);
    real_X = NaN(1, length(Fig4TValues));
    real_Y = NaN(1, length(Fig4TValues));
    real_Z = NaN(1, length(Fig4TValues));
    for i = 1:length(Fig4TValues)
        index = Fig4TValues(i);
        if index <= size(ballData, 1)
            real_X(i) = ballData(index, 3);
            real_Y(i) = ballData(index, 1);
            real_Z(i) = ballData(index, 2);
        else
            error('Index exceeds the number of rows in ballData file.');
        end
    end
    % Plot Figure 4
    figure;
    plot(Fig4TValues, real_Z, 'b-');  % Plot real_Z in blue with a line width of 2
    hold on;  % This command keeps the current plot and all axes properties so that the next plot adds to it.
    plot(Fig4TValues, Fig4ZValues, 'r-');  % Plot Fig4ZValues in red  line with a line width of 2
    % Adding labels and legend
    xlabel('Time (ms)');
    ylabel('Z Values, m');
    title('Comparison of Real Z Values and Unfiltered Z Values Over Time');
    legend('Real Z Values', 'Unfiltered Z Values');
    % Save the figure to a JPEG file
    saveas(gcf, 'UNFILTERED_Z_VALUES.jpg', 'jpg');
    hold off;


    % FIGURE 5 - Filtered Data
    % Populate actual correct results
    ballData = load(path);
    real_X = NaN(1, length(Fig5TValues));
    real_Y = NaN(1, length(Fig5TValues));
    real_Z = NaN(1, length(Fig5TValues));
    for i = 1:length(Fig5TValues)
        index = Fig5TValues(i);
        if index <= size(ballData, 1)
            real_X(i) = ballData(index, 3);
            real_Y(i) = ballData(index, 1);
            real_Z(i) = ballData(index, 2);
        else
            error('Index exceeds the number of rows in ballData file.');
        end
    end
    % Plot Figure 5
    figure;
    plot(Fig5TValues, real_Z, 'b-');  % Plot real_Z in blue with a line width of 2
    hold on;  % This command keeps the current plot and all axes properties so that the next plot adds to it.
    plot(Fig5TValues, Fig5ZValues, 'r-');  % Plot Fig5ZValues in red  line with a line width of 2
    % Adding labels and legend
    xlabel('Time (ms)');
    ylabel('Z Values, m');
    title('Comparison of Real Z Values and Filtered Z Values Over Time');
    legend('Real Z Values', 'Filtered Z Values');
    % Save the figure to a JPEG file
    saveas(gcf, 'FILTERED_Z_VALUES.jpg', 'jpg');
    hold off;


    % 2. 3D plot of real and calc trajectory?
    % Plotting
    figure;
    plot3(Fig5XValues, Fig5YValues, Fig5ZValues, 'r'); % Plot calculated X,Y,Z positions in red
    hold on;
    plot3(real_X, real_Y, real_Z, 'b'); % Plot real X,Y,Z positions in blue
    legend('Calculated XYZ', 'Real XYZ');
    title('Comparison of Calculated and Real XYZ Positions Over Time');
    xlabel('X position, m');
    ylabel('Y position, m');
    zlabel('Z position, m');
    grid on;
    zlim([0 inf]); % Set the minimum Z value to 0
    saveas(gcf, 'FILTERED_DATA_3D.jpg', 'jpg');
    hold off;

end