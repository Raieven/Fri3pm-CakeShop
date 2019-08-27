% Author: Alexander Thanh Minh Nguyen
% ID: z5114918
% Date: 23/8/19
% Description:  
% MTRN4230 Group Assignment
% Computer Vision program for Decoration
%
% Objectification by Jesse Falzon
%
% Usage:
%       make object with:
%   >> Dec = Decoration();
%
%       call vision code with
%   >> Image = imread('path/to.jpg');
%   >> [from, to, angle] = Dec.update(Image);
%
%  Input: 
%   Image - Image taken from table camera
%   eg: Image = '1.png';
%
%  Output:
%
%   from(i,:)   - X, Y, Z coords of the i-th block on the conveyor
%   to(i,:)     - X, Y, Z coords of the i-th block on the table
%   angle(i)    - the angle to turn i-th block on the table


% in the main function it should loop:
%=================== sample loop ===============================
% UnmatchedBlocksFlag = 0;
% cake = 0;
% detectedCakeBlocks = [];
% detectedCakeBlocksCentres = [];
% cakeBlockUnmatchedIndex = [];
% processFlag = 0;
% completeCakeFlag = 0;
% %when a new image of a cake is taken then the completeCakeFlag will be set
% %to 0
% if completeCakeFlag == 0
%     [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
%         UnmatchedBlocksFlag,prevcake,prevdetectedCakeBlocks,...
%         prevdetectedCakeBlocksCentres,processFlag] = dectorationDetection(UnmatchedBlocksFlag,cakeBlockUnmatchedIndex,cake,detectedCakeBlocks,...
%                                                                 detectedCakeBlocksCentres,processFlag);
%     % the 2 matricies are sent to the robot and it performs the motions until
%     % it exhasted all the matrix co-ordinates, after completeting the motions,
%     % it will check if the variable completeCake is set to 1, if not that means
%     % there is an UNMATCHED block.
% 
%     pause; %wiating for the robot to be done
% 
%     %% write a function that loops until the UnmatchedIndex is fin e.g. for int i=size(cakeBlockUnmatchedIndex,2)
%     while UnmatchedBlocksFlag == 1
%         %we move the conveyor for new blocks
%         len = length(find(cakeBlockUnmatchedIndex>0));
%         fprintf("There is %d left over blocks\n",len);
%         pause;
%         [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
%             UnmatchedBlocksFlag,prevcake,prevdetectedCakeBlocks,...
%                 prevdetectedCakeBlocksCentres,processFlag] = dectorationDetection(UnmatchedBlocksFlag,cakeBlockUnmatchedIndex,prevcake,...
%                                                 prevdetectedCakeBlocks,prevdetectedCakeBlocksCentres,processFlag);
%     end
% end
% %if there are no unmatched blocks then
% completeCakeFlag = 1;
% disp("Cake Complete");
%=======================================================================

function [Decor_copy] = Decoration()
    % do your setup stuff here
    global Decor;
    Decor.blockColourFlag = 0;
    Decor.cakeOrientation = 0;
    Decor.convOrientaion = 0;
    Decor.blockOrderCounter = 1;
    Decor.blockHeight = 11; %block height it 12
    
    Decor.UnmatchedBlocksFlag = 0;
%     Decor.detectedCakeBlocks = [];
%     Decor.detectedCakeBlocksCentres = [];
%     Decor.cakeBlockUnmatchedIndex = [];
    Decor.processFlag = 0;  %flag for a completed cycle of 1 process
    Decor.completeCakeFlag = 0; %flag for a completed Cake
    
    Decor.unmatchedIterator = 1;
    %Camera Calibration
    Decor.camParam = load('cameraParams3');
    IM1 = [798, 288];
    IM2 = [21, 288];
    IM3 = [1586, 296];
    IM4 = [793, 856];
    IM5 = [795.5,572]; %midpoint of IM1 and IM4
    imagePoints = [IM1; IM2; IM3; IM4; IM5];
    
    T1 = [175,0];
    T2 = [175,-520];
    T3 = [175,520];
    T4 = [548.6,0];
    T5 = [361.8,0]; %midpoint of T1 and T4
    worldPoints = [T1; T2; T3; T4; T5];
    
    [Decor.tableRotationMatrix,Decor.tableTranslationVector] = extrinsics(imagePoints,worldPoints,Decor.camParam.cameraParams3);
    
    Decor.convParam = load('cameraParams_conveyor.mat');
    convImagePoints = load('convImagePoints.mat');
    convWorldPoints = load('convWorldPoints.mat');
    [Decor.convRotationMatrix, Decor.convTranslationVector] = extrinsics(convImagePoints.imagePoints, ...
                                                        convWorldPoints.worldPoints, Decor.convParam.ConvCameraParams);
    
    Decor.update = @your_decoration_function;
    Decor.test = @your_decoration_unit_test_function;
    Decor_copy = Decor;
end

function [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
        cake,detectedCakeBlocks,detectedCakeBlocksCentres,detectedConvBlocks] = your_decoration_function(cake,conveyor,cakeBlockUnmatchedIndex,...
                                                                            detectedCakeBlocks,detectedCakeBlocksCentres,detectedConvBlocks)
    global Decor;    
    % detect the blocks on cake
    if Decor.UnmatchedBlocksFlag == 0
        IbwCake = ~im2bw(cake, graythresh(cake));
        Ifill1 = imfill(IbwCake, 'holes');
        IfillCake = bwmorph(Ifill1, 'erode');
        IareaCake = bwareaopen(IfillCake,100);
        IfinalCake = bwlabel(IareaCake);
        stat = regionprops(IfinalCake, 'boundingbox');
        j = 1;
        for i = 1:size(stat,1)
            if (abs(diff([stat(i).BoundingBox(3) stat(i).BoundingBox(4)],1)) < 10) && ...
                    (stat(i).BoundingBox(3) > 45)
                bb = stat(i).BoundingBox;
                detectedCakeBlocks(j,:) = stat(i).BoundingBox;
                detectedCakeBlocksCentres(j,:) = [bb(1)+bb(3)/2 bb(2)+bb(4)/2];
                j = j + 1;
            end
        end
    end
    % detecting blocks on the conveyor
    conveyor = imcrop(conveyor,[544.5 349.5 617 346]);%,[568.5 0.5 578 678]);%,[418.5 3.5 574 428]);
    [BW,maskedRGBImage] = identifyConveyorBlocks2(conveyor);
    IbwConv = ~BW;
    Ifill = imfill(IbwConv, 'holes');
    IareaConv = bwareaopen(Ifill,200);
    IfinalConv = bwlabel(IareaConv);
    stat = regionprops(IfinalConv, 'boundingbox');
    j = 1;
    if (size(stat,1) > 0)
        for i = 1:size(stat,1)
           if (abs(diff([stat(i).BoundingBox(3) stat(i).BoundingBox(4)],1)) < 13) && ...
                   (stat(i).BoundingBox(3) > 40)
               bb = stat(i).BoundingBox;
               detectedConvBlocks(j,:) = stat(i).BoundingBox;
               detectedConvBlocksCentres(j,:) = [bb(1)+bb(3)/2 bb(2)+bb(4)/2];
               j = j + 1;
           end
        end
    else
        detectedConvBlocks = [];
        detectedConvBlocksCentres = [];
    end
    %%
    %Indexing all the blocks on the conveyor belt
    if (isempty(detectedConvBlocks) == 0)
        redConvBlockIndex = findRedConvBlock(conveyor,detectedConvBlocks);
        greenConvBlockIndex = findGreenConvBlock(conveyor,detectedConvBlocks);
        blueConvBlockIndex = findBlueConvBlock(conveyor,detectedConvBlocks);
        yellowConvBlockIndex = findYellowConvBlock(conveyor,detectedConvBlocks);
    else
        detectedConvBlocks = [];
        detectedConvBlocksCentres = [];
    end

    if Decor.UnmatchedBlocksFlag == 0
        numberOfBlocks = size(detectedCakeBlocks,1);
    elseif Decor.UnmatchedBlocksFlag == 1
        numberOfBlocks = length(cakeBlockUnmatchedIndex);
    end
    unmatchedIterator = 1;
    
    if (isempty(detectedConvBlocks) == 0)
        numB = 1;
    else
        numB = numberOfBlocks + 1;
    end
    for i = numB:numberOfBlocks
        Decor.convOrientation = 0;
        if Decor.processFlag == 0
            %put the centres of the first cake block in the matricies
            cakeWorldCentres = pointsToWorld(Decor.camParam.cameraParams3, Decor.tableRotationMatrix, Decor.tableTranslationVector, ...
                                [detectedCakeBlocksCentres(i,1), detectedCakeBlocksCentres(i,2)]);
            blockOrder(Decor.blockOrderCounter,1) = cakeWorldCentres(1);
            blockOrder(Decor.blockOrderCounter,2) = cakeWorldCentres(2);
            blockOrder(Decor.blockOrderCounter,3) = 147 + Decor.blockHeight;

            block = imcrop(cake, [detectedCakeBlocks(i,1)-5,detectedCakeBlocks(i,2)-5, ...
                                    detectedCakeBlocks(i,3)+10, detectedCakeBlocks(i,4)+10]);
        elseif Decor.processFlag == 1
            if Decor.cakeBlockUnmatchedIndex(i) == 0
                continue;
            else
                cakeWorldCentres = pointsToWorld(Decor.camParam.cameraParams3, Decor.tableRotationMatrix, Decor.tableTranslationVector, ...
                                                [detectedCakeBlocksCentres(Decor.cakeBlockUnmatchedIndex(i),1),...
                                                detectedCakeBlocksCentres(Decor.cakeBlockUnmatchedIndex(i),2)]);
                blockOrder(Decor.blockOrderCounter,1) = cakeWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,2) = cakeWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,3) = 147 + Decor.blockHeight;

                block = imcrop(cake, [detectedCakeBlocks(i,1)-5,detectedCakeBlocks(i,2)-5, ...
                                        detectedCakeBlocks(Decor.cakeBlockUnmatchedIndex(i),3)+10,...
                                        detectedCakeBlocks(Decor.cakeBlockUnmatchedIndex(i),4)+10]);
            end
        end
    %     imwrite(block,'block.jpg');
        Decor.cakeOrientation = getCakeOrientation(block);
        
        %checks if the cake block is red, green, blue or yellow
        redCheck = cakeRedBlocks(block);
        [Iarea,shapes] = filter(redCheck);
        check = regionprops(shapes, 'Area');
        idx = find([check.Area] > 220);
        if(idx > 0)
            %ITS A RED BLOCK
            Decor.blockColourFlag = 1;
        else
            greenCheck = cakeGreenBlocks(block);
            [Iarea,shapes] = filter(greenCheck);
            check = regionprops(shapes, 'Area');
            idx = find([check.Area] > 220);
            if (idx > 0)
                %ITS A GREEN BLOCK
                Decor.blockColourFlag = 2;
            else
                blueCheck = cakeBlueBlocks(block);
                [Iarea,shapes] = filter(blueCheck);
                check = regionprops(shapes, 'Area');
                idx = find([check.Area] > 220);
                if (idx > 0)
                    %ITS A BLUE BLOCK
                    Decor.blockColourFlag = 3;
                else
                    yellowCheck = cakeYellowBlocks(block);
                    [Iarea,shapes] = filter(yellowCheck);
                    check = regionprops(shapes, 'Area');
                    idx = find([check.Area] > 220);
                    if (idx > 0)
                        %ITS A YELLOW BLOCK
                        Decor.blockColourFlag = 4;
                    else
                        disp("This is not a real block: skipped");
                        Decor.blockColourFlag = 5;
                    end
                end
            end
        end

        if (Decor.blockColourFlag == 1)
            redCakeShape = findRedCakeBlockShape(blockOrder,block,Decor.blockColourFlag);
            [matchedIndex,Decor.convOrientation] = matchWithConveyor(Decor.blockColourFlag,redCakeShape, redConvBlockIndex, ...
                                                                detectedConvBlocks, conveyor,block);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, ...
                                    [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + Decor.blockHeight;
                
                %if i am reusing old data then i need to make that index in
                %cakeBlocksUnmatedIndex to be empty.
                if Decor.processFlag == 1
                    Decor.cakeBlockUnmatchedIndex(i) = 0;
                end
                
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                Decor.UnmatchedBlocksFlag = 1;
                if Decor.processFlag == 0
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = i;
                else
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = cakeBlockUnmatchedIndex(i); 
                end
                unmatchedIterator = unmatchedIterator + 1;
            end
        elseif (Decor.blockColourFlag == 2)
            greenCakeShape = findGreenCakeBlockShape(blockOrder,block,Decor.blockColourFlag);
            [matchedIndex,Decor.convOrientation] = matchWithConveyor(Decor.blockColourFlag,greenCakeShape, greenConvBlockIndex, detectedConvBlocks, conveyor,block);
            %155 is a value that i set for no index of the conveyor mataching
            %with 
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(Decor.convParam.ConvCameraParams, Decor.convRotationMatrix, Decor.convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + Decor.blockHeight;
                
                %if i am reusing old data then i need to make that index in
                %cakeBlocksUnmatedIndex to be empty.
                if Decor.processFlag == 1
                    Decor.cakeBlockUnmatchedIndex(i) = 0;
                end
                
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                Decor.UnmatchedBlocksFlag = 1;
                if Decor.processFlag == 0
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = i;
                else
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = cakeBlockUnmatchedIndex(i); 
                end
                unmatchedIterator = unmatchedIterator + 1;
            end
        elseif (Decor.blockColourFlag == 3)
            blueCakeShape = findBlueCakeBlockShape(blockOrder,block,Decor.blockColourFlag);
            [matchedIndex,Decor.convOrientation] = matchWithConveyor(Decor.blockColourFlag,blueCakeShape, blueConvBlockIndex, detectedConvBlocks, conveyor,block);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(Decor.convParam.ConvCameraParams, Decor.convRotationMatrix, Decor.convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + Decor.blockHeight;
                
                %if i am reusing old data then i need to make that index in
                %cakeBlocksUnmatedIndex to be empty.
                if Decor.processFlag == 1
                    Decor.cakeBlockUnmatchedIndex(i) = 0;
                end
                
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                Decor.UnmatchedBlocksFlag = 1;
                if Decor.processFlag == 0
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = i;
                else
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = cakeBlockUnmatchedIndex(i); 
                end
                unmatchedIterator = unmatchedIterator + 1;
            end
        elseif (Decor.blockColourFlag == 4)
            yellowCakeShape = findYellowCakeBlockShape(blockOrder,block,Decor.blockColourFlag);
    %         sprintf('yellowCakeShape: %d\n', yellowCakeShape)
            [matchedIndex,Decor.convOrientation] = matchWithConveyor(Decor.blockColourFlag,yellowCakeShape, yellowConvBlockIndex, detectedConvBlocks, conveyor,block);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(Decor.convParam.ConvCameraParams, Decor.convRotationMatrix, Decor.convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + Decor.blockHeight;
                
                %if i am reusing old data then i need to make that index in
                %cakeBlocksUnmatedIndex to be empty.
                if Decor.processFlag == 1
                    Decor.cakeBlockUnmatchedIndex(i) = 0;
                end
                
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                Decor.UnmatchedBlocksFlag = 1;
                if Decor.processFlag == 0
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = i;
                else
                    cakeBlockUnmatchedIndex(1,unmatchedIterator) = cakeBlockUnmatchedIndex(i); 
                end
                unmatchedIterator = unmatchedIterator + 1;
            end
        elseif (Decor.blockColourFlag == 5)
            %this block will be skipped
        end
        %calculates the difference in angles and that puts it in the matrix
        %CW = positve
        %CCW = negative
        if matchedIndex ~= 155
            blockOrder(blockOrderCounter,7) = cakeOrientation - convOrientation;
        elseif matchedIndex == 155
            blockOrder(blockOrderCounter,7) = 0;
        end
        % increments the variable that cycles throught the orderBlocks matrix
        blockOrderCounter = blockOrderCounter + 1;
    end
    
    if (isempty(detectedConvBlocks) == 1)
        blockOrder(Decor.blockOrderCounter,1:7) = 0;
        leftOverBlocks = [];
        Decor.processFlag = 1;
        if Decor.UnmatchedBlocksFlag == 0
            Decor.UnmatchedBlocksFlag = 1;
            cakeBlockUnmatchedIndex = 1:numberOfBlocks;
        %else this is not the first run, thus needs to put shit in the indexes
        else
            cakeBlockUnmatchedIndex(:) = cakeBlockUnmatchedIndex(:);
        end
    else
        j = 1;
        for i = 1:size(detectedConvBlocksCentres,1)
            if (detectedConvBlocksCentres(i,1) ~= -100)
                convWorldCentres = pointsToWorld(Decor.convParam.ConvCameraParams, Decor.convRotationMatrix, Decor.convTranslationVector,...
                                    [detectedConvBlocksCentres(i,1) detectedConvBlocksCentres(i,2)]);
                leftOverBlocks(j,1) = convWorldCentres(1);
                leftOverBlocks(j,2) = convWorldCentres(2);
                leftOverBlocks(j,3) = 22.1 + Decor.blockHeight;
                leftOverBlocks(j,4) = randi([587 751]);
                leftOverBlocks(j,5) = randi([315 514]);
                leftOverBlocks(j,6) = 147 + Decor.blockHeight;
                j=j+1;
            end
        end
        if unmathcedIterator == 1
           Decor.UnmatchedBlocksFlag = 0; 
        end
    end
    function cakeShape = findRedCakeBlockShape(blockOrder,block)
        redCakeBlocks = cakeRedBlocks(block);
        [Iarea,shapes] = filter(redCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        cakeShape = redCakeShapeIdentifier(BP,block,shapes);
    end
    function cakeShape = findGreenCakeBlockShape(blockOrder,block)
        greenCakeBlocks = cakeGreenBlocks(block);
        [Iarea,shapes] = filter(greenCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        cakeShape = greenCakeShapeIdentifier(BP,block,shapes);
    end
    function cakeShape = findBlueCakeBlockShape(blockOrder,block)
        blueCakeBlocks = cakeBlueBlocks(block);
        [Iarea,shapes] = filter(blueCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        cakeShape = blueCakeShapeIdentifier(BP,block,shapes);
    end
    function cakeShape = findYellowCakeBlockShape(blockOrder,block)
        yellowCakeBlocks = cakeYellowBlocks(block);
        [Iarea,shapes] = filter(yellowCakeBlocks);
        shapes = bwareaopen(shapes,200);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        cakeShape = yellowCakeShapeIdentifier(BP,block,shapes);
    end

    function redConvBlockIndex = findRedConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorRedBlocks(convBlock);
             redStats = regionprops(b, 'Area');
             if size(redStats,1) > 0
                 idx = find([redStats.Area] > 250);
                 if (idx ~= 0)
                     redConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(redBlockIndex);
    end
    function greenConvBlockIndex = findGreenConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorGreenBlocks(convBlock);
             greenStats = regionprops(b, 'Area');
             if size(greenStats,1) > 0
                 idx = find([greenStats.Area] > 250);
                 if (idx ~= 0)
                     greenConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(greenConvBlockIndex);
    end
    function blueConvBlockIndex = findBlueConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorBlueBlocks(convBlock);
             blueStats = regionprops(b, 'Area');
             if size(blueStats,1) > 0
                 idx = find([blueStats.Area] > 250);
                 if (idx ~= 0)
                     blueConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(blueConvBlockIndex);
    end
    function yellowConvBlockIndex = findYellowConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorYellowBlocks(convBlock);
             yellowStats = regionprops(b, 'Area');
             if size(yellowStats,1) > 0
                 idx = find([yellowStats.Area] > 250);
                 if (idx ~= 0)
                     yellowConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(yellowConvBlockIndex);
    end

    function [area,shapes] = filter(BW)
        shapes = imfill(BW, 'holes');
        %shapes = bwmorph(shapes, 'erode');
        area = bwareaopen(shapes,200);
    end
    function [BW,maskedRGBImage] = identifyConveyorBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 21-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.989;
    channel1Max = 0.098;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.436;
    channel2Max = 0.949;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.164;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Invert mask
    BW = ~BW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
    function [BW,maskedRGBImage] = identifyConveyorBlocks2(RGB)
    %used when the exposure is -6
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 21-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    % channel1Min = 0.110;
    % channel1Max = 0.008;
    % channel1Min = 0.960;
    % channel1Max = 0.125;
    channel1Min = 0.009;
    channel1Max = 0.141;

    % Define thresholds for channel 2 based on histogram settings
    % channel2Min = 0.000;
    % channel2Max = 1.000;
    % channel2Min = 0.272;
    % channel2Max = 1.000;
    channel2Min = 0.331;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    % channel3Min = 0.000;
    % channel3Max = 1.000;
    % channel3Min = 0.124;
    % channel3Max = 0.659;
    channel3Min = 0.175;
    channel3Max = 0.640;

    % Create mask based on chosen histogram thresholds
    %FOR THE 2ND AND 1ST OPTION
    % sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
    %     (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
    %     (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    % BW = sliderBW;
    %FOR THE THIRD OPTION
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;
    
    %inverter
    BW = ~BW;
    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
    end

    function [BW,maskedRGBImage] = conveyorRedBlocks(RGB)
        %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
        %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
        %  auto-generated code from the colorThresholder app. The colorspace and
        %  range for each channel of the colorspace were set within the app. The
        %  segmentation mask is returned in BW, and a composite of the mask and
        %  original RGB images is returned in maskedRGBImage.

        % Auto-generated by colorThresholder app on 20-Aug-2019
        %------------------------------------------------------


        % Convert RGB image to chosen color space
        I = rgb2hsv(RGB);

        % Define thresholds for channel 1 based on histogram settings
        channel1Min = 0.906;
        channel1Max = 0.027;

        % Define thresholds for channel 2 based on histogram settings
        channel2Min = 0.263;
        channel2Max = 1.000;

        % Define thresholds for channel 3 based on histogram settings
        channel3Min = 0.293;
        channel3Max = 1.000;

        % Create mask based on chosen histogram thresholds
        sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
            (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
            (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
        BW = sliderBW;

        % Initialize output masked image based on input image.
        maskedRGBImage = RGB;

        % Set background pixels where BW is false to zero.
        maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

        end
    function [BW,maskedRGBImage] = cakeRedBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.927;
    channel1Max = 0.053;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.137;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.487;
    channel3Max = 0.809;

    % Create mask based on chosen histogram thresholds
    sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorGreenBlocks(RGB)
        %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
        %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
        %  auto-generated code from the colorThresholder app. The colorspace and
        %  range for each channel of the colorspace were set within the app. The
        %  segmentation mask is returned in BW, and a composite of the mask and
        %  original RGB images is returned in maskedRGBImage.

        % Auto-generated by colorThresholder app on 20-Aug-2019
        %------------------------------------------------------


        % Convert RGB image to chosen color space
        I = rgb2hsv(RGB);

        % Define thresholds for channel 1 based on histogram settings
    %     channel1Min = 0.231;
    %     channel1Max = 0.493;
        channel1Min = 0.252;
        channel1Max = 0.410;

        % Define thresholds for channel 2 based on histogram settings
    %     channel2Min = 0.285;
    %     channel2Max = 1.000;
        channel2Min = 0.258;
        channel2Max = 1.000;

        % Define thresholds for channel 3 based on histogram settings
    %     channel3Min = 0.184;
    %     channel3Max = 1.000;
        channel3Min = 0.184;
        channel3Max = 1.000;

        % Create mask based on chosen histogram thresholds
        sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
            (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
            (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
        BW = sliderBW;

        % Initialize output masked image based on input image.
        maskedRGBImage = RGB;

        % Set background pixels where BW is false to zero.
        maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

        end
    function [BW,maskedRGBImage] = cakeGreenBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    % base filter
    % channel1Min = 0.179;
    % channel1Max = 0.521;
    channel1Min = 0.208;
    channel1Max = 0.408;

    % Define thresholds for channel 2 based on histogram settings
    % base filter
    % channel2Min = 0.047;
    % channel2Max = 0.927;
    channel2Min = 0.069;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    % base filter
    % channel3Min = 0.317;
    % channel3Max = 1.000;
    channel3Min = 0.398;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorBlueBlocks(RGB)
        %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
        %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
        %  auto-generated code from the colorThresholder app. The colorspace and
        %  range for each channel of the colorspace were set within the app. The
        %  segmentation mask is returned in BW, and a composite of the mask and
        %  original RGB images is returned in maskedRGBImage.

        % Auto-generated by colorThresholder app on 20-Aug-2019
        %------------------------------------------------------


        % Convert RGB image to chosen color space
        I = rgb2hsv(RGB);

        % Define thresholds for channel 1 based on histogram settings
        channel1Min = 0.557;
        channel1Max = 0.677;

        % Define thresholds for channel 2 based on histogram settings
        channel2Min = 0.297;
        channel2Max = 1.000;

        % Define thresholds for channel 3 based on histogram settings
        channel3Min = 0.385;
        channel3Max = 1.000;

        % Create mask based on chosen histogram thresholds
        sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
            (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
            (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
        BW = sliderBW;

        % Initialize output masked image based on input image.
        maskedRGBImage = RGB;

        % Set background pixels where BW is false to zero.
        maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

        end
    function [BW,maskedRGBImage] = cakeBlueBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.524;
    channel1Max = 0.685;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.151;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.452;
    channel3Max = 0.894;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorYellowBlocks(RGB)
        %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
        %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
        %  auto-generated code from the colorThresholder app. The colorspace and
        %  range for each channel of the colorspace were set within the app. The
        %  segmentation mask is returned in BW, and a composite of the mask and
        %  original RGB images is returned in maskedRGBImage.

        % Auto-generated by colorThresholder app on 20-Aug-2019
        %------------------------------------------------------


        % Convert RGB image to chosen color space
        I = rgb2hsv(RGB);

        % Define thresholds for channel 1 based on histogram settings
        % channel1Min = 0.136;
        % channel1Max = 0.194;
        channel1Min = 0.114;
        channel1Max = 0.222;
        % Define thresholds for channel 2 based on histogram settings
        % channel2Min = 0.167;
        % channel2Max = 1.000;
        channel2Min = 0.000;
        channel2Max = 1.000;

        % Define thresholds for channel 3 based on histogram settings
        % channel3Min = 0.476;
        % channel3Max = 1.000;
        channel3Min = 0.282;
        channel3Max = 1.000;

        % Create mask based on chosen histogram thresholds
        sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
            (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
            (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
        BW = sliderBW;

        % Initialize output masked image based on input image.
        maskedRGBImage = RGB;

        % Set background pixels where BW is false to zero.
        maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

        end
    function [BW,maskedRGBImage] = cakeYellowBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.106;
    channel1Max = 0.246;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.159;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.550;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function cakeShape = redCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1096 && BP.Area <= 1286) && (BP.Solidity >= 0.93 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 128 && BP.Perimeter <= 144) && (BP.EquivDiameter >= 35 && BP.EquivDiameter <= 42) &&...
                (BP.MinorAxisLength >= 35 && BP.MinorAxisLength <= 41)&&(BP.MajorAxisLength >= 37 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 924 && BP.Area <= 999) && (BP.Solidity >= 0.83 && BP.Solidity <= 0.95 ) && ...
                (BP.Perimeter >= 117 && BP.Perimeter <= 164) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 37) && (BP.MajorAxisLength >= 34 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 420 && BP.Area <= 773) && (BP.Solidity >= 0.57 && BP.Solidity <= 0.82 ) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 177) && (BP.EquivDiameter >= 22 && BP.EquivDiameter <= 31) &&...
                (BP.MinorAxisLength >= 21 && BP.MinorAxisLength <= 33) && (BP.MajorAxisLength >= 25 && BP.MajorAxisLength <= 35))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 545 && BP.Area <= 1136) && (BP.Solidity >= 0.50 && BP.Solidity <= 0.85 ) && ...
                (BP.Perimeter >= 152 && BP.Perimeter <= 246) && (BP.EquivDiameter >= 25 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 27 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 28 && BP.MajorAxisLength <= 41) &&...
                BP.Extent > 0.5) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 454 && BP.Area <= 919) && (BP.Solidity >= 0.47 && BP.Solidity <= 0.58 ) && ...
                (BP.Perimeter >= 151 && BP.Perimeter <= 218) && (BP.EquivDiameter >= 23 && BP.EquivDiameter <= 35.5) &&...
                (BP.MinorAxisLength >= 26 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 30 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 839 && BP.Area <= 915) && (BP.Solidity >= 0.88 && BP.Solidity <= 0.94) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 150) && (BP.EquivDiameter >= 31 && BP.EquivDiameter <= 35) &&...
                (BP.MinorAxisLength >= 30 && BP.MinorAxisLength <= 35) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 36.5)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            if size(stats,1) > 1
                cb = bwmorph(cb, 'erode');
                area = bwareaopen(cb,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end
    function cakeShape = greenCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1237 && BP.Area <= 1548) && (BP.Solidity >= 0.9 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 131 && BP.Perimeter <= 161) && (BP.EquivDiameter >= 37 && BP.EquivDiameter <= 43) &&...
                (BP.MinorAxisLength >= 37 && BP.MinorAxisLength <= 45)&&(BP.MajorAxisLength >= 37 && BP.MajorAxisLength <= 46)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 819 && BP.Area <= 1045) && (BP.Solidity >= 0.83 && BP.Solidity <= 0.93 ) && ...
                (BP.Perimeter >= 130 && BP.Perimeter <= 153) && (BP.EquivDiameter >= 31 && BP.EquivDiameter <= 38) &&...
                (BP.MinorAxisLength >= 32 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 32 && BP.MajorAxisLength <= 40)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 420 && BP.Area <= 868) && (BP.Solidity >= 0.57 && BP.Solidity <= 0.82 ) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 210) && (BP.EquivDiameter >= 22 && BP.EquivDiameter <= 34) &&...
                (BP.MinorAxisLength >= 21 && BP.MinorAxisLength <= 35) && (BP.MajorAxisLength >= 25 && BP.MajorAxisLength <= 35.5) &&...
                BP.Extent > 0.4)%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 778 && BP.Area <= 1176) && (BP.Solidity >= 0.70 && BP.Solidity <= 0.87 ) && ...
                (BP.Perimeter >= 139 && BP.Perimeter <= 200) && (BP.EquivDiameter >= 30 && BP.EquivDiameter <= 40) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 41) && (BP.MajorAxisLength >= 35 && BP.MajorAxisLength <= 43)) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 402 && BP.Area <= 1024) && (BP.Solidity >= 0.54 && BP.Solidity <= 0.7 ) && ...
                (BP.Perimeter >= 108 && BP.Perimeter <= 222) && (BP.EquivDiameter >= 21 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 23 && BP.MinorAxisLength <= 43) && (BP.MajorAxisLength >= 27 && BP.MajorAxisLength <= 47)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 768 && BP.Area <= 1168) && (BP.Solidity >= 0.85 && BP.Solidity <= 1) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 151) && (BP.EquivDiameter >= 30 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 30 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 31 && BP.MajorAxisLength <= 41)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            if size(stats,1) > 1
                cb = bwmorph(cb, 'erode');
                area = bwareaopen(cb,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end
    function cakeShape = blueCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1130 && BP.Area <= 1450) && (BP.Solidity >= 0.90 && BP.Solidity <= 0.98 ) && ...
                (BP.Perimeter >= 140 && BP.Perimeter <= 175) && (BP.EquivDiameter >= 36 && BP.EquivDiameter <= 44) &&...
                (BP.MinorAxisLength >= 36.5 && BP.MinorAxisLength <= 44)&&(BP.MajorAxisLength >= 37 && BP.MajorAxisLength <= 44)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 932 && BP.Area <= 1108) && (BP.Solidity >= 0.91 && BP.Solidity <= 0.97 ) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 136) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 38) && (BP.MajorAxisLength >= 34 && BP.MajorAxisLength <= 40)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 565 && BP.Area <= 888) && (BP.Solidity >= 0.58 && BP.Solidity <= 0.70 ) && ...
                (BP.Perimeter >= 162 && BP.Perimeter <= 230) && (BP.EquivDiameter >= 26 && BP.EquivDiameter <= 34) &&...
                (BP.MinorAxisLength >= 27.5 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 29.5 && BP.MajorAxisLength <= 42))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 845 && BP.Area <= 1221) && (BP.Solidity >= 0.78 && BP.Solidity <= 0.86 ) && ...
                (BP.Perimeter >= 137 && BP.Perimeter <= 199) && (BP.EquivDiameter >= 32 && BP.EquivDiameter <= 40) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 42) && (BP.MajorAxisLength >= 35 && BP.MajorAxisLength <= 43)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape =  4;
        elseif ((BP.Area >= 663 && BP.Area <= 968) && (BP.Solidity >= 0.28 && BP.Solidity <= 0.66 ) && ...
                (BP.Perimeter >= 167 && BP.Perimeter <= 210) && (BP.EquivDiameter >= 28.5 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 35.5 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 837 && BP.Area <= 1079) && (BP.Solidity >= 0.85 && BP.Solidity <= 0.98) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 170) && (BP.EquivDiameter >= 32 && BP.EquivDiameter <= 38) &&...
                (BP.MinorAxisLength >= 32.5 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 39)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            if size(stats,1) > 1
                cb = bwmorph(cb, 'erode');
                area = bwareaopen(cb,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end
    end
    function cakeShape = yellowCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
       if ((BP.Area >= 1130 && BP.Area <= 1274) && (BP.Solidity >= 0.82 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 116 && BP.Perimeter <= 128) && (BP.EquivDiameter >= 37 && BP.EquivDiameter <= 42) &&...
                (BP.MinorAxisLength >= 36 && BP.MinorAxisLength <= 40)&&(BP.MajorAxisLength >= 38 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 935 && BP.Area <= 976) && (BP.Solidity >= 0.79 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 125) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 36) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 538 && BP.Area <= 615) && (BP.Solidity >= 0.42 && BP.Solidity <= 0.76 ) && ...
                (BP.Perimeter >= 163 && BP.Perimeter <= 181) && (BP.EquivDiameter >= 25 && BP.EquivDiameter <= 30) &&...
                (BP.MinorAxisLength >= 27 && BP.MinorAxisLength <= 31) && (BP.MajorAxisLength >= 28 && BP.MajorAxisLength <= 32))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 878 && BP.Area <= 1001) && (BP.Solidity >= 0.63 && BP.Solidity <= 0.96 ) && ...
                (BP.Perimeter >= 140 && BP.Perimeter <= 162) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 33.5 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 36 && BP.MajorAxisLength <= 41)) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 557 && BP.Area <= 636) && (BP.Solidity >= 0.35 && BP.Solidity <= 0.71 ) && ...
                (BP.Perimeter >= 142 && BP.Perimeter <= 156) && (BP.EquivDiameter >= 26 && BP.EquivDiameter <= 30) &&...
                (BP.MinorAxisLength >= 30.5 && BP.MinorAxisLength <= 35) && (BP.MajorAxisLength >= 32 && BP.MajorAxisLength <= 37)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 800 && BP.Area <= 980) && (BP.Solidity >= 0.79 && BP.Solidity <= 1) && ...
                (BP.Perimeter >= 105 && BP.Perimeter <= 125) && (BP.EquivDiameter >= 31 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 31.5 && BP.MinorAxisLength <= 36) && (BP.MajorAxisLength >= 32 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
       end

       if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            if size(stats,1) > 1
                cb = bwmorph(cb, 'erode');
                area = bwareaopen(cb,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end

    function convShape = redConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
    if ((CB.Area >= 951 && CB.Area <= 1250) && (CB.Solidity >= 0.79 && CB.Solidity <= 0.98 ) && ...
            (CB.Perimeter >= 108 && CB.Perimeter <= 190) && (CB.EquivDiameter >= 33 && CB.EquivDiameter <= 40) &&...
            (CB.MinorAxisLength >= 34 && CB.MinorAxisLength <= 40) && (CB.MajorAxisLength >= 34 && CB.MajorAxisLength <= 42)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32)
        convShape = 1;
    elseif ((CB.Area >= 698 && CB.Area <= 827.5) && (CB.Solidity >= 0.75 && CB.Solidity <= 0.97 ) && ...
            (CB.Perimeter >= 106 && CB.Perimeter <= 128) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 33) &&...
            (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 34)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4)
        convShape = 2;
    elseif ((CB.Area >= 257 && CB.Area <= 673) && (CB.Solidity >= 0.45 && CB.Solidity <= 0.96 ) && ...
            (CB.Perimeter >= 81 && CB.Perimeter <= 183) && (CB.EquivDiameter >= 16 && CB.EquivDiameter <= 30) &&...
            (CB.MinorAxisLength >= 17 && CB.MinorAxisLength <= 31) && (CB.MajorAxisLength >= 19 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41)
        convShape = 3;
    elseif ((CB.Area >= 758 && CB.Area <= 1323) && (CB.Solidity >= 0.63 && CB.Solidity <= 0.99 ) && ...
            (CB.Perimeter >= 125 && CB.Perimeter <= 307) && (CB.EquivDiameter >= 29 && CB.EquivDiameter <= 42) &&...
            (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 40) && (CB.MajorAxisLength >= 32 && CB.MajorAxisLength <= 53) &&...
            CB.Extent < 0.60) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3)
        convShape =  4;
    elseif ((CB.Area >= 480 && CB.Area <= 595) && (CB.Solidity >= 0.35 && CB.Solidity <= 0.81 ) && ...
            (CB.Perimeter >= 130 && CB.Perimeter <= 155) && (CB.EquivDiameter >= 23 && CB.EquivDiameter <= 29) &&...
            (CB.MinorAxisLength >= 29 && CB.MinorAxisLength <= 36) && (CB.MajorAxisLength >= 29 && CB.MajorAxisLength <= 40)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43)
        convShape = 5;
    elseif ((CB.Area >= 750 && CB.Area <= 870) && (CB.Solidity >= 0.88 && CB.Solidity <= 0.97) && ...
            (CB.Perimeter >= 100 && CB.Perimeter <= 133) && (CB.EquivDiameter >= 28 && CB.EquivDiameter <= 35) &&...
            (CB.MinorAxisLength >= 20 && CB.MinorAxisLength <= 34) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38)
        convShape = 6;
    else
        disp("No Shape Match");
        convShape = 7;
    end
    if (convShape == 2 || convShape == 6)
        cb = identifyConveyorBlocks(convBlock);
        cb = imfill(cb,'holes');
        cb = bwareaopen(cb,200);
        figure(5); imshow(cb);
        stats = regionprops(cb, 'Extrema');
        h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle1 = getAngleFromHorizontal(h1);

        stats = regionprops(shapes, 'Extrema');
        if size(stats,1) > 1
            %if more than one thing is detected
            shapes = bwmorph(shapes, 'erode');
            area = bwareaopen(shapes,200);
            stats = regionprops(area, 'Extrema');
            figure(5); imshow(shapes);
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        else
            figure(5); imshow(shapes);
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        end
        angle2 = getAngleFromHorizontal(h1);

        if abs(angle1-angle2) < 10
            %its a square
            convShape = 6;
        else
            convShape = 2;
        end
    end
    end
    function convShape = greenConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
    if ((CB.Area >= 866 && CB.Area <= 1178) && (CB.Solidity >= 0.87 && CB.Solidity <= 1 ) && ...
            (CB.Perimeter >= 104 && CB.Perimeter <= 130) && (CB.EquivDiameter >= 31 && CB.EquivDiameter <= 40) &&...
            (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 38) && (CB.MajorAxisLength >= 35 && CB.MajorAxisLength <= 41)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32)
        convShape = 1;
    elseif ((CB.Area >= 608 && CB.Area <= 1102) && (CB.Solidity >= 0.84 && CB.Solidity <= 0.97 ) && ...
            (CB.Perimeter >= 92 && CB.Perimeter <= 153) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 38) &&...
            (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 38) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 41)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4)
        convShape = 2;
    elseif ((CB.Area >= 323.5 && CB.Area <= 648) && (CB.Solidity >= 0.61 && CB.Solidity <= 0.78 ) && ...
            (CB.Perimeter >= 87 && CB.Perimeter <= 184) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 29) &&...
            (CB.MinorAxisLength >= 20 && CB.MinorAxisLength <= 30) && (CB.MajorAxisLength >= 20 && CB.MajorAxisLength <= 33)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41)
        convShape = 3;
    elseif ((CB.Area >= 716 && CB.Area <= 860) && (CB.Solidity >= 0.79 && CB.Solidity <= 0.85 ) && ...
            (CB.Perimeter >= 124 && CB.Perimeter <= 152) && (CB.EquivDiameter >= 28 && CB.EquivDiameter <= 34) &&...
            (CB.MinorAxisLength >= 32 && CB.MinorAxisLength <= 35) && (CB.MajorAxisLength >= 31 && CB.MajorAxisLength <= 39)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3)
        convShape =  4;
    elseif ((CB.Area >= 326 && CB.Area <= 676) && (CB.Solidity >= 0.51 && CB.Solidity <= 0.68) && ...
            (CB.Perimeter >= 112 && CB.Perimeter <= 187) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 30) &&...
            (CB.MinorAxisLength >= 23 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 24 && CB.MajorAxisLength <= 43)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43)
        convShape = 5;
    elseif ((CB.Area >= 628 && CB.Area <= 859) && (CB.Solidity >= 0.86 && CB.Solidity <= 0.99) && ...
            (CB.Perimeter >= 96 && CB.Perimeter <= 121) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 34) &&...
            (CB.MinorAxisLength >= 28 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 28 && CB.MajorAxisLength <= 37)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38)
        convShape = 6;
    else
        disp("No Shape Match");
        convShape = 7;
    end
    if (convShape == 2 || convShape == 6)
        cb = identifyConveyorBlocks(convBlock);
        cb = imfill(cb,'holes');
        cb = bwareaopen(cb,200);
        %         figure(5); imshow(cb);
        stats = regionprops(cb, 'Extrema');
        h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle1 = getAngleFromHorizontal(h1);

        stats = regionprops(shapes, 'Extrema');
        if size(stats,1) > 1
            %if more than one thing is detected
            shapes = bwmorph(shapes, 'erode');
            area = bwareaopen(shapes,200);
            stats = regionprops(area, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        else
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        end
        angle2 = getAngleFromHorizontal(h1);

        if abs(angle1-angle2) < 10
            %its a square
            convShape = 6;
        else
            convShape = 2;
        end
    end
    end
    function convShape = blueConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
    if ((CB.Area >= 800 && CB.Area <= 1055) && (CB.Solidity >= 0.92 && CB.Solidity <= 0.99 ) && ...
            (CB.Perimeter >= 111 && CB.Perimeter <= 126) && (CB.EquivDiameter >= 30 && CB.EquivDiameter <= 37) &&...
            (CB.MinorAxisLength >= 31 && CB.MinorAxisLength <= 37) && (CB.MajorAxisLength >= 31 && CB.MajorAxisLength <= 38) &&...
            (CB.Extent >= 0.70 && CB.Extent <= 0.79)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32)
        convShape = 1;
    elseif ((CB.Area >= 566 && CB.Area <= 880) && (CB.Solidity >= 0.84 && CB.Solidity <= 0.95 ) && ...
            (CB.Perimeter >= 99 && CB.Perimeter <= 142) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 34) &&...
            (CB.MinorAxisLength >= 25 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 35) && ...
            (CB.Extent >= 0.56 && CB.Extent <= 0.72)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4)
        convShape = 2;
    elseif ((CB.Area >= 314 && CB.Area <= 541) && (CB.Solidity >= 0.6 && CB.Solidity <= 0.82 ) && ...
            (CB.Perimeter >= 101 && CB.Perimeter <= 165) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 27) &&...
            (CB.MinorAxisLength >= 18 && CB.MinorAxisLength <= 28) && (CB.MajorAxisLength >= 20 && CB.MajorAxisLength <= 30)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41)
        convShape = 3;
    elseif ((CB.Area >= 505 && CB.Area <= 824) && (CB.Solidity >= 0.73 && CB.Solidity <= 0.86 ) && ...
            (CB.Perimeter >= 123 && CB.Perimeter <= 165) && (CB.EquivDiameter >= 23 && CB.EquivDiameter <= 33) &&...
            (CB.MinorAxisLength >= 28 && CB.MinorAxisLength <= 34) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3)
        convShape =  4;
    elseif ((CB.Area >= 328 && CB.Area <= 646) && (CB.Solidity >= 0.45 && CB.Solidity <= 0.67 ) && ...
            (CB.Perimeter >= 111 && CB.Perimeter <= 177) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 29) &&...
            (CB.MinorAxisLength >= 22 && CB.MinorAxisLength <= 34) && (CB.MajorAxisLength >= 23 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43)
        convShape = 5;
    elseif ((CB.Area >= 579 && CB.Area <= 807) && (CB.Solidity >= 0.9 && CB.Solidity <= 0.99) && ...
            (CB.Perimeter >= 98 && CB.Perimeter <= 114) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 34) &&...
            (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 34)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38)
        convShape = 6;
    else
        disp("No Shape Match");
        convShape = 7;
    end
    if (convShape == 2 || convShape == 6)
        cb = identifyConveyorBlocks(convBlock);
        cb = imfill(cb,'holes');
        cb = bwareaopen(cb,200);
        figure(5); imshow(cb);
        stats = regionprops(cb, 'Extrema');
        h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle1 = getAngleFromHorizontal(h1);

        stats = regionprops(shapes, 'Extrema');
        if size(stats,1) > 1
            %if more than one thing is detected
            shapes = bwmorph(shapes, 'erode');
            area = bwareaopen(shapes,200);
            figure(5); imshow(shapes);
            stats = regionprops(area, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        else
            figure(5); imshow(shapes);
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        end
        angle2 = getAngleFromHorizontal(h1);

        if abs(angle1-angle2) < 10
            %its a square
            convShape = 6;
        else
            convShape = 2;
        end
    end
    end
    function convShape = yellowConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
    if ((CB.Area >= 914 && CB.Area <= 985) && (CB.Solidity >= 0.93 && CB.Solidity <= 0.99 ) && ...
            (CB.Perimeter >= 106 && CB.Perimeter <= 122) && (CB.EquivDiameter >= 32 && CB.EquivDiameter <= 37) &&...
            (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 35) && (CB.MajorAxisLength >= 33 && CB.MajorAxisLength <= 37)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32)
        convShape = 1;
    elseif ((CB.Area >= 732 && CB.Area <= 743) && (CB.Solidity >= 0.9 && CB.Solidity <= 0.97 ) && ...
            (CB.Perimeter >= 102 && CB.Perimeter <= 111) && (CB.EquivDiameter >= 29 && CB.EquivDiameter <= 32) &&...
            (CB.MinorAxisLength >= 30 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4)
        convShape = 2;
    elseif ((CB.Area >= 342 && CB.Area <= 545) && (CB.Solidity >= 0.56 && CB.Solidity <= 0.781 ) && ...
            (CB.Perimeter >= 94 && CB.Perimeter <= 165) && (CB.EquivDiameter >= 19 && CB.EquivDiameter <= 27) &&...
            (CB.MinorAxisLength >= 19.98 && CB.MinorAxisLength <= 29) && (CB.MajorAxisLength >= 22.90 && CB.MajorAxisLength <= 32) &&...
            CB.Extent >= 0.40) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41)
        convShape = 3;
    elseif ((CB.Area >= 629 && CB.Area <= 825) && (CB.Solidity >= 0.71 && CB.Solidity <= 0.83 ) && ...
            (CB.Perimeter >= 127 && CB.Perimeter <= 155) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 33) &&...
            (CB.MinorAxisLength >= 29 && CB.MinorAxisLength <= 35) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41)
        convShape =  4;
    elseif ((CB.Area >= 340 && CB.Area <= 566) && (CB.Solidity >= 0.50 && CB.Solidity <= 0.67 ) && ...
            (CB.Perimeter >= 102 && CB.Perimeter <= 145) && (CB.EquivDiameter >= 20 && CB.EquivDiameter <= 27) &&...
            (CB.MinorAxisLength >= 24 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 35)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43)
        convShape = 5;
    elseif ((CB.Area >= 561 && CB.Area <= 795) && (CB.Solidity >= 0.89 && CB.Solidity <= 0.98) && ...
            (CB.Perimeter >= 98 && CB.Perimeter <= 114) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 33) &&...
            (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 34)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38)
        convShape = 6;
    else
        disp("No Shape Match");
        convShape = 7;
    end
    if (convShape == 2 || convShape == 6)
        cb = identifyConveyorBlocks(convBlock);
        cb = imfill(cb,'holes');
        cb = bwareaopen(cb,200);
        %         figure(5); imshow(cb);
        stats = regionprops(cb, 'Extrema');
        h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle1 = getAngleFromHorizontal(h1);

        stats = regionprops(shapes, 'Extrema');
        if size(stats,1) > 1
            %if more than one thing is detected
            shapes = bwmorph(shapes, 'erode');
            area = bwareaopen(shapes,200);
            stats = regionprops(area, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        else
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        end
        angle2 = getAngleFromHorizontal(h1);

        if abs(angle1-angle2) < 10
            %its a square
            convShape = 6;
        else
            convShape = 2;
        end
    end
    end

    function [matchedIndex,convOrientation] = matchWithConveyor(colourIndex,blockShape, ConvIndex, detectedConvBlocks, conveyor,cakeB)
        %colourIndex:
    %     red = 1
    %     green = 2
    %     blue = 3
    %     yellow = 4
        matchedIndex = 0;
        if detectedConvBlocks == 0
           k = length(ConvIndex) + 1; 
        end
        for i = k:length(ConvIndex)
            if (ConvIndex(i) ~= 255) %this is a removed point, not supposed to visit the spot that we already looked at
                convBlock = imcrop(conveyor, detectedConvBlocks(ConvIndex(i),:));
                if (colourIndex == 1)
        %           red
                    redConvBlock = conveyorRedBlocks(convBlock);
                    [Iarea, shapes] = filter(redConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', ...
                           'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    convShape = redConvShapeIdentifier(CB,convBlock,shapes);

                elseif (colourIndex == 2)
        %           green
                    greenConvBlock = conveyorGreenBlocks(convBlock);
                    [Iarea, shapes] = filter( greenConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', ...
                        'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    convShape = greenConvShapeIdentifier(CB,convBlock,shapes);
                elseif (colourIndex == 3)
        %           blue
                    blueConvBlock = conveyorBlueBlocks(convBlock);
                    [Iarea, shapes] = filter( blueConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', ...
                        'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    convShape = blueConvShapeIdentifier(CB,convBlock,shapes);

                elseif (colourIndex == 4)
        %           yellow
                    yellowConvBlock = conveyorYellowBlocks(convBlock);
                    [Iarea, shapes] = filter(yellowConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', ...
                        'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    convShape = yellowConvShapeIdentifier(CB,convBlock,shapes);

                end
                disp(convShape);
                if (blockShape == convShape)
                    matchedIndex = ConvIndex(i);
                    %match Found, obtains the orientation and prints the match
                    %for me to see
                    convBlock = imcrop(conveyor, [detectedConvBlocks(matchedIndex,1)-5,detectedConvBlocks(matchedIndex,2)-5 ...
                                        detectedConvBlocks(matchedIndex,3)+10, detectedConvBlocks(matchedIndex,4)+10]);
                    Decor.convOrientation = getConvOrientation(convBlock);
                    return;
                end
            end
        end

        if (matchedIndex == 0)
            matchedIndex = 155; %static variable
            Decor.convOrientation = 0;
            return;
        end
    end

    function angle = getCakeOrientation(block)
        IbwBlock = ~im2bw(block, graythresh(block));
        area = bwareaopen(IbwBlock,200);
        stats = regionprops(area, 'Extrema');
        h = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle = getAngleFromHorizontal(h);
    end
    function angle = getConvOrientation(block)
        [bw, mask] = identifyConveyorBlocks(block);
        [bw1,mask1] = convOrientationMask(block);
        BW = imfill(bw, 'holes');
        bbw = bwmorph(BW,'erode');
        area = bwareaopen(bbw,200);
    %     %shapes = bwmorph(shapes, 'erode');
    %     area = bwareaopen(shapes,200);
    %     IbwBlock = ~im2bw(block, graythresh(block));
        stats = regionprops(area, 'Extrema');
    %     figure(3); imshow(block); hold on;
    %     for i = 1:size(stats.Extrema,1)
    %        plot(stats.Extrema(i,1),stats.Extrema(i,2),'g+');
    %     end
        h = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle = getAngleFromHorizontal(h);
    end

    function [BW,maskedRGBImage] = convOrientationMask(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 21-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = RGB;

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 25.000;
    channel1Max = 255.000;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.000;
    channel2Max = 255.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.000;
    channel3Max = 255.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
end
function your_decoration_unit_test_function(~,~)

    global blockColourFlag;
    global cakeOrientation;
    global convOrientation;
    % blockOrder = [];
    cakeBlockUnmatchedIndex = [];
    blockOrderCounter = 1;
    blockHeight = 12 - 1; %-1 so that the vacumm can have a nice strong suck

    cake = imread('Pattern1.jpg');
    conveyor = imread('conveyor__08_14_21_35_41.jpg');
    %% Camera Calibration for Table
    %RGB = imread('C:\Users\someo\Documents\UNI\Yr4 Term2\MTRN4230\Individual Assignment\blank_image2.jpg');
    cp = load('cameraParams3');
    %undistortedImage = undistortImage(RGB, cameraParams3);
    %imshow(undistortedImage);

    IM1 = [798, 288];
    IM2 = [21, 288];
    IM3 = [1586, 296];
    IM4 = [793, 856];
    IM5 = [795.5,572]; %midpoint of IM1 and IM4
    imagePoints = [IM1; IM2; IM3; IM4; IM5];

    T1 = [175,0];
    T2 = [175,-520];
    T3 = [175,520];
    T4 = [548.6,0];
    T5 = [361.8,0]; %midpoint of T1 and T4
    worldPoints = [T1; T2; T3; T4; T5];

    [tableRotationMatrix,tableTranslationVector] = extrinsics(imagePoints,worldPoints,cp.cameraParams3);

    %% Camera Calibtration for Conveyor
    convParam = load('cameraParams_conveyor.mat');
    convImagePoints = load('convImagePoints.mat');
    convWorldPoints = load('convWorldPoints.mat');

    [convRotationMatrix, convTranslationVector] = extrinsics(convImagePoints.imagePoints, convWorldPoints.worldPoints, convParam.ConvCameraParams);

    %% detect the blocks on cake
    IbwCake = ~im2bw(cake, graythresh(cake));
    Ifill1 = imfill(IbwCake, 'holes');
    IfillCake = bwmorph(Ifill1, 'erode');
    IareaCake = bwareaopen(IfillCake,100);
    IfinalCake = bwlabel(IareaCake);
    figure(1);
    stat = regionprops(IfinalCake, 'boundingbox');
    imshow(cake); hold on;
    j = 1;
    for i = 1:size(stat,1)
       if (abs(diff([stat(i).BoundingBox(3) stat(i).BoundingBox(4)],1)) < 10) && ...
               (stat(i).BoundingBox(3) > 45)
           bb = stat(i).BoundingBox;
           detectedCakeBlocks(j,:) = stat(i).BoundingBox;
           detectedCakeBlocksCentres(j,:) = [bb(1)+bb(3)/2 bb(2)+bb(4)/2];
                                        %[stat(i).BoundingBox(1)+stat(i).BoundingBox(3)/2 ...
                                        %stat(i).BoundingBox(2)+stat(i).BoundingBox(4)/2]; 
           rectangle('position',bb,'edgecolor','g','linewidth',2);
           j = j + 1;
       end
    end
    for i = 1:size(detectedCakeBlocksCentres,1)
        plot(detectedCakeBlocksCentres(i,1),detectedCakeBlocksCentres(i,2),'r+');
    end
    title('Detecting Cake blocks');
    %% detecting blocks on the conveyor
    %conveyor = imcrop(conveyor,[557.5 0.5 588 703]);%,[568.5 0.5 578 678]);%,[418.5 3.5 574 428]);
    [BW,maskedRGBImage] = identifyConveyorBlocks(conveyor);
    Gconveyor = rgb2gray(conveyor);
    IbwConv = BW;
    % Ibw = ~im2bw(conveyor,0.1);%graythresh(conveyor));
    Ifill = imfill(IbwConv, 'holes');
    IfillConv = bwmorph(Ifill, 'erode');
    IareaConv = bwareaopen(Ifill,100);
    IfinalConv = bwlabel(IareaConv);
    % Gcake = rgb2gray(cake);
    % imshow(Ibw); 
    figure(2);
    stat = regionprops(IfinalConv, 'boundingbox');
    imshow(conveyor); hold on;
    j = 1;
    for i = 1:size(stat,1)
       if (abs(diff([stat(i).BoundingBox(3) stat(i).BoundingBox(4)],1)) < 10) && ...
               (stat(i).BoundingBox(3) > 40)
           bb = stat(i).BoundingBox;
           detectedConvBlocks(j,:) = stat(i).BoundingBox;
           detectedConvBlocksCentres(j,:) = [bb(1)+bb(3)/2 bb(2)+bb(4)/2];
                                        %[stat(i).BoundingBox(1)+stat(i).BoundingBox(3)/2 ...
                                        %stat(i).BoundingBox(2)+stat(i).BoundingBox(4)/2]; 
           rectangle('position',bb,'edgecolor','g','linewidth',2);
           j = j + 1;
       end
    end
    for i = 1:size(detectedConvBlocksCentres,1)
        plot(detectedConvBlocksCentres(i,1),detectedConvBlocksCentres(i,2),'r+');
    end
    title('Detecting Conveyor blocks');
    %%
    %Indexing all the blocks on the conveyor belt
    redConvBlockIndex = findRedConvBlock(conveyor,detectedConvBlocks);
    greenConvBlockIndex = findGreenConvBlock(conveyor,detectedConvBlocks);
    blueConvBlockIndex = findBlueConvBlock(conveyor,detectedConvBlocks);
    yellowConvBlockIndex = findYellowConvBlock(conveyor,detectedConvBlocks);

    for i = 1:size(detectedCakeBlocks,1)
        %cakeOrientation = 0;
        convOrientation = 0;
        %put the centres of the first cake block in the matricies
        cakeWorldCentres = pointsToWorld(cp.cameraParams3, tableRotationMatrix, tableTranslationVector, [detectedCakeBlocksCentres(i,1), detectedCakeBlocksCentres(i,2)]);
        blockOrder(Decor.blockOrderCounter,1) = cakeWorldCentres(1);
        blockOrder(Decor.blockOrderCounter,2) = cakeWorldCentres(2);
        blockOrder(Decor.blockOrderCounter,3) = 147 + blockHeight;

        % This is used for a image at the end of the file
        blockOrderMaintenance(Decor.blockOrderCounter,1) = detectedCakeBlocksCentres(i,1);
        blockOrderMaintenance(Decor.blockOrderCounter,2) = detectedCakeBlocksCentres(i,2);

        block = imcrop(cake, [detectedCakeBlocks(i,1)-5,detectedCakeBlocks(i,2)-5, detectedCakeBlocks(i,3)+10, detectedCakeBlocks(i,4)+10]);
        %     imwrite(block,'block2.jpg');
        [cakeOrientation,points] = getCakeOrientation(block);
        blockOrderMaintenance(Decor.blockOrderCounter,5) = points(1);
        blockOrderMaintenance(Decor.blockOrderCounter,6) = points(2);
        blockOrderMaintenance(Decor.blockOrderCounter,7) = points(3);
        blockOrderMaintenance(Decor.blockOrderCounter,8) = points(4);

        %checks if the cake block is red, green, blue or yellow
        redCheck = cakeRedBlocks(block);
        [Iarea,shapes] = filter(redCheck);
        check = regionprops(shapes, 'Area');
        idx = find([check.Area] > 220);
        if(idx > 0)
            %ITS A RED BLOCK
            blockColourFlag = 1;
        else
            greenCheck = cakeGreenBlocks(block);
            [Iarea,shapes] = filter(greenCheck);
            check = regionprops(shapes, 'Area');
            idx = find([check.Area] > 220);
            if (idx > 0)
                %ITS A GREEN BLOCK
                blockColourFlag = 2;
            else
                blueCheck = cakeBlueBlocks(block);
                [Iarea,shapes] = filter(blueCheck);
                check = regionprops(shapes, 'Area');
                idx = find([check.Area] > 220);
                if (idx > 0)
                    %ITS A BLUE BLOCK
                    blockColourFlag = 3;
                else
                    yellowCheck = cakeYellowBlocks(block);
                    [Iarea,shapes] = filter(yellowCheck);
                    check = regionprops(shapes, 'Area');
                    idx = find([check.Area] > 220);
                    if (idx > 0)
                        %ITS A YELLOW BLOCK
                        blockColourFlag = 4;
                    else
                        disp("This is not a real block: skipped");
                        blockColourFlag = 5;
                    end
                end
            end
        end

        if (blockColourFlag == 1)
            disp("red");
            redCakeShape = findRedCakeBlockShape(blockOrder,block,blockColourFlag);
    %         sprintf('redCakeShape: %d\n', redCakeShape)
            [matchedIndex,convOrientation,points] = matchWithConveyor(blockColourFlag,redCakeShape, redConvBlockIndex, ...
                                                            detectedConvBlocks, conveyor,block,blockOrderMaintenance,Decor.blockOrderCounter);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + blockHeight;

                % for the image at the end
                blockOrderMaintenance(Decor.blockOrderCounter,3) = detectedConvBlocksCentres(matchedIndex,1);
                blockOrderMaintenance(Decor.blockOrderCounter,4) = detectedConvBlocksCentres(matchedIndex,2);
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                disp("No Blocks Matched");
                cakeBlockUnmatchedIndex(1,:) = i;
            end
        elseif (blockColourFlag == 2)
            disp("green");
            greenCakeShape = findGreenCakeBlockShape(blockOrder,block,blockColourFlag);
            [matchedIndex,convOrientation,points] = matchWithConveyor(blockColourFlag,greenCakeShape, greenConvBlockIndex, ...
                                                detectedConvBlocks, conveyor,block,blockOrderMaintenance,Decor.blockOrderCounter);
            %155 is a value that i set for no index of the conveyor mataching
            %with 
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + blockHeight;

                blockOrderMaintenance(Decor.blockOrderCounter,3) = detectedConvBlocksCentres(matchedIndex,1);
                blockOrderMaintenance(Decor.blockOrderCounter,4) = detectedConvBlocksCentres(matchedIndex,2);

                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                disp("No Blocks Matched");
                cakeBlockUnmatchedIndex(1,:) = i;
            end
        elseif (blockColourFlag == 3)
            disp("blue");
            blueCakeShape = findBlueCakeBlockShape(blockOrder,block,blockColourFlag);
            [matchedIndex,convOrientation,points] = matchWithConveyor(blockColourFlag,blueCakeShape, blueConvBlockIndex, ...
                                                    detectedConvBlocks, conveyor,block,blockOrderMaintenance,Decor.blockOrderCounter);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + blockHeight;


                blockOrderMaintenance(Decor.blockOrderCounter,3) = detectedConvBlocksCentres(matchedIndex,1);
                blockOrderMaintenance(Decor.blockOrderCounter,4) = detectedConvBlocksCentres(matchedIndex,2);
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                disp("No Blocks Matched");
                cakeBlockUnmatchedIndex(1,:) = i;
            end
        elseif (blockColourFlag == 4)
            disp("yellow");
            yellowCakeShape = findYellowCakeBlockShape(blockOrder,block,blockColourFlag);
    %         sprintf('yellowCakeShape: %d\n', yellowCakeShape)
            [matchedIndex,convOrientation,points] = matchWithConveyor(blockColourFlag,yellowCakeShape, yellowConvBlockIndex, ...
                                                    detectedConvBlocks, conveyor,block,blockOrderMaintenance,Decor.blockOrderCounter);
            if matchedIndex ~= 155
                convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, [detectedConvBlocksCentres(matchedIndex,1) detectedConvBlocksCentres(matchedIndex,2)]);
                blockOrder(Decor.blockOrderCounter,4) = convWorldCentres(1);
                blockOrder(Decor.blockOrderCounter,5) = convWorldCentres(2);
                blockOrder(Decor.blockOrderCounter,6) = 22.1 + blockHeight;


                blockOrderMaintenance(Decor.blockOrderCounter,3) = detectedConvBlocksCentres(matchedIndex,1);
                blockOrderMaintenance(Decor.blockOrderCounter,4) = detectedConvBlocksCentres(matchedIndex,2);
                %sets the found block on conveyor to a really large value to not
                %consider it anyomore, matchWithConveyor does not consider 255
                idx = find(redConvBlockIndex == matchedIndex);
                redConvBlockIndex(idx) = 255;
                detectedConvBlocksCentres(matchedIndex,:) = -100;
            else
                disp("No Blocks Matched");
                cakeBlockUnmatchedIndex(1,:) = i;
            end
        elseif (blockColourFlag == 5)
            disp("SKIP DIS SHIT");
        end

        %calculates the difference in angles and that puts it in the matrix
        %CW = positve
        %CCW = negative
        if matchedIndex ~= 155
            blockOrder(Decor.blockOrderCounter,7) = cakeOrientation - convOrientation;
        elseif matchedIndex == 155
            blockOrder(Decor.blockOrderCounter,7) = 0;
        end
        blockOrderMaintenance(Decor.blockOrderCounter,9) = points(1);
        blockOrderMaintenance(Decor.blockOrderCounter,10) = points(2);
        blockOrderMaintenance(Decor.blockOrderCounter,11) = points(3);
        blockOrderMaintenance(Decor.blockOrderCounter,12) = points(4);
        % increments the variable that cycles throught the orderBlocks matrix
        Decor.blockOrderCounter = Decor.blockOrderCounter + 1;
    end
    j = 1;
    for i = 1:size(detectedConvBlocksCentres,1)
        if (detectedConvBlocksCentres(i,1) ~= -100)
            convWorldCentres = pointsToWorld(convParam.ConvCameraParams, convRotationMatrix, convTranslationVector, [detectedConvBlocksCentres(i,1) detectedConvBlocksCentres(i,2)]);
            leftOverBlocks(j,1) = convWorldCentres(1);
            leftOverBlocks(j,2) = convWorldCentres(2);
            leftOverBlocks(j,3) = 22.1 + blockHeight;
            j=j+1;
        end
    end
    %% lets print on seperate figures for now
    figure(5); axis;
    subplot(1,2,1);
    imshow(cake); hold on;
    % for i = 1:size(detectedCakeBlocks,1)
    %     bb = detectedCakeBlocks(i,:);
    %     rectangle('position',bb,'edgecolor','g','linewidth',2);
    % end
    for i = 1:size(blockOrder,1)
        if (blockOrderMaintenance(i,3) ~= 0)
            plot(blockOrderMaintenance(i,1),blockOrderMaintenance(i,2),'g+','linewidth',2);
            xShift = blockOrderMaintenance(i,5) - blockOrderMaintenance(i,7);
            yShift = blockOrderMaintenance(i,6) - blockOrderMaintenance(i,8);
            p1 = [blockOrderMaintenance(i,1),blockOrderMaintenance(i,2)];
            p2 = [blockOrderMaintenance(i,1) - 1.5*xShift, blockOrderMaintenance(i,2) - 1.5*yShift];
            D = p1 - p2;
            q = quiver( p1(1), p1(2), D(1), D(2), 0,'linewidth', 2);
            q.Color = 'red'; q.ShowArrowHead = 'on';
            text(p1(1),p1(2)-20, sprintf('Block %d',i),'Color','red')
        end
    end

%     figure(6); axis;
    subplot(1,2,2);
    imshow(conveyor); hold on;
    for i = 1:size(blockOrderMaintenance,1)
        if (blockOrderMaintenance(i,3) ~= 0)
            plot(blockOrderMaintenance(i,3),blockOrderMaintenance(i,4),'g+','linewidth',2);
            xShift = blockOrderMaintenance(i,9) - blockOrderMaintenance(i,11);
            yShift = blockOrderMaintenance(i,10) - blockOrderMaintenance(i,12);
            p1 = [blockOrderMaintenance(i,3),blockOrderMaintenance(i,4)];
            p2 = [blockOrderMaintenance(i,3) - 1.5*xShift, blockOrderMaintenance(i,4) - 1.5*yShift];
            D = p1 - p2;
            q = quiver( p1(1), p1(2), D(1), D(2), 0,'linewidth', 2);
            q.Color = 'red'; q.ShowArrowHead = 'on';
            text(p1(1),p1(2)-20, sprintf('Block %d',i),'Color','red')
        end
    end
    %% write a function that loops until the UnmatchedIndex is complex
    %% e.g. for int i=size(cakeBlockUnmatchedIndex,2)
    %%
    function cakeShape = findRedCakeBlockShape(blockOrder,block,blockColourFlag)
        redCakeBlocks = cakeRedBlocks(block);
        [Iarea,shapes] = filter(redCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        %figure(4); imshowpair(block,shapes,'montage');
        cakeShape = redCakeShapeIdentifier(BP,block,shapes);
        disp(cakeShape);
    end
    function cakeShape = findGreenCakeBlockShape(blockOrder,block,blockColourFlag)
        greenCakeBlocks = cakeGreenBlocks(block);
        [Iarea,shapes] = filter(greenCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        %figure(4); imshowpair(block,shapes,'montage');
        cakeShape = greenCakeShapeIdentifier(BP,block,shapes);
        disp(cakeShape);
    end
    function cakeShape = findBlueCakeBlockShape(blockOrder,block,blockColourFlag)
        blueCakeBlocks = cakeBlueBlocks(block);
        [Iarea,shapes] = filter(blueCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        %figure(4); imshowpair(block,shapes,'montage');
        cakeShape = blueCakeShapeIdentifier(BP,block,shapes);
        disp(cakeShape);
    end
    function cakeShape = findYellowCakeBlockShape(blockOrder,block,blockColourFlag)
        yellowCakeBlocks = cakeYellowBlocks(block);
        [Iarea,shapes] = filter(yellowCakeBlocks);
        BP = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity','Extent'});
        idx = find([BP.Area] > 220);
        BP = BP(idx);
        %figure(4); imshowpair(block,shapes,'montage');
        cakeShape = yellowCakeShapeIdentifier(BP,block,shapes);
        disp(cakeShape);
    end

    function redConvBlockIndex = findRedConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorRedBlocks(convBlock);
             redStats = regionprops(b, 'Area');
             if size(redStats,1) > 0
                 idx = find([redStats.Area] > 250);
                 if (idx ~= 0)
                     redConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(redBlockIndex);
    end
    function greenConvBlockIndex = findGreenConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorGreenBlocks(convBlock);
             greenStats = regionprops(b, 'Area');
             if size(greenStats,1) > 0
                 idx = find([greenStats.Area] > 250);
                 if (idx ~= 0)
                     greenConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(greenConvBlockIndex);
    end
    function blueConvBlockIndex = findBlueConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorBlueBlocks(convBlock);
             blueStats = regionprops(b, 'Area');
             if size(blueStats,1) > 0
                 idx = find([blueStats.Area] > 250);
                 if (idx ~= 0)
                     blueConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(blueConvBlockIndex);
    end
    function yellowConvBlockIndex = findYellowConvBlock(conveyor,detectedConvBlocks)
        j = 1;
        k = 4;
        for i = 1:size(detectedConvBlocks,1)
             convBlock = imcrop(conveyor, detectedConvBlocks(i,:));
             %figure(k); imshow(convBlock);
             [b,bb] = conveyorYellowBlocks(convBlock);
             yellowStats = regionprops(b, 'Area');
             if size(yellowStats,1) > 0
                 idx = find([yellowStats.Area] > 250);
                 if (idx ~= 0)
                     yellowConvBlockIndex(j) = i;
    %                  figure(k); imshowpair(convBlock,b,'montage');
                     j = j + 1;
                     k = k + 1;
                 end
             end
        end
        %disp(yellowConvBlockIndex);
    end

    function [area,shapes] = filter(BW)
        shapes = imfill(BW, 'holes');
    %     shapes = bwmorph(shapes, 'erode');
        area = bwareaopen(shapes,200);
    end

    function [BW,maskedRGBImage] = identifyConveyorBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 21-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2ycbcr(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 37.000;
    channel1Max = 73.000;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 111.000;
    channel2Max = 128.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 134.000;
    channel3Max = 152.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Invert mask
    BW = ~BW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorRedBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.906;
    channel1Max = 0.027;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.263;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.293;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
    function [BW,maskedRGBImage] = cakeRedBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.927;
    channel1Max = 0.053;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.137;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.487;
    channel3Max = 0.809;

    % Create mask based on chosen histogram thresholds
    sliderBW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorGreenBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.231;
    channel1Max = 0.493;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.285;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.184;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
    function [BW,maskedRGBImage] = cakeGreenBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.179;
    channel1Max = 0.521;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.047;
    channel2Max = 0.927;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.317;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorBlueBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.517;
    channel1Max = 0.692;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.398;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.258;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
    function [BW,maskedRGBImage] = cakeBlueBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.524;
    channel1Max = 0.685;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.151;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.452;
    channel3Max = 0.894;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function [BW,maskedRGBImage] = conveyorYellowBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.136;
    channel1Max = 0.194;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.167;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.476;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
    function [BW,maskedRGBImage] = cakeYellowBlocks(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 20-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = rgb2hsv(RGB);

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 0.106;
    channel1Max = 0.246;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.159;
    channel2Max = 1.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.550;
    channel3Max = 1.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end

    function cakeShape = redCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1096 && BP.Area <= 1276) && (BP.Solidity >= 0.93 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 128 && BP.Perimeter <= 144) && (BP.EquivDiameter >= 35 && BP.EquivDiameter <= 42) &&...
                (BP.MinorAxisLength >= 35 && BP.MinorAxisLength <= 41)&&(BP.MajorAxisLength >= 37 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 924 && BP.Area <= 999) && (BP.Solidity >= 0.83 && BP.Solidity <= 0.95 ) && ...
                (BP.Perimeter >= 124 && BP.Perimeter <= 164) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 37) && (BP.MajorAxisLength >= 34 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 420 && BP.Area <= 773) && (BP.Solidity >= 0.57 && BP.Solidity <= 0.82 ) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 173) && (BP.EquivDiameter >= 22 && BP.EquivDiameter <= 30) &&...
                (BP.MinorAxisLength >= 21 && BP.MinorAxisLength <= 33) && (BP.MajorAxisLength >= 25 && BP.MajorAxisLength <= 35))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 545 && BP.Area <= 1136) && (BP.Solidity >= 0.50 && BP.Solidity <= 0.83 ) && ...
                (BP.Perimeter >= 170 && BP.Perimeter <= 246) && (BP.EquivDiameter >= 25 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 27 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 28 && BP.MajorAxisLength <= 41)) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 454 && BP.Area <= 919) && (BP.Solidity >= 0.47 && BP.Solidity <= 0.58 ) && ...
                (BP.Perimeter >= 151 && BP.Perimeter <= 218) && (BP.EquivDiameter >= 23 && BP.EquivDiameter <= 35.5) &&...
                (BP.MinorAxisLength >= 26 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 30 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 839 && BP.Area <= 902) && (BP.Solidity >= 0.88 && BP.Solidity <= 0.94) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 150) && (BP.EquivDiameter >= 31 && BP.EquivDiameter <= 35) &&...
                (BP.MinorAxisLength >= 30 && BP.MinorAxisLength <= 33) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 36.5)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end
    function cakeShape = greenCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1237 && BP.Area <= 1548) && (BP.Solidity >= 0.9 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 131 && BP.Perimeter <= 161) && (BP.EquivDiameter >= 37 && BP.EquivDiameter <= 43) &&...
                (BP.MinorAxisLength >= 37 && BP.MinorAxisLength <= 45)&&(BP.MajorAxisLength >= 37 && BP.MajorAxisLength <= 46)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 819 && BP.Area <= 1028) && (BP.Solidity >= 0.83 && BP.Solidity <= 0.93 ) && ...
                (BP.Perimeter >= 130 && BP.Perimeter <= 143) && (BP.EquivDiameter >= 31 && BP.EquivDiameter <= 38) &&...
                (BP.MinorAxisLength >= 32 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 32 && BP.MajorAxisLength <= 40)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 420 && BP.Area <= 773) && (BP.Solidity >= 0.57 && BP.Solidity <= 0.82 ) && ...
                (BP.Perimeter >= 110 && BP.Perimeter <= 154) && (BP.EquivDiameter >= 22 && BP.EquivDiameter <= 32) &&...
                (BP.MinorAxisLength >= 21 && BP.MinorAxisLength <= 33) && (BP.MajorAxisLength >= 25 && BP.MajorAxisLength <= 35))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 778 && BP.Area <= 1176) && (BP.Solidity >= 0.70 && BP.Solidity <= 0.87 ) && ...
                (BP.Perimeter >= 139 && BP.Perimeter <= 200) && (BP.EquivDiameter >= 30 && BP.EquivDiameter <= 40) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 41) && (BP.MajorAxisLength >= 35 && BP.MajorAxisLength <= 43)) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 402 && BP.Area <= 1024) && (BP.Solidity >= 0.54 && BP.Solidity <= 0.7 ) && ...
                (BP.Perimeter >= 108 && BP.Perimeter <= 222) && (BP.EquivDiameter >= 21 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 23 && BP.MinorAxisLength <= 43) && (BP.MajorAxisLength >= 27 && BP.MajorAxisLength <= 47)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 768 && BP.Area <= 1168) && (BP.Solidity >= 0.85 && BP.Solidity <= 0.96) && ...
                (BP.Perimeter >= 112 && BP.Perimeter <= 151) && (BP.EquivDiameter >= 30 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 30 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 31 && BP.MajorAxisLength <= 41)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end
    function cakeShape = blueCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((BP.Area >= 1334 && BP.Area <= 1450) && (BP.Solidity >= 0.90 && BP.Solidity <= 0.98 ) && ...
                (BP.Perimeter >= 150 && BP.Perimeter <= 175) && (BP.EquivDiameter >= 40 && BP.EquivDiameter <= 44) &&...
                (BP.MinorAxisLength >= 39 && BP.MinorAxisLength <= 44)&&(BP.MajorAxisLength >= 40 && BP.MajorAxisLength <= 44)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 932 && BP.Area <= 1108) && (BP.Solidity >= 0.91 && BP.Solidity <= 0.97 ) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 136) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 39) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 38) && (BP.MajorAxisLength >= 34 && BP.MajorAxisLength <= 40)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 647 && BP.Area <= 888) && (BP.Solidity >= 0.58 && BP.Solidity <= 0.70 ) && ...
                (BP.Perimeter >= 165 && BP.Perimeter <= 230) && (BP.EquivDiameter >= 27 && BP.EquivDiameter <= 34) &&...
                (BP.MinorAxisLength >= 28 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 42))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 948 && BP.Area <= 1221) && (BP.Solidity >= 0.78 && BP.Solidity <= 0.86 ) && ...
                (BP.Perimeter >= 154 && BP.Perimeter <= 199) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 40) &&...
                (BP.MinorAxisLength >= 36 && BP.MinorAxisLength <= 42) && (BP.MajorAxisLength >= 36 && BP.MajorAxisLength <= 43)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape =  4;
        elseif ((BP.Area >= 710 && BP.Area <= 968) && (BP.Solidity >= 0.28 && BP.Solidity <= 0.66 ) && ...
                (BP.Perimeter >= 179 && BP.Perimeter <= 210) && (BP.EquivDiameter >= 29 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 36 && BP.MinorAxisLength <= 40) && (BP.MajorAxisLength >= 36 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 955 && BP.Area <= 1079) && (BP.Solidity >= 0.85 && BP.Solidity <= 0.98) && ...
                (BP.Perimeter >= 120 && BP.Perimeter <= 170) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 38) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 35 && BP.MajorAxisLength <= 39)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
        end

        if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end
    end
    function cakeShape = yellowCakeShapeIdentifier(BP,block,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
       if ((BP.Area >= 1223 && BP.Area <= 1274) && (BP.Solidity >= 0.82 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 122 && BP.Perimeter <= 128) && (BP.EquivDiameter >= 38 && BP.EquivDiameter <= 42) &&...
                (BP.MinorAxisLength >= 39 && BP.MinorAxisLength <= 40)&&(BP.MajorAxisLength >= 38 && BP.MajorAxisLength <= 42)) %(BP.Eccentricity >= 0.17 && BP.Eccentricity <= 0.42) 
                cakeShape = 1;
        elseif((BP.Area >= 935 && BP.Area <= 976) && (BP.Solidity >= 0.79 && BP.Solidity <= 1 ) && ...
                (BP.Perimeter >= 115 && BP.Perimeter <= 125) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 36) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.10 && BP.Eccentricity <= 0.38)
            cakeShape = 2;
        elseif ((BP.Area >= 567 && BP.Area <= 615) && (BP.Solidity >= 0.42 && BP.Solidity <= 0.76 ) && ...
                (BP.Perimeter >= 163 && BP.Perimeter <= 181) && (BP.EquivDiameter >= 25 && BP.EquivDiameter <= 30) &&...
                (BP.MinorAxisLength >= 29 && BP.MinorAxisLength <= 31) && (BP.MajorAxisLength >= 28 && BP.MajorAxisLength <= 32))%(BP.Eccentricity >= 0.25 && BP.Eccentricity <= 0.57)
            cakeShape = 3;
        elseif ((BP.Area >= 956.5 && BP.Area <= 1001) && (BP.Solidity >= 0.63 && BP.Solidity <= 0.96 ) && ...
                (BP.Perimeter >= 152 && BP.Perimeter <= 162) && (BP.EquivDiameter >= 33 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 37 && BP.MinorAxisLength <= 39) && (BP.MajorAxisLength >= 36 && BP.MajorAxisLength <= 41)) %(BP.Eccentricity >= 0.28 && BP.Eccentricity <= 0.37)
            cakeShape =  4;
        elseif ((BP.Area >= 621 && BP.Area <= 636) && (BP.Solidity >= 0.35 && BP.Solidity <= 0.71 ) && ...
                (BP.Perimeter >= 146 && BP.Perimeter <= 156) && (BP.EquivDiameter >= 26 && BP.EquivDiameter <= 30) &&...
                (BP.MinorAxisLength >= 33 && BP.MinorAxisLength <= 35) && (BP.MajorAxisLength >= 32 && BP.MajorAxisLength <= 37)) %(BP.Eccentricity >= 0.38 && BP.Eccentricity <= 0.55)
            cakeShape = 5;
        elseif ((BP.Area >= 926 && BP.Area <= 980) && (BP.Solidity >= 0.79 && BP.Solidity <= 1) && ...
                (BP.Perimeter >= 114 && BP.Perimeter <= 125) && (BP.EquivDiameter >= 32 && BP.EquivDiameter <= 37) &&...
                (BP.MinorAxisLength >= 34 && BP.MinorAxisLength <= 36) && (BP.MajorAxisLength >= 33 && BP.MajorAxisLength <= 38)) %(BP.Eccentricity >= 0.24 && BP.Eccentricity <= 0.44)
            cakeShape = 6;
        else
            disp("Shape Was Not Identified");
            cakeShape = 7;
       end

       if (cakeShape == 2 || cakeShape == 6)
            cb = ~im2bw(block, graythresh(block));
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h2 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h2);
            % checks the angle between the edge of a block and the edge of a
            % shape
            if abs(angle1-angle2) < 10
                %its a square
                cakeShape = 6;
            else
                cakeShape = 2;
            end
        end

    end

    function convShape = redConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((CB.Area >= 951 && CB.Area <= 1079) && (CB.Solidity >= 0.79 && CB.Solidity <= 0.97 ) && ...
                (CB.Perimeter >= 108 && CB.Perimeter <= 131) && (CB.EquivDiameter >= 33 && CB.EquivDiameter <= 38) &&...
                (CB.MinorAxisLength >= 34 && CB.MinorAxisLength <= 37) && (CB.MajorAxisLength >= 34 && CB.MajorAxisLength <= 39)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32) 
            convShape = 1;
        elseif ((CB.Area >= 698 && CB.Area <= 827.5) && (CB.Solidity >= 0.75 && CB.Solidity <= 0.97 ) && ...
                (CB.Perimeter >= 106 && CB.Perimeter <= 128) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 31) &&...
                (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 31) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 33)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4) 
            convShape = 2;
        elseif ((CB.Area >= 257 && CB.Area <= 618) && (CB.Solidity >= 0.45 && CB.Solidity <= 0.96 ) && ...
                (CB.Perimeter >= 81 && CB.Perimeter <= 175) && (CB.EquivDiameter >= 16 && CB.EquivDiameter <= 29) &&...
                (CB.MinorAxisLength >= 17 && CB.MinorAxisLength <= 29) && (CB.MajorAxisLength >= 19 && CB.MajorAxisLength <= 31)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41) 
            convShape = 3;
        elseif ((CB.Area >= 758 && CB.Area <= 947) && (CB.Solidity >= 0.63 && CB.Solidity <= 0.99 ) && ...
                (CB.Perimeter >= 135 && CB.Perimeter <= 177) && (CB.EquivDiameter >= 29 && CB.EquivDiameter <= 36) &&...
                (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 36) && (CB.MajorAxisLength >= 32 && CB.MajorAxisLength <= 38)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3) 
            convShape =  4;
        elseif ((CB.Area >= 480 && CB.Area <= 595) && (CB.Solidity >= 0.35 && CB.Solidity <= 0.81 ) && ...
                (CB.Perimeter >= 130 && CB.Perimeter <= 155) && (CB.EquivDiameter >= 23 && CB.EquivDiameter <= 29) &&...
                (CB.MinorAxisLength >= 29 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 29 && CB.MajorAxisLength <= 35)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43) 
            convShape = 5;
        elseif ((CB.Area >= 750 && CB.Area <= 816) && (CB.Solidity >= 0.9 && CB.Solidity <= 0.97) && ...
                (CB.Perimeter >= 100 && CB.Perimeter <= 114) && (CB.EquivDiameter >= 28 && CB.EquivDiameter <= 35) &&...
                (CB.MinorAxisLength >= 20 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38) 
            convShape = 6;
        else
            disp("No Shape Match");
            convShape = 7;
        end

        if (convShape == 2 || convShape == 6)
            cb = identifyConveyorBlocks(convBlock);
            cb = imfill(cb,'holes');
            cb = bwareaopen(cb,200);
    %         figure(5); imshow(cb);
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h1);

            if abs(angle1-angle2) < 10
                %its a square
                convShape = 6;
            else
                convShape = 2;
            end
        end
    end
    function convShape = greenConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((CB.Area >= 866 && CB.Area <= 1178) && (CB.Solidity >= 0.87 && CB.Solidity <= 1 ) && ...
                (CB.Perimeter >= 104 && CB.Perimeter <= 144) && (CB.EquivDiameter >= 31 && CB.EquivDiameter <= 40) &&...
                (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 38) && (CB.MajorAxisLength >= 36 && CB.MajorAxisLength <= 41)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32) 
            convShape = 1;
        elseif ((CB.Area >= 608 && CB.Area <= 1102) && (CB.Solidity >= 0.84 && CB.Solidity <= 0.97 ) && ...
                (CB.Perimeter >= 92 && CB.Perimeter <= 153) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 38) &&...
                (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 38) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 41)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4) 
            convShape = 2;
        elseif ((CB.Area >= 323.5 && CB.Area <= 570.5) && (CB.Solidity >= 0.61 && CB.Solidity <= 0.78 ) && ...
                (CB.Perimeter >= 87 && CB.Perimeter <= 146) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 28) &&...
                (CB.MinorAxisLength >= 20 && CB.MinorAxisLength <= 27) && (CB.MajorAxisLength >= 20 && CB.MajorAxisLength <= 31)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41) 
            convShape = 3;
        elseif ((CB.Area >= 716 && CB.Area <= 866) && (CB.Solidity >= 0.79 && CB.Solidity <= 0.83 ) && ...
                (CB.Perimeter >= 124 && CB.Perimeter <= 152) && (CB.EquivDiameter >= 28 && CB.EquivDiameter <= 34) &&...
                (CB.MinorAxisLength >= 32 && CB.MinorAxisLength <= 35) && (CB.MajorAxisLength >= 31 && CB.MajorAxisLength <= 39)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3) 
            convShape =  4;
        elseif ((CB.Area >= 320 && CB.Area <= 676) && (CB.Solidity >= 0.51 && CB.Solidity <= 0.71 ) && ...
                (CB.Perimeter >= 110 && CB.Perimeter <= 187) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 30) &&...
                (CB.MinorAxisLength >= 21 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 23 && CB.MajorAxisLength <= 43)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43) 
            convShape = 5;
        elseif ((CB.Area >= 628 && CB.Area <= 859) && (CB.Solidity >= 0.86 && CB.Solidity <= 0.99) && ...
                (CB.Perimeter >= 96 && CB.Perimeter <= 121) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 34) &&...
                (CB.MinorAxisLength >= 28 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 28 && CB.MajorAxisLength <= 37)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38) 
            convShape = 6;
        else
            disp("No Shape Match");
            convShape = 7;
        end

        if (convShape == 2 || convShape == 6)
            cb = identifyConveyorBlocks(convBlock);
            cb = imfill(cb,'holes');
            cb = bwareaopen(cb,200);
    %         figure(5); imshow(cb);
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h1);

            if abs(angle1-angle2) < 10
                %its a square
                convShape = 6;
            else
                convShape = 2;
            end
        end

    end
    function convShape = blueConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((CB.Area >= 800 && CB.Area <= 1011) && (CB.Solidity >= 0.92 && CB.Solidity <= 0.99 ) && ...
                (CB.Perimeter >= 111 && CB.Perimeter <= 126) && (CB.EquivDiameter >= 30 && CB.EquivDiameter <= 37) &&...
                (CB.MinorAxisLength >= 31 && CB.MinorAxisLength <= 34) && (CB.MajorAxisLength >= 31 && CB.MajorAxisLength <= 38) &&...
                (CB.Extent >= 0.70 && CB.Extent <= 0.79)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32) 
            convShape = 1;
        elseif ((CB.Area >= 566 && CB.Area <= 880) && (CB.Solidity >= 0.81 && CB.Solidity <= 0.95 ) && ...
                (CB.Perimeter >= 99 && CB.Perimeter <= 145) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 34) &&...
                (CB.MinorAxisLength >= 25 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 35) && ...
                (CB.Extent >= 0.56 && CB.Extent <= 0.72)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4) 
            convShape = 2;
        elseif ((CB.Area >= 314 && CB.Area <= 595) && (CB.Solidity >= 0.6 && CB.Solidity <= 0.82 ) && ...
                (CB.Perimeter >= 101 && CB.Perimeter <= 165) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 28) &&...
                (CB.MinorAxisLength >= 18 && CB.MinorAxisLength <= 28.5) && (CB.MajorAxisLength >= 20 && CB.MajorAxisLength <= 30)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41) 
            convShape = 3;
        elseif ((CB.Area >= 505 && CB.Area <= 1008) && (CB.Solidity >= 0.73 && CB.Solidity <= 0.87 ) && ...
                (CB.Perimeter >= 123 && CB.Perimeter <= 155) && (CB.EquivDiameter >= 23 && CB.EquivDiameter <= 36) &&...
                (CB.MinorAxisLength >= 28 && CB.MinorAxisLength <= 36.5) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 38)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.3) 
            convShape =  4;
        elseif ((CB.Area >= 328 && CB.Area <= 612) && (CB.Solidity >= 0.45 && CB.Solidity <= 0.68 ) && ...
                (CB.Perimeter >= 111 && CB.Perimeter <= 151) && (CB.EquivDiameter >= 18 && CB.EquivDiameter <= 28) &&...
                (CB.MinorAxisLength >= 22 && CB.MinorAxisLength <= 31) && (CB.MajorAxisLength >= 23 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43) 
            convShape = 5;
        elseif ((CB.Area >= 579 && CB.Area <= 762) && (CB.Solidity >= 0.9 && CB.Solidity <= 0.98) && ...
                (CB.Perimeter >= 98 && CB.Perimeter <= 114) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 32) &&...
                (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 27 && CB.MajorAxisLength <= 33)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38) 
            convShape = 6;
        else
            disp("No Shape Match");
            convShape = 7;
        end

        if (convShape == 2 || convShape == 6)
            cb = identifyConveyorBlocks(convBlock);
            cb = imfill(cb,'holes');
            cb = bwareaopen(cb,200);
    %         figure(5); imshow(cb);
            stats = regionprops(cb, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                area = bwareaopen(shapes,200);
                stats = regionprops(area, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h1);

            if abs(angle1-angle2) < 10
                %its a square
                convShape = 6;
            else
                convShape = 2;
            end
        end
    end
    function convShape = yellowConvShapeIdentifier(CB,convBlock,shapes)
    %     Circle = 1
    %     Diamond = 2
    %     Star = 3
    %     Clover = 4
    %     Shuriken = 5
    %     Square = 6
        if ((CB.Area >= 914 && CB.Area <= 985) && (CB.Solidity >= 0.93 && CB.Solidity <= 0.99 ) && ...
                (CB.Perimeter >= 107 && CB.Perimeter <= 122) && (CB.EquivDiameter >= 32 && CB.EquivDiameter <= 37) &&...
                (CB.MinorAxisLength >= 33 && CB.MinorAxisLength <= 35) && (CB.MajorAxisLength >= 33 && CB.MajorAxisLength <= 37)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.32) 
            convShape = 1;
        elseif ((CB.Area >= 732 && CB.Area <= 743) && (CB.Solidity >= 0.9 && CB.Solidity <= 0.97 ) && ...
                (CB.Perimeter >= 102 && CB.Perimeter <= 111) && (CB.EquivDiameter >= 29 && CB.EquivDiameter <= 32) &&...
                (CB.MinorAxisLength >= 30 && CB.MinorAxisLength <= 32) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.09 && CB.Eccentricity <= 0.4) 
            convShape = 2;
        elseif ((CB.Area >= 359 && CB.Area <= 471) && (CB.Solidity >= 0.56 && CB.Solidity <= 0.63 ) && ...
                (CB.Perimeter >= 129 && CB.Perimeter <= 151) && (CB.EquivDiameter >= 19 && CB.EquivDiameter <= 25) &&...
                (CB.MinorAxisLength >= 21 && CB.MinorAxisLength <= 27) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41) 
            convShape = 3;
        elseif ((CB.Area >= 629 && CB.Area <= 786) && (CB.Solidity >= 0.71 && CB.Solidity <= 0.83 ) && ...
                (CB.Perimeter >= 127 && CB.Perimeter <= 155) && (CB.EquivDiameter >= 26 && CB.EquivDiameter <= 33) &&...
                (CB.MinorAxisLength >= 29 && CB.MinorAxisLength <= 33) && (CB.MajorAxisLength >= 30 && CB.MajorAxisLength <= 36)) %(CB.Eccentricity >= 0.15 && CB.Eccentricity <= 0.41) 
            convShape =  4;
        elseif ((CB.Area >= 373 && CB.Area <= 512) && (CB.Solidity >= 0.50 && CB.Solidity <= 0.58 ) && ...
                (CB.Perimeter >= 121 && CB.Perimeter <= 142) && (CB.EquivDiameter >= 20 && CB.EquivDiameter <= 27) &&...
                (CB.MinorAxisLength >= 24 && CB.MinorAxisLength <= 31) && (CB.MajorAxisLength >= 28 && CB.MajorAxisLength <= 32)) %(CB.Eccentricity >= 0.26 && CB.Eccentricity <= 0.43) 
            convShape = 5;
        elseif ((CB.Area >= 561 && CB.Area <= 727) && (CB.Solidity >= 0.89 && CB.Solidity <= 0.98) && ...
                (CB.Perimeter >= 98 && CB.Perimeter <= 114) && (CB.EquivDiameter >= 25 && CB.EquivDiameter <= 31) &&...
                (CB.MinorAxisLength >= 26 && CB.MinorAxisLength <= 30) && (CB.MajorAxisLength >= 26 && CB.MajorAxisLength <= 33)) %(CB.Eccentricity >= 0.23 && CB.Eccentricity <= 0.38) 
            convShape = 6;
        else
            disp("No Shape Match");
            convShape = 7;
        end

        if (convShape == 2 || convShape == 6)
            cb = identifyConveyorBlocks(convBlock);
            cb = imfill(cb,'holes');
            cb = bwareaopen(cb,200);
    %         figure(5); imshow(cb);
            area = bwareaopen(shapes,200);
            stats = regionprops(area, 'Extrema');
            h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            angle1 = getAngleFromHorizontal(h1);

            stats = regionprops(shapes, 'Extrema');
            if size(stats,1) > 1
                %if more than one thing is detected
                shapes = bwmorph(shapes, 'erode');
                stats = regionprops(shapes, 'Extrema');
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            else
                h1 = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
            end
            angle2 = getAngleFromHorizontal(h1);

            if abs(angle1-angle2) < 10
                %its a square
                convShape = 6;
            else
                convShape = 2;
            end
        end
    end

    function [matchedIndex,convOrientation,points] = matchWithConveyor(colourIndex,blockShape, ConvIndex, detectedConvBlocks, conveyor,cakeB,blockOrderMaintenance,blockOrderCounter)
        %colourIndex:
    %     red = 1
    %     green = 2
    %     blue = 3
    %     yellow = 4
        matchedIndex = 0;
        for i = 1:length(ConvIndex)
            if (ConvIndex(i) ~= 255) %this is a removed point, not supposed to visit the spot that we already looked at
                convBlock = imcrop(conveyor, detectedConvBlocks(ConvIndex(i),:));
    %             imwrite(convBlock,'convBlock1.jpg');
                if (colourIndex == 1)
        %           red
                    redConvBlock = conveyorRedBlocks(convBlock);
                    [Iarea, shapes] = filter(redConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    %figure(5); imshowpair(convBlock, shapes,'montage');
                    convShape = redConvShapeIdentifier(CB,convBlock,shapes);

                elseif (colourIndex == 2)
        %           green
                    greenConvBlock = conveyorGreenBlocks(convBlock);
                    [Iarea, shapes] = filter( greenConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    %figure(5); imshowpair(convBlock, shapes,'montage');
                    convShape = greenConvShapeIdentifier(CB,convBlock,shapes);
                elseif (colourIndex == 3)
        %           blue
                    blueConvBlock = conveyorBlueBlocks(convBlock);
                    [Iarea, shapes] = filter( blueConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    %figure(5); imshowpair(convBlock, shapes,'montage');
                    convShape = blueConvShapeIdentifier(CB,convBlock,shapes);

                elseif (colourIndex == 4)
        %           yellow
                    yellowConvBlock = conveyorYellowBlocks(convBlock);
                    [Iarea, shapes] = filter(yellowConvBlock);
                    CB = regionprops(shapes, {'Area', 'Eccentricity', 'EquivDiameter', 'EulerNumber', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Extent'});
                    C = vertcat(CB.Area);
                    idx = find([CB.Area] == max(C));
                    CB = CB(idx);
                    %figure(5); imshowpair(convBlock, shapes,'montage');
                    convShape = yellowConvShapeIdentifier(CB,convBlock,shapes);

                end
                disp(convShape);
                if (blockShape == convShape)
                    matchedIndex = ConvIndex(i);
                    disp("MATCH FOUND");
                    %match Found, obtains the orientation and prints the match
                    %for me to see
                    convBlock = imcrop(conveyor, [detectedConvBlocks(matchedIndex,1)-5,detectedConvBlocks(matchedIndex,2)-5 ...
                                        detectedConvBlocks(matchedIndex,3)+10, detectedConvBlocks(matchedIndex,4)+10]);
                    [convOrientation,points] = getConvOrientation(convBlock);
                    figure(4); imshowpair(cakeB,convBlock,'montage');
    %                 pause(0.5);
                    return;
                end
            end
        end

        if (matchedIndex == 0)
            matchedIndex = 155; %static variable
            convOrientation = 0;
            points(1:4) = 0;
            return;
        end
    end
    function [angle,points] = getCakeOrientation(block)
        IbwBlock = ~im2bw(block, graythresh(block));
        area = bwareaopen(IbwBlock,200);
        stats = regionprops(area, 'Extrema');
        h = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle = getAngleFromHorizontal(h);
        points(1) = stats.Extrema(6,1);
        points(2) = stats.Extrema(6,2);
        points(3) = stats.Extrema(7,1);
        points(4) = stats.Extrema(7,2);
    end
    function [angle,points] = getConvOrientation(block)
        [bw, mask] = identifyConveyorBlocks(block);
        [bw1,mask1] = convOrientationMask(block);
        BW = imfill(bw, 'holes');
        bbw = bwmorph(BW,'erode');
        area = bwareaopen(bbw,200);
        stats = regionprops(area, 'Extrema');
        h = imdistline(gca,[stats.Extrema(6,1),stats.Extrema(7,1)],[stats.Extrema(6,2),stats.Extrema(7,2)]);
        angle = getAngleFromHorizontal(h);
        figure(3); imshow(area); hold on;
        plot(stats.Extrema(6,1),stats.Extrema(6,2),'g+');
        plot(stats.Extrema(7,1),stats.Extrema(7,2),'r+');
        points(1) = stats.Extrema(6,1);
        points(2) = stats.Extrema(6,2);
        points(3) = stats.Extrema(7,1);
        points(4) = stats.Extrema(7,2);
    end
    function [BW,maskedRGBImage] = convOrientationMask(RGB)
    %createMask  Threshold RGB image using auto-generated code from colorThresholder app.
    %  [BW,MASKEDRGBIMAGE] = createMask(RGB) thresholds image RGB using
    %  auto-generated code from the colorThresholder app. The colorspace and
    %  range for each channel of the colorspace were set within the app. The
    %  segmentation mask is returned in BW, and a composite of the mask and
    %  original RGB images is returned in maskedRGBImage.

    % Auto-generated by colorThresholder app on 21-Aug-2019
    %------------------------------------------------------


    % Convert RGB image to chosen color space
    I = RGB;

    % Define thresholds for channel 1 based on histogram settings
    channel1Min = 25.000;
    channel1Max = 255.000;

    % Define thresholds for channel 2 based on histogram settings
    channel2Min = 0.000;
    channel2Max = 255.000;

    % Define thresholds for channel 3 based on histogram settings
    channel3Min = 0.000;
    channel3Max = 255.000;

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
        (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
        (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
    BW = sliderBW;

    % Initialize output masked image based on input image.
    maskedRGBImage = RGB;

    % Set background pixels where BW is false to zero.
    maskedRGBImage(repmat(~BW,[1 1 3])) = 0;

    end
end
