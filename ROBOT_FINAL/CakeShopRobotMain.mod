MODULE CakeShopRobotMain
    !***********************************************************
    !
    ! Module: Main robot controller
    ! Author: Rachel Feng, z5112668
    ! 
    ! Description:
    !   This module is the main controller of all robot movements.
    !   Contains ongoing error checking.
    !   Calls functions to decorate the cake with blocks & icing.
    !   After each pick and place, communicate back to server to see
    !   if decoration is completed.   
    !
    !***********************************************************

    ! Interrupts for emergency stops
    VAR intnum lightCurtain;
    VAR intnum emergencyStop;
    VAR intnum emergencyStopMotor;
    VAR num tempConv;
    VAR num response;

    ! Flags to send error message back to GUI
    PERS bool lightCurtainError:=FALSE;
    PERS bool emergencyStopError:=FALSE;
    PERS bool conveyorError:=FALSE;
    PERS bool vacuumError:=FALSE;
    PERS bool clearMessage:=FALSE;

    ! Data received from server
    PERS num letterArrayCopy{3,100,1000};
    PERS num blockArrayCopy{50,7};
    PERS num leftOverArrayCopy{50,6};

    PERS num numLettersCopy;
    PERS num numCoordinatesCopy{100};
    VAR num z_coord:=147.5;

    PERS num numBlocksCopy;
    PERS num numLeftOverCopy;

    ! Flags to check
    PERS bool chocBlocks;
    PERS bool isDecorDone;
    PERS bool letters;
    PERS bool robotMoving;
    PERS bool pauseResume;
    PERS bool stopFlag;

    VAR bool firstConvMove:=FALSE;

    PROC Main()
        ! set up interrups
        CONNECT timerInt WITH checkTime;
        ITimer 5,timerInt;
        ISleep timerInt;

        CONNECT lightCurtain WITH lTrap;
        CONNECT emergencyStop WITH eTrap;
        CONNECT emergencyStopMotor WITH eTrapMotor;

        ISignalDO\Single,DO_LIGHT_CURTAIN,0,lightCurtain;
        ISignalDO\Single,DO_ESTOP,1,emergencyStop;
        ISignalDO\Single,DO_ESTOP2,0,emergencyStopMotor;

        ! stop all functions, return robot arm to home position
        IF stopFlag=TRUE THEN
            turnOffConveyor;
            turnOffGripper;
            turnOffVacuum;
            MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
            StopMove;
            EXIT;
        ENDIF

        ! pause/resume loop
        IF pauseResume=FALSE THEN
            StopMove;
            IF DOutput(DO10_3)=1 THEN
                turnOffConveyor;
                tempConv:=1;
            ENDIF
            WHILE pauseResume=FALSE DO
                ! do nothing
            ENDWHILE
            IF tempConv=1 THEN
                turnOnConveyor;
                tempConv:=0;
            ENDIF
            StartMove;
        ENDIF

        ! move conveyor for first choc block picture
        IF firstConvMove=FALSE THEN
            setDirToRobot;
            turnOnConveyor;
            WaitTime 5;
            turnOffConveyor;
            firstConvMove:=TRUE;
            robotMoving:=FALSE;
        ENDIF

        ! main decoration routine
        IF chocBlocks=TRUE THEN
            DecorateMain blockArrayCopy;
            DecorateMain leftOverArrayCopy;
            chocBlocks:=FALSE;
            turnOnConveyor;
            WaitTime 2;
            turnOffConveyor;
            robotMoving:=FALSE;
        ENDIF

        ! main lettering/icing routine
        IF letters=TRUE THEN
            draw_letter letterArrayCopy,z_coord;
            letters:=FALSE;
        ENDIF

        ! delete interrupts (temp)
        IDelete timerInt;
        IDelete emergencyStop;
        IDelete emergencyStopMotor;
        IDelete lightCurtain;


        ! Error routines
    ERROR
        IF ERRNO=SUCTION_CUP_ERR THEN
            vacuumError:=TRUE;
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

        IF ERRNO=CONV_MOVE_ERR THEN
            conveyorError:=TRUE;
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
                clearMessage:=TRUE;
                TPErase;
                TPWrite "Retrying...";
                conveyorError:=FALSE;
                RETRY;
            ENDIF
        ENDIF
    ENDPROC

    ! pause/resume trap routine


    ! light curtain trap routine
    TRAP lTrap
        ! stop the robot & conveyor
        StopMove;
        IF DOutput(DO10_3)=1 THEN
            turnOffConveyor;
            tempConv:=1;
        ENDIF
        lightCurtainError:=TRUE;
        ! print message to gui
        ! Write: Please remove any obstructions and hazards from the robot including people.\nPlease reset the light curtain.
        ! get response from gui
        TPErase;
        TPWrite "Light curtain obstruction";
        TPReadFK response,"Please remove obstruction",stEmpty,stEmpty,stEmpty,"No","Fixed";
        IF response=4 THEN
            TPErase;
            TPWrite "Exiting program...";
            WaitTime 2;
            EXIT;
        ELSEIF response=5 THEN
            TPErase;
            TPWrite "Resuming...";
            clearMessage:=TRUE;
        ENDIF
        StartMove;
        IF tempConv=1 THEN
            turnOnConveyor;
            tempConv:=0;
        ENDIF
        lightCurtainError:=FALSE;
        RETURN ;
    ENDTRAP

    ! emergency stop interrupt for red buttons except motor
    TRAP eTrap
        ! stop the robot
        StopMove;
        IF DOutput(DO10_3)=1 THEN
            turnOffConveyor;
            tempConv:=1;
        ENDIF
        emergencyStopError:=TRUE;
        ! print message to gui
        ! Write: Please remove any obstructions and hazards from the robot including people.\nPlease reset the light curtain on your way out.
        ! get response from gui
        TPErase;
        TPWrite "Emergency stop!";
        TPWrite "Please remove any obstructions and hazards from the robot.";
        TPWrite "Don't forget to reset the light curtain.";
        TPReadFK response,"Restart?",stEmpty,stEmpty,stEmpty,"No","Yes";
        IF response=4 THEN
            TPErase;
            TPWrite "Exiting program...";
            WaitTime 2;
            EXIT;
        ELSEIF response=5 THEN
            TPErase;
            TPWrite "Resuming...";
            clearMessage:=TRUE;
        ENDIF
        StartMove;
        IF tempConv=1 THEN
            turnOnConveyor;
            tempConv:=0;
        ENDIF
        emergencyStopError:=FALSE;
        RETURN ;
    ENDTRAP

    TRAP eTrapMotor
        ! emergency stop interrupt for motor button
        ! stop the robot
        StopMove;
        IF DOutput(DO10_3)=1 THEN
            turnOffConveyor;
            tempConv:=1;
        ENDIF
        emergencyStopError:=TRUE;
        ! print message to gui
        ! Write: Please remove all hazards. Please restart the motors.
        ! get response from gui
        TPErase;
        TPWrite "Motor stop!";
        TPWrite "Please remove any obstructions and hazards from the robot.";
        TPWrite "Don't forget to reset the light curtain.";
        TPReadFK response,"Restart?",stEmpty,stEmpty,stEmpty,"No","Yes";
        IF response=4 THEN
            TPErase;
            TPWrite "Exiting program...";
            WaitTime 2;
            EXIT;
        ELSEIF response=5 THEN
            TPErase;
            TPWrite "Resuming...";
            clearMessage:=TRUE;
        ENDIF
        StartMove;
        IF tempConv=1 THEN
            turnOnConveyor;
            tempConv:=0;
        ENDIF
        emergencyStopError:=FALSE;
        RETURN ;
    ENDTRAP

ENDMODULE