# ZynqServer_1.py allows a client to connect, receives frames and passes them back to client. NO PROCESSING
# Dr. Kaputa
# Matlab Server
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
    else:
        break
npSocket.close()