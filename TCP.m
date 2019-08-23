% Author: 
% ID: 
% Date: 
% Description: 
% MTRN4230 Group Assignment
% Computer Vision program for ink printing 
%
% Objectification by Jesse Falzon
%
% Usage:
%       make object with:
%   >> Dec = Decoration();
%
%       call vision code with
%   >> Image = imread('path/to.jpg');
%   >> [from, to, angle] = Dec.update(Image);
%
%  Input: 
%   Image - Image taken from table camera
%   eg: Image = '1.png';
%
%  Output:
%
%   from(i,:)   - X, Y, Z coords of the i-th block on the conveyor
%   to(i,:)     - X, Y, Z coords of the i-th block on the table
%   angle(i)    - the angle to turn i-th block on the table


function [tcpip_copy] = TCP()
    global tcpip_internal;
    
    tcpip_internal.open = @openSocket;
    tcpip_internal.close = @your_close_function;
    tcpip_internal.receive = @your_receive_function;
    tcpip_internal.send_decorations = @your_send_decorations_function;
    tcpip_internal.send_ink = @your_send_ink_function;
    tcpip_internal.send_toggle = @your_send_toggle_function;
    tcpip_copy = tcpip_internal;
end

function openSocket(ip, port)
    global tcpip_internal;
% open socket to robot

    %tcpip_internal = tcpip(ip, port, 'NetworkRole', 'client');
    %fopen(tcpip_internal);
    fprintf('opening robot socket\n');
end

function [str] = your_close_function()
    global tcpip_internal;
% close socket to robot

    %fclose(tcpip_internal);
    fprintf('closing robot socket\n');
end

function [str] = your_update_function()
    global tcpip_internal;
% recv error data from robot
    str = [];
    fprintf('getting robot string\n');
end

function your_send_decorations_function(data)
    global tcpip_internal;
% send decoration data to robot
    fprintf('sending decoration data\n');

end

function your_send_ink_function(data)
    global tcpip_internal;
% send ink data to robot

    fprintf('sending ink data\n');
end

function your_send_toggle_function(data)
    global tcpip_internal;
% send ink data to robot

    fprintf('sending status toggle\n');
end

% ----------------- Function ------------------ %
% INTERNAL FUNCTIONS HERE
