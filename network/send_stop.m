% name: send_stop
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to send decoration messages over tcp/ip
%
% usage: send_stop(tcpObject)
%
% inputs: 
%   tcpObject - a tcpip object which you want to send data to
%
% Outputs:
%   none
function send_stop(tcpObject)

networksend(tcpObject, 0, 0, 5);

end