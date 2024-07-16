% === Initialization ===

% Load test images
emptyLeftImage = imread("testImages/LeftEmptyCourt.jpg");
emptyRightImage = imread("testImages/rightEmptyCourt.jpg");
leftTestImage1 = imread("testImages/leftImage1.jpg");
leftTestImage2 = imread("testImages/leftImage2.jpg");
leftTestImage3 = imread("testImages/leftImage3.jpg");
leftTestImage4 = imread("testImages/leftImage4.jpg");
leftTestImage5 = imread("testImages/leftImage5.jpg");
rightTestImage1 = imread("testImages/rightImage1.jpg");
rightTestImage2 = imread("testImages/rightImage2.jpg");
rightTestImage3 = imread("testImages/rightImage3.jpg");
rightTestImage4 = imread("testImages/rightImage4.jpg");
rightTestImage5 = imread("testImages/rightImage5.jpg");

% Load an answer key of correct depths
actualValues = [1.5, 2.5, 5.5, 2.5, 1.5];

% Initialize the camera intrinsics and extrinsics
b = 100;          % baseline [mm]
f = 2.56;         % focal length [mm]
ps = 0.006;       % pixel size [mm]
xNumPix = 752;    % total number of pixels in x direction of the sensor [px]
cxLeft = xNumPix / 2;  % left camera x center [px]
cxRight = xNumPix / 2; % right camera x center [px]
cameraHeight = 9; % camera height [m]

% === PreProcessing ===

% Function to preprocess images (convert to grayscale)
preprocessImage = @(img) rgb2gray(img);

% Preprocess all loaded images
emptyLeftImage = preprocessImage(emptyLeftImage);
emptyRightImage = preprocessImage(emptyRightImage);
leftImages = {leftTestImage1, leftTestImage2, leftTestImage3, leftTestImage4, leftTestImage5};
rightImages = {rightTestImage1, rightTestImage2, rightTestImage3, rightTestImage4, rightTestImage5};

% Convert all test images to grayscale
for i = 1:length(leftImages)
    leftImages{i} = preprocessImage(leftImages{i});
    rightImages{i} = preprocessImage(rightImages{i});
end

% Shift all test images to grayscale
for i = 1:length(leftImages)
    leftImages{i} = shiftImage(leftImages{i}, 20, 0);
    rightImages{i} = shiftImage( rightImages{i}, 20, 0);
end

% After performing the shift operations on the first set of images
shiftedLeftImage1 = leftImages{1};
shiftedRightImage1 = rightImages{1};
% Save the shifted left image of the first set as a JPEG file
imwrite(shiftedLeftImage1, 'shiftedLeftImage1.jpg');

% Save the shifted right image of the first set as a JPEG file
imwrite(shiftedRightImage1, 'shiftedRightImage1.jpg');

% === Processing ===
calculatedDepths = zeros(1, 5);
differences = zeros(1, length(leftImages));

for i = 1:length(leftImages)
    % Background subtraction and binarization
    procLeftImg = imbinarize(imabsdiff(leftImages{i}, emptyLeftImage));
    procRightImg = imbinarize(imabsdiff(rightImages{i}, emptyRightImage));
    
    % Find sphere centers
    xLeft = findSphereCenter(procLeftImg);
    xRight = findSphereCenter(procRightImg);
    
    % Calculate depth
    d = abs((xLeft - cxLeft) - (xRight - cxRight)) * ps; % disparity [mm]
    Z = (b * f) / d; % depth [mm]
    Z = Z / 1000; % Convert depth to meters
    AdjustedZ = cameraHeight - Z;
    
    % Store calculated depth
    calculatedDepths(i) = AdjustedZ;
    
    % Calculate the difference between calculated and actual depths
    differences(i) = actualValues(i) - AdjustedZ;
end

% === Results Display ===

% Toggle between display modes
displayMode = 1; % Set to 1 for original display, 2 for new display mode

if displayMode == 1
    % Original Display Code (Now commented out)
    % Plot calculated depth vs actual depth
    figure;
    plot(1:5, actualValues, 'bo-', 1:5, calculatedDepths, 'rx-');
    legend('Actual Depth', 'Calculated Depth');
    xlabel('Image Set');
    ylabel('Depth (m)');
    title('Calculated Depth vs. Actual Depth');

    % Display differences
    disp('Differences between calculated and actual depths:');
    disp(differences);

    % Display all left background subtracted images with markers
    % (Original code here, now commented out for brevity)
else
    % New Display Mode
    for i = 1:1 % Only display for the first set of test images
        % Display left and right images with and without the ball
        figure;
        subplot(2, 2, 1);
        imshow(leftImages{i});
        title('Left Image with Ball');
        
        subplot(2, 2, 2);
        imshow(rightImages{i});
        title('Right Image with Ball');
        
        subplot(2, 2, 3);
        imshow(imabsdiff(leftImages{i}, emptyLeftImage));
        title('Left Background Subtracted');
        
        subplot(2, 2, 4);
        imshow(imabsdiff(rightImages{i}, emptyRightImage));
        title('Right Background Subtracted');
        
        % Display background subtracted product without the shift
        % Note: Assume shiftImage function reverses the previous shift if provided with positive values
        leftImageNoShift = shiftImage(leftImages{i}, 20, 0); % Corrected shift reversal
        rightImageNoShift = shiftImage(rightImages{i}, 20, 0); % Corrected shift reversal
        
        figure;
        subplot(1, 2, 1);
        imshow(imabsdiff(leftImageNoShift, emptyLeftImage));
        title('Left No Shift Background Subtracted');
        
        subplot(1, 2, 2);
        imshow(imabsdiff(rightImageNoShift, emptyRightImage));
        title('Right No Shift Background Subtracted');
    end
end
