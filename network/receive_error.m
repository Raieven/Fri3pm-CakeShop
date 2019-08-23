% name: receive_error
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to open a socket to connect to
%
% usage: errorString = receive_error(tcpObject)
%
% inputs: 
%   tcpObject - a tcpip object which you want to receive data from
%
% Outputs:
%   errorString - the error message received

function errorString = receive_error(tcpObject)
    errorMessage = fscanf(tcpObject);
    errorString = errorMessage(3:end-1);
end