function [Z_mm, X_mm, Y_mm] = getCenterPosition(x1, y1, x2, y2) 
  b = 60;              % baseline [mm] how far eyes are away from each other
  f = 6;               % focal length [mm] focal length of eye
  pixelSize = .006;    % pixel size [mm] 

  xNumPix = 752;       % total number of pixels in x direction of the sensor [px]
  yNumPix = 480;

  cxLeft = xNumPix/2;  % left camera x center [px]
  cxRight = xNumPix/2; % right camera x center [px]

  cyLeft = yNumPix / 2;
  cyRight = yNumPix / 2;

  Z_mm = (b * f)/(abs((x1-cxLeft)-(x2-cxRight))*pixelSize);
  X_mm = (Z_mm * (x1-cxLeft)*pixelSize)/f;
  Y_mm = (Z_mm * (y1-cyLeft)*pixelSize)/f;

  Z = Z_mm / 1000;
  X = X_mm / 1000;
  Y = Y_mm / 1000;
end