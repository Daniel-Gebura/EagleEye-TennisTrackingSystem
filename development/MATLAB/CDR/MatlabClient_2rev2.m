% MatlabClient_3 Connest to a Zynq server and continuously awaits a request
% from server for a frame at time t

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLIENT INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Image Transfer Dimensions
width = 752.0;
height = 480.0;

% Initialize the camera intrinsics and extrinsics
b = 100.0;          % baseline [mm]
f = 2.56;         % focal length [mm]
ps = 0.006;       % pixel size [mm]
xNumPix = 752.0;    % total number of pixels in x direction of the sensor [px]
cxLeft = xNumPix / 2;  % left camera x center [px]
cxRight = xNumPix / 2; % right camera x center [px]
cameraHeight = 9.0; % camera height [m]

% Function to preprocess images (convert to grayscale)
preprocessImage = @(img) rgb2gray(img);

% Get and save Empty Court images (Left/Right). 
emptyLeftImage = imread("../../testImages/LeftEmptyCourt.jpg");
emptyRightImage = imread("../../testImages/rightEmptyCourt.jpg");
emptyLeftGray = preprocessImage(emptyLeftImage);
emptyRightGray = preprocessImage(emptyRightImage);


%Connect to sever
server_ip   = '129.21.41.4';     % IP address of the server -NEEDS CHANGE

% NO CHNAGE
server_port = 9999;                % Server Port of the sever
client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SEND SERVER INIT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SEND
write(client,'0'); %Transfer Protocol
flush(client);

% For now, just leave values as is
MODE = '7';       % 1 -> coefficient of restitution, 2 -> ball is inside or out
write(client, MODE);
flush(client);

MATCH_TYPE = '3'; % 1 -> singles mode, -> 2 doubles mode
write(client, MATCH_TYPE);
flush(client);

SHOT_TYPE = '5';  % 1 -> serve mode, 2 -> volley mode
write(client, SHOT_TYPE);
flush(client);


% Serve/Volley Number  
SHOT_NUM = 0;   % 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REQUEST-RETRIEVE-RESPOND LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tell Server to begin processing a shot
write(client,'1'); %Transfer Protocol
flush(client);

% Loop until Server sends special value
while 1

    % 1. Wait for request from server (t value), exit if special value
    request = read(client, 1, 'uint32');
    request
    if request == 99999
        break
    end

    % 2. Retrieve Left/Right Unity images at time t
    path = '../datFiles/serve1.dat';
    errorCode = MoveTennisBall(request, path);

    if errorCode == 0 
        [leftImage, rightImage] = MoveCamera(request, 0); 

        % 3. Grayscale Left/Right
        BallLeftGray  = preprocessImage(leftImage);
        BallRightGray = preprocessImage(rightImage);

        % 4. Perform Background Subtraction and binarization
        % Background Subtraction
        diffLeft = imsubtract(BallLeftGray, emptyLeftGray);
        diffRight = imsubtract(BallRightGray, emptyRightGray);
        % Binarize the image
        threshold = 0.11; % graythresh(diffLeft)  Determine the best threshold
        binaryLeft = imbinarize(diffLeft, threshold);
        binaryRight = imbinarize(diffRight, threshold);
        % Convert binary image to uint8
        processedLeft = uint8(binaryLeft * 255); % Convert logical to uint8 by multiply
        processedRight = uint8(binaryRight * 255); % Convert logical to uint8 by multiply

        
        % 4. Send Left/Right
        %Package the two processed images
        imageStack = uint8(ones(height,width,8));
        imageStack(:,:,1) = processedLeft;
        imageStack(:,:,2) = processedRight;

        imageStack = permute(imageStack,[3 2 1]);
        write(client,imageStack(:)); %SEND
    else
        % 4. Send Left/Right
        %Package all four images
        disp('Printing zeros')
        imageStack = uint8(ones(height,width,8));
        imageStack(:,:,1) = ones(480, 752) * 0;
        imageStack(:,:,2) = ones(480, 752) * 0;
        imageStack(:,:,3) = ones(480, 752) * 0;
        imageStack(:,:,4) = ones(480, 752) * 0;
        imageStack(:,:,5) = ones(480, 752) * 0;
        imageStack(:,:,6) = ones(480, 752) * 0;
        imageStack(:,:,7) = ones(480, 752) * 0;
        imageStack(:,:,8) = ones(480, 752) * 0;

        imageStack = permute(imageStack,[3 2 1]);
        write(client,imageStack(:)); %SEND
        break
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESULTS HANDELING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write(client,'2'); %Transfer Protocol
flush(client);

% Receive coordinates in 2D array [xLeft,yLeft,xRight,yRight,t][Frame]
numFrames = read(client, 1, 'uint32');
xLeft = read(client,numFrames, 'double');
yLeft = read(client,numFrames, 'double');
xRight = read(client,numFrames, 'double');
yRight = read(client,numFrames, 'double');

% xLeft = double(xLeft);
% yLeft = double(yLeft);
% xRight = double(xRight);
% yRight = double(yRight);
t = read(client,numFrames, 'uint32');

realDepth = [];

%Calculate Depths 
AdjustedZ = zeros(1, numFrames);
calculatedDepths_t = zeros(1, numFrames);
calculatedDepths = zeros(1, numFrames);
differences = zeros(1, numFrames);
for i = 1:numFrames
    % Calculate depth
    d = (abs((xLeft(i) - cxLeft) - (xRight(i) - cxRight)) * ps); % disparity [mm]
    Z = (b * f) / d; % depth [mm]
    Z = Z/1000; % Convert depth to meters
    AdjustedZ(i) = cameraHeight - Z;
    
    % Store calculated depth
    calculatedDepths_t(i) = t(i);
    calculatedDepths(i) = AdjustedZ(i);

    actualDepths = zeros(size(calculatedDepths));
    ballData = load(path);

    % Populate actualDepths using indices from calculatedDepths_t
    for i = 1:length(calculatedDepths_t)
        t_index = t(i);
        if t_index <= size(ballData, 1)
            actualDepths(i) = ballData(t_index, 2); % Assumes the depth value is in the second column
        else
            error('Index exceeds the number of rows in ballData file.');
        end
    end
end


% Plotting both depths arrays against t
figure; % Create a new figure window
windowSize = 3;
calculatedDepths = calculatedDepths(5:85);
calculatedDepths_t = calculatedDepths_t(5:85);
actualDepths = actualDepths(5:85);
movingAveragedCalculatedDepths = smooth(calculatedDepths,windowSize);
movingAveragedT = smooth(calculatedDepths_t, windowSize);
[Coefficients, Structure] = polyfit(movingAveragedT,movingAveragedCalculatedDepths,2);
polynomialFunction = @(inputTime) Coefficients(1) * inputTime ^ 2 + Coefficients(2) * inputTime + Coefficients(3);

N = size(movingAveragedT);

polyFit = zeros(1, N(1));

for i = 1 : N(1)
    polyFit(i) = polynomialFunction(movingAveragedT(i));
end

hold on
plot(movingAveragedT, polyFit, '-x', 'DisplayName', 'Moving Averaged PolyFit')
%plot(movingAveragedT, movingAveragedCalculatedDepths, '-o', 'DisplayName', 'Moving Averaged Calculated Depth' )
plot(calculatedDepths_t, calculatedDepths, '-o', 'DisplayName', 'Calculated Depths');
plot(calculatedDepths_t, actualDepths, '-s', 'DisplayName', 'Actual Depths from File');
hold off;

% Formatting the graph
xlabel('Frame Number (t)');
ylabel('Depth');
title('Comparison of Calculated Depths and Actual Depths');
legend show; % Show legend to identify the plots



%Close Server
write(client,'9999');