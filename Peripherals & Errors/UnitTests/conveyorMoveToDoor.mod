! Unit test for conveyor 2
! Sets direction away from robot
! Turns on conveyor for 3 seconds, then turns off
    
MODULE ConveyorMoveFromRobot
    
    PROC Main()
        setDirFromRobot;
        turnOnConveyor;
        WaitTime 3;
        turnOffConveyor;
    ENDPROC
    
ENDMODULE