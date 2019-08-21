MODULE trapRoutines
    VAR intnum lightCurtain;
    VAR intnum emergencyStop;
    VAR intnum emergencyStopMotor;
    VAR num tempConv;
    
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
            turnOnConveyor;
            WaitTime 2;
            turnOffConveyor;
        ENDWHILE
        
        IDelete emergencyStop;
        IDelete lightCurtain;
    ENDPROC
    
    
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
ENDMODULE