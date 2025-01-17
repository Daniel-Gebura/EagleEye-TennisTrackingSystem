-- -------------------------------------------------------------
-- 
-- File Name: S:\Documents\ESD2_Final_Project\FPGA_stuff\hdl_prj3\hdlsrc\ImageProcessingNoShift\subtracti_ip_src_subtraction_core.vhd
-- Created: 2024-04-27 11:05:49
-- 
-- Generated by MATLAB 9.14 and HDL Coder 4.1
-- 
-- 
-- -------------------------------------------------------------
-- Rate and Clocking Details
-- -------------------------------------------------------------
-- Model base rate: 2.77039e-06
-- Target subsystem base rate: 2.77039e-06
-- 
-- 
-- Clock Enable  Sample Time
-- -------------------------------------------------------------
-- ce_out        2.77039e-06
-- -------------------------------------------------------------
-- 
-- 
-- Output Signal                 Clock Enable  Sample Time
-- -------------------------------------------------------------
-- Video_out                     ce_out        2.77039e-06
-- valid_out_hStart              ce_out        2.77039e-06
-- valid_out_hEnd                ce_out        2.77039e-06
-- valid_out_vStart              ce_out        2.77039e-06
-- valid_out_vEnd                ce_out        2.77039e-06
-- valid_out_valid               ce_out        2.77039e-06
-- -------------------------------------------------------------
-- 
-- -------------------------------------------------------------


-- -------------------------------------------------------------
-- 
-- Module: subtracti_ip_src_subtraction_core
-- Source Path: ImageProcessingNoShift/subtraction_core
-- Hierarchy Level: 0
-- 
-- Simulink model description for ImageProcessingNoShift:
-- 
-- Sobel Edge Detection Using the MATLAB(R) Function Block
-- This example shows how to use HDL Coder(TM) to check, 
-- generate, and verify HDL code for a Sobel Edge Detection 
-- block built using the MATLAB Function block.
-- 
-- -------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY subtracti_ip_src_subtraction_core IS
  PORT( clk                               :   IN    std_logic;
        reset                             :   IN    std_logic;
        clk_enable                        :   IN    std_logic;
        Video_in                          :   IN    std_logic_vector(63 DOWNTO 0);  -- ufix64
        ctrl_hStart                       :   IN    std_logic;
        ctrl_hEnd                         :   IN    std_logic;
        ctrl_vStart                       :   IN    std_logic;
        ctrl_vEnd                         :   IN    std_logic;
        ctrl_valid                        :   IN    std_logic;
        ce_out                            :   OUT   std_logic;
        Video_out                         :   OUT   std_logic_vector(63 DOWNTO 0);  -- ufix64
        valid_out_hStart                  :   OUT   std_logic;
        valid_out_hEnd                    :   OUT   std_logic;
        valid_out_vStart                  :   OUT   std_logic;
        valid_out_vEnd                    :   OUT   std_logic;
        valid_out_valid                   :   OUT   std_logic
        );
END subtracti_ip_src_subtraction_core;


ARCHITECTURE rtl OF subtracti_ip_src_subtraction_core IS

  -- Component Declarations
  COMPONENT subtracti_ip_src_Subsystem1
    PORT( clk                             :   IN    std_logic;
          reset                           :   IN    std_logic;
          enb                             :   IN    std_logic;
          In2                             :   IN    std_logic_vector(63 DOWNTO 0);  -- ufix64
          Video_out                       :   OUT   std_logic_vector(63 DOWNTO 0)  -- ufix64
          );
  END COMPONENT;

  -- Component Configuration Statements
  FOR ALL : subtracti_ip_src_Subsystem1
    USE ENTITY work.subtracti_ip_src_Subsystem1(rtl);

  -- Signals
  SIGNAL enb                              : std_logic;
  SIGNAL Subsystem1_out1                  : std_logic_vector(63 DOWNTO 0);  -- ufix64
  SIGNAL alpha_reg                        : std_logic_vector(0 TO 1);  -- ufix1 [2]
  SIGNAL Delay1_out1_hStart               : std_logic;
  SIGNAL alpha_reg_1                      : std_logic_vector(0 TO 1);  -- ufix1 [2]
  SIGNAL Delay1_out1_hEnd                 : std_logic;
  SIGNAL alpha_reg_2                      : std_logic_vector(0 TO 1);  -- ufix1 [2]
  SIGNAL Delay1_out1_vStart               : std_logic;
  SIGNAL alpha_reg_3                      : std_logic_vector(0 TO 1);  -- ufix1 [2]
  SIGNAL Delay1_out1_vEnd                 : std_logic;
  SIGNAL alpha_reg_4                      : std_logic_vector(0 TO 1);  -- ufix1 [2]
  SIGNAL Delay1_out1_valid                : std_logic;

BEGIN
  u_Subsystem1 : subtracti_ip_src_Subsystem1
    PORT MAP( clk => clk,
              reset => reset,
              enb => clk_enable,
              In2 => Video_in,  -- ufix64
              Video_out => Subsystem1_out1  -- ufix64
              );

  enb <= clk_enable;

  c_process : PROCESS (clk)
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF reset = '1' THEN
        alpha_reg <= (OTHERS => '0');
      ELSIF enb = '1' THEN
        alpha_reg(0) <= ctrl_hStart;
        alpha_reg(1) <= alpha_reg(0);
      END IF;
    END IF;
  END PROCESS c_process;

  Delay1_out1_hStart <= alpha_reg(1);

  c_1_process : PROCESS (clk)
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF reset = '1' THEN
        alpha_reg_1 <= (OTHERS => '0');
      ELSIF enb = '1' THEN
        alpha_reg_1(0) <= ctrl_hEnd;
        alpha_reg_1(1) <= alpha_reg_1(0);
      END IF;
    END IF;
  END PROCESS c_1_process;

  Delay1_out1_hEnd <= alpha_reg_1(1);

  c_2_process : PROCESS (clk)
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF reset = '1' THEN
        alpha_reg_2 <= (OTHERS => '0');
      ELSIF enb = '1' THEN
        alpha_reg_2(0) <= ctrl_vStart;
        alpha_reg_2(1) <= alpha_reg_2(0);
      END IF;
    END IF;
  END PROCESS c_2_process;

  Delay1_out1_vStart <= alpha_reg_2(1);

  c_3_process : PROCESS (clk)
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF reset = '1' THEN
        alpha_reg_3 <= (OTHERS => '0');
      ELSIF enb = '1' THEN
        alpha_reg_3(0) <= ctrl_vEnd;
        alpha_reg_3(1) <= alpha_reg_3(0);
      END IF;
    END IF;
  END PROCESS c_3_process;

  Delay1_out1_vEnd <= alpha_reg_3(1);

  c_4_process : PROCESS (clk)
  BEGIN
    IF clk'EVENT AND clk = '1' THEN
      IF reset = '1' THEN
        alpha_reg_4 <= (OTHERS => '0');
      ELSIF enb = '1' THEN
        alpha_reg_4(0) <= ctrl_valid;
        alpha_reg_4(1) <= alpha_reg_4(0);
      END IF;
    END IF;
  END PROCESS c_4_process;

  Delay1_out1_valid <= alpha_reg_4(1);

  ce_out <= clk_enable;

  Video_out <= Subsystem1_out1;

  valid_out_hStart <= Delay1_out1_hStart;

  valid_out_hEnd <= Delay1_out1_hEnd;

  valid_out_vStart <= Delay1_out1_vStart;

  valid_out_vEnd <= Delay1_out1_vEnd;

  valid_out_valid <= Delay1_out1_valid;

END rtl;

