This code base implements a server on a Xilinx Zynq FPGA SoC which is capable of communicating with a host PC.  The server
is setup to receive discrete commands as well as full raw image frames.  This is a major component of the Mathworks Virtual 
Camera infrastructure.  One can process the images in linux or optionally send them down to the programmable logic via the 
user space VDMA driver.
