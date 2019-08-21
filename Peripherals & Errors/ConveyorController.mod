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
    PROC main()
        !Add your code here
    ENDPROC

    PROC turnOnConveyor()
        ! if conveyor status (constat) is 1, good to go
        IF DI10_1 = 1 THEN
            SetDO DO10_3,1;
        ELSE
            turnOffConveyor;
            ! do error checklist
        ENDIF
    ENDPROC

    ! turning off conveyor also resets conveyor direction
    PROC turnOffConveyor()
        setDir2Door;
        Reset(DO10_3);
    ENDPROC

    PROC setDir2Robot()
        SetDO DO10_4,1;
    ENDPROC

    PROC setDir2Door()
        Reset(DO10_4);
    ENDPROC
ENDMODULE