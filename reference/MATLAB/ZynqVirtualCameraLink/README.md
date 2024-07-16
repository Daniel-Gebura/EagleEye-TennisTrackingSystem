# matlab-virtual-camera
this code base will send over an image from Matlab to a Zynq FPGA SoC and receive back 
a filtered image.  The Zynq SoC can prove out any image processing algorithm without the 
need to have an actual hardware camera.

- the matlab zynq server is required and needs to be run on the Zynq SoC
- for FPGA image processing the userspace vdma driver and vivado dma project are needed