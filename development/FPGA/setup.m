% Dr. Kaputa
% Sobel Demo Setup File
R = 752; 
C = 480;
coefficients = [1 0 -1;
                2 0 -2;
                1 0 -1];

leftImage = imread("leftImage5.jpg");
rightImage = imread("rightImage5.jpg");
leftEmpty = imread("leftEmptyCourt.jpg");
rightEmpty = imread("rightEmptyCourt.jpg");

grayLeft = im2gray(leftImage);
grayRight = im2gray(rightImage);
grayLeftEmpty = im2gray(leftEmpty);
grayRightEmpty = im2gray(rightEmpty);

imwrite(grayLeft,"grayLeft.jpg");
imwrite(grayRight,"grayRight.jpg");
imwrite(grayLeftEmpty,"grayLeftEmpty.jpg");
imwrite(grayRightEmpty,"grayRightEmpty.jpg");

