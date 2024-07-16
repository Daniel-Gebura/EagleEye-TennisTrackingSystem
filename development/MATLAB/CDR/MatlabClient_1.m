% MatlabClinet_1 simply sends over a single frame in our defined format and
% receives back the ballLeftGray image

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
emptyRightImage = imread("testImages/rightEmptyCourt.jpg");
leftTestImage3 = imread("testImages/leftImage3.jpg");
rightTestImage3 = imread("testImages/rightImage3.jpg");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% image preprocessing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to preprocess images (convert to grayscale)
preprocessImage = @(img) rgb2gray(img);

% Preprocess all loaded images
emptyLeftGray = preprocessImage(emptyLeftImage);
emptyLeftGray = uint8(emptyLeftGray);
emptyRightGray = preprocessImage(emptyRightImage);
emptyRightGray = uint8(emptyRightGray);
BallLeftGray = preprocessImage(leftTestImage3);
BallLeftGray = uint8(BallLeftGray);
BallRightGray = preprocessImage(rightTestImage3);
BallRightGray = uint8(BallRightGray);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% send frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
for x = 1:5
    write(client,'0');
    flush(client);

    % mark the image number on the image
    %emptyLeftGray = insertText(emptyLeftGray,[100 100],x);

    imageStack = uint8(ones(height,width,8));
    imageStack(:,:,1) = BallLeftGray;
    imageStack(:,:,2) = emptyLeftGray;
    imageStack(:,:,3) = BallLeftGray;
    imageStack(:,:,4) = emptyLeftGray;
    imageStack(:,:,5) = BallRightGray;
    imageStack(:,:,6) = emptyRightGray;
    imageStack(:,:,7) = BallRightGray;
    imageStack(:,:,8) = emptyRightGray;

    imageStack = permute(imageStack,[3 2 1]);
    write(client,imageStack(:));
    %temp = read(client,1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    % receive feedthrough frame
    write(client,'1');
    flush(client);

    data = read(client,width*height);   
    temp = reshape(data,[width,height]);
    dataProcessed = permute(temp,[2 1]);
    imageToShow = dataProcessed(:, :, 1);
    imagesc(imageToShow);
    colormap gray; % Sets the colormap to gray for better visualization of grayscale images
    colorbar;  
    pause(1)
end

%Close Server
write(client,'2');