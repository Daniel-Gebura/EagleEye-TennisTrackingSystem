# ZynqServer_3.py is a simulation of the final implementation EXCLUDING the FPGA Processing.
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

# Open Server
npSocket = NumpySocket()
npSocket.startServer(9999)
print("Server Started")

# ENTER INFINITE MAIN LOOP
while True:
    # TOP TRANSFER PROTOCOL MANAGEMENT
    cmd = int(npSocket.receiveCmd())  # Await Transfer Protocol cmd
    if cmd == 0: # INIT PARAMETERS
        # RESET ALL FOR NEW SHOT
        mode, matchType, shotType = 0, 0, 0  # Reset the following parameter values

        # Get init parameters
        mode = int(npSocket.receiveParam())
        matchType = int(npSocket.receiveParam())
        shotType = int(npSocket.receiveParam())
        print('Received Parameters')
    elif cmd == 1: # Process Shot
        t = 1  # initialize to start of shot
        frame = 0  # current frame counter
        coordinates = np.zeros((5, 0), dtype=int)  # Initialize a 2D array with 5 rows and dynamic columns
        while True:  # While more frames to process
            # 1. Send request for frame at t
            request_t = np.array(t, dtype=np.uint32) # Formatting 
            print("Requesting frame %d at t = %d" % (frame, t))
            npSocket.send(request_t)
            
            # 2. Receive stereoImage for t
            data = npSocket.receive()
            stereoImage = np.reshape(data, (480, 752, 8))
            # Isolate the unique frames
            ballLeftGray = stereoImage[:, :, 0]
            ballLeftGray = np.ascontiguousarray(ballLeftGray, dtype=np.uint8) 
            emptyLeftGray = stereoImage[:, :, 1]
            emptyLeftGray = np.ascontiguousarray(emptyLeftGray, dtype=np.uint8) 
            ballRightGray = stereoImage[:, :, 4]
            ballRightGray = np.ascontiguousarray(ballRightGray, dtype=np.uint8)
            emptyRightGray = stereoImage[:, :, 5]
            emptyRightGray = np.ascontiguousarray(emptyRightGray, dtype=np.uint8)
            if np.all(stereoImage == 0) :
                break
            """
            # Start Processing timer
            start_time = time.time()  # start a timer from 0 to track processing time
            
            # 3. Pass through to FPGA
            FPGA_ENABLE = False
            if FPGA_ENABLE: 
                pass  # NO IMPLEMENTATION YET
            else:
                processedLeft = cv2.threshold(cv2.absdiff(ballLeftGray, emptyLeftGray), 25, 255, cv2.THRESH_BINARY)[1]  # Background subtraction and binarization for left image
                processedRight = cv2.threshold(cv2.absdiff(ballRightGray, emptyRightGray), 25, 255, cv2.THRESH_BINARY)[1]  # Background subtraction and binarization for right image
            
            # 4. Receive processedImage from FPGA
            if FPGA_ENABLE: 
                pass  # NO IMPLEMENTATION YET
                
            # 5. Centroid Detection
            def find_centroid(binary_image):
                contours, _ = cv2.findContours(binary_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
                if contours:
                    largest_contour = max(contours, key=cv2.contourArea)
                    M = cv2.moments(largest_contour)
                    if M["m00"] != 0:
                        cx = int(M["m10"] / M["m00"])
                        cy = int(M["m01"] / M["m00"])
                    else:
                        cx, cy = -1, -1  # Centroid not found
                    return cx, cy
                else:
                    return -1, -1  # No contours found

            xLeft, yLeft = find_centroid(processedLeft)
            xRight, yRight = find_centroid(processedRight)

            # Append results to coordinates array
            new_coords = np.array([[xLeft], [yLeft], [xRight], [yRight], [t]])
            coordinates = np.hstack((coordinates, new_coords))  # Append new frame data as a new column

            
            # 6. Stereo Calculate X,Y,Z at t
            # IMPLEMENT: TBD
            
            # 7. Update t
            end_time = time.time()
            t += int((end_time - start_time) * 1000)  # Convert processing time to ms
            """
            t += 50
            frame += 1  # Increment frame counter
        print("Exiting infinite while loop")
        # Calculate Result
        # IMPLEMENT: TBD
        
        # Send Stop Command
        stopCmd = np.array(-1, dtype=np.uint32) # Formatting 
        npSocket.send(stopCmd)  # Stop Command: Tell Client to stop sending frames and instead request the result back
    elif cmd == 2: # Send Results
        print('HERE')
        if mode == 1:  # Coeff Mode
            pass  # IMPLEMENT: TBD
        elif mode == 2:  # Shot Mode
            pass  # IMPLEMENT: TBD
        else:  # DEBUGGING MODE
            # Send Coordinate Information
            numFramesMsg = np.array(coordinates.shape[1], dtype=np.uint32)
            npSocket.send(numFramesMsg)
            
            xLeftMsg = np.ascontiguousarray(coordinates[0, :], dtype=np.uint32)
            yLeftMsg = np.ascontiguousarray(coordinates[1, :], dtype=np.uint32)
            xRightMsg = np.ascontiguousarray(coordinates[2, :], dtype=np.uint32)
            yRightMsg = np.ascontiguousarray(coordinates[3, :], dtype=np.uint32)
            tMsg = np.ascontiguousarray(coordinates[4, :], dtype=np.uint32)
            npSocket.send(xLeftMsg)
            npSocket.send(yLeftMsg)
            npSocket.send(xRightMsg)
            npSocket.send(yRightMsg)
            npSocket.send(tMsg)
    else:
        print("Exit Command. Close Server")
        npSocket.close()  # Close Server
        break  # Break out of the loop for any other value
