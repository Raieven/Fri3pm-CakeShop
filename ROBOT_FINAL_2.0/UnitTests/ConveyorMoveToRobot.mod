MODULE ConveyorMoveToRobot
    !***********************************************************
    !
    ! Module:  Conveyor Test
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the conveyor's ability to move towards
    !   the robot.
    !
    !***********************************************************
    
    PROC ConveyorTestMove01()
        setDirToRobot;
        turnOnConveyor;
        WaitTime 3;
        turnOffConveyor;
    ENDPROC
    
ENDMODULE