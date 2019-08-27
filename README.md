# Fri3pm-CakeShop
All code snippets for robot simulation of a cake shop

Current version: ROBOT_FINAL_2.0
Please put all updates inside this folder.
If you're confused about the change in function names, please ask on Facebook

# Instructions 
## How to put our code on lab computer
### From personal computer: 
1. Pack and Go from laptop (currently doing it from Lawrence's laptop)
    T_COM should contain: CakeShopServer.mod and ConveyorController.mod
    T_ROB contains all other .mod files (including a duplicate of ConveyorController.mod; do not worry about this duplicate)
2. Put the .rspag on a USB along with the current folder (ROBOT_FINAL_2.0) which contains all the Matlab files

### From lab computer:
#### Matlab:
1. Open Matlab
2. Load all .m, .mat, .jpg files
3. Run main.m *after* Step 5 under Flex Pendant

#### RobotStudio:
1. Open RobotStudio
2. Go to File > Share > Unpack and Go and load up the .rspag file
3. Go to Controller > Add Controller > Local Controller
    You should now see two stations: Vinnie and the IRB
4. Go to both T_COMs and "Stop Task"
5. Go to Controller > Create Relation
    Name: put anything, I don't think it matters
    2nd Box: the Vinnie station
    3rd Box: the IRB station
6. The Vinnie .mod files should sync up to the IRB station and in turn the Flex Pendant

#### Flex Pendant:
1. Go to ABB > Program Editor
    This should load T_ROB by default
2. Go to ABB > Program Editor
    This will open another T_ROB. Then do:
    a. Task and Programs and select T_COM1 > Show Modules
    b. Locate CakeShopServer main and open that
3. Click on the square symbol botton right corner of the screen
    a. Then click on gear shift ish button (next one up)
    b. Make sure both T_COM and T_ROB are ticked
4. Along the bottom of the Flex Pendant, you should see T_COM and T_ROB main programs, set both pointers to Main (Debug > PP to Main)
5. Hold down thing and hit play

#### Notes:
- anything changed on RobotStudio does not save unless we Pack and Go again (I think)
- alternatively copy paste via Notepad
- make sure you're running Matlab files from USB, else changes will also be lost

## How to run Unit Tests
1. If all code has been loaded up as per above, there should be a UnitTests folder on your USB
2. In RobotStudio, go to T_ROB (right click) > Load Module and select all files in the UnitTest folder
3a. Run from Flex Pendant
3b. Alternatively, uncomment lines 67-77 in CakeShopRobotMain.mod

## How to test Light Curtain/E_STOP/E_STOP2
1. Run any lengthy program
2. Interrupt light curtain to trigger Light Curtain trap routine
3. Hit any emergency stop EXCEPT the one on the motor box to trigger E_STOP
4. Hit the motor box emergency stop to trigger E_STOP2
In any of these cases, a message should print in Matlab (should print to GUI?) and also on the FlexPendant.
Can resume program from Flex Pendant if everything is reset (hopefully)
