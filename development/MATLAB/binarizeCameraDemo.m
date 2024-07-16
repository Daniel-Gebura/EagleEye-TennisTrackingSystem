figure
firstFrame = imread("testImages/left1_1.jpg");
imshow(firstFrame)

figure
secondFrame = imread("testImages/left2_1.jpg");
imshow(secondFrame)


figure
diff = secondFrame - firstFrame;
imshow(diff)

grayDiff = rgb2gray(diff);

thresholdValue = 10;
binaryDiff = imbinarize(grayDiff, thresholdValue/255);

figure
imshow(binaryDiff)