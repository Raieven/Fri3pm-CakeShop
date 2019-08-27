MODULE DecorTestPickAndPlace
    !***********************************************************
    !
    ! Module: Decoration Test Code
    ! Author: Dylan Dam, z5115759
    !
    ! Description: 
    !    This module is responsible for testing the pick and place for the qwirkle decoration.
    ! 
    ! Input: Array of coordinates from Computer Vision 
    ! Output: 
    !   Arm should move from: 
    !       - Conveyor Home to T1 and rotate end effector by +45 degrees.
    !       - Conveyor Home to T2 and not rotate the end-effector
    !       - Conveyor Home to T3 and rotate end effector by -45 degrres;
    !
    !***********************************************************
    
    ! Dummy Array for Testing
    CONST num qwirkleArray{3,7}:=[[175,0,147,0,409,22.1,45],[175,-520,147,0,409,22.1,0],[175,520,147,0,409,22.1,-45]];

    PROC DecorTest()
        DecorateMain qwirkleArray;
    ENDPROC
    
ENDMODULE