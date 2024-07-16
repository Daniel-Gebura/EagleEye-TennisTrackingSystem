# Dr. Kaputa
# Frame Grabber

import cv2
import numpy as np
import time
import mmap
import struct
import sys, random
import ctypes
import copy

class ImageFeedthrough(object):
  def __init__(self):
    self.lib = ctypes.cdll.LoadLibrary('/fusion2/imageFeedthroughDriver.so')
    result = self.lib.init("vdma1-read-regs","vdma1-read-bufs",752,480,8)
    self.receiveFrame= np.ones((480,752,8), dtype=np.uint8)
    
    self.f2 = open("/dev/mem", "r+b")
    self.switchMem = mmap.mmap(self.f2.fileno(), 1000, offset=0x43c20000)
    
  def getStereoRGB(self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    self.switchMem.seek(0) 
    self.switchMem.write(struct.pack('l', 1))
    return self.receiveFrame[:,:,0:3],self.receiveFrame[:,:,4:7]

  def getStereoGray (self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    return self.receiveFrame[:,:,0],self.receiveFrame[:,:,1]
    
  def getStereoAll (self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    return self.receiveFrame[:,:,0:4],self.receiveFrame[:,:,4:8]
 
  def __del__(self):
    result = self.lib.destroy
    self.switchMem.close()
    self.f2.close()
        
class ImageProcessing(object):
  def __init__(self):
    self.lib = ctypes.cdll.LoadLibrary('/fusion2/imageProcessingDriver.so')
    result = self.lib.init()
    self.receiveFrame= np.ones((480,752,8), dtype=np.uint8)
  
    self.f2 = open("/dev/mem", "r+b")
    self.switchMem = mmap.mmap(self.f2.fileno(), 1000, offset=0x43c20000)

  def getStereoRGB(self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    self.switchMem.seek(0) 
    self.switchMem.write(struct.pack('l', 1))
    return self.receiveFrame[:,:,0:3],self.receiveFrame[:,:,4:7]

  def getStereoGray (self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    return self.receiveFrame[:,:,0],self.receiveFrame[:,:,1]

  # temp function until I have the simulink data stored in the gray channel
  def getStereoGrayFrame (self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    self.switchMem.seek(0) 
    self.switchMem.write(struct.pack('l', 1))
    return self.receiveFrame[:,:,1],self.receiveFrame[:,:,4]
    
  def getStereoAll (self):
    result = self.lib.getFrame(ctypes.c_void_p(self.receiveFrame.ctypes.data))
    return self.receiveFrame[:,:,0:4],self.receiveFrame[:,:,4:8]
    
  def setSource(self,source):
    if source == 0:
        print ("setting camera source [cam]")
        self.switchMem.seek(4) 
        self.switchMem.write(struct.pack('l', 0))
    else:    
        print ("setting camera source [debug]")
        self.switchMem.seek(4) 
        self.switchMem.write(struct.pack('l', 1))
      
  def __del__(self):
    result = self.lib.destroy
    self.switchMem.close()
    self.f2.close()
    
class ImageWriter(object):
  def __init__(self):
    self.lib = ctypes.cdll.LoadLibrary('/fusion2/imageWriterDriver.so')
    result = self.lib.init()
    self.f2 = open("/dev/mem", "r+b")
    self.switchMem = mmap.mmap(self.f2.fileno(), 1000, offset=0x43c20000)
  
  def setFrame(self,frame):
    result = self.lib.setFrame(ctypes.c_void_p(frame.ctypes.data))
    self.switchMem.seek(4) 
    self.switchMem.write(struct.pack('l', 1))
    # when x04 is 0 this is pulling from real camera
    # have to set 0x00 to 1 twice to get matlab pic to display for some reason
    
    time.sleep(.5)
    self.switchMem.seek(0) 
    self.switchMem.write(struct.pack('l', 1))
    time.sleep(.5)
    self.switchMem.write(struct.pack('l', 1))
    # time.sleep(.5)
    # self.switchMem.seek(0) 
    # self.switchMem.write(struct.pack('l', 1))
    # time.sleep(.5)
    # self.switchMem.seek(0) 
    # self.switchMem.write(struct.pack('l', 1))
    # time.sleep(.5)
    # self.switchMem.seek(0) 
    # self.switchMem.write(struct.pack('l', 1))
 
  def __del__(self):
    result = self.lib.destroy

#
def initFPGA():
    """
    Imitializes the simulink model and returns objects to interact with the model

    :param fpga : Boolean to dictate whether this FPGA should be initialized

    :return : A tuple of VDMA controlling objects called camProcess, camFeedthrough, camWriter
    """
    camProcessed = ImageProcessing()
    camFeedthrough = ImageFeedthrough()
    camWriter = ImageWriter()

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

    return camProcessed, camFeedthrough, camWriter
