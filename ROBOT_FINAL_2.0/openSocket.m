% name: openSocket
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to open a socket to connect to
%
% usage: t = openSocket(ip, port)
%
% inputs: 
%   ip - the ip address which you want to connect to
%   port - the port which you want to connect to
%
% Outputs:
%   t - a tcpip oebject which contains information on the socket
%
% Notes:
%   the socket should be closed after use - fclose(t)
function t = openSocket(ip, port)
    
    t = tcpip(ip, port, 'NetworkRole', 'client');
    fopen(t);
end