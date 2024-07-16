function [xCenter, yCenter] = getCenterPixels(depth, pose, client)
   unityImage = unityLink(client,pose);
   gray = rgb2gray(unityImage);
   [centers, radii] = imfindcircles(gray, [5 70], "Sensitivity", 0.950);
   xCenter = centers(1, 1);
   yCenter = centers(1, 2);
end
