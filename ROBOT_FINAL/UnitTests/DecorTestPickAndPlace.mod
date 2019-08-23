MODULE DecorTestPickAndPlace
    !***********************************************************
    !
    ! Module: Decoration Test Code
    ! Author: Dylan Dam, z5115759
    !
    ! Description: 
    !    This module is responsible for testing the pick and place for the qwirkle decoration.
    !
    !***********************************************************
    
    ! Dummy Array for Testing
    CONST num qwirkleArray{3,7}:=[[20,409,24,520,0,150,45],[20,409,24,500,0,150,0],[20,409,24,450,0,150,45]];

    PROC DecorTest()
        DecorateMain qwirkleArray;
    ENDPROC
    
ENDMODULE