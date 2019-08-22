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