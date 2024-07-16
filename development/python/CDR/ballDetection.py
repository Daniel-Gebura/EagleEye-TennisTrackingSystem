import cv2
import numpy as np
import matplotlib as plt

def process_images(ballLeftGray, emptyLeftGray, ballRightGray, emptyRightGray):
    """
    process_images takes 2 stereo images (an image with a ball, and an image of the empty court),
    background subtracts the two stereo images and thresholds the product to produce a binarized
    stereo image of an isolate ball in the frame

    :param ballLeftGray: uint8 image of a tennis court with a ball from left camera perspective
    :param emptyLeftGray: uint8 image of empty tennis court from left camera perspective
    :param ballRightGray: uint8 image of a tennis court with a ball from right camera perspective
    :param emptyRightGray: uint8 image of empty tennis court from right camera perspective

    :return : A tuple containing two numpy arrays:
            - processedLeft : Processed binary image of the left view.
            - processedRight : Processed binary image of the right view.
    """ 
    # Ensure images are of type uint8 and have dimensions 752x480
    assert ballLeftGray.dtype == np.uint8 and ballLeftGray.shape == (480, 752)
    assert emptyLeftGray.dtype == np.uint8 and emptyLeftGray.shape == (480, 752)
    assert ballRightGray.dtype == np.uint8 and ballRightGray.shape == (480, 752)
    assert emptyRightGray.dtype == np.uint8 and emptyRightGray.shape == (480, 752)

    # Background subtraction for left and right images
    diffLeft = cv2.absdiff(ballLeftGray, emptyLeftGray)
    diffRight = cv2.absdiff(ballRightGray, emptyRightGray)

    # Binarization of the subtracted images
    threshold = int(0.11 * 255)
    _, processedLeft = cv2.threshold(diffLeft, threshold, 255, cv2.THRESH_BINARY)
    _, processedRight = cv2.threshold(diffRight, threshold, 255, cv2.THRESH_BINARY)

    # Convert images to uint8 if necessary
    processedLeft = np.uint8(processedLeft)
    processedRight = np.uint8(processedRight)

    return processedLeft, processedRight

def find_centroid(binary_image):
    """
    find_centroid receives a processed binary image of a presumable black image with a white ball 
    somewhere in the frame. Returns the x,y pixel coordinates of the centroid.

    :param binary_image : The image to find the centroid within

    :return : A tuple containing three values:
            - ballFound : boolean for if a centroid was detected
            - cx : x-coordinate of centroid pixel.
            - cy : y-coordinate of centroid pixel.
    """
    # BInitialize Variables
    ballFound = True # Boolean for specifying if a ball was found

    # Identfy all possible contours in image
    contours, _ = cv2.findContours(binary_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[-2:]

    # Iterate through all identified contours to find best centroid
    if contours:
        largest_contour = max(contours, key=cv2.contourArea)
        M = cv2.moments(largest_contour)
        if M["m00"] != 0:
            cx = M["m10"] / M["m00"]
            cy = M["m01"] / M["m00"]
        else:
            ballFound = False
            cx, cy = 0, 0  # Centroid not found
        return ballFound, cx, cy
    else:
        return False, 0, 0  # No contours found
    
def calcStereoXYZ(xLeft, yLeft, xRight, yRight):
    """
    calcStereoXYZ receives a centroid's (x,y) coordinate from a stereo camera's left and right perspective 
    and returns the centroid's X,Y,Z position in 3D space [m] in terms of the center of the court on the ground = (0,0,0)

    :param xLeft : The x-coordinate of the centroid from the left camera perspective
    :param yLeft : The y-coordinate of the centroid from the left camera perspective
    :param xRight : The x-coordinate of the centroid from the right camera perspective
    :param yRight : The y-coordinate of the centroid from the right camera perspective

    :return : A tuple containing three values:
            - X : ball's X position [m] in 3D Space
            - Y : ball's Y position [m] in 3D Space
            - Z : ball's Z position [m] in 3D Space
    """
    # CAMERA INTRINSICS
    CAM_B = 100.0 # baseline [mm]
    CAM_F = 2.56 # focal length [mm]
    CAM_PS = 0.006 # pixel size [mm]
    CAM_XNUMPIX = 752.0 # total number of pixels in x direction of the sensor [px]
    CAM_CXLEFT = CAM_XNUMPIX / 2 # left camera x center [px]
    CAM_CXRIGHT = CAM_XNUMPIX / 2 # right camera x center [px]
    CAM_YNUMPIX = 480 # total number of pixels in y direction of the sensor [px]
    CAM_CYLEFT = CAM_YNUMPIX / 2 # left camera y center [px]

    # CAMERA EXTRINSICS
    CAM_HEIGHT = 9000.0 # camera height from ground [mm]

    # Calculate depth from camera [mm]
    disparity = (abs((xLeft - CAM_CXLEFT) - (xRight - CAM_CXRIGHT)) * CAM_PS) # disparity [mm]
    depth = (CAM_B * CAM_F) / disparity # depth [mm]

    # Calculate real-world X,Y,Z [mm]
    X = depth * (xLeft - CAM_CXLEFT) * CAM_PS / CAM_F + CAM_B / 2
    Y = depth * (yLeft - CAM_CYLEFT) * CAM_PS / CAM_F
    Z = CAM_HEIGHT - depth # Centroid's height off of the ground [mm]

    # Convert to Meters and adjust to cordinate system
    X = -(X / 1000)
    Y = -(Y / 1000)
    Z = Z / 1000

    return X, Y, Z

def removeInvalidXYZ(ballPositionXYZ_RAW):
    """
    removeInvalidXYZ removes completely invalid entries in an array of ball XYZ positions over time.

    :param ballPositionXYZ_RAW : Array to be filtered

    :return : The filtered 2D numpy array
    """
    # SETTINGS
    MAX_LOWER_LIMIT = -1
    MAX_UPPER_LIMIT = 8

    # GENERAL FILTER (Remove invalid entries)
    valid_columns = [] # Keep track of valid entries

    # Iterate over each frame to remove invalid entries
    for i in range(ballPositionXYZ_RAW.shape[1]):
        # Is Z value within valid limits
        if (MAX_LOWER_LIMIT <= ballPositionXYZ_RAW[2, i]) and (ballPositionXYZ_RAW[2, i] <= MAX_UPPER_LIMIT):
            # Add this valid entry to filtered array
            valid_columns.append(ballPositionXYZ_RAW[:, i])

    # Convert the list of arrays back into a 2D NumPy array
    if valid_columns:
        ballPositionXYZ = np.column_stack(valid_columns)
    else:
        # If no valid columns, return an empty array with the same number of rows and zero columns
        print("ERROR: NO VALID ENTRIES FOUND")
        ballPositionXYZ = np.empty((ballPositionXYZ_RAW.shape[0], 0))

    return ballPositionXYZ

def filterStereoXYZ(ballPositionXYZ, shotType):
    """
    filterStereoXYZ removes/normalizes invalid entries in an array of ball XYZ positions over time.
    Current implementation:
        - Find a rough estimate for bounce t
        - Remove all entries after a possible bounce
        - Polyfit remaining Z entries
        - Create a "BufferZone" around the rough polyfit
        - Remove/Normalize to BufferZone edges any data that is outside of BufferZone

    :param ballPositionXYZ : Array to be filtered

    :return : The filtered 2D numpy array
    """
    # SETTINGS
    FILTER_SELECT = 1 # Select Which Filter (1 = Normal, 2 = Experimental)
    REMOVE_INCORRECT = False  # True = Remove extreme values, False = Normalize Extreme Values
    BUFFER_WIDTH = 0.4
    CUTOFF_DEPTH = 0.2


    # Select Filter
    if (FILTER_SELECT == 1): #Polyfit, normalize strays to polyfit zone
        # Initialize Variables
        valid_columns = []
        if (shotType == 2):
            cutMinT = 400
        else:
            cutMinT = 100

        # 1. REMOVE DATA NEAR/AFTER POTENTIAL BOUNCE
        cutIndex = 0 # Iterate through Z values until you reach cutoff depth
        found = False
        for i in range (ballPositionXYZ.shape[1]):
            depth = ballPositionXYZ[2, i] # Get this depth
            # Only look for cutIndex if it is not found yet AND there is no chnace that we are looking at a volley starting near the ground
            if (not found):
                # Does this depth meet the cutoff depth
                if (depth <= CUTOFF_DEPTH) and (ballPositionXYZ[3, i] > cutMinT): # Arbitrary cutoff height
                    found = True # Found cutIndex, no need to continue to look
                else:
                    cutIndex += 1
        ballPositionXYZ = ballPositionXYZ[:, 4:cutIndex] # Get entries just before potential bounce (remove first couple entries)

        # Extract Z values and corresponding times BEFORE a potential bounce
        Z = ballPositionXYZ[2, :]
        t = ballPositionXYZ[3, :]
        print("Num Valid Frames:")
        print(len(Z))

        # Fit a second order polynomial to Z over time
        p = np.polyfit(t, Z, 2)  # Coefficients of the polynomial
        # Check if the polyfit is a positive paraobola (Bad)
        if p[0] > 0:
            p = np.polyfit(t, Z, 1)  # Refit with a linear polyfit

        # Normalize or Remove any entries outside of expected bounds
        for i in range(len(Z)):
            # Calculate the upper and lower bounds of the buffer zone
            Z_fit = np.polyval(p, t[i])  # Evaluated polynomial at current time
            upper_bound = Z_fit + BUFFER_WIDTH
            lower_bound = Z_fit - BUFFER_WIDTH

            # Check which alteration method used (Removing or normalizing bad entries)
            if (REMOVE_INCORRECT): # Remove Bad Entries
                if (lower_bound <= Z[i]) and (Z[i] <= upper_bound):
                    # Add valid entry to filtered data
                    valid_columns.append(ballPositionXYZ[:, i])
            else: # Normalize Bad Entries
                if (lower_bound > Z[i]):
                    ballPositionXYZ[2, i] = lower_bound
                    #ballPositionXYZ[2, i] = Z_fit
                    #ballPositionXYZ[2, i] += BUFFER_WIDTH
                elif (upper_bound < Z[i]):
                    ballPositionXYZ[2, i] = upper_bound
                    #ballPositionXYZ[2, i] = Z_fit
                    #ballPositionXYZ[2, i] -= BUFFER_WIDTH
                valid_columns.append(ballPositionXYZ[:, i]) # Add the entry to filtered data

        # Convert the list of arrays back into a 2D NumPy array
        if valid_columns:
            filteredXYZ = np.column_stack(valid_columns)
        else:
            # If no valid columns, return an empty array with the same number of rows and zero columns
            print("ERROR: NO VALID ENTRIES FOUND AT NORMAL FILTER")
            filteredXYZ = np.empty((ballPositionXYZ.shape[0], 0))

        return filteredXYZ

    return ballPositionXYZ

def filterStereoXYZ_Coeff(ballPositionXYZ_RAW):
    """
    filterStereoXYZ_Coeff splits ball's XYZ into two arrays (before/after bounce) and filters them both individually

    :param ballPositionXYZ_RAW : Array to be filtered

    :return : A tuple containing the following:
            - The filtered 2D numpy array before a bounce
            - The filtered 2D numpy array after a bounce
    """
    # SETTINGS 
    CUTOFF_DEPTH = 0.0
    FILTER_SELECT = 1
    BUFFER_WIDTH = 0.4

    # 1. ISOLATE ENTRIES BEFORE BOUNCE
    cutIndex1 = 0 # Iterate through Z values until you reach cutoff depth
    found = False
    for i in range (ballPositionXYZ_RAW.shape[1]):
        depth = ballPositionXYZ_RAW[2, i] # Get this depth
        # Only look for cutIndex if it is not found yet 
        if (not found):
            # Does this depth meet the cutoff depth
            if (depth <= CUTOFF_DEPTH): # Arbitrary cutoff height
                found = True # Found cutIndex, no need to continue to look
            else:
                cutIndex1 += 1
    beforeXYZ = ballPositionXYZ_RAW[:, :cutIndex1] # Get entries just before potential bounce
    ballPositionXYZ_RAW = ballPositionXYZ_RAW[:, cutIndex1:] # Get remaining entries

    # 2. ISOLATE ENTRIES AFTER BOUNCE
    cutIndex2 = 0 # Iterate through Z values until you reach cutoff depth
    found = False
    for i in range (ballPositionXYZ_RAW.shape[1]):
        depth = ballPositionXYZ_RAW[2, i] # Get this depth
        # Only look for cutIndex if it is not found yet 
        if (not found):
            # Does this depth meet the cutoff depth
            if (depth >= CUTOFF_DEPTH): # Arbitrary cutoff height
                found = True # Found cutIndex, no need to continue to look
            else:
                cutIndex2 += 1
    afterXYZ = ballPositionXYZ_RAW[:, cutIndex2:] # Get entries just after potential bounce

    # 3. FURTHER FILTER THE TWO HALVES
    # Select Filter
    if (FILTER_SELECT == 1): #Polyfit, normalize strays to polyfit zone
        # Initialize Variables
        valid_columns_before = []
        valid_columns_after = []

        # Extract Z values and corresponding times BEFORE and AFTER a potential bounce
        beforeZ = beforeXYZ[2, :]
        beforeT = beforeXYZ[3, :]
        afterZ = afterXYZ[2, :]
        afterT = afterXYZ[3, :]

        # Debugging print to user
        print("Num Valid Frames BEFORE Bounce:")
        print(len(beforeZ))
        print("Num Valid Frames AFTER Bounce:")
        print(len(afterZ))

        # Fit a second order polynomial to Z before bounce over time
        beforeP = np.polyfit(beforeT, beforeZ, 2)  # Coefficients of the polynomial
        # Check if the polyfit is a positive paraobola (Bad)
        if beforeP[0] > 0:
            beforeP = np.polyfit(beforeT, beforeZ, 1)  # Refit with a linear polyfit
        # Fit a second order polynomial to Z after bounce over time
        afterP = np.polyfit(afterT, afterZ, 2)  # Coefficients of the polynomial
        # Check if the polyfit is a positive paraobola (Bad)
        if afterP[0] > 0:
            afterP = np.polyfit(afterT, afterZ, 1)  # Refit with a linear polyfit

        # Normalize or Remove any entries outside of expected bounds for before bounce
        for i in range(len(beforeZ)):
            # Calculate the upper and lower bounds of the buffer zone
            Z_fit = np.polyval(beforeP, beforeT[i])  # Evaluated polynomial at current time
            upper_bound = Z_fit + BUFFER_WIDTH
            lower_bound = Z_fit - BUFFER_WIDTH

            # Normalize bad entries found
            if (lower_bound > beforeZ[i]):
                beforeXYZ[2, i] = lower_bound
            elif (upper_bound < beforeZ[i]):
                beforeXYZ[2, i] = upper_bound
            valid_columns_before.append(beforeXYZ[:, i]) # Add the entry to filtered data

        # Convert the list of arrays back into a 2D NumPy array
        if valid_columns_before:
            filteredBeforeXYZ = np.column_stack(valid_columns_before)
        else:
            # If no valid columns, return an empty array with the same number of rows and zero columns
            print("ERROR: NO VALID BEFORE ENTRIES FOUND AT NORMAL FILTER")
            filteredBeforeXYZ = np.empty((beforeXYZ.shape[0], 0))

        # Normalize or Remove any entries outside of expected bounds for after bounce
        for i in range(len(afterZ)):
            # Calculate the upper and lower bounds of the buffer zone
            Z_fit = np.polyval(afterP, afterT[i])  # Evaluated polynomial at current time
            upper_bound = Z_fit + BUFFER_WIDTH
            lower_bound = Z_fit - BUFFER_WIDTH

            # Normalize bad entries found
            if (lower_bound > afterZ[i]):
                afterXYZ[2, i] = lower_bound
            elif (upper_bound < afterZ[i]):
                afterXYZ[2, i] = upper_bound
            valid_columns_after.append(afterXYZ[:, i]) # Add the entry to filtered data

        # Convert the list of arrays back into a 2D NumPy array
        if valid_columns_after:
            filteredAfterXYZ = np.column_stack(valid_columns_after)
        else:
            # If no valid columns, return an empty array with the same number of rows and zero columns
            print("ERROR: NO VALID AFTER ENTRIES FOUND AT NORMAL FILTER")
            filteredAfterXYZ = np.empty((afterXYZ.shape[0], 0))

        return filteredBeforeXYZ, filteredAfterXYZ

    return beforeXYZ, afterXYZ

def findBounceT(ballPositionXYZ):
    """
    findBounceT uses a polyfit on an array of ball XYZ positions over time to estimate the approx. t[ms] 
    in which the ball will reach a Z = 0 (bounce depth)

    :param ballPositionXYZ : Array to estimate bounceT from

    :return : The floating point estimate of t[ms] at which Z = 0
    """

    # Remove data before a potantial bounce
    # Find cutoff point just before a bounce
    cutIndex = 0
    found = False
    for i in range (ballPositionXYZ.shape[1]):
        depth = ballPositionXYZ[2, i]
        if (not found):
            if (depth <= 0.1): # Arbitrary cutoff height
                found = True
            else:
                cutIndex += 1
    ballPositionXYZ_cut = ballPositionXYZ[:, :cutIndex]
    # Extract just the Z and t values for each frame
    calculatedDepths = ballPositionXYZ_cut[2, :]
    t = ballPositionXYZ_cut[3, :]

    # Fit a polynomial to the data to get its coefficients
    coefficients = np.polyfit(t, calculatedDepths, 2) # Use quadratic polyfit because of gravity affecting trajectory
    # Check if the polyfit is a positive paraobola (Bad)
    if coefficients[0] > 0:
         coefficients = np.polyfit(t, calculatedDepths, 1)  # Refit using first linear 
    # Create a polynomial from the coefficients
    p = np.poly1d(coefficients)
    # Find the roots of the polynomial where the depth will be zero
    roots = p.roots
    # Filter roots to find the correct one that comes after the initial depth
    valid_roots = [root for root in roots if root.imag == 0 and root.real >= min(t)]

    # Choose the smallest valid root that occurs after the start
    if valid_roots:
        return min(valid_roots).real
    else:
        return None

def findEstimatedValue(positionArray, tUsedArray, estimatedTimeBallHitsGround, order = 1):
    """
    findEstimatedValue uses a polyfit of a ball's X,Y, or Z position to estimate the coordinate's value
    at a given time guess[ms]

    :param positionArray : Array of ball positions to estimate from
    :param tUsedArray : Array of corresponding times [ms] to estimate from
    :param estimatedTimeBallHitsGround : t value to evaluate function at
    :param order : order of the polyfit used (Linear polyfit by default)

    :return : The estimated X, Y, or Z coordinate at the given t
    """
    # Fit a polynomial to the data
    coefficients = np.polyfit(tUsedArray, positionArray, order)

    # Evaluate and return
    return np.polyval(coefficients, estimatedTimeBallHitsGround)

def getBallTrajectory(ballPositionXYZ):
    """
    getBallTrajectory uses a polyfit of a ball's X,Y, or Z position to  return the corresponding coefficients
    of each coordinate trajectory

    :param ballPositionXYZ : Array of ball positions to estimate from

    :return : A tuple of the following arrays:
            - X coefficients
            - Y coefficients
            - Z coefficients
    """
    # Extract Relevant Position/Time Arrays
    xArray = ballPositionXYZ[0,:]
    yArray = ballPositionXYZ[1,:]
    zArray = ballPositionXYZ[2,:]
    tArray = ballPositionXYZ[3,:]

    # Fit a polynomial to the data
    xCoefficients = np.polyfit(tArray, xArray, 1) # Linear fit for x values
    yCoefficients = np.polyfit(tArray, yArray, 1) # Linear fit for y values
    zCoefficients = np.polyfit(tArray, zArray, 2) # Quadratic fit for z values
    # Check if the polyfit is a positive paraobola (Bad)
    if zCoefficients[0] > 0:
        zCoefficients = np.polyfit(tArray, zArray, 1)  # Refit with a linear polyfit

    # Evaluate and return
    return xCoefficients, yCoefficients, zCoefficients

def getLineDecision(ballPositionXYZ, matchType, shotType):
    """
    getLineDecision analyzes a filtered data set of a ball's X,Y,Z,t position accross a series of frames
    to determine whether the ball bounced within boundary lines (dependent on match/shot type)

    :param ballPositionXYZ : X,Y,Z,t information of the ball
    :param matchType : integer to specify the tpe of match (singles = 1, doubles = 2)
    :param shotType : integer to specify the tpe of shot (serve = 1, volley = 2)

    :return : a tuple with the the following information
                - "In" (1.0) or "Out" (0.0)
                - X position of ball at bounce (double)
                - Y position of ball at bounce (double)
    """
    # Extract Relevant Position/Time Arrays
    tArray = ballPositionXYZ[3,:]
    xArray = ballPositionXYZ[0,:]
    yArray = ballPositionXYZ[1,:]
    # Get X,y at start of shot
    startX = xArray[0]
    startY = yArray[1]
    # Get X,Y at bounceT
    bounceT = findBounceT(ballPositionXYZ)
    bounceX = findEstimatedValue(xArray, tArray, bounceT, 1)
    bounceY = findEstimatedValue(yArray, tArray, bounceT, 1)

    # Setermine Shot Type Bounds
    if(shotType == 1): # Handle a serve
        result = isServeInBound(startX, startY, bounceX, bounceY)
    else: # Handle Volley
        result = isVolleyInBound(startX, startY, bounceX, bounceY, matchType)

    # Print Answer to user
    print("Shot bounced at (%f, %f)" % (bounceX, bounceY))

    # Format boolean into Double for tcp protocol 
    if result:
        resultFormatted = 1.0
    else:
        resultFormatted = 0.0
    
    return resultFormatted, bounceX, bounceY

def isServeInBound(startX, startY, bounceX, bounceY):
    """
    isServeInBound determines whether a given bounce X,Y landed within its proper service area bounds

    :param startX : The initial X value of the ball
    :param startY : The initial Y value of the ball
    :param bounceX : The X value of the ball at bounce
    :param bounceY : The Y value of the ball at bounce

    :return : True ("In") or False ("Out")
    """
    # Top Left Service Area Bounds
    TL_AREA_X_LEFT = 6.4
    TL_AREA_X_RIGHT = 0
    TL_AREA_Y_TOP = 4.115
    TL_AREA_Y_Bottom = 0
    # Bottom Left Service Area Bounds
    BL_AREA_X_LEFT = 6.4
    BL_AREA_X_RIGHT = 0
    BL_AREA_Y_TOP = 0
    BL_AREA_Y_Bottom = -4.115
    # Top Right Service Area Bounds
    TR_AREA_X_LEFT = 0
    TR_AREA_X_RIGHT = -6.4
    TR_AREA_Y_TOP = 4.115
    TR_AREA_Y_Bottom = 0
    # Bottom Right Service Area Bounds
    BR_AREA_X_LEFT = 0
    BR_AREA_X_RIGHT = -6,4
    BR_AREA_Y_TOP = 0
    BR_AREA_Y_Bottom = -4.115

    if bounceX > startX: # The serve is going right-to-left from the camera POV
        if startY > bounceY: # The serve is going from top-right corner to bottom-left corner
            # Must land in Bottom Left Service Area
            return (bounceX <= BL_AREA_X_LEFT) and (bounceX >= BL_AREA_X_RIGHT) and (bounceY <= BL_AREA_Y_TOP) and (bounceY >= BL_AREA_Y_Bottom)
        elif startY < bounceY: # The serve is going from bottom-right corner to top-left corner
            # Must land in Top Left Service Area
            return (bounceX <= TL_AREA_X_LEFT) and (bounceX >= TL_AREA_X_RIGHT) and (bounceY <= TL_AREA_Y_TOP) and (bounceY >= TL_AREA_Y_Bottom)
        else:
            return False

    else: # The serve is going left-to-right from the camera POV
        if startY > bounceY:  # The serve is going top-left corner to bottom-right corner
            # Must land in Bottom Right Service Area
            return (bounceX <= BR_AREA_X_LEFT) and (bounceX >= BR_AREA_X_RIGHT) and (bounceY <= BR_AREA_Y_TOP) and (bounceY >= BR_AREA_Y_Bottom)
        elif startY < bounceY: # The serve is going bottom-left corner to top-right corner
            # Must land in Top Right Service Area
            return (bounceX <= TR_AREA_X_LEFT) and (bounceX >= TR_AREA_X_RIGHT) and (bounceY <= TR_AREA_Y_TOP) and (bounceY >= TR_AREA_Y_Bottom)
        else:
            return False

def isVolleyInBound(startX, startY, bounceX, bounceY, matchType):
    """
    isVolleyInBound determines whether a given bounce X,Y landed within its proper sideline and end line

    :param startX : The initial X value of the ball
    :param startY : The initial Y value of the ball
    :param bounceX : The X value of the ball at bounce
    :param bounceY : The Y value of the ball at bounce
    :param matchType : Match Singles (1) or Doubles (2)

    :return : True ("In") or False ("Out")
    """
    # Define Court Bounds
    X_LEFT_ENDLINE = 11.885
    X_RIGHT_ENDLINE = -11.885
    X_CENTER_LINE = 0
    Y_TOP_SIDELINE_SINGLES = 4.115
    Y_TOP_SIDELINE_DOUBLES = 5.485
    Y_BOTTOM_SIDELINE_SINGLES = -4.115
    Y_BOTTOM_SIDELINE_DOUBLES = -5.485
    
    # Determine if bounce X,Y is within given bounds
    if bounceX > startX: # The serve is going right-to-left from the camera POV
        if (matchType == 1): # Use SINGLES bounds
            # Must land in Left Singles Zone
            return (bounceX <= X_LEFT_ENDLINE) and (bounceX >= X_CENTER_LINE) and (bounceY <= Y_TOP_SIDELINE_SINGLES) and (bounceY >= Y_BOTTOM_SIDELINE_SINGLES)
        elif (matchType == 2): # Use DOUBLES bounds
            # Must land in Left Doubles Zone
            return (bounceX <= X_LEFT_ENDLINE) and (bounceX >= X_CENTER_LINE) and (bounceY <= Y_TOP_SIDELINE_DOUBLES) and (bounceY >= Y_BOTTOM_SIDELINE_DOUBLES)
        else:
            return False

    else: # The serve is going left-to-right from the camera POV
        if (matchType == 1): # Use SINGLES bounds
            # Must land in Right Singles Zone
            return (bounceX <= X_CENTER_LINE) and (bounceX >= X_RIGHT_ENDLINE) and (bounceY <= Y_TOP_SIDELINE_SINGLES) and (bounceY >= Y_BOTTOM_SIDELINE_SINGLES)
        elif (matchType == 2): # Use DOUBLES bounds
            # Must land in Right Doubles Zone
            return (bounceX <= X_CENTER_LINE) and (bounceX >= X_RIGHT_ENDLINE) and (bounceY <= Y_TOP_SIDELINE_DOUBLES) and (bounceY >= Y_BOTTOM_SIDELINE_DOUBLES)
        else:
            return False

def getCoefficientOfRestitution(beforeBounceXYZ, afterBounceXYZ):
    """
    getCoefficientOfRestitution uses a ball's X,Y,Z position over time before and after to calculate the ball/court 
    coefficient of restitution by comparing velocities

    :param beforeBounceXYZ : The ball X,Y,Z,t information before a bounce
    :param afterBounceXYZ : The ball X,Y,Z,t information after a bounce

    :return : The coefficient of restitution (Ideally 0.7)
    """
    # Extract desired range of frames
    beforeZ = beforeBounceXYZ[2,:]
    beforeT = beforeBounceXYZ[3,:]
    afterZ = afterBounceXYZ[2,:]
    afterT = afterBounceXYZ[3,:]

    # Isolate Z positions near bounce T to get true velocity
    beforeLength = len(beforeZ)
    afterLength = len(afterZ)
    beforeStartIdx = beforeLength / 2 # Find split point of data
    afterEndIdx = afterLength / 2 # Find split point of data
    beforeZ = beforeZ[beforeStartIdx:] # Only use back portion of data
    beforeT = beforeT[beforeStartIdx:] # Only use back portion of data
    afterZ = afterZ[:afterEndIdx] # Only use first portion of data
    afterT = afterT[:afterEndIdx] # Only use first portion of data

    # First order polyfit (linear regression) to get the slope before and after the bounce
    coefficientsBefore = np.polyfit(beforeT, beforeZ, 1)
    coefficientsAfter = np.polyfit(afterT, afterZ, 1)

    # Extract the slopes
    beforeV = coefficientsBefore[0]  # Slope of the line before the bounce
    afterV = coefficientsAfter[0]    # Slope of the line after the bounce

    # Calculate the ratio of the slopes
    # Ensure afterV is not zero to avoid division by zero
    if afterV == 0:
        return None

    # Calculate Ratio
    restitutionRatio = abs(afterV / beforeV)

    # Print Answer to user
    print('Coefficient of Restitution:')
    print(restitutionRatio)

    return restitutionRatio