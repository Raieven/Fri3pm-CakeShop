function networksend(data, data2,messagetype)
t = tcpip('localhost', 20000, 'NetworkRole', 'client');
t.OutputBufferSize = 1000000;
endmessage = 'end';
if (messagetype == 2)
    m = letterTraj2Str(data);
    
elseif (messagetype == 1)
    m = blockTraj2Str(data,data2);
    
end


sizeOfStrArr = size(m,2);
    
fopen(t);

for i = 1:sizeOfStrArr
    ack = '';
    fprintf(t, m(i));
    while (t.BytesAvailable == 0)
        %wait for ack
    end
    ack = fscanf(t);
    if (ack == "ACK\n")
        %string was received
    else
        %error
    end
end
fprintf(t, endmessage);

fclose(t);

end

