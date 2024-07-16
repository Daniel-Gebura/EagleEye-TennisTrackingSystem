"""
ZynqServer_FIGURES.py
"""
print("File Opened")
from numpysocket import NumpySocket
from matplotlib import pyplot as plt
import cv2
import numpy as np
import time
import mmap
import struct
import sys, random
import ctypes
import copy
import TCP_communication as tcp
import ballDetection as ball
import frameGrabber as fpga

# CONSTANTS
#----------------------------------------------------------------------------------------------------------
# TCP Commands
STOP_CMD = 99999
INIT_CMD = 0
PROCESS_CMD = 1
RESULTS_CMD = 2

# General Mapping
MODE_COEFF = 1
MODE_IN_OUT = 2
MATCH_TYPE_SINGLES = 1
MATCH_TYPE_DOUBLES = 2
SHOT_TYPE_SERVE = 1
SHOT_TYPE_VOLLEY = 2

# SETTINGS
FPGA_ENABLE = False
CV2_PREPROCESS_ENABLE = True
WINDSHIFT_ENABLE = False
ACCEL_PROCESSING = True
FRAME_REQUEST_TIMEOUT = 2000
T_SKIP = 20
PROCESS_T = 3
FIXED_PROCESS_TIME = True

ITERATION = 1
#----------------------------------------------------------------------------------------------------------
# INITIALIZE FPGA
if (FPGA_ENABLE):
    print("Initializing FPGA...")
    camProcessed, camFeedthrough, camWriter = fpga.initFPGA()
    print("Initialized.")

while(True):
    # Open Server
    npSocket = NumpySocket()
    npSocket.startServer(9999)
    print("Server Started")

    # ENTER INFINITE MAIN LOOP
    while True:
        # TOP TRANSFER PROTOCOL MANAGEMENT
        print('Awaiting cmd...')
        cmd = int(npSocket.receiveCmd())  # Await Transfer Protocol cmd
        if cmd == INIT_CMD: # INIT PARAMETERS
            # Get init parameters from client
            mode, matchType, shotType = tcp.getInitParameters(npSocket)

        elif cmd == PROCESS_CMD: # Process Shot
            # Initialize Variables
            resultsReady = False
            t = 1  # initialize to start of shot
            frame = 0  # current frame counter
            ballPositionXYZ = np.zeros((4, 0), dtype=int)  # Initialize a 2D array with 4 rows and dynamic columns

            # SPEED OPTIMIZATION
            dummyFrame = np.zeros((480, 752), dtype=np.uint8)  # Initialize an empty dummy image
            _, _, _ = ball.find_centroid(dummyFrame)

            # Process All Frames
            while True:  # While more frames to process
                # Get images at time t
                if (t > FRAME_REQUEST_TIMEOUT): # Check for invalid t request
                    print("All Frames Received")
                    break
                tcp.requestFrame(t, frame, npSocket) # Send request for frame at t
                if(not FPGA_ENABLE):
                    frame_data = tcp.receiveFrame(npSocket) # Receive frame for t
                    # Access the individual images from frame
                    ballLeftGray = frame_data['ballLeftGray']
                    emptyLeftGray = frame_data['emptyLeftGray']
                    ballRightGray = frame_data['ballRightGray']
                    emptyRightGray = frame_data['emptyRightGray']
                else:
                    data = npSocket.receive() # Read data from client

                # Check if shot has ended
                if np.all(emptyLeftGray == 0) and np.all(emptyRightGray == 0):
                    # Stop processing frames
                    print("Requested for frame out of bounds for time ", t)
                    break

                # Start Processing Current Frame
                start_time = time.time()  # start a timer from 0 to track processing time
                # 0. Adapt stereo background to possible wind shifts in new stereo image
                if (WINDSHIFT_ENABLE): # Wind present, may shift camera around
                    # IMPLEMENT 
                    # Account for a winshift in teh new ball images
                    pass
                else: # No processing needed. Images are perfectly alligned
                    pass

                # 1. Process frames to isolate ball from background
                if (CV2_PREPROCESS_ENABLE): # Background subtract in cv2
                    processedLeft, processedRight = ball.process_images(ballLeftGray, emptyLeftGray, ballRightGray, emptyRightGray)
                elif (FPGA_ENABLE): # Processing needed by FPGA
                    camWriter.setFrame(data) # Send stereo image for processing
                    processedLeft,processedRight = camProcessed.getStereoGray() # Receieve processed stereo frames
                    processedLeft = np.ascontiguousarray(processedLeft, dtype=np.uint8)
                    processedRight = np.ascontiguousarray(processedRight, dtype=np.uint8)
                else: # No processing needed. Server Initially receieved processed images
                    processedLeft = ballLeftGray # => processedLeft = channel_0 image from client stream
                    processedRight = emptyLeftGray # => processedRight = channel_1 image from client stream

                # SAVE FIGURE 3
                if (ITERATION == 30):
                    # Save processed Left
                    cv2.imwrite('SERVER_PROCESSED_Image.jpg', processedLeft)
                # 2. Centroid Detection
                ballFound, xLeft, yLeft = ball.find_centroid(processedLeft)
                ballFound, xRight, yRight = ball.find_centroid(processedRight)

                # 3. Stereo Calculate X,Y,Z at t
                if ((t > 5) and (ballFound)): # Only Calculate for frames after initialization and with a found ball
                    X, Y, Z = ball.calcStereoXYZ(xLeft, yLeft, xRight, yRight)
                    newPosition = np.array([[X], [Y], [Z], [t]])
                    ballPositionXYZ = np.hstack((ballPositionXYZ, newPosition))  # Append new frame data as a new column
                    frame += 1  # Increment frame counter

                # 4. Update t
                end_time = time.time()
                if ((not ballFound) and (ACCEL_PROCESSING)): # DEBUGGING update t faster when ball is out of frame
                    t += T_SKIP
                elif(FIXED_PROCESS_TIME):
                    t += PROCESS_T
                else:
                    t += int((end_time - start_time) * 1000)  # Convert processing time to ms

            # All Frames Processed
            print("Exiting process frames loop")
            resultsReady = True
            tcp.sendCMD(STOP_CMD, npSocket)  # Stop Command: Tell Client to stop sending frames and instead request the result back
            print('Sent Stop CMD')

        elif cmd == RESULTS_CMD: # Send Results
            print('Results Requested...')

            # Calculate Corresponding Result
            if (resultsReady):
                # SEND FIGURE 4. Unfiltered Data 
                tcp.sendBallXYZ(ballPositionXYZ, npSocket)
                # Remove any completely inaccurate data
                ballPositionXYZ = ball.removeInvalidXYZ(ballPositionXYZ)

                # Get/Send Mode-Specific Results
                if (mode == MODE_COEFF):  # Coeff Mode
                    print('Calculating Coefficient of Restitution...')
                    # Just calculate coefficient of restitution and send
                    beforeBounceXYZ, afterBounceXYZ = ball.filterStereoXYZ_Coeff(ballPositionXYZ) # Filter 
                    coeff = ball.getCoefficientOfRestitution(beforeBounceXYZ, afterBounceXYZ) # Calculate coefficient
                    tcp.sendResult(mode, coeff, npSocket) # Send Coefficient

                elif mode == MODE_IN_OUT:  # Shot Mode
                    print('Calculating In/Out...')
                    ballPositionXYZ = ball.filterStereoXYZ(ballPositionXYZ, shotType)
                    # SEND FIGURE 5. Filtered Data 
                    tcp.sendBallXYZ(ballPositionXYZ, npSocket)
                    lineDecision, _, _ = ball.getLineDecision(ballPositionXYZ, matchType, shotType) # Calculate In/Out
                    tcp.sendResult(mode, lineDecision, npSocket) # Send In/Out
                    # Get and send trajectory of shot
                    bounceX, bounceY, bounceZ = ball.getBallTrajectory(ballPositionXYZ)
                    tcp.sendTrajectoryCoeff(bounceX, bounceY, bounceZ, ball.findBounceT(ballPositionXYZ), npSocket)
                    # Report bounceT to user
                    print('Bounce t:')
                    print(ball.findBounceT(ballPositionXYZ))

                else:  # DEBUGGING MODE
                    print('DEBUGGING RESULTS...')
                    # Send XYZ over t Information
                    ballPositionXYZ = ball.filterStereoXYZ(ballPositionXYZ, shotType)
                    bounceX, bounceY, bounceZ = ball.getBallTrajectory(ballPositionXYZ)
                    tcp.sendTrajectoryCoeff(bounceX, bounceY, bounceZ, ball.findBounceT(ballPositionXYZ), npSocket)
                    print('Bounce t:')
                    print(ball.findBounceT(ballPositionXYZ))

                print('Results Sent')
            # Client has requested results at an invalid time
            else :
                print('Results Not Valid')

        else: # Received Terminate Command
            print("Exit Command. Close Server")
            npSocket.close()  # Close Server
            break  # Break out of the loop for any other value