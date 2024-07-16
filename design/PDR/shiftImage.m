function shiftedImg = shiftImage(img, xShift, yShift)
    % Get the size of the image
    [rows, cols, channels] = size(img);
    
    % Create an empty matrix for the shifted image
    shiftedImg = zeros(rows, cols, channels, 'like', img);
    
    % Calculate the effective shifts taking image boundaries into account
    xShiftMod = mod(xShift, cols);
    yShiftMod = mod(yShift, rows);
    
    % Calculate the indices for the shifted image
    xIndices = [1:cols] - xShiftMod;
    yIndices = [1:rows] - yShiftMod;
    
    % Handle wrapping around for negative shifts
    xIndices(xIndices <= 0) = xIndices(xIndices <= 0) + cols;
    yIndices(yIndices <= 0) = yIndices(yIndices <= 0) + rows;
    
    % Handle wrapping around for positive shifts
    xIndices(xIndices > cols) = xIndices(xIndices > cols) - cols;
    yIndices(yIndices > rows) = yIndices(yIndices > rows) - rows;
    
    % Apply the shifts for each color channel
    for channel = 1:channels
        shiftedImg(:,:,channel) = img(yIndices, xIndices, channel);
    end
end
