MODULE DecorationPickAndPlace
    !***********************************************************
    !
    ! Module: Decoration Movement Code for Robot
    ! Author: Dylan Dam, z5115759
    !
    ! Description: 
    !    This module is responsible for the pick and place for the qwirkle decoration.
    !    The function takes an array that contains the start and end coordinates of the 
    !    blocks as well as it’s orientation. The robot then moves via a set path that is 
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
    
    ! Predefined intermediate points for the robot trajectory
    CONST robtarget EndPoint:=[[520,0,145],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint1:=[[430,125,450],[0,0,1,0],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint2:=[[265,165,450],[0,0,1,0],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget ImmediatePoint3:=[[0,409,450],[0,0,1,0],[1,-1,1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget StartPoint:=[[20,409,24],[0,0,-1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget MoveToHome:=[[410,0,450],[0,0,-1,0],[0,0,-1,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST num offSet:=12;
    
    !Dummy Array for Testing
    CONST num qwirkleArray{3,7}:=[[20,409,24,520,0,150,45],[20,409,24,500,0,150,0],[20,409,24,450,0,150,45]];

    ! Main decoration function
    PROC DecorateMain(num array{*,*})
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
        decorationProcess array;
        MoveL MoveToHome,v1000,z100,tool0\WObj:=wobj0;
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
            xStart:=array{a,1};
            yStart:=array{a,2};
            zStart:=array{a,3}+offSet;
            xEnd:=array{a,4};
            yEnd:=array{a,5};
            zEnd:=array{a,6}+offSet;
            orientation:=array{a,7};

            qwirkleLocation:=[[xStart,yStart,zStart],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
            qwirklePlacement:=[[xEnd,yEnd,zEnd],[0,0,1,0],[0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];

            PathToConvFromHome;
            MoveL qwirkleLocation,v1000,z100,tool0\WObj:=wobj0;
            turnOnVacuum;
            turnOnGripper;
            ResetConveyorPath;
            PathToHomeFromConv;
            MoveL qwirklePlacement,v1000,z100,tool0\WObj:=wobj0;
            RotateTool orientation,qwirklePlacement;

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

    PROC ToStartPoint()
        MoveL StartPoint,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC

    PROC ToEndPoint()
        MoveL EndPoint,v1000,z100,tool0\WObj:=wobj0;
    ENDPROC

    PROC RotateTool(num Orientation,robtarget a)
        MoveL RelTool(a,0,0,0,\Rz:=Orientation),v1000,fine,tool0\WObj:=wobj0;
        WaitTime 2;
        turnOffGripper;
        turnOffVacuum;
        WaitTime 1;

    ENDPROC

ENDMODULE