% name: send_pause_resume
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to send decoration messages over tcp/ip
%
% usage: send_pause_resume(tcpObject)
%
% inputs: 
%   tcpObject - a tcpip object which you want to send data to
%
% Outputs:
%   none
function send_pause_resume(tcpObject)

networksend(tcpObject, 0, 0, 4);

end