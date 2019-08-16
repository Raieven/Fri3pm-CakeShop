MODULE VacuumController
    !***********************************************************
    !
    ! Module:  Module1
    !
    ! Description:
    !   <Insert description here>
    !
    ! Author: Forrestal
    !
    ! Version: 1.0
    !
    !***********************************************************

    VAR clock clk;
    VAR num time;
    !***********************************************************
    !
    ! Procedure main
    !
    !   This is the entry point of your program
    !
    !***********************************************************
    PROC main()
        !Add your code here

    ENDPROC
    

    PROC turnOnVacuum()
        SetDO DO10_1,1;
        ClkStart clk;
    ENDPROC

    PROC turnOffVacuum()
        turnOffGripper;
        Reset(DO10_1);
        ClkReset(clk);
    ENDPROC

    PROC turnOnGripper()
        IF DOutput(DO10_1)=1 THEN
            SetDO DO10_2,1;
        ENDIF
    ENDPROC

    PROC turnOffGripper()
        Reset(DO10_2);
    ENDPROC
    
    PROC checkTime()
        time := ClkRead(clk);
        IF time > 10 THEN
            turnOffVacuum;
        ENDIF
    ENDPROC
ENDMODULE