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
    VAR num convResp;
    ! Error number for conveyor movement fail
    VAR errnum CONV_MOVE_ERR;

    PROC turnOnConveyor()
        BookErrNo CONV_MOVE_ERR;
        ! if conveyor status (constat) is 1, good to go
        IF DI10_1=1 THEN
            SetDO DO10_3,1;
        ELSE
            turnOffConveyor;
            RAISE CONV_MOVE_ERR;
        ENDIF
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