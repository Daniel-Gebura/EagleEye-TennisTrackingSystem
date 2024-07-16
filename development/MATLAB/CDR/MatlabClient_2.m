% MatlabClient_2 Preprocesses an image to send the expected FPGA
% output to the ZynqServer. The Client then receives back the calculated
% coordinate for the centroid. It then shows the original image with a
% marker over the the calculated coordinates

width = 752;
height = 480;

%Initialization Parameters
server_ip   = '129.21.42.202';     % IP address of the server
server_port = 9999;                % Server Port of the sever

client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get raw frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
emptyLeftImage = imread("testImages/LeftEmptyCourt.jpg");
testImage = imread("testImages/leftImage4.jpg");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% image preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preprocess images (convert to grayscale)
preprocessImage = @(img) rgb2gray(img);

% Preprocess all loaded images
emptyLeftGray = preprocessImage(emptyLeftImage);
emptyLeftGray = uint8(emptyLeftGray);
BallLeftGray = preprocessImage(testImage);
BallLeftGray = uint8(BallLeftGray);

% Background Subtraction
differenceImage = imsubtract(BallLeftGray, emptyLeftGray);

% Binarize the image
% Adjust the threshold according to your specific image contrast and lighting conditions
threshold = graythresh(differenceImage); % Otsu's method to determine the best threshold
binaryImage = imbinarize(differenceImage, threshold);

% Convert binary image to uint8
processedImage = uint8(binaryImage * 255); % Convert logical to uint8 by multiply

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    write(client,'0');
    flush(client);

    % mark the image number on the image
    %emptyLeftGray = insertText(emptyLeftGray,[100 100],x);

    imageStack = uint8(ones(height,width,8));
    imageStack(:,:,1) = processedImage;
    % imageStack(:,:,2) = emptyLeftGray;
    % imageStack(:,:,3) = BallLeftGray;
    % imageStack(:,:,4) = emptyLeftGray;
    % imageStack(:,:,5) = BallRightGray;
    % imageStack(:,:,6) = emptyRightGray;
    % imageStack(:,:,7) = BallRightGray;
    % imageStack(:,:,8) = emptyRightGray;

    imageStack = permute(imageStack,[3 2 1]);
    write(client,imageStack(:));

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% receive calculated centroid coordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
write(client,'2');
flush(client);

% Read two uint32 numbers from the server
data = read(client, 2, 'uint32');

% Extract coordinates
x_coord = double(data(1));  % Convert to double for plotting purposes
y_coord = double(data(2));  % Convert to double for plotting purposes

% Display the image
imshow(testImage);
hold on; % This command allows you to plot on top of the image

% Plot a marker at the specified coordinates
% You can use 'r+' for a red cross marker, or 'ro' for a red circle
plot(x_coord, y_coord, 'r+', 'MarkerSize', 10, 'LineWidth', 2);

% Optionally, you can add annotations or more details
title(sprintf('Marker at (%d, %d)', x_coord, y_coord));
hold off; % Release the hold to prevent further plotting on the same figure

%Close Server
write(client,'3');