<picture>
   <img src = "design/graphics/EagleEyeCompanyLogo.png">
</picture>

## Tennis Ball Tracking Solution
1. Access Tennis Ball Tracking App in directory `/development/MATLAB/Demo/cdr_GUI.mlapp`
2. Start the server on the snickerdoodle board with command line `python ZyqnServer_5.py`
3. In the GUI, click `Run` to simulate ball shot and calculate trajectory
4. To display the coefficient of restitution, click `Calculate`

## How to access snickerdoodle board
1. Plug snickerdoodle board into your computer via USB-A cable.
2. Using PuTTY or Tera Term V3, initiate a SSH/TCP connection or a serial connection
   
    - For SSH/TCP connection:
      - username: `root@<snickerdoodleIP>`
      - port: `22`
    - For serial connection:
      - port: `COM#STMelectronics`
      - The COM # will vary depending on which USB port and device you plug the snickerdoodle board into
      
3. If you are attempting a serial connection, enter username `xilinx` and password `xilinx` to access the board.
4. To access root, enter `sudo -i` by which you will be prompted to enter your password again, `xilinx`.
5. Change directory to `/fusion2/` with command `cd /fusion2`
6. From there, you can run the server using `python ZyqnServer_5.py`

