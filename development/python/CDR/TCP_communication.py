from numpysocket import NumpySocket
import matplotlib as plt
import numpy as np

def getInitParameters(npSocket):
    """
    Receives initial parameters from a remote client via a TCP socket and returns them

    :param npSocket : The socket connection over which information is received

    :return : A tuple containing the mode, matchType, and shotType as integers
    """
    # Initialize Variables
    mode, matchType, shotType = 0, 0, 0

    mode = int(npSocket.receiveCmd())      # 1 = Coefficient of restitution, 2 = In/Out Mode
    matchType = int(npSocket.receiveCmd()) # 1 = Singles, 2 = Doubles
    shotType = int(npSocket.receiveCmd())  # 1 = Serve, 2 = Volley
    # Print info to server user
    print('Received Parameters')
    print("Mode: %d, Match Type: %d, Shot Type: %d" % (mode, matchType, shotType))
    return mode, matchType, shotType

def requestFrame(t, frame, npSocket):
    """
    Sends a request to a MATLAB client to retrieve a stereo frame at a specified time, t

    :param t : The time of the requested frame, ms
    :param frame : The identifier of the frame to be requested
    :param npSocket : The socket connection over which the frame request is sent

    :return : None
    """
    request_t = np.array(t, dtype=np.uint32)  # Formatting
    print("Requesting frame %d at t = %d" % (frame, t))
    npSocket.send(request_t)

def receiveFrame(npSocket):
    """
    Receives a stereo frame from a MATLAB client and parces it into four distinct grayscale images

    :param npSocket : The socket connection over which information is received

    :return : A dictionary containing numpy arrays for each of the processed grayscale images
    """
    data = npSocket.receive() # Read data from client
    stereoImage = np.reshape(data, (480, 752, 8)) # Format data
    print('Received Frame')
    return {
        'ballLeftGray': np.ascontiguousarray(stereoImage[:, :, 0], dtype=np.uint8),
        'emptyLeftGray': np.ascontiguousarray(stereoImage[:, :, 1], dtype=np.uint8),
        'ballRightGray': np.ascontiguousarray(stereoImage[:, :, 2], dtype=np.uint8),
        'emptyRightGray': np.ascontiguousarray(stereoImage[:, :, 3], dtype=np.uint8)
    }

def sendCMD(cmd, npSocket):
    """
    Sends a command to a MATLAB client via a TCP socket

    :param cmd : the integer command to be sent
    :param npSocket : The socket connection over which information is sent

    :return : None
    """
    cmd_msg = np.array(cmd, dtype=np.uint32)  # Formatting
    npSocket.send(cmd_msg)

    return

def sendBallXYZ(ballPositionXYZ, npSocket):
    """
    Sends a ball's XYZ position [mm] in 3D space over a set of frames in the following format:
    Send numFrames : 1, uint32
    Send X values  : numFrames, double
    Send Y values  : numFrames, double
    Send Z values  : numFrames, double
    Send t values  : numFrames, uint32

    :param ballPositionXYZ : The XYZ,t ball information to be sent to the client
    :param npSocket : The socket connection over which information is sent
    
    :return : None
    """
    numFramesMsg = np.array(ballPositionXYZ.shape[1], dtype=np.uint32)
    npSocket.send(numFramesMsg)

    X_msg = np.array(ballPositionXYZ[0, :], dtype=np.double)
    npSocket.send(X_msg)

    Y_msg = np.array(ballPositionXYZ[1, :], dtype=np.double)
    npSocket.send(Y_msg)

    Z_msg = np.array(ballPositionXYZ[2, :], dtype=np.double)
    npSocket.send(Z_msg)
    
    tMsg = np.array(ballPositionXYZ[3, :], dtype=np.uint32)
    npSocket.send(tMsg)

    return

def sendTrajectoryCoeff(xCoeff, yCoeff, zCoeff, bounceT, npSocket):
    """
    Sends a ball's XYZ trajectory in the form of polynomial coefficients

    :param xCoeff : Linear polynomial coefficients
    :param yCoeff : Linear polynomial coefficients
    :param zCoeff : Quadratic (or Linear) polynomial coefficients
    :param bounceT : The estimated time of bounce
    :param npSocket : The socket connection over which information is sent
    
    :return : None
    """
    X_msg = np.array(xCoeff[:], dtype=np.double)
    npSocket.send(X_msg)

    Y_msg = np.array(yCoeff[:], dtype=np.double)
    npSocket.send(Y_msg)

    Z_Len = len(zCoeff)
    Z_LenMsg = np.array(Z_Len, dtype=np.uint32)
    npSocket.send(Z_LenMsg)

    Z_msg = np.array(zCoeff[:], dtype=np.double)
    npSocket.send(Z_msg)

    tMsg = np.array(bounceT, dtype=np.double)
    npSocket.send(tMsg)

    return

def sendResult(mode, result, npSocket):
    """
    Depending on the requested mode, sends a final determination to the client

    :param mode : The mode that the result is correlated to (1 = Coeff Mode, 2 = In/Out Mode)
    :param result : Simple determination (ie. coefficient of restitution or In(1)/Out(0))
    :param ballPositionXYZ : The ball's XYZ psition over time
    :param npSocket : The socket connection over which information is sent
    
    :return : None
    """
    # Only send results for a valid mode
    if (mode == 1 or mode == 2): # Only process valid mode results
        # Notify client which type of result this is
        result_msg = np.array(mode, dtype=np.uint32)  # Formatting
        npSocket.send(result_msg)
        # Send Result as Double 
        result_msg = np.array(result, dtype=np.double)  # Formatting
        npSocket.send(result_msg)

    return 