MODULE CakeShopRobotMain
    !***********************************************************
    !
    ! Module:  Main robot controller
    ! 
    ! Description:
    !   This module is the main controller of all robot movements
    !
    !***********************************************************

    PROC Main()
        CONNECT timerInt WITH checkTime;
        ITimer 5, timerInt;
        ISleep timerInt;
        
!        WHILE TRUE DO
!            ! if frosting.complete
!            !   if decoration.complete
!            !       !sleep, robot is not doing anything
!            !   else
!            !       ! do next action in decoration path
!            !       decoration.update
!            !   endif
!            ! else
!            !   ! do next action in frosting path
!            !   frosting.update
!            ! end
!        ENDWHILE

        ! Error routines
    ERROR
        IF ERRNO=SUCTION_CUP_ERR THEN
            TPErase;
            TPReadFK vacResp,"Do you want to turn on vacuum?",stEmpty,stEmpty,stEmpty,"No","Yes";
            IF vacResp=4 THEN
                vacResp:=0;
                TPErase;
                TPWrite "Exiting...";
                EXIT;
            ELSEIF vacResp=5 THEN
                vacResp:=0;
                TPErase;
                TPWrite "Turning on vacuum";
                turnOnVacuum;
                RETRY;
            ENDIF
        ENDIF
    
        IF ERRNO=CONV_MOVE_ERR THEN
            ! print to gui
            ! Write: Conveyor could not be started. 
            ! Write: Please check the following:\n - light curtain\n - conveyor guard\n Then please restart the conveyor from the control box
            ! read back from an ok button?
            ! get response from gui: 
            TPErase;
            TPWrite "Please check light curtain and conveyor guard then restart conveyor";
            TPReadFK convResp,"Checked?",stEmpty,stEmpty,stEmpty,"No","Yes";
            IF convResp=4 THEN
                convResp:=0;
                TPErase;
                TPWrite "Exiting...";
                EXIT;
            ELSEIF convResp=5 THEN
                convResp:=0;
                TPErase;
                TPWrite "Retrying...";
                RETRY;
            ENDIF
            RETRY;
        ENDIF
    ENDPROC

ENDMODULE