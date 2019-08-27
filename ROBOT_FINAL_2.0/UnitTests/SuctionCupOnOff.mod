MODULE SuctionCupOnOff
    !***********************************************************
    !
    ! Module:  Suction Cup Test
    ! Author: Rachel Feng, z5112668
    !
    ! Description:
    !   This is a module which tests the suction cup's ability to 
    !    grab an object.
    !
    !***********************************************************

    VAR robtarget block := [[175,0,147],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

    PROC testSuctionCup()
        ! move to ptablehome over block
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
        MoveL block,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
        turnOnVacuum;
        turnOnGripper;
        ! move back
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
        MoveL block,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
        turnOffGripper;
        turnOffVacuum;
    ENDPROC
    
ENDMODULE
