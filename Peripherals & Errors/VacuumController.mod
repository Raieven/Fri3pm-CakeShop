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
    
    VAR num vacResp;
    VAR errnum SUCTION_CUP_ERR;
    VAR intnum timerInt;

    PROC turnOnVacuum()
        SetDO DO10_1,1;
        IWatch timerInt;
    ENDPROC

    PROC turnOffVacuum()
        ISleep timerInt;
        turnOffGripper;
        SetDO DO10_1,0;
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

    TRAP checkTime
        TPErase;
        TPWrite "Vacuum was on for too long...";
        TPWrite "Turning off...";
        turnOffVacuum;
        RETURN;
    ENDTRAP 
ENDMODULE