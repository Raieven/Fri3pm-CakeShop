% name: networksend 
% author: Lawrence Wang, z5075019
%
% Description: This is a routine to send messages over tcp/ip
%
% usage: networksend(tcpObject, data, data2,messagetype)
%
% inputs: 
%   tcpObject - a tcpip object which you want to send data to
%   data - for messagetype 1, a blockOrder, the x,y,z coordinates of blocks
%          for messagetype 2, a Traj, the x,y coordinates of letter
%          trajectories
%   data2 - for message type 1, a leftOverBlocks, the x,y,z coordinates of
%           leftover blocks
%           for message type 2, unused
%   messagetype - describes what type of message is being sent. 0 for
%                 error message, 1 for block trajectories, 2 for letter
%                 trajectories
%
% Outputs:
%   none


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
    m(2) = 'pauseResume';
    
elseif (messagetype == 5)
    m(1) = "5";
    m(2) = 'stop';
end


sizeOfStrArr = size(m,2);
%  while (tcpObject.BytesAvailable > 0)
%         fscanf(tcpObject);
%  end
    
%fopen(t);
count = 0;
for i = 1:sizeOfStrArr
    ack = '';
    fprintf(tcpObject, m(i));
    %pause(0.005);
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
%fclose(t);

end

