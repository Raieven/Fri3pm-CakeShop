! Unit test for conveyor 1
! Sets direction towards robot (default)
! Turns on conveyor for 3 seconds, then turns off
    
MODULE ConveyorMoveToRobot
    
    PROC Main()
        setDirToRobot;
        turnOnConveyor;
        WaitTime 3;
        turnOffConveyor;
    ENDPROC
    
ENDMODULE