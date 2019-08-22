MODULE VacuumEdgeCases
    !***********************************************************
    !
    ! Module:  Vacuum Edge Case Tests
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the possible edge cases of the vacuum
    !
    !***********************************************************
    
    ! Turning on suction cup without vacuum on
    ! Error message should be displayed on flex pendant
    PROC testFailSuctionCup()
        turnOffVacuum;
        turnOnGripper;
    ENDPROC
    
    ! Test vacuum pump timeout
    ! Message should appear on flex pendant and vacuum pump should turn off
    PROC testVacuumTimeout()
        turnOnVacuum;
    ENDPROC
    
ENDMODULE