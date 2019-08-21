! Unit test for turning on/off the vacuum pump  
! Turns on vacuum for 3 seconds, then turns it off

MODULE VacuumOnOff
    
    PROC Main()
        turnOnVacuum;
        WaitTime 3;
        turnOffVacuum;
    ENDPROC
    
ENDMODULE