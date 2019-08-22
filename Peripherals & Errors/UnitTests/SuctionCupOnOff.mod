MODULE SuctionCupOnOff
    !***********************************************************
    !
    ! Module:  Suction Cup Test
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the suction cup's ability to 
    !    grab an object.
    !
    !***********************************************************

    PROC testSuctionCup()
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