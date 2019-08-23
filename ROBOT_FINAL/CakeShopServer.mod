MODULE CakeShopServer
    !***********************************************************
    !
    ! Module: Cake Shop Server
    ! Author: Lawrence Wang, z5075019
    !
    ! Description: 
    !    Main server to receive information from Matlab image processing.
    !    Translates received data into arrays for T_ROB
    !   
    ! Inputs & Outputs: 
    !    See below functions
    !
    !***********************************************************

    ! Tcp socket object
    VAR socketdev client_socket;

    ! The host and port that we will be listening for a connection on. Currently set to localhost.
    PERS string host:="127.0.0.1";
    CONST num port:=20000;

    ! Array of letter coordinates
    ! Dimension 1 is the type of data i.e. 1 = boldness, 2 = x coordinate, 3 = y coordinate
    ! Dimension 2 is the letter number i.e. 1 is the first letter, 5 is the fifth letter
    ! Dimension 3 is the coordinate number in a letter i.e. 3 is the third coordinate
    ! e.g. letterArray{2, 3, 6} refers to the x coordinate of the 6th point in the 3rd letter
    ! e.g. letterArray{1, 6, 1} refers to the boldness of the 6th letter (Dimension 3 is always 1 for boldness)
    VAR num letterArray{3,100,1000};

    ! Array of strings storing the message. Each element is one part (part is a section separated by a comma delimiter)
    VAR string messageArray{10000};
    ! Array of blocks on the cake/conveyor + orientation. Limit of 50 blocks but array may not be filled.
    VAR num blockArray{50,7};
    ! Array of left over blocks on conveyor + junk area.
    VAR num leftOverArray{50,6};
    ! Flag to check if error has occurred. (Not used at the moment)
    VAR bool errorFlag;
    ! String containing error message that needs to be sent
    VAR string errorMessage;

    ! Number of letters in a letterArray. Needed as array size may change and leftover data may still be there.
    VAR num numLetters;
    ! Number of coordinates in path for each letter.
    VAR num numCoordinates{100};

    ! Number of blocks on cake/conveyor. Needed as array size may change.
    VAR num numBlocks;
    ! Number of left over blocks on conveyor.
    VAR num numLeftOver;

    ! A copy of relevant variables above to be shared with T_ROB
    PERS num letterArrayCopy{3,100,1000};
    PERS num blockArrayCopy{50,7};
    PERS num leftOverArrayCopy{50,6};

    PERS num numLettersCopy;
    PERS num numCoordinatesCopy{100};

    PERS num numBlocksCopy;
    PERS num numLeftOverCopy;

    ! Flags so the robot knows which operation to run
    PERS bool chocBlocks:=FALSE;
    PERS bool isDecorDone:=FALSE;
    PERS bool letters:=FALSE;

    ! Flag to determine if more information will be received
    PERS bool robotMoving:=TRUE;
    
    ! Flag to pause and resume robot operations, TRUE will indicate operations are resumed, FALSE will pause the robot
    PERS bool pauseResume:= TRUE;


    PROC Main()
        host:="127.0.0.1";
        MainServer;
    ENDPROC

    ! Example of how the functions might be called. Normally start with ListenForAndAcceptConnection to open the socket, 
    ! Do all the receiveMessage and sendError.
    ! When the program has finished then call CloseConnection to close the connection.
    PROC MainServer()
        errorMessage:="errorerror";

        ListenForAndAcceptConnection client_socket,host,port;

        receiveMessage client_socket,messageArray;

        parseString messageArray,blockArray,leftOverArray,numBlocks,numLeftOver,letterArray,numLetters,numCoordinates;

        sendError client_socket,errorMessage;

        IF robotMoving=FALSE THEN
            sendRobotUpdate client_socket,"Take another picture";
        ENDIF

        ! Send the string back to the client, adding a line feed character.
        ! SocketSend client_socket \Str:=(received_str + "\0A");

        CloseConnection client_socket;
    ENDPROC

    ! INPUT
    !   socketdev client_socket - this is a socket to be opened and connected to
    !   string host - ip address to connect to e.g. "192.168.0.2" or "127.0.0.1"
    !   num port - port number to connect to e.g. 20000
    ! OUTPUT
    !   socketdev client_socket - the socket has now connected to a client
    PROC ListenForAndAcceptConnection(VAR socketdev client_socket,string host,num port)
        ! Create the socket to listen for a connection on.
        VAR socketdev welcome_socket;
        SocketCreate welcome_socket;

        ! Bind the socket to the host and port.
        SocketBind welcome_socket,host,port;

        ! Listen on the welcome socket.
        SocketListen welcome_socket;

        ! Accept a connection on the host and port.
        SocketAccept welcome_socket,client_socket\Time:=WAIT_MAX;

        ! Close the welcome socket, as it is no longer needed.
        SocketClose welcome_socket;
    ENDPROC

    ! INPUT
    !   socketdev client_socket - socket to be closed
    ! OUTPUT
    !   socketdev client_socket - closed socket
    PROC CloseConnection(VAR socketdev client_socket)
        SocketClose client_socket;
    ENDPROC

    ! INPUT
    !   socketdev client_socket - socket to be read from
    ! OUTPUT
    !   string messageArray{*} - Array of strings which stores all the parts of the message
    PROC receiveMessage(VAR socketdev client_socket,VAR string messageArray{*})
        VAR string received_str;
        VAR num count:=1;
        VAR string end_str:="end";
        VAR string ack_str:="ACK";

        !errorMessage := "errorerror";

        ! Receive a string from the client.
        SocketReceive client_socket\Str:=received_str;

        messageArray{count}:=received_str;
        SocketSend client_socket\Str:=(ack_str+"\0A");
        count:=count+1;
        WHILE (received_str<>(end_str+"\0A")) DO
            SocketReceive client_socket\Str:=received_str;
            messageArray{count}:=received_str;
            SocketSend client_socket\Str:=(ack_str+"\0A");
            !            !IF count MOD 2 = 1 THEN
            !               SocketSend client_socket \Str:=(ack_str+"\0A");
            !            ELSE
            !                sendError errorMessage;
            !            ENDIF
            count:=count+1;
        ENDWHILE
    ENDPROC

    ! INPUT
    !   socketdev client_socket - Socket which the message will be sent to.
    !   string errorMessage - error message that will be sent.
    PROC sendError(VAR socketdev client_socket,string errorMessage)
        SocketSend client_socket\Str:=("0, "+errorMessage+"\0A");
    ENDPROC

    ! INPUT
    !   socketdev client_socket - Socket which the message will be sent to.
    !   string message - robot update message that will be sent.
    PROC sendRobotUpdate(VAR socketdev client_socket,string message)
        SocketSend client_socket\Str:=("3, "+message+"\0A");
    ENDPROC

    ! INPUT
    !   string messageArray{*} - Array of strings which contains the message
    ! OUTPUT
    !   num blockArray{*,*} - Array of blocks on the cake/conveyor. Only used when messagetype is for block trajectories
    !   num leftOverArray{*,*} - Array of left over blocks on conveyor and junk area. Only used when messagetype is for block trajectories
    !   num numBlocks - Number of blocks on cake/conveyor. Only used when messagetype is for block trajectories
    !   num numLeftOver - Number of left over blocks. Only used when messagetype is for block trajectories
    !   num letterArray{*,*,*} - Array which contains boldness and letters/numbers. Only used when messagetype is for letter trajectories
    !   num numLetters - Number of letters. Only used when messagetype is for letter trajectories
    !   num numCoordinates{100} - Number of coordinates for each letter. Only used when messagetype is for letter trajectories
    ! NOTES
    !   messagetype is determined by first element of messageArray.
    PROC parseString(VAR string messageArray{*},VAR num blockArray{*,*},VAR num leftOverArray{*,*},VAR num numBlocks,VAR num numLeftOver,VAR num letterArray{*,*,*},VAR num numLetters,VAR num numCoordinates{*})
        IF messageArray{1}="0\0A" THEN

        ELSEIF messageArray{1}="1\0A" THEN
            str2BlockTraj messageArray,blockArray,leftOverArray,numBlocks,numLeftOver;
            blockArrayCopy:=blockArray;
            leftOverArrayCopy:=leftOverArray;
            numBlocksCopy:=numBlocks;
            numLeftOverCopy:=numLeftOver;
            chocBlocks:=TRUE;
            robotMoving:=TRUE;
        ELSEIF messageArray{1}="2\0A" THEN
            str2LetterTraj messageArray,letterArray,numLetters,numCoordinates;
            letterArrayCopy:=letterArray;
            numLettersCopy:=numLetters;
            numCoordinatesCopy:=numCoordinates;
            letters:=TRUE;
        ELSEIF messageArray{1}="4\0A" THEN
            IF pauseResume = TRUE THEN
                pauseResume := FALSE;
            ELSE
                pauseResume := TRUE;
            ENDIF
        ENDIF
    ENDPROC

    ! INPUT
    !   string messageArray - Array of strings which contains the message
    ! OUTPUT
    !   num letterArray{*,*,*} - Array which contains boldness and letters/numbers.
    !   num numLetters - Number of letters.
    !   num numCoordinates{100} - Number of coordinates for each letter.
    ! NOTES
    !   This function does not need to be called. Normally done by parseString.
    PROC str2LetterTraj(string messageArray{*},VAR num letterArray{*,*,*},VAR num numLetters,VAR num numCoordinates{*})
        !VAR num numLetters;
        !VAR num numCoordinates{100};
        VAR bool convertStatus;
        !VAR num count;
        !VAR num count2;
        VAR num posInStr;
        VAR num i;
        VAR num j;

        posInStr:=2;
        !number of letters
        convertStatus:=StrToVal(messageArray{posInStr},numLetters);
        posInStr:=posInStr+1;

        !posInStr := 1 + 2
        FOR i FROM 1 TO numLetters DO
            !number of cooridnates for each letter
            convertStatus:=StrToVal(messageArray{posInStr},numCoordinates{i});
            posInStr:=posInStr+1;

        ENDFOR
        !posInStr := 1 + 2 + numLetters
        FOR i FROM 1 TO numLetters DO
            !boldness of letters
            convertStatus:=StrToVal(messageArray{posInStr},letterArray{1,i,1});
            posInStr:=posInStr+1;

        ENDFOR

        !posInStr := 1 + 2 + 2*numLetters;
        FOR i FROM 1 TO numLetters DO
            FOR j FROM 1 TO numCoordinates{i} DO
                ! x coordinate of letters
                convertStatus:=StrToVal(messageArray{posInStr},letterArray{2,i,j});
                posInStr:=posInStr+1;
                ! y coordinate of letters
                convertStatus:=StrToVal(messageArray{posInStr},letterArray{3,i,j});
                posInStr:=posInStr+1;
            ENDFOR

        ENDFOR
    ENDPROC

    ! INPUT
    !   socketdev client_socket - Socket which the message will be sent to.
    ! OUTPUT
    !   num blockArray{*,*} - Array of blocks on the cake/conveyor.
    !   num leftOverArray{*,*} - Array of left over blocks on conveyor and junk area.
    !   num numBlocks - Number of blocks on cake/conveyor.
    !   num numLeftOver - Number of left over blocks.
    ! NOTES
    !   This function does not need to be called. Normally done by parseString.
    PROC str2BlockTraj(string messageArray{*},VAR num blockArray{*,*},VAR num leftOverArray{*,*},VAR num numBlocks,VAR num numLeftOver)
        !VAR num numBlocks;
        !VAR num numLeftOver;
        VAR bool convertStatus;
        !VAR num count;
        VAR num posInStr;
        VAR num i;
        VAR num j;

        posInStr:=2;
        convertStatus:=StrToVal(messageArray{posInStr},numBlocks);
        posInStr:=posInStr+1;
        convertStatus:=StrToVal(messageArray{posInStr},numLeftOver);
        posInStr:=posInStr+1;

        !count := 1;
        FOR i FROM 1 TO numBlocks DO
            FOR j FROM 1 TO 7 DO
                convertStatus:=StrToVal(messageArray{posInStr},blockArray{i,j});
                posInStr:=posInStr+1;
            ENDFOR

            !            ! x coordinate of cake block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{i,1});
            !            posInStr := posInStr + 1;
            !            ! y coordinate of cake block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{i,2});
            !            posInStr := posInStr + 1;
            !            ! z coordinate of cake block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{count,3});
            !            posInStr := posInStr + 1;
            !            ! x coordinate of conveyor block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{count,4});
            !            posInStr := posInStr + 1;
            !            ! y coordinate of conveyor block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{count,5});
            !            posInStr := posInStr + 1;
            !            ! z coordinate of conveyor block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{count,6});
            !            posInStr := posInStr + 1;
            !            ! orientation of block
            !            convertStatus := StrToVal(messageArray{posInStr},blockArray{count,7});
            !            posInStr := posInStr + 1;
            !            count := count + 1;
        ENDFOR

        !count := 1;
        FOR i FROM 1 TO numLeftOver DO
            FOR j FROM 1 TO 6 DO
                convertStatus:=StrToVal(messageArray{posInStr},leftOverArray{i,j});
                posInStr:=posInStr+1;
            ENDFOR
            !            !x coordinate of leftover block
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,1});
            !            posInStr := posInStr + 1;
            !            !y coordinate of leftover block
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,2});
            !            posInStr := posInStr + 1;
            !            !z coordinate of leftover block
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,3});
            !            posInStr := posInStr + 1;
            !            !x coordinate of junk area
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,4});
            !            posInStr := posInStr + 1;
            !            !y coordinate of junk area
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,5});
            !            posInStr := posInStr + 1;
            !            !z coordinate of junk area
            !            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,6});
            !            posInStr := posInStr + 1;
            !            count := count + 1;
        ENDFOR

    ENDPROC

    ! INPUT
    !   string message - message which is to be SplitStr
    ! OUTPUT
    !   string messageArray{*} - Array of strings which contain the message
    ! NOTES
    !   Due to changes in how messages are sent, SplitStr is unused and replaced by receiveMessage
    PROC SplitStr(VAR string message,VAR string messageArray{*})
        VAR string delimiter:=",";
        VAR string buffer:="";
        VAR string char:="";
        VAR num len;

        VAR num charCount:=1;
        VAR num numStrings:=1;

        len:=StrLen(message);
        WHILE (charCount<=len) DO
            char:=StrPart(message,1,charCount);


            IF (char=",") THEN

                messageArray{numStrings}:=buffer;
                buffer:="";
                numStrings:=numStrings+1;
            ELSE
                buffer:=buffer+Char;
            ENDIF

            charCount:=charCount+1;
        ENDWHILE


    ENDPROC

ENDMODULE