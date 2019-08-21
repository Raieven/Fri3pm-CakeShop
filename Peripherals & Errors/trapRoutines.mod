MODULE TrapRoutines
    VAR intnum lightCurtain;
    VAR intnum emergencyStop;
       
    
    PROC Main ()
        CONNECT lightCurtain WITH lTrap;
        CONNECT emergencyStop WITH eTrap;
        ISignalDO\Single,DO_LIGHT_CURTAIN,1,lightCurtain;
        ISignalDO\Single,DO_ESTOP,1,emergencyStop;
        ISignalDO\Single,DO_ESTOP2,1,emergencyStop;
        
        WHILE TRUE DO
            turnOnConveyor;
            WaitTime 2;
            turnOffConveyor;
        ENDWHILE
        
        IDelete emergencyStop;
        IDelete lightCurtain;
    ENDPROC
    
    
    TRAP lTrap
        ! light curtain interrupt
        
    ENDTRAP 
    
    TRAP eTrap
        ! emergency stop interrupt
        
    ENDTRAP 

ENDMODULE