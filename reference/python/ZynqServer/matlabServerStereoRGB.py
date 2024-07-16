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
from frameGrabber import ImageProcessing
from frameGrabber import ImageFeedthrough
from frameGrabber import ImageWriter

camProcessed = ImageProcessing()
camFeedthrough = ImageFeedthrough()
camWriter = ImageWriter()

npSocket = NumpySocket()
npSocket.startServer(9999)

# only set this flag to true if you have generated your bit file with a 
# Vivado reference design for Simulink
simulink = True    
if simulink == True:
    f1 = open("/dev/mem", "r+b")
    simulinkMem = mmap.mmap(f1.fileno(), 1000, offset=0x43c60000)
    simulinkMem.seek(0) 
    simulinkMem.write(struct.pack('l', 1))       # reset IP core
    simulinkMem.seek(8)                         
    simulinkMem.write(struct.pack('l', 1920))     # image width
    simulinkMem.seek(12)                        
    simulinkMem.write(struct.pack('l', 1080))     # image height
    simulinkMem.seek(16)                        
    simulinkMem.write(struct.pack('l', 94))       #  horizontal porch
    simulinkMem.seek(20)                        
    simulinkMem.write(struct.pack('l', 1000))     #  vertical porch when reading from debug
    simulinkMem.seek(256) 
    simulinkMem.write(struct.pack('l', 1))       # filter select
    simulinkMem.seek(4) 
    simulinkMem.write(struct.pack('l', 1))       # enable IP core

print "entering main loop"

# feel free to modify this command structue as you wish.  It might match the 
# command structure that is setup in the Matlab side of things on the host PC.
while(1):
    cmd = npSocket.receiveCmd()
    print(cmd)
    if cmd == '0':
        data = npSocket.receive()
        camWriter.setFrame(data)
        npSocket.send(np.array(2))
    elif cmd == '1':
        frameLeft,frameRight = camFeedthrough.getStereoRGB()
        tempImageLeft = np.ascontiguousarray(frameLeft, dtype=np.uint8) 
        tempImageRight = np.ascontiguousarray(frameRight, dtype=np.uint8) 
        npSocket.send(tempImageLeft)
        npSocket.send(tempImageRight)
    elif cmd == '2':
        frameLeft,frameRight = camProcessed.getStereoRGB()
        tempImageLeft = np.ascontiguousarray(frameLeft, dtype=np.uint8) 
        tempImageRight = np.ascontiguousarray(frameRight, dtype=np.uint8) 
        npSocket.send(tempImageLeft)
        npSocket.send(tempImageRight) 
    else:
        break
npSocket.close()