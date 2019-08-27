MODULE InkPrinting
    !***********************************************************
    !
    ! Module: Ink Printing
    ! Author: Mike Ni, z5083683
    !
    ! Description:
    !   Runs program to move TCP along a given trajectory with a given speed decided by boldness of letter
    !
    ! Input:
    !   data_matrix - a 3xnxm matrix data, recevied from GUI part, see GUI for more info
    !   z_coor - the z coordinate for ink printing, assume to be 147.5
    !
    !***********************************************************
    
    PERS num x_array{135,1};
    PERS num y_array{135,1};
    PERS num z_array;
    PERS num letterArray{3,8,135};
    PERS num sizes{8};
    ! boldness 0 - unbolded, 1 - bolded
    PERS num bolded{8};
    PERS num boldness;
    ! The Main procedure. When you select 'PP to Main' on the FlexPendant, it will go to this procedure.
    PROC InkPrintingMain()
        
        ! This is a procedure defined in a System Module, so you will have access to it.
        ! This will move the robot to its calibration.
         MoveToCalibPos;
        
        ! Call a procedure that we have defined below.
         MoveJSample;
        
        ! Call another procedure that we have defined.
        ! MoveLSample;
        Path_10;
        !draw_path;
        draw_letter letterArray, sizes, 167;
        !Path_10;
        
        ! Call another procedure, but provide some input arguments.
        ! VariableSample pTableHome, 100, 100, 0, v100, fine;
        
        MoveToCalibPos;
    ENDPROC
    
    PROC draw_path()
        VAR num x;
        VAR num y;
        VAR num z;
        VAR num x_next;
        VAR num y_next;
        VAR pos curr;
        VAR pos next;
        VAR pos prev;
        VAR robtarget pathLoc;
        VAR num distance_from_next;
        VAR num displacement;
        VAR num time_req;
        FOR i FROM 1 TO DIM(x_array,1) DO
            x := x_array{i, 1};
            y := y_array{i, 1};
            ! find next point, except for last point
            IF i <> DIM(x_array, 1) THEN
                x_next := x_array{i+1, 1};
                y_next := y_array{i+1, 1};
            ELSE
                x_next := x;
                y_next := y;
            ENDIF
            z := z_array;
            curr := [x, y, z];
            next := [x_next, y_next, z];
            distance_from_next := Distance(curr, next);
            ! find previous point, start from i = 2
            IF i > 1 THEN
                prev := [x_array{i-1, 1}, x_array{i-1, 1}, z];
                displacement :=  Distance(CPos(\Tool:=tSCup \WObj:=wobj0), curr);
            ENDIF
            pathLoc := [[x, y, z],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
            ! check boldness to set speed. 0 - 50mm/s; 1 - 100mm/s
            IF boldness = 0 THEN
                time_req := displacement / 50;
                MoveL pathLoc, v50, z0, tSCup;
                !MoveL pathLoc, v50, \T:=1, fine, tSCup;
            ELSE
                time_req := displacement / 100;
                MoveL pathLoc, v100, z0, tSCup;
                !MoveL pathLoc, v100, \T:= 1, fine, tSCup;
            ENDIF
            !if next point is very far away, move tcp away from object surface
            IF distance_from_next > 15 THEN
                pathLoc := [[x, y, z+50],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
                MoveL pathLoc, vmax, \T:=0.1, fine, tSCup;
            ENDIF
        ENDFOR
        !move tcp away once all movement done
        pathLoc := [[x, y, z+10],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
        MoveL pathLoc, vmax, \T:=0.1, fine, tSCup;
    ENDPROC
    
    !use "draw_letter data_matrix" to run
    PROC draw_letter(num data_matrix{*,*,*}, num sizeOfLetter{*}, num z_coor)
        VAR num x;
        VAR num y;
        VAR num z;
        VAR num x_next;
        VAR num y_next;
        VAR pos curr;
        VAR pos next;
        VAR pos prev;
        VAR robtarget pathLoc;
        VAR num distance_from_next;
        VAR num displacement;
        VAR num time_req;
        VAR num bolded;
        VAR speeddata speed;
        FOR index FROM 1 TO DIM(data_matrix,2) DO
            bolded := data_matrix{1,index,1};
            IF bolded = 0 THEN
                speed := [50, 500, 5000, 1000];
            ELSE
                speed := [100, 500, 5000, 1000];
            ENDIF
            FOR i FROM 1 TO sizeOfLetter{index} DO
                x := data_matrix{2,index,i};
                y := data_matrix{3,index,i};
                
                ! find next point, except for last point
                IF i <> DIM(data_matrix,3) THEN
                    x_next := data_matrix{2,index,i+1};
                    y_next := data_matrix{3,index,i+1};
                ELSE
                    x_next := x;
                    y_next := y;
                ENDIF
                z := z_coor;
                curr := [x, y, z];
                next := [x_next, y_next, z];
                distance_from_next := Distance(curr, next);
                ! find previous point, start from i = 2
                IF i > 1 THEN
                    prev := [data_matrix{2,index,i-1}, data_matrix{3,index,i-1}, z];
                    displacement :=  Distance(CPos(\Tool:=tSCup \WObj:=wobj0), curr);
                ENDIF
                pathLoc := [[x, y, z],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
                ! check boldness to set speed. 0 - 50mm/s; 1 - 100mm/s
                
                MoveL pathLoc, speed, z0, tSCup;
                    
                !if next point is very far away, move tcp away from object surface
                IF distance_from_next > 15 THEN
                    pathLoc := [[x, y, z+50],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
                    MoveL pathLoc, vmax, \T:=0.1, fine, tSCup;
                ENDIF
            ENDFOR
            !move tcp away once all movement done
            pathLoc := [[x, y, z+10],[0,0,-1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
            MoveL pathLoc, vmax, \T:=0.1, fine, tSCup;
        ENDFOR
    ENDPROC
    
    PROC Path_10()
        !Defines the trajectory coordinates
        VAR num step_count := 0;
        bolded := [0,1,0,1,0,1,0,1];
        boldness := 0;
        x_array := [
        [347.3852228],
        [340.1824253],
        [332.9796278],
        [325.7768303],
        [319.2288325],
        [312.026035],
        [304.8232375],
        [309.4068359],
        [315.9548336],
        [322.5028314],
        [329.0508291],
        [335.5988269],
        [342.1468246],
        [300.2396391],
        [306.7876368],
        [313.9904343],
        [321.1932318],
        [327.7412296],
        [334.9440271],
        [341.4920249],
        [302.8588381],
        [308.7520361],
        [315.3000339],
        [321.8480316],
        [328.3960294],
        [334.9440271],
        [341.4920249], 
        [304.1684377],
        [304.8232375],
        [304.8232375],
        [304.8232375],
        [350.0044219],
        [344.111224],
        [336.9084264],
        [329.7056289],
        [322.5028314],
        [315.3000339],
        [308.0972363],
        [348.0400226],
        [340.8372251],
        [333.6344276],
        [326.43163],
        [325.1220305],
        [325.7768303],
        [331.0152285],
        [337.5632262],
        [344.7660237],
        [324.4672307],
        [319.2288325],
        [312.6808348],
        [306.132837],
        [302.8588381],
        [302.2040384],
        [305.4780372],
        [312.6808348],
        [319.8836323],
        [302.2040384],
        [307.4424366],
        [312.6808348],
        [319.2288325],
        [325.7768303],
        [332.324828],
        [338.8728258],
        [344.7660237],
        [304.8232375],
        [311.3712352],
        [318.5740327],
        [325.7768303],
        [332.324828],
        [338.8728258],
        [350.0044219],
        [343.4564242],
        [336.2536267],
        [329.0508291],
        [321.8480316],
        [314.6452341],
        [350.0044219],
        [336.9084264],
        [341.4920249],
        [348.6948224],
        [304.1684377],
        [310.7164354],
        [317.919233],
        [325.1220305],
        [332.324828],
        [336.2536267],
        [336.2536267],
        [329.7056289],
        [323.1576312],
        [316.6096334],
        [310.7164354],
        [304.8232375],
        [351.3140215],
        [346.0756233],
        [348.6948224],
        [348.6948224],
        [312.6808348],
        [307.4424366],
        [306.132837],
        [310.7164354],
        [317.2644332],
        [323.8124309],
        [329.0508291],
        [334.2892273],
        [340.1824253],
        [343.4564242],
        [349.3496222],
        [351.3140215],
        [348.6948224],
        [342.8016244],
        [335.5988269],
        [329.0508291],
        [322.5028314],
        [315.9548336],
        [309.4068359],
        [304.8232375],
        [305.4780372],
        [310.7164354],
        [325.7768303],
        [321.8480316],
        [315.3000339],
        [308.7520361],
        [306.7876368],
        [310.0616357],
        [316.6096334],
        [323.1576312],
        [330.3604287],
        [336.9084264],
        [343.4564242],
        [348.6948224],
        [349.3496222],
        [344.7660237],
        [338.218026],
        [331.6700282],
        [324.4672307]
        ];
        
        y_array := [
        [137.4530852],
        [137.4530852],
        [137.4530852],
        [137.4530852],
        [136.800876],
        [136.800876],
        [136.800876],
        [131.5832025],
        [130.2787841],
        [128.9743658],
        [127.6699474],
        [126.3655291],
        [125.0611107],
        [104.842626],
        [106.7992536],
        [106.7992536],
        [106.7992536],
        [106.7992536],
        [106.7992536],
        [107.4514628],
        [108.103672],
        [111.3647179],
        [113.3213454],
        [115.277973],
        [117.2346005],
        [118.5390189],
        [119.8434372],
        [94.40727912],
        [87.23297812],
        [80.05867712],
        [72.88437611],
        [80.7108863],
        [83.97193221],
        [83.97193221],
        [83.97193221],
        [83.97193221],
        [83.97193221],
        [83.97193221],
        [61.14461083],
        [61.14461083],
        [61.14461083],
        [60.49240165],
        [53.97030983],
        [46.79600882],
        [42.23054455],
        [41.57833537],
        [41.57833537],
        [46.79600882],
        [41.57833537],
        [40.92612618],
        [42.88275373],
        [48.75263637],
        [55.27472819],
        [61.14461083],
        [61.14461083],
        [61.14461083],
        [29.1863609],
        [24.62089663],
        [20.05543235],
        [17.44659562],
        [15.48996808],
        [12.88113135],
        [9.620085438],
        [6.359039527],
        [3.750202798],
        [4.40241198],
        [4.40241198],
        [4.40241198],
        [3.750202798],
        [5.706830344],
        [24.62089663],
        [27.22973336],
        [27.22973336],
        [27.22973336],
        [27.22973336],
        [26.57752417],
        [-25.5992104],
        [-30.81688386],
        [-25.5992104],
        [-25.5992104],
        [-26.25141958],
        [-25.5992104],
        [-25.5992104],
        [-25.5992104],
        [-25.5992104],
        [-19.72932776],
        [-12.55502676],
        [-10.59839921],
        [-13.85944512],
        [-17.12049103],
        [-20.38153694],
        [-24.29479204],
        [-36.6867665],
        [-41.90443996],
        [-48.42653178],
        [-55.60083278],
        [-40.60002159],
        [-45.16548587],
        [-51.68757769],
        [-57.55746033],
        [-58.20966951],
        [-56.25304197],
        [-51.68757769],
        [-47.12211341],
        [-43.20885832],
        [-68.64501643],
        [-71.90606234],
        [-78.42815416],
        [-84.95024598],
        [-88.21129189],
        [-88.21129189],
        [-85.60245516],
        [-84.95024598],
        [-87.55908271],
        [-86.90687353],
        [-81.68920007],
        [-74.51489907],
        [-69.94943479],
        [-77.1237358],
        [-100.6032664],
        [-101.9076847],
        [-105.1687306],
        [-111.6908225],
        [-118.2129143],
        [-120.1695418],
        [-120.821751],
        [-120.821751],
        [-120.1695418],
        [-118.8651235],
        [-114.2996592],
        [-107.7775674],
        [-102.5598939],
        [-101.2554755],
        [-100.6032664],
        [-100.6032664]
        ];
        
        sizes:=[27,11,18,20,16,13,14,16];
        z_array := 147;
        FOR i FROM 1 TO 27 DO
            letterArray{1,1,1} := bolded{1};
            letterArray{2,1,i} := x_array{i+step_count,1};
            letterArray{3,1,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 27;
        FOR i FROM 1 TO 11 DO
            letterArray{1,2,1} := bolded{2};
            letterArray{2,2,i} := x_array{i+step_count,1};
            letterArray{3,2,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 38;
        FOR i FROM 1 TO 18 DO
            letterArray{1,3,1} := bolded{3};
            letterArray{2,3,i} := x_array{i+step_count,1};
            letterArray{3,3,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 56;
        FOR i FROM 1 TO 20 DO
            letterArray{1,4,1} := bolded{4};
            letterArray{2,4,i} := x_array{i+step_count,1};
            letterArray{3,4,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 76;
        FOR i FROM 1 TO 16 DO
            letterArray{1,5,1} := bolded{5};
            letterArray{2,5,i} := x_array{i+step_count,1};
            letterArray{3,6,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 92;
        FOR i FROM 1 TO 13 DO
            letterArray{1,6,1} := bolded{6};
            letterArray{2,6,i} := x_array{i+step_count,1};
            letterArray{3,6,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 105;
        FOR i FROM 1 TO 14 DO
            letterArray{1,7,1} := bolded{7};
            letterArray{2,7,i} := x_array{i+step_count,1};
            letterArray{3,7,i} := y_array{i+step_count,1};
        ENDFOR
        step_count := 119;
        FOR i FROM 1 TO 16 DO
            letterArray{1,8,1} := bolded{8};
            letterArray{2,8,i} := x_array{i+step_count,1};
            letterArray{3,8,i} := y_array{i+step_count,1};
        ENDFOR
        !FOR i FROM 1 TO DIM(x_array, 1) DO
        !    letterArray{2,1,i} := x_array{i,1};
        !    letterArray{3,1,i} := y_array{i,1};
        !ENDFOR
    ENDPROC
    
    PROC MoveJSample()
    
        ! 'MoveJ' executes a joint motion towards a robtarget. This is used to move the robot quickly from one point to another when that 
        !   movement does not need to be in a straight line.
        ! 'pTableHome' is a robtarget defined in system module. The exact location of this on the table has been provided to you.
        ! 'v100' is a speeddata variable, and defines how fast the robot should move. The numbers is the speed in mm/sec, in this case 100mm/sec.
        ! 'fine' is a zonedata variable, and defines how close the robot should move to a point before executing its next command. 
        !   'fine' means very close, other values such as 'z10' or 'z50', will move within 10mm and 50mm respectively before executing the next command.
        ! 'tSCup' is a tooldata variable. This has been defined in a system module, and represents the tip of the suction cup, telling the robot that we
        !   want to move this point to the specified robtarget. Please be careful about what tool you use, as using the incorrect tool will result in
        !   the robot not moving where you would expect it to. Generally you should be using
        MoveJ pTableHome, v100, \T:=0.5, fine, tSCup;
        
    ENDPROC
    
    PROC MoveLSample()
        
        ! 'MoveL' will move in a straight line between 2 points. This should be used as you approach to pick up a chocolate
        ! 'Offs' is a function that is used to offset an existing robtarget by a specified x, y, and z. Here it will be offset 100mm in the positive z direction.
        !   Note that function are called using brackets, whilst procedures and called without brackets.
        MoveL Offs(pTableHome, 0, 0, 100), v100, fine, tSCup;
        
    ENDPROC
    
    PROC VariableSample(robtarget target, num x_offset, num y_offset, num z_offset, speeddata speed, zonedata zone)
        
        ! Call 'MoveL' with the input arguments provided.
        MoveL Offs(target, x_offset, y_offset, z_offset), speed, zone, tSCup;
        
    ENDPROC
    
ENDMODULE