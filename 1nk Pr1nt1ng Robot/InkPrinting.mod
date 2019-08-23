!Name: Int Printing Robot
!Author Name: Mike Ni
!ZID: Z5083683
!Description: 
! runs program to move TCP along a given trajectory with a given speed dicided by boldness of letter
!
!input 
! data_matrix - a 3-by-n-by-m matrix data, recevied from GUI part, see GUI for more info
! sizeOfLetter - a n-by-1 array, where n is the number of chars, 
!                each value represents the number of coordinates for the planned trajectory 
! z_coor - the z coordinate for ink printing, assume to be 147
MODULE InkPrinting
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
ENDMODULE
