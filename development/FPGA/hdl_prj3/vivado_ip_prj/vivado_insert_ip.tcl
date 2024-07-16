open_project vivado_prj.xpr
set HDLVerifierAXI {off}
update_ip_catalog -delete_ip {./ipcore/subtracti_ip_v1_0/component.xml} -repo_path {./ipcore} -quiet
update_ip_catalog -add_ip {./ipcore/subtracti_ip_v1_0.zip} -repo_path {./ipcore}
update_ip_catalog
set HDLCODERIPVLNV [get_property VLNV [get_ipdefs -filter {NAME==subtracti_ip && VERSION==1.0}]]
set HDLCODERIPINST subtracti_ip_0
set BDFILEPATH [get_files -quiet design_1.bd]
open_bd_design $BDFILEPATH
create_bd_cell -type ip -vlnv $HDLCODERIPVLNV $HDLCODERIPINST
connect_bd_net -net [get_bd_nets -of_objects [get_bd_pins processing_system7_0/FCLK_CLK0]] [get_bd_pins $HDLCODERIPINST/AXI4_Lite_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net -net [get_bd_nets -of_objects [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]] [get_bd_pins $HDLCODERIPINST/AXI4_Lite_ARESETN] [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]
connect_bd_intf_net [get_bd_intf_pins $HDLCODERIPINST/AXI4_Lite] [get_bd_intf_pins ps7_0_axi_periph/M05_AXI]
create_bd_addr_seg -range 0x10000 -offset 0x43C60000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs $HDLCODERIPINST/AXI4_Lite/reg0] SEG_${HDLCODERIPINST}_reg0
connect_bd_intf_net [get_bd_intf_pins $HDLCODERIPINST/AXI4_Stream_Video_Master] [get_bd_intf_pins axi_vdma_2/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins $HDLCODERIPINST/AXI4_Stream_Video_Slave] [get_bd_intf_pins axis_broadcaster_0/M00_AXIS]
connect_bd_net -net [get_bd_nets -of_objects [get_bd_pins processing_system7_0/FCLK_CLK0]] [get_bd_pins $HDLCODERIPINST/IPCORE_CLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
connect_bd_net -net [get_bd_nets -of_objects [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]] [get_bd_pins $HDLCODERIPINST/IPCORE_RESETN] [get_bd_pins rst_ps7_0_50M/peripheral_aresetn]
make_wrapper -files $BDFILEPATH -top
regsub -all "design_1.bd" [get_files design_1.bd] "hdl" TOPFILEPATH
add_files -norecurse $TOPFILEPATH
update_compile_order -fileset sources_1
validate_bd_design
save_bd_design
add_files -fileset constrs_1 -norecurse constraints.xdc
close_project
exit
