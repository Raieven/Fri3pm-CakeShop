! Unit test for Suction Cup
! Pass if the tool tip manages to pick up a block for 2 seconds, 
! then releases block
    
MODULE GripperOnOff
    
    PROC Main()
        ! move to ptablehome over block
        turnOnVacuum;
        turnOnGripper;
        ! move up
        WaitTime 2;
        ! move down
        turnOffGripper;
        turnOffVacuum;
    ENDPROC
    
ENDMODULE