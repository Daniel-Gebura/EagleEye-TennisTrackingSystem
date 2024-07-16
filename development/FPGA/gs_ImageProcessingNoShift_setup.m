function gs_ImageProcessingNoShift_setup(hFPGA)
%--------------------------------------------------------------------------
% Host Interface Script Setup
% 
% Generated with MATLAB 9.14 (R2023a) at 11:42:25 on 27/04/2024.
% This function was created for the IP Core generated from design 'ImageProcessingNoShift'.
% 
% Run this function on an "fpga" object to configure it with the same interfaces as the generated IP core.
%--------------------------------------------------------------------------

%% AXI4-Lite
addAXI4SlaveInterface(hFPGA, ...
	"InterfaceID", "AXI4-Lite", ...
	"BaseAddress", 0x43C60000, ...
	"AddressRange", 0x10000);


end
