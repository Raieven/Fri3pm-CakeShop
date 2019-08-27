MODULE ConveyorController
    !***********************************************************
    !
    ! Module: Conveyor Controller
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module containing all conveyor commands to be called by other modules
    !
    !***********************************************************

    ! Response from error provided from the user
    !VAR num convResp;
    ! Error number for conveyor movement fail
    !VAR errnum CONV_MOVE_ERR:=-1;

    PROC turnOnConveyor()
        BookErrNo CONV_MOVE_ERR;
        ! if conveyor status (constat) is 1, good to go
        !IF DI10_1=1 THEN
            SetDO DO10_3,1;
        !ELSE
        !    turnOffConveyor;
        !    RAISE CONV_MOVE_ERR;
        !ENDIF

!    ERROR
!        ! Conveyor error: occurs when attempt to turn on conveyor occured when IO/Light Curtain/Cage is not ready/set up
!        IF ERRNO=CONV_MOVE_ERR THEN
!            ! print to gui
!            conveyorError:=TRUE;
!            ! print message to flex pendant
!            TPErase;
!            TPWrite "Please check light curtain and conveyor guard then restart conveyor";
!            TPReadFK convResp,"Checked?",stEmpty,stEmpty,stEmpty,"No","Yes";
!            IF convResp=4 THEN
!                convResp:=0;
!                TPErase;
!                TPWrite "Exiting...";
!                EXIT;
!            ELSEIF convResp=5 THEN
!                convResp:=0;
!                clearMessage:=TRUE;
!                TPErase;
!                TPWrite "Retrying...";
!                conveyorError:=FALSE;
!                RETRY;
!            ENDIF
!        ENDIF
    ENDPROC

    PROC turnOffConveyor()
        SetDO DO10_3,0;
    ENDPROC

    PROC setDirToRobot()
        SetDO DO10_4,1;
    ENDPROC

    PROC setDirFromRobot()
        ! default
        SetDO DO10_4,0;
    ENDPROC
ENDMODULE