MODULE ConveyorMoveFromRobot
    !***********************************************************
    !
    ! Module:  Conveyor Test
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the conveyor's ability to move towards
    !   the door (away from the robot).
    !
    !***********************************************************

    PROC ConveyorTestMove02()
        setDirFromRobot;
        turnOnConveyor;
        WaitTime 3;
        turnOffConveyor;
    ENDPROC
    
ENDMODULE