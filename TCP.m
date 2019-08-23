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
    tcpip_internal.receive = @receive_message;
    tcpip_internal.send_decorations = @send_decorations;
    tcpip_internal.send_ink = @send_ink_printing;
    tcpip_internal.send_toggle = @send_pause_resume;
    tcpip_internal.send_stop = @send_stop;
    tcpip_copy = tcpip_internal;
end

function openSocket(ip, port)
    global tcpip_internal;
% open socket to robot

    tcpip_internal = tcpip(ip, port, 'NetworkRole', 'client');
    fopen(tcpip_internal);

end

function [str] = your_close_function()
    global tcpip_internal;
% close socket to robot
    fclose(tcpip_internal.socket);
end

function [messageString, messageType] = receive_message()
    global tcpip_internal;
% recv error data from robot
    %str = [];
    message = fscanf(tcpip_internal);
    messageType = str2num(message(1));
    messageString = message(3:end-1);
end

function send_decorations(blockOrder, leftOverBlocks)
    global tcpip_internal;
% send decoration data to robot
    networksend(tcpip_internal, blockOrder, leftOverBlocks, 1);
end

function send_ink_printing(Traj)
    global tcpip_internal;
% send ink data to robot
    networksend(tcpip_internal, Traj, 0, 2);

end

function send_pause_resume()
    global tcpip_internal;
% send ink data to robot
    networksend(tcpip_internal, 0, 0, 4);

end

function send_stop()
    global tcpip_internal;
% send ink data to robot
    networksend(tcpip_internal, 0, 0, 5);

end

% ----------------- Function ------------------ %
% INTERNAL FUNCTIONS HERE
function networksend(tcpObject, data, data2,messagetype)
    %t = tcpip('localhost', 20000, 'NetworkRole', 'client');
    %t.OutputBufferSize = 1000000;
    endmessage = 'end';
    if (messagetype == 2)
        m = letterTraj2Str(data);

    elseif (messagetype == 1)
        m = blockTraj2Str(data,data2);

    elseif (messagetype == 4)
        m(1) = "4";
        m(2) = 'pause/resume';

    elseif (messagetype == 5)
        m(1) = "5";
        m(2) = 'stop';
    end


    sizeOfStrArr = size(m,2);

    %fopen(t);
    count = 0;
    for i = 1:sizeOfStrArr
        ack = '';
        fprintf(tcpObject, m(i));
        while (tcpObject.BytesAvailable == 0)
            %wait for ack
        end
        ack = fscanf(tcpObject);
        if (contains(ack, "ACK"))
            %string was received
        elseif (ack(1) == '0')
            %count = count+1;
            %string was not received
        end
    end
    fprintf(tcpObject, endmessage);     %end the transmission
    ack = fscanf(tcpObject);
    if (contains(ack, "ACK"))
        %string was received
    elseif (ack(1) == '0')
        %count = count+1;
        %string was not received
    end
    %fclose(t);

end

function m = letterTraj2Str(Traj)
    s = size(Traj);
    posStringArray = 1;
    m(posStringArray) = "2";  %message type is letter trajectory
    posStringArray = posStringArray + 1;
    m(posStringArray) = num2str(s(2));  %num letters
    posStringArray = posStringArray + 1;
    for i = 1:s(2)
        sd{i} = size(Traj{2,i});
        m(posStringArray) = num2str(sd{i}(1)); %num coords of each letter
        posStringArray = posStringArray + 1;
    end
    
    for i = 1:s(2)
        m(posStringArray) = num2str(Traj{1,i}); % boldness of letter
        posStringArray = posStringArray + 1;
    end
    for i = 1:s(2)
       
       for j = 1:sd{i}(1)
           m(posStringArray) = num2str(Traj{2,i}(j,1)); %x coordinate
           posStringArray = posStringArray + 1;
           m(posStringArray) = num2str(Traj{2,i}(j,2)); %y coordinate
           posStringArray = posStringArray + 1;
           
       end
        
    end
    

end

function m = blockTraj2Str(blockOrder,leftOverBlocks)
    s = size(blockOrder);
    s1 = size(leftOverBlocks);
    posStringArray = 1;
    m(posStringArray) = "1";  %message type is block trajectory
    posStringArray = posStringArray + 1;
    m(posStringArray) = num2str(s(1));  %num blocks on cake
    posStringArray = posStringArray + 1;
    m(posStringArray) = num2str(s1(1));  %num leftOver blocks
    posStringArray = posStringArray + 1;
       
    for i = 1:s(1)
        m(posStringArray) = num2str(blockOrder(i,1));  %x coordinate of cake block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,2));  %y coordinate of cake block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,3));  %z coordinate of cake block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,4));  %x coordinate of conveyor block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,5));  %y coordinate of conveyor block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,6));  %z coordinate of cake block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(blockOrder(i,7));  %orientation of block
        posStringArray = posStringArray + 1;
    end
    for i = 1:s1(1)
        m(posStringArray) = num2str(leftOverBlocks(i,1));  %x coordinate of leftover block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(leftOverBlocks(i,2));  %y coordinate of leftover block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(leftOverBlocks(i,3));  %z coordinate of leftover block
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(leftOverBlocks(i,4));  %x coordinate of junk area
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(leftOverBlocks(i,5));  %y coordinate of junk area
        posStringArray = posStringArray + 1;
        m(posStringArray) = num2str(leftOverBlocks(i,6));  %z coordinate of junk area
        posStringArray = posStringArray + 1;
    end
    
end