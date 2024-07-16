function [isShotIn, restitutionCoeff, xCoeff, yCoeff, bounceT] = MatlabClientAPI(inMODE, inMATCH_TYPE, inSHOT_TYPE, inpath)
	% MatlabClient_Final performs the following:
	% - Waits for the GUI to initialize its parameters
	% - Once GUI initiates process, connects to server over wifi
	% - Sends INIT PARAMETERS protocol to server
	% - Enters REQUEST-RETRIEVE-RESPOND LOOP to send frames to the server
	% - Once told to stop, requests results
	% - Receives results to diaply on GUI including some debugging graphics
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CONSTANTS AND SETTINGS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Image Transfer Dimensions
	width = 752.0;
	height = 480.0;
	
	% Server IP address
	%server_ip   = '129.21.42.146'; % Debug Computer
	server_ip   = '129.21.42.10'; % Board
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CLIENT INITIALIZATION (GUI PASS PARAMETERS/START)
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Function to preprocess images (convert to grayscale)
	preprocessImage = @(img) rgb2gray(img);
	% Get and save Empty Court images (Left/Right) ONCE. 
	emptyLeftImage = imread("../../testImages/LeftEmptyCourt.jpg");
	emptyRightImage = imread("../../testImages/rightEmptyCourt.jpg");
	emptyLeftGray = preprocessImage(emptyLeftImage);
	emptyRightGray = preprocessImage(emptyRightImage);
	
	% Get these parameters from GUI
	MODE = num2str(inMODE);    % 1 -> coefficient of restitution, 2 -> ball is inside or out
	MATCH_TYPE = num2str(inMATCH_TYPE); % 1 -> singles mode, -> 2 doubles mode
	SHOT_TYPE = num2str(inSHOT_TYPE);  % 1 -> serve mode, 2 -> volley mode
	path = inpath % Path to .dat file being used
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% CONNECT TO SERVER
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%Connect to sever;
	server_port = 9999;                % Server Port of the sever
	client = tcpclient(server_ip,server_port);
	fprintf(1,"Connected to server\n");
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% SEND SERVER INIT PARAMETERS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Tell server to prepare to receive init parameters
	write(client,'0'); %Transfer Protocol
	flush(client);
	
	% Send mode
	write(client, MODE);
	flush(client);
	% Send match type
	write(client, MATCH_TYPE);
	flush(client);
	% Send shot type
	write(client, SHOT_TYPE);
	flush(client);
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% REQUEST-RETRIEVE-RESPOND LOOP
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Tell Server to begin processing a shot
	write(client,'1'); %Transfer Protocol
	flush(client);
	
	% Loop until Server sends special value
	while 1
		% 1. REQUEST - Wait for request from server (t value), exit if special value
		request = read(client, 1, 'uint32');
		request;
		if request == 99999 % Check if received STOP CMD
			break % Leaving Request-retrieve-respond Loop
		end
	
		% 2. RETRIEVE - Get Left/Right Unity images at time t
		errorCode = MoveTennisBall(request, path); % Move Tennis ball to desired location based on .dat file
		% Check if a request frame is valid (shot hasn't ended yet)
		if errorCode == 0 % Valid request: Send the frame
			% Get the image from UNITY
			[leftImage, rightImage] = MoveCamera(request, 0);
			% Grayscale Left/Right
			BallLeftGray  = preprocessImage(leftImage);
			BallRightGray = preprocessImage(rightImage);
			% Package all four images
			imageStack = uint8(ones(height,width,8));
			imageStack(:,:,1) = BallLeftGray;
			imageStack(:,:,2) = emptyLeftGray;
			imageStack(:,:,3) = BallRightGray;
			imageStack(:,:,4) = emptyRightGray;
			imageStack(:,:,5) = emptyRightGray;
			imageStack(:,:,6) = BallRightGray;
			imageStack(:,:,7) = emptyLeftGray;
			imageStack(:,:,8) = BallLeftGray;
		else % Invalid request: Shot ended. Send dummy frames
			%Package all four images (Empty Frames)
			disp('Requested Invalid Frames')
			imageStack = uint8(ones(height,width,8));
			imageStack(:,:,1) = ones(480, 752) * 0;
			imageStack(:,:,2) = ones(480, 752) * 0;
			imageStack(:,:,3) = ones(480, 752) * 0;
			imageStack(:,:,4) = ones(480, 752) * 0;
			imageStack(:,:,5) = ones(480, 752) * 0;
			imageStack(:,:,6) = ones(480, 752) * 0;
			imageStack(:,:,7) = ones(480, 752) * 0;
			imageStack(:,:,8) = ones(480, 752) * 0;
		end
		
		% 3. RESPOND - Send retrieved image stack
		imageStack = permute(imageStack,[3 2 1]);
		write(client,imageStack(:)); %SEND
		flush(client);
	
	end
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% RECEIVE RESULTS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Tell server to send requested results
	write(client,'2'); %Transfer Protocol
	flush(client);
	
	% Verify result format
	receiveMode = read(client, 1, 'uint32');
	
	% Get Mode-Specific Results
	if receiveMode == 1 % Coefficient of restitution
		restitutionCoeff = read(client, 1, 'double')
        isShotIn = 0;
        xCoeff = 0;
        yCoeff = 0;
        bounceT = 0;
	
	else % In/Out Decison or DEBUGGING
		if receiveMode == 2 % In/Out decision
			isShotIn = read(client, 1, 'double') % 1.0 = TRUE, 0.0 = FALSE
            restitutionCoeff = 0;
		end 
	
		% Receive calculated X,Y,Z trajectories
		xCoeff = read(client, 2, 'double');
		yCoeff = read(client, 2, 'double');
		zLen = read(client, 1, 'uint32');
		zCoeff = read(client, zLen, 'double');
		bounceT = read(client, 1, 'double');
	end
	
	% CLOSE SERVER
	write(client,'9999');
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% FORMAT RESULTS
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	isShotIn = uint8(isShotIn);
    restitutionCoeff = double(restitutionCoeff);
    xCoeff = double(xCoeff);
    yCoeff = double(yCoeff);
    bounceT = double(bounceT);
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% GUI RESULTS DISPLAY
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% IMPLEMENTATION NOTE: 
	% - If Coeff mode, gui only needs to state coefficient
	%   of restitution
	% - If In/Out Mode, gui displays In/Out decison and shows a top down plot
	%   of the court with the calc X,Y trajectory plotted ontop. Then put a
	%   special marker on he line at bounce(x,y) [x and y trajectories evaluated
	%   at bounceT]
	
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% ADDITIONAL INFO DISPLAY
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	if receiveMode == 2
		% 1. DISPLAY X,Y,Z REAL/CALC TRAJECTORY INDIVIDUALLY
		t = 1:ceil(bounceT); % Discrete steps of 1 ms
		% Populate calculated trajectory
		% Evaluate polynomials
		poly_X = polyval(xCoeff, t); % Flip to use polyval correctly
		poly_Y = polyval(yCoeff, t);
		poly_Z = polyval(zCoeff, t);
		% Populate actual correct results
		ballData = load(path);
		real_X = NaN(1, length(t));
		real_Y = NaN(1, length(t));
		real_Z = NaN(1, length(t));
		for i = 1:length(t)
			if i <= size(ballData, 1)
				real_X(i) = ballData(i, 3);
				real_Y(i) = ballData(i, 1);
				real_Z(i) = ballData(i, 2);
			else
				error('Index exceeds the number of rows in ballData file.');
			end
		end
		% Plotting
		figure;
		subplot(3, 1, 1);
		plot(t, poly_X, 'r'); % Plot calculated X positions in red
		hold on;
		plot(t, real_X, 'b'); % Plot real X positions in blue
		legend('Calculated X', 'Real X');
		title('Comparison of Calculated and Real X Positions Over Time');
		xlabel('Time, ms');
		ylabel('X Position, m');
		grid on;
		hold off;
		subplot(3, 1, 2);
		plot(t, poly_Y, 'r'); % Plot calculated Y positions in red
		hold on;
		plot(t, real_Y, 'b'); % Plot real X positions in blue
		legend('Calculated Y', 'Real Y');
		title('Comparison of Calculated and Real Y Positions Over Time');
		xlabel('Time, ms');
		ylabel('Y Position, m');
		grid on;
		hold off;
		subplot(3, 1, 3);
		plot(t, poly_Z, 'r'); % Plot calculated Z positions in red
		hold on;
		plot(t, real_Z, 'b'); % Plot real Z positions in blue
		legend('Calculated Z', 'Real Z');
		title('Comparison of Calculated and Real Z Positions Over Time');
		xlabel('Time, ms');
		ylabel('Z Position, m');
		grid on;
		hold off;
	
	% 2. 3D plot of real and calc trajectory?
		% Plotting
		figure;
		plot3(poly_X, poly_Y, poly_Z, 'r'); % Plot calculated X,Y,Z positions in red
		hold on;
		plot3(real_X, real_Y, real_Z, 'b'); % Plot real X,Y,Z positions in blue
		legend('Calculated XYZ', 'Real XYZ');
		title('Comparison of Calculated and Real XYZ Positions Over Time');
		xlabel('X position, m');
		ylabel('Y position, m');
		zlabel('Z position, m');
		grid on;
		zlim([0 inf]); % Set the minimum Z value to 0
		hold off;
	
    end
end