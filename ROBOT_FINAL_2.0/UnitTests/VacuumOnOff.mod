MODULE VacuumOnOff
    !***********************************************************
    !
    ! Module: Vacuum Test
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the vacuum pump.
    !
    !***********************************************************

    PROC testVacuumOnOff()
        turnOnVacuum;
        WaitTime 3;
        turnOffVacuum;
    ENDPROC
    
ENDMODULE