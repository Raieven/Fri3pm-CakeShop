MODULE ConveyorEdgeCases
    !***********************************************************
    !
    ! Module:  Conveyor Edge Case Tests
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the possible edge cases of the conveyor
    !
    !***********************************************************
    
    ! When ConStat is 0 -> should go into an error
    ! Attempt to start conveyor when either:
    ! - light curtain is obstructed
    ! - conveyor locks open
    ! - conveyor not on at power box
    ! Should show error message on flex pendant
    PROC testConstatZero()
        turnOnConveyor;
    ENDPROC
    
    
ENDMODULE