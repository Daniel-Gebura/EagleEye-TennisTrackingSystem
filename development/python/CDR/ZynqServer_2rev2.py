# ZynqServer_2rev2.py is a simulation of the the centroid detection algorithm over multiple frames over time 
# 1. Open Server and await client connection and transfer protocol
# 2. Respond to transfer protocol requests
# 3. Reach determination and send STOP Command to client
# 4. Send determination to client
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
#----------------------------------------------------------------------------------------------------------


# Open Server
npSocket = NumpySocket()
npSocket.startServer(9999)
print("Server Started")

# ENTER INFINITE MAIN LOOP
while True:
    # TOP TRANSFER PROTOCOL MANAGEMENT
    cmd = int(npSocket.receiveCmd())  # Await Transfer Protocol cmd
    if cmd == 0: # INIT PARAMETERS
        # Get init parameters from client
        mode, matchType, shotType = tcp.getInitParameters(npSocket)

    elif cmd == 1: # Process Shot
        # Initialize Variables
        t = 1  # initialize to start of shot
        frame = 0  # current frame counter
        coordinates = np.zeros((5, 0), dtype=int)  # Initialize a 2D array with 5 rows and dynamic columns

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
            #if np.all(frame_data == 0) :
            if np.all(t > 400) :
                print("All Frames Received")
                break

            # Start Processing Current Frame
            start_time = time.time()  # start a timer from 0 to track processing time
                
            # 5. Centroid Detection
            ballFound, xLeft, yLeft = ball.find_centroid(processedLeft)
            ballFound, xRight, yRight = ball.find_centroid(processedRight)

            # Append results to coordinates array
            if ((t > 5) and (ballFound)):
                new_coords = np.array([[xLeft], [yLeft], [xRight], [yRight], [t]])
                coordinates = np.hstack((coordinates, new_coords))  # Append new frame data as a new column
                frame += 1  # Increment frame counter

            # 6. Stereo Calculate X,Y,Z at t
            # IMPLEMENT: TBD
            
            # 7. Update t
            end_time = time.time()
            t += int((end_time - start_time) * 1000)  # Convert processing time to ms

        print("Exiting infinite while loop")
        # Calculate Result
        # IMPLEMENT: TBD
        
        # Send Stop Command
        tcp.sendCMD(STOP_CMD, npSocket)  # Stop Command: Tell Client to stop sending frames and instead request the result back
        print('sent Stop CMD')

    elif cmd == 2: # Send Results
        print('Sending Results...')
        if mode == 1:  # Coeff Mode
            pass  # IMPLEMENT: TBD
        elif mode == 2:  # Shot Mode
            pass  # IMPLEMENT: TBD
        else:  # DEBUGGING MODE
            print('DEBUGGING RESULTS')


            # Send Coordinate Information
            print(coordinates.shape[1])
            numFramesMsg = np.array(coordinates.shape[1], dtype=np.uint32)
            npSocket.send(numFramesMsg)
            print('Sent Num Frames')
            xLeftMsg = np.array(coordinates[0, :], dtype=np.double)
            npSocket.send(xLeftMsg)
            print('Sent xLeft')
            yLeftMsg = np.array(coordinates[1, :], dtype=np.double)
            npSocket.send(yLeftMsg)
            print('Sent yLeft')
            xRightMsg = np.array(coordinates[2, :], dtype=np.double)
            npSocket.send(xRightMsg)
            print('Sent xRight')
            yRightMsg = np.array(coordinates[3, :], dtype=np.double)
            npSocket.send(yRightMsg)
            print('Sent yRight')
            tMsg = np.array(coordinates[4, :], dtype=np.uint32)
            npSocket.send(tMsg)
            print(xLeftMsg)
            print(xRightMsg)
            print(tMsg)

    else:
        print("Exit Command. Close Server")
        npSocket.close()  # Close Server
        break  # Break out of the loop for any other value
