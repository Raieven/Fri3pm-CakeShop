MODULE ConveyorController
    !***********************************************************
    !
    ! Module:  Unnamed
    !
    ! Description:
    !   <Insert description here>
    !
    ! Author: Forrestal
    !
    ! Version: 1.0
    !
    !***********************************************************


    !***********************************************************
    !
    ! Procedure main
    !
    !   This is the entry point of your program
    !
    !***********************************************************
    PROC turnOnConveyor()
        ! if conveyor status (constat) is 1, good to go
        IF DI10_1 = 1 THEN
            SetDO DO10_3,1;
        ELSE
            turnOffConveyor;
            RAISE ERR_CNV_NOT_ACT;
        ENDIF
        
        ERROR 
            IF ERRNO = ERR_CNV_NOT_ACT THEN
                ! print to gui
                ! do error checklist
                ! reactivate light curtain
                ! check conveyor guard
                ! restart conveyor from control box
                ! attempt to restart conveyor?
                ! Write: Conveyor could not be started. 
                ! Write: Please check the following:\n - light curtain\n - conveyor guard\n Then please restart the conveyor from the control box
                ! read back from an ok button?
                ! get response from gui: 
                RETRY;
            ENDIF 
    ENDPROC

    ! turning off conveyor also resets conveyor direction
    PROC turnOffConveyor()
        setDirFromRobot;
        SetDO DO10_3, 0;
    ENDPROC

    PROC setDirToRobot()
        SetDO DO10_4, 1;
    ENDPROC

    PROC setDirFromRobot()
        SetDO DO10_4, 0;
    ENDPROC
ENDMODULE