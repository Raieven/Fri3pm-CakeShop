% name: send_decorations
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to send decoration messages over tcp/ip
%
% usage: send_decorations(tcpObject, blockOrder, leftOverBlocks)
%
% inputs: 
%   tcpObject - a tcpip object which you want to send data to
%   blockOrder -  the x,y,z coordinates of blocks
%   leftOverBlocks - the x,y,z coordinates of leftover blocks
%
% Outputs:
%   none
function send_decorations(tcpObject, blockOrder, leftOverBlocks)

networksend(tcpObject, blockOrder,leftOverBlocks, 1);

end