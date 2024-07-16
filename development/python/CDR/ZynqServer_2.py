# ZynqServer_2.py allows a client to connect, receives a processed image (expected FPGA output),
# applies a centroid detection algorithm and returns the x,y centroid pixel coordinate
from numpysocket import NumpySocket
import cv2
import numpy as np
import time
import mmap
import struct
import sys, random
import ctypes
import copy

npSocket = NumpySocket()
npSocket.startServer(9999)

print ("entering main loop")

# feel free to modify this command structue as you wish.  It might match the 
# command structure that is setup in the Matlab side of things on the host PC.
while(1):
    cmd = npSocket.receiveCmd()
    #print(cmd)
    if cmd == '0':
        print ("received frame from matlab")
        data = npSocket.receive()
        stereoImage = np.reshape(data,(480, 752,8))
        print ("converted image")
    elif cmd == '1':
        print ("sending processed frames to matlab")
        time.sleep(1)
        ballLeftGray = stereoImage[:,:,0]
        ballLeftGray = np.ascontiguousarray(ballLeftGray, dtype=np.uint8) 
        
        npSocket.send(ballLeftGray)
    elif cmd == '2':
        print("sending coordinates to matlab")
        time.sleep(1)

        # Assuming 'stereoImage[:,:,0]' has been loaded into 'image'
        image = stereoImage[:,:,0]

        # Step 1: Threshold the image to isolate the white ball
        _, thresh = cv2.threshold(image, 200, 255, cv2.THRESH_BINARY)  # Adjust the threshold value as needed

        # Step 2: Find contours in the thresholded image
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)[-2:]

        # Step 3: Find the centroid of the largest contour
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            M = cv2.moments(largest_contour)
            if M["m00"] != 0:
                cx = int(M["m10"] / M["m00"])
                cy = int(M["m01"] / M["m00"])
            else:
                cx, cy = 0, 0  # Default to (0,0) if contour is negligible

            # Convert coordinates to uint32
            coordinates = np.array([cx, cy], dtype=np.uint32)

            # Step 4: Send the coordinates
            npSocket.send(coordinates)
        else:
            print("No contours found!")
            coordinates = np.array([0,0], dtype=np.uint32)
            npSocket.send(coordinates)
    else:
        break
npSocket.close()