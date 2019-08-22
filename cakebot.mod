MODULE main_module
    PROC Main ()
        IF RobOS() THEN
            host := "192.168.125.1";
        ELSE
            host := "127.0.0.1";
        ENDIF
        MainServer;
        CONNECT lightCurtain WITH lTrap;
        CONNECT emergencyStop WITH eTrap;
        CONNECT emergencyStopMotor WITH eTrapMotor;
        
        ISignalDO\Single,DO_LIGHT_CURTAIN,1,lightCurtain;
        ISignalDO\Single,DO_ESTOP,1,emergencyStop;
        ISignalDO\Single,DO_ESTOP2,1,emergencyStopMotor;
        
        WHILE TRUE DO
            ! if frosting.complete
            !   if decoration.complete
            !       !sleep, robot is not doing anything
            !   else
            !       ! do next action in decoration path
            !       decoration.update
            !   endif
            ! else
            !   ! do next action in frosting path
            !   frosting.update
            ! end
        ENDWHILE
        
        IDelete emergencyStop;
        IDelete lightCurtain;
    ENDPROC
ENDMODULE

MODULE tcp
    ! internal TCP variables
    string input_string;
    
    ! public functions (for others to call)
    PROC recv()
    
        ! if ( decoration_string )
        !   call frosting.load_data()
        ! endif
        
        ! if ( frosting_string )
        !   call decoration.load_data()
        ! endif
        
        ! if (
    
    ENDPROC
    
    PROC send_string(string str)
    
    ENDPROC
    
    ! private function (used internally)
    PROC parse_string()
        ! do stuff
    ENDPROC

ENDMODULE

MODULE decoration
    ! internal decoration variabled
    num state;
    num points_from{*,*};
    num points_to{*,*};
    num bold{*};
    
    ! public functions (for others to call)
    PROC load_data(num input_data{*,*})
        ! ... fill structures with data
    ENDPROC
    
    PROC update()
        ! ... do next (small) action, eg move to next waypoint..
    ENDPROC
    
    PROC complete()
        ! ... test if process has completed
        RETURN done;
    ENDPROC
    
    ! private functions (used internally)
    PROC something()
        ! do stuff
    ENDPROC
ENDMODULE

MODULE frosting
    ! internal decoration variabled
    num state;
    num points{*,*};
    num bold{*};
    
    ! public functions (for others to call)
    PROC load_data(num input_data{*,*})
        ! ... fill structures with data
    ENDPROC
    
    PROC update()
        ! ... do next (small) action, eg move to next waypoint..
    ENDPROC
    
    FUNC complete()
        ! ... test if process has completed
        RETURN done;
    ENDFUNC
    
    ! private functions (used internally)
    PROC something()
        ! do stuff
    ENDPROC
ENDMODULE

MODULE interface
    ! interface stuff in here
    
    ! light curtain trap routine
    TRAP lTrap
        ! stop the robot & conveyor
        StopMove;
        IF DOutput(DO10_3) = 1 THEN 
            turnOffConveyor;
            tempConv := 1;
        ENDIF
        ! print message to gui
        ! Write: Please remove any obstructions and hazards from the robot including people.\nPlease reset the light curtain.
        ! get response from gui
        StartMove;
        IF tempConv = 1 THEN 
            turnOnConveyor;
            tempConv := 0;
        ENDIF 
        RETURN;
    ENDTRAP 
    
    ! emergency stop interrupt for red buttons except motor
    TRAP eTrap
        ! stop the robot
        StopMove;
        IF DOutput(DO10_3) = 1 THEN 
            turnOffConveyor;
            tempConv := 1;
        ENDIF
        ! print message to gui
        ! Write: Please remove any obstructions and hazards from the robot including people.\nPlease reset the light curtain on your way out.
        ! get response from gui
        StartMove;
        IF tempConv = 1 THEN 
            turnOnConveyor;
            tempConv := 0;
        ENDIF 
        RETURN;
    ENDTRAP 
    
    TRAP eTrapMotor
        ! emergency stop interrupt for motor button
        ! stop the robot
        StopMove;
        IF DOutput(DO10_3) = 1 THEN 
            turnOffConveyor;
            tempConv := 1;
        ENDIF
        ! print message to gui
        ! Write: Please remove all hazards. Please restart the motors.
        ! get response from gui
        StartMove;
        IF tempConv = 1 THEN 
            turnOnConveyor;
            tempConv := 0;
        ENDIF 
        RETURN;
    ENDTRAP 
    
    PROC turnOnVacuum()
        SetDO DO10_1,1;
        ClkStart clk;
    ENDPROC

    PROC turnOffVacuum()
        turnOffGripper;
        SetDO DO10_1, 0;
        ClkReset clk;
    ENDPROC

    PROC turnOnGripper()
        IF DOutput(DO10_1)=1 THEN
            SetDO DO10_2,1;
        ENDIF
    ENDPROC

    PROC turnOffGripper()
        SetDO DO10_2, 0;
    ENDPROC
    
    PROC checkTime()
        time := ClkRead(clk);
        IF time > 10 THEN
            turnOffVacuum;
        ENDIF
    ENDPROC
    
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
