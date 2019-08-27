% name: send_ink_printing
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to send decoration messages over tcp/ip
%
% usage: send_ink_printing(tcpObject, Traj)
%
% inputs: 
%   tcpObject - a tcpip object which you want to send data to
%   Traj -the x,y coordinates of letter trajectories
%
% Outputs:
%   none
function send_ink_printing(tcpObject, Traj)

networksend(tcpObject, Traj, 0, 2);

end