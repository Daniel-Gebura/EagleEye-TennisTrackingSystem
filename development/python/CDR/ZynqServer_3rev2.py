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
            ballLeftGray = frame_data['ballLeftGray']
            emptyLeftGray = frame_data['emptyLeftGray']
            ballRightGray = frame_data['ballRightGray']
            emptyRightGray = frame_data['emptyRightGray']
            # If frame is empty, stop processing
            #if np.all(frame_data == 0) :
            if np.all(t >= 250) :
                print("All Frames Received")
                break

            # Start Processing Current Frame
            start_time = time.time()  # start a timer from 0 to track processing time
            
            # 3. Pass through to FPGA
            FPGA_ENABLE = False
            if FPGA_ENABLE: 
                pass  # NO IMPLEMENTATION YET
            else:
                processedLeft, processedRight = ball.process_images(ballLeftGray, emptyLeftGray, ballRightGray, emptyRightGray)
            
            # 4. Receive processedImage from FPGA
            if FPGA_ENABLE: 
                pass  # NO IMPLEMENTATION YET
                
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
            frame += 1  # Increment frame counter

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

            # Display Image Processing 
            fig, axs = plt.subplots(1, 3, figsize=(15, 5))  # 1 row, 3 columns
            # Plot the first image: ballLeftGray
            axs[0].imshow(ballLeftGray, cmap='gray')  # cmap='gray' ensures grayscale display
            axs[0].axis('off')  # Hide the axes
            axs[0].set_title('Ball Left Gray')
            # Plot the second image: emptyLeftGray
            axs[1].imshow(emptyLeftGray, cmap='gray')
            axs[1].axis('off')
            axs[1].set_title('Empty Left Gray')
            # Plot the third image: processedLeft
            axs[2].imshow(processedLeft, cmap='gray')
            axs[2].axis('off')
            axs[2].set_title('Processed Left')
            plt.show()

            # Send Processed Image for Confirmation
            sendProduct = np.ascontiguousarray(processedLeft, dtype=np.uint8)
            npSocket.send(sendProduct)

            # Send Coordinate Information
            numFramesMsg = np.array(coordinates.shape[1], dtype=np.uint32)
            npSocket.send(numFramesMsg)
            xLeftMsg = np.array(coordinates[0, :], dtype=np.uint32)
            npSocket.send(xLeftMsg)
            yLeftMsg = np.array(coordinates[1, :], dtype=np.uint32)
            npSocket.send(yLeftMsg)
            xRightMsg = np.array(coordinates[2, :], dtype=np.uint32)
            npSocket.send(xRightMsg)
            yRightMsg = np.array(coordinates[3, :], dtype=np.uint32)
            npSocket.send(yRightMsg)
            tMsg = np.array(coordinates[4, :], dtype=np.uint32)
            npSocket.send(tMsg)
            print(xLeftMsg)
            print(tMsg)

    else:
        print("Exit Command. Close Server")
        npSocket.close()  # Close Server
        break  # Break out of the loop for any other value
