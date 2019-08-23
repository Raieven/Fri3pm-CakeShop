MODULE CakeShopRobotMain
    !***********************************************************
    !
    ! Module:  Main robot controller
    ! 
    ! Description:
    !   This module is the main controller of all robot movements
    !
    !***********************************************************
    
    VAR string str;
    
    PERS num letterArrayCopy{3,100,1000};
    PERS num blockArrayCopy{50,7};
    PERS num leftOverArrayCopy{50,6};
    
    PERS num numLettersCopy;
    PERS num numCoordinatesCopy{100};
    VAR num z_coord:=147.5;

    PERS num numBlocksCopy;
    PERS num numLeftOverCopy;
    
    PERS bool chocBlocks;
    PERS bool letters;
    
    PROC Main()
        CONNECT timerInt WITH checkTime;
        ITimer 5, timerInt;
        ISleep timerInt;
        ! 
        
        
        ! main decoration routine
        IF chocBlocks = TRUE THEN 
            DecorateMain blockArrayCopy;
            DecorateMain leftOverArrayCopy;
            chocBlocks:=FALSE;
        ENDIF 
        IF letters = TRUE THEN
            draw_letter letterArrayCopy,z_coord;
            letters:=FALSE;
        ENDIF
        IDelete timerInt;
        
        
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