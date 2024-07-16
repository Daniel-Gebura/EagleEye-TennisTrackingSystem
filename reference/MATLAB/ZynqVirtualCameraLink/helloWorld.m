% Dr. Kaputa
% Virtual Camera Demo
% must run helloWorld.py first on the FPGA SoC

%Initialization Parameters
server_ip   = '129.21.40.214';     % IP address of the server
server_port = 9999;                % Server Port of the sever

client = tcpclient(server_ip,server_port);
fprintf(1,"Connected to server\n");
 
for i = 5:6
    % Convert the current number i to a string and concatenate it
    numberStr = num2str(i);
    
    % Send the string to the client
    write(client, numberStr);
    flush(client);
end