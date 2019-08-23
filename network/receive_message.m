% name: receive_message
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to open a socket to connect to
%
% usage: [messageString, messageType] = receive_message(tcpObject)
%
% inputs: 
%   tcpObject - a tcpip object which you want to receive data from
%
% Outputs:
%   errorString - the error message received
%   messageType - the type of message (0 is an error message, 3 is a job
%                   finished message)

function [messageString, messageType] = receive_message(tcpObject)
    message = fscanf(tcpObject);
    messageType = str2num(message(1));
    messageString = message(3:end-1);
end