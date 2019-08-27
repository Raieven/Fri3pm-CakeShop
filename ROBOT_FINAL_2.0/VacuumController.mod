MODULE VacuumController
    !***********************************************************
    !
    ! Module: Vacuum Controller
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module containing all vacuum commands to be called by other modules
    !
    !***********************************************************

    ! Response from error provided by the user
    VAR num vacResp;
    ! Error number for suction cup fail
    VAR errnum SUCTION_CUP_ERR:=-1;
    ! Timer interrupt
!    VAR intnum timerInt;

    PROC turnOnVacuum()
        SetDO DO10_1,1;
        !        IWatch timerInt;
    ENDPROC

    PROC turnOffVacuum()
!        ISleep timerInt;
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

    ERROR
        ! Suction cup error: occurs when attempt to activate suction cup occured before vacuum pump activation
        IF ERRNO=SUCTION_CUP_ERR THEN
            ! print message to gui
            vacuumError:=TRUE;
            ! print message to flex pendant
            TPErase;
            TPReadFK vacResp,"Do you want to turn on vacuum?",stEmpty,stEmpty,stEmpty,"No","Yes";
            IF vacResp=4 THEN
                vacResp:=0;
                TPErase;
                TPWrite "Exiting...";
                EXIT;
            ELSEIF vacResp=5 THEN
                vacResp:=0;
                clearMessage:=TRUE;
                TPErase;
                TPWrite "Turning on vacuum";
                turnOnVacuum;
                vacuumError:=FALSE;
                RETRY;
            ENDIF
        ENDIF


    ENDPROC

    PROC turnOffGripper()
        SetDO DO10_2,0;
    ENDPROC

!    TRAP checkTime
!        TPErase;
!        TPWrite "Vacuum was on for too long...";
!        TPWrite "Turning off...";
!        turnOffVacuum;
!        RETURN ;
!    ENDTRAP
ENDMODULE