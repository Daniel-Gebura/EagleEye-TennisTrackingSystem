function sphereCenter = findSphereCenter(img)
    % Read the image from the given path
    %img = imread(imagePath);
    
    % Convert image to grayscale if it's not already
    if size(img, 3) == 3
        grayImg = rgb2gray(img);
    else
        grayImg = img;
    end
    
    % Apply edge detection to find potential sphere borders
    edges = edge(grayImg, 'Canny');
    
    % Use morphological operations to close gaps in edges
    se = strel('disk', 2);
    closedEdges = imclose(edges, se);
    
    % Label connected components in the image
    [labeledImage, numRegions] = bwlabel(closedEdges);
    
    % Measure properties of image regions to find potential sphere
    regionProps = regionprops(labeledImage, 'Centroid', 'Area');
    
    % Placeholder for the center of the sphere
    sphereCenter = [];
    maxArea = 0;
    
    % Loop through the regions to find the most sphere-like object
    for k = 1:numRegions
        % Assume the largest circular-like region is the sphere
        if regionProps(k).Area > maxArea
            maxArea = regionProps(k).Area;
            sphereCenter = regionProps(k).Centroid(1);
        end
    end
    
    % Display the original image and overlay the detected center
    % imshow(img); hold on;
    % plot(sphereCenter(1), sphereCenter(2), 'r+', 'MarkerSize', 30, 'LineWidth', 2);
    % hold off;
    
    % Return the sphere center coordinates
end

