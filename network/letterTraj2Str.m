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