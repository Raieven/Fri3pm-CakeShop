MODULE VacuumController
    !***********************************************************
    !
    ! Module:  Vacuum Controller
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module containing all vacuum commands to be called by other modules
    !
    !***********************************************************

    VAR clock clk;
    VAR num time;
    VAR num vacResp;
    VAR errnum SUCTION_CUP_ERR;

    !***********************************************************
    !
    ! Procedure main
    !
    !   This is the entry point of your program
    !
    !***********************************************************


    PROC turnOnVacuum()
        SetDO DO10_1,1;
        ClkStart clk;
    ENDPROC

    PROC turnOffVacuum()
        turnOffGripper;
        SetDO DO10_1,0;
        ClkReset clk;
    ENDPROC

    PROC turnOnGripper()
        BookErrNo SUCTION_CUP_ERR;
        IF DOutput(DO10_1)=1 THEN
            SetDO DO10_2,1;
        ELSE
            RAISE SUCTION_CUP_ERR;
        ENDIF
    ENDPROC

    PROC turnOffGripper()
        SetDO DO10_2,0;
    ENDPROC

    PROC checkTime()
        time:=ClkRead(clk);
        IF time>10 THEN
            turnOffVacuum;
        ENDIF
    ENDPROC
ENDMODULE