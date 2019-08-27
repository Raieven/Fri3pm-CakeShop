MODULE DecorationPickAndPlace
    !***********************************************************
    !
    ! Module: Decoration Movement Code for Robot
    ! Author: Dylan Dam, z5115759
    !
    ! Description: 
    !    This module is responsible for the pick and place for the qwirkle decoration.
    !    The function takes an array that contains the start and end coordinates of the 
    !    blocks as well as it's orientation. The robot then moves via a set path that is 
    !    defined and proceeds to move to the location of the block on the conveyor belt. 
    !    After picking up the block the arm traverses back via the same path and places 
    !    the block down. There is a function that rotates axis 6 for blocks that are 
    !    orientated differently. After the execution of the place and drop the robot 
    !    moves back to the home position.
    !   
    ! Inputs: 
    !   array - a nx6 or nx7 matrix data, recevied from GUI part, see GUI for more info
    !
    !***********************************************************
    
    ! Custom waypoints that I have selected
    CONST robtarget ImmediatePoint1:=[[430,125,450],[0,0,1,0],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint2:=[[265,180,450],[0,0,1,0],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint3:=[[0,409,450],[0,0,1,0],[1,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint4:=[[265,-180,450],[0,0,1,0],[1,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint5:=[[430,-125,450],[0,0,1,0],[1,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget MoveToHome:=[[410,0,450],[0,0,-1,0],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    ! Offset for the end-effector
    CONST num offSet := 75;
    !Dummy Array for Testing
    !CONST num qwirkleArray{4,7} := [[175,0,147,0,409,22.1,45],[548.6,0,147,0,409,22.1,0],[175,520,147,0,409,22.1,-45],[175,-300,147,0,409,22.1,-45]];
    CONST num qwirkleArray{1,7} := [[175,-50,147,0,409,22.1,-89]];
    
    PROC DecorateMain(num array{*,*})
        TPWRite "Decorating...";
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
        decorationProcess array;
        WaitTime 1;
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        WaitTime 1;
    ENDPROC
    
    PROC decorationProcess(num array{*,*})
        
        VAR num xStart;
        VAR num yStart;
        VAR num zStart;
        VAR num xEnd;
        VAR num yEnd;
        VAR num zEnd;
        VAR num orientation;
        VAR robtarget qwirkleLocation;
        VAR robtarget qwirklePlacement;
        
        FOR a FROM 1 TO Dim(array,1) DO
            ! This part reads in the first line.
            xStart := array{a,4};            
            yStart := array{a,5};
            IF xStart = 0 AND yStart = 0 THEN
                ExitCycle;
            ENDIF
            !zStart := array{a,6}+offSet;
            zStart := 22.1+offSet;
            xEnd := array{a,1};            
            yEnd := array{a,2};
            zEnd := 147+offSet;
            orientation := array{a,7};
            
            qwirkleLocation := [[xStart,yStart,zStart],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
            qwirklePlacement :=[[xEnd,yEnd,zEnd],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

            PathToConvFromHome;
            MoveL qwirkleLocation,v1000,z100,tool0\WObj:=wobj0;
            WaitTime 1;
            turnOnVacuum;
            turnOnGripper;
            ResetConveyorPath;
            PathToHomeFromConv;
            WaitTime 1;
            MoveL qwirklePlacement,v1000,z100,tool0\WObj:=wobj0;
            RotateTool orientation,qwirklePlacement;
            IF (yEnd < -400) THEN
                LeftSidePath;
            ELSE
                MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
            ENDIF
                
        ENDFOR
          
    ENDPROC
    
    PROC InitialiseStart()
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC
    
    PROC PathToConvFromHome()
            MoveL ImmediatePoint1,v1000,z100,tool0\WObj:=wobj0;
            MoveL ImmediatePoint2,v1000,z100,tool0\WObj:=wobj0;
            MoveL ImmediatePoint3,v1000,z100,tool0\WObj:=wobj0;    
    ENDPROC
    
    PROC PathToHomeFromConv()       
        MoveL ImmediatePoint3,v1000,z100,tool0\WObj:=wobj0;
        MoveL ImmediatePoint2,v1000,z100,tool0\WObj:=wobj0;
        MoveL ImmediatePoint1,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC
    PROC ResetConveyorPath()
        MoveL ImmediatePoint3,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC
    PROC ResetTablePath()
        MoveL ImmediatePoint1,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC

    PROC RotateTool(num Orientation,robtarget a)
        IF Orientation > 90 THEN
            Orientation := 90 - Orientation;
            MoveL RelTool(a,0,0,0,\Rz:= Orientation),v1000,fine,tool0\WObj:=wobj0;
            WaitTime 1;
            turnOffGripper;
            turnOffVacuum;
            WaitTime 1;
        ELSE    
            MoveL RelTool(a,0,0,0,\Rz:= Orientation),v1000,fine,tool0\WObj:=wobj0;
            WaitTime 1;
            turnOffGripper;
            turnOffVacuum;
            WaitTime 1;
        ENDIF
            
    ENDPROC
    
    PROC LeftSidePath()
       
        MoveL ImmediatePoint4,v1000,z100,tool0\WObj:=wobj0;
        MoveL ImmediatePoint5,v1000,z100,tool0\WObj:=wobj0;
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        
        
    ENDPROC
    
ENDMODULE