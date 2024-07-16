"""
ZynqServer_4.py
"""
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

# CONSTANTS
STOP_CMD = 99999
INIT_CMD = 0
PROCESS_CMD = 1
RESULTS_CMD = 2

MODE_COEFF = 1
MODE_IN_OUT = 2

FRAME_REQUEST_TIMEOUT = 400
#----------------------------------------------------------------------------------------------------------

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
        dummyFrame = np.zeros((480, 752), dtype=np.uint8)  # Initialize a 2D array with 4 rows and dynamic columns
        _, _, _ = ball.find_centroid(dummyFrame)

        # Process All Frames
        while True:  # While more frames to process
            # Send request for frame at t
            tcp.requestFrame(t, frame, npSocket)
            # Receive frame for t
            frame_data = tcp.receiveFrame(npSocket)
            # Access the individual images from frame
            processedLeft = frame_data['ballLeftGray']
            processedRight = frame_data['emptyLeftGray']
            # If frame is empty, stop processing
            if t > FRAME_REQUEST_TIMEOUT:
                print("All Frames Received")
                break

            # Start Processing Current Frame
            start_time = time.time()  # start a timer from 0 to track processing time
                
            # 5. Centroid Detection
            ballFound, xLeft, yLeft = ball.find_centroid(processedLeft)
            ballFound, xRight, yRight = ball.find_centroid(processedRight)

            # 6. Stereo Calculate X,Y,Z at t
            if ((t > 5) and (ballFound)): # Only Calculate for frames after initialization and with a found ball
                X, Y, Z = ball.calcStereoXYZ(xLeft, yLeft, xRight, yRight)
                newPosition = np.array([[X], [Y], [Z], [t]])
                ballPositionXYZ = np.hstack((ballPositionXYZ, newPosition))  # Append new frame data as a new column
                frame += 1  # Increment frame counter
            
            # 7. Update t
            end_time = time.time()

            t += int((end_time - start_time) * 1000)  # Convert processing time to ms

        # All Frames Processed
        print("Exiting process frames loop")
        resultsReady = True
        tcp.sendCMD(STOP_CMD, npSocket)  # Stop Command: Tell Client to stop sending frames and instead request the result back
        print('Sent Stop CMD')

    elif cmd == RESULTS_CMD: # Send Results
        print('Results Requested...')
        if (resultsReady):
            print('Sending Results...')
            if (mode == MODE_COEFF):  # Coeff Mode
                pass  # IMPLEMENT: TBD
            elif mode == MODE_IN_OUT:  # Shot Mode
                pass  # IMPLEMENT: TBD
            else:  # DEBUGGING MODE
                print('DEBUGGING RESULTS')
                # Send XYZ over t Information
                ballPositionXYZ = ball.filterStereoXYZ(ballPositionXYZ)
                tcp.sendBallXYZ(ballPositionXYZ, npSocket)
                print(ball.findBounceT(ballPositionXYZ))
        
            print('Results Sent')
        else :
            print('Results Not Valid')

    else:
        print("Exit Command. Close Server")
        npSocket.close()  # Close Server
        break  # Break out of the loop for any other value
