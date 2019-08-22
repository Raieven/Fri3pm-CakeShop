MODULE MTRN4230_Server_Sample1   

    ! The socket connected to the client.
    VAR socketdev client_socket;
    
    ! The host and port that we will be listening for a connection on.
    PERS string host := "127.0.0.1";
    
    CONST num port := 20000;
    
    !Array of letter coordinates
    !Dimension 1 is the type of data i.e. 1 = boldness, 2 = x coordinate, 3 = y coordinate
    !Dimension 2 is the letter number i.e. 1 is the first letter, 5 is the fifth letter
    !Dimension 3 is the coordinate number in a letter i.e. 3 is the third coordinate
    !e.g. letterArray{2, 3, 6} refers to the x coordinate of the 6th point in the 3rd letter
    !e.g. letterArray{1, 6, 1} refers to the boldness of the 6th letter (Dimension 3 is always 1 for boldness)
    VAR num letterArray{3,100,1000};
    
    VAR string messageArray{10000};
    VAR num blockArray{50,7};
    VAR num leftOverArray{50,6};
    VAR bool errorFlag;
    VAR string errorMessage;
    
    VAR num numLetters;
    VAR num numCoordinates{100};
    
    VAR num numBlocks;
    VAR num numLeftOver;
        
    
    
    PROC Main ()
        
        host := "127.0.0.1";
        MainServer;
        
    ENDPROC

    PROC MainServer()
        
        VAR string received_str;
        VAR num count := 1;
        VAR string end_str := "end";
        VAR string ack_str := "ACK";
        
        errorMessage := "errorerror";
        
        ListenForAndAcceptConnection;
        
        
        ! Receive a string from the client.
        SocketReceive client_socket \Str:=received_str;
            
        messageArray{count} := received_str;
        SocketSend client_socket \Str:=(ack_str+"\0A");
        count := count + 1;
        !WaitTime 0.001;
        WHILE (received_str <> (end_str+"\0A")) DO
            SocketReceive client_socket \Str:=received_str;
            messageArray{count} := received_str;
            IF count MOD 2 = 1 THEN
                SocketSend client_socket \Str:=(ack_str+"\0A");
            ELSE
                sendError errorMessage;
            ENDIF
            count := count+1;
            !WaitTime 0.001;
        ENDWHILE
        
        IF messageArray{1} = "0\0A" THEN
            
        ELSEIF messageArray{1} = "1\0A" THEN
            str2BlockTraj messageArray, blockArray, leftOverArray, numBlocks, numLeftOver;
        ELSEIF messageArray{1} = "2\0A" THEN
            str2LetterTraj messageArray, letterArray, numLetters, numCoordinates;
        ENDIF
        ! Send the string back to the client, adding a line feed character.
        ! SocketSend client_socket \Str:=(received_str + "\0A");

        CloseConnection;
		
    ENDPROC

    PROC ListenForAndAcceptConnection()
        
        ! Create the socket to listen for a connection on.
        VAR socketdev welcome_socket;
        SocketCreate welcome_socket;
        
        ! Bind the socket to the host and port.
        SocketBind welcome_socket, host, port;
        
        ! Listen on the welcome socket.
        SocketListen welcome_socket;
        
        ! Accept a connection on the host and port.
        SocketAccept welcome_socket, client_socket \Time:=WAIT_MAX;
        
        ! Close the welcome socket, as it is no longer needed.
        SocketClose welcome_socket;
        
    ENDPROC
    
    ! Close the connection to the client.
    PROC CloseConnection()
        SocketClose client_socket;
    ENDPROC
    
    PROC sendError(string errorMessage)
        SocketSend client_socket \Str:=("0, "+errorMessage+"\0A");
        
    ENDPROC
    
    PROC str2LetterTraj(string messageArray{*}, VAR num letterArray{*,*,*}, VAR num numLetters, VAR num numCoordinates{*})
        !VAR num numLetters;
        !VAR num numCoordinates{100};
        VAR bool convertStatus;
        !VAR num count;
        !VAR num count2;
        VAR num posInStr;
        VAR num i;
        VAR num j;
        
        posInStr := 2;
        !number of letters
        convertStatus:=StrToVal(messageArray{posInStr}, numLetters);
        posInStr := posInStr + 1;
        
        !posInStr := 1 + 2
        FOR i FROM 1 TO numLetters DO
            !number of cooridnates for each letter
            convertStatus:=StrToVal(messageArray{posInStr}, numCoordinates{i});
            posInStr := posInStr + 1;
            
        ENDFOR
        !posInStr := 1 + 2 + numLetters
        FOR i FROM 1 TO numLetters DO
            !boldness of letters
            convertStatus:=StrToVal(messageArray{posInStr}, letterArray{1,i,1});
            posInStr := posInStr + 1;
            
        ENDFOR
        
        !posInStr := 1 + 2 + 2*numLetters;
        FOR i FROM 1 TO numLetters DO
            FOR j FROM 1 TO numCoordinates{i} DO
                ! x coordinate of letters
                convertStatus:=StrToVal(messageArray{posInStr}, letterArray{2,i,j});
                posInStr := posInStr + 1;
                ! y coordinate of letters
                convertStatus:=StrToVal(messageArray{posInStr}, letterArray{3,i,j});
                posInStr := posInStr + 1;
            ENDFOR
            
        ENDFOR
        
    ENDPROC
    
    
    ! convert array of strings to block locations
    PROC str2BlockTraj(string messageArray{*}, VAR num blockArray{*,*}, VAR num leftOverArray{*,*}, VAR num numBlocks, VAR num numLeftOver)
        !VAR num numBlocks;
        !VAR num numLeftOver;
        VAR bool convertStatus;
        !VAR num count;
        VAR num posInStr;
        VAR num i;
        VAR num j;
        
        posInStr := 2;
        convertStatus:=StrToVal(messageArray{posInStr}, numBlocks);
        posInStr := posInStr + 1;
        convertStatus:=StrToVal(messageArray{posInStr}, numLeftOver);
        posInStr := posInStr + 1;
        
        !count := 1;
        FOR i FROM 1 TO numBlocks DO
            FOR j FROM 1 TO 7 DO
                convertStatus := StrToVal(messageArray{posInStr},blockArray{i,j});
                posInStr := posInStr + 1;
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
                convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,j});
            posInStr := posInStr + 1;
            ENDFOR
!            !x coordinate of leftover block
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,1});
!            posInStr := posInStr + 1;
!            !y coordinate of leftover block
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,2});
!            posInStr := posInStr + 1;
!            !y coordinate of leftover block
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,3});
!            posInStr := posInStr + 1;
!            !x coordinate of junk area
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,4});
!            posInStr := posInStr + 1;
!            !y coordinate of junk area
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,5});
!            posInStr := posInStr + 1;
!            !y coordinate of junk area
!            convertStatus := StrToVal(messageArray{posInStr},leftOverArray{i,6});
!            posInStr := posInStr + 1;
!            count := count + 1;
        ENDFOR
        
    ENDPROC
    
    ! Split string into an array of strings
    PROC  SplitStr(VAR string message,VAR string messageArray{*})
        VAR string delimiter := ",";
        VAR string buffer := "";
        VAR string char := "";
        VAR num len;
        
        VAR num charCount := 1;
        VAR num numStrings := 1;
        
        len:= StrLen(message);
        WHILE (charCount <= len) DO
            char := StrPart(message,1,charCount);
            

            IF (char = ",") THEN

                messageArray{numStrings}:=buffer;
                buffer:="";
                numStrings:= numStrings +1;
            ELSE
                buffer:=buffer+Char;
            ENDIF
            
            charCount := charCount + 1;
        ENDWHILE
        
        
    ENDPROC
    
!LOCAL FUNC string ReadStrMab(VAR iodev IODevice,string Delim)
!        VAR string sBuffer:="";
!        VAR string sBuf:="";
!        VAR string sChar:="";
!        VAR string sDelimiter:="A";
!        VAR num nDelimLength:=1;

!        IF (Present(Delim)) THEN
!            sDelimiter:=Delim;
!            nDelimLength:=StrLen(sDelimiter);
!        ENDIF

!        WHILE (sBuf<>sDelimiter) DO
!            sChar:=ReadStrBin(IODevice,1);
!            sBuf:=sBuf+sChar;

!            IF (StrLen(sBuf)>nDelimLength) THEN
!                sBuffer:=sBuffer+StrPart(sBuf,1,1);
!                sBuf:=StrPart(sBuf,2,StrLen(sBuf)-1);
!            ENDIF
!        ENDWHILE

!        RETURN sBuffer;
!    ENDFUNC
    

ENDMODULE