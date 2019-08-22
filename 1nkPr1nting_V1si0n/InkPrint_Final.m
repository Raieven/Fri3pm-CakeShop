% Author: WENJIE MAO
% ID: z5097983
% Date: 22/08/2019
% MTRN4230 Group Assignment
% Computer Vision program for ink printing 

close all;clear;clc;
MTRN4230_image_capture();
pause;
colorImage = imread('text.png');
I = rgb2gray(colorImage);
% figure;
% imshow(colorImage);
% title("Original Image");

% Binarize the image
BWImage = ~imbinarize(I);

% Extract the region of interest
Mask = zeros(size(BWImage));
Mask(250:850,500:1100) = 1;

% Apply filters
BWImage = BWImage & Mask;
BWImage = bwareafilt(BWImage,[50,8000]);
BWImage = bwpropfilt(BWImage,'MajorAxisLength',[50,150]);
BWImage = bwpropfilt(BWImage,'MinorAxisLength',[5,150]);
BWImage = bwpropfilt(BWImage,'Solidity',[0.2,1]);
BWImage = bwpropfilt(BWImage,'Extent',[0.2,1]);

% figure;
% imshow(BWImage);
% title("Binarized Image");

% --------------- Check boldness --------------------%

CC = bwconncomp(BWImage);
Text_Im = regionprops(CC, 'BoundingBox', 'Image', 'Centroid');
coords = vertcat(Text_Im.Centroid);

if max(diff(coords(:, 2))) > 50
    [~, ~, coords(:, 2)] = histcounts(coords(:, 2), 3);  % Bin the "y" data
    [~, sortIndex] = sortrows(coords, [2 1]);   % Sort by "y" ascending, then "x" ascending
    Text_Im = Text_Im(sortIndex);   % Apply sort index to Text_Im
else
    [~, sortIndex] = sortrows(coords, 1);  % Sort by "x" ascending
    Text_Im = Text_Im(sortIndex);  % Apply sort index to Text_Im
end

Bold_list = logical(zeros(numel(Text_Im),1)); % 1 ---- Bold, 0 ---- Normal
R_arry = [];

for i = 1:numel(Text_Im)
    
    CC_1 = Text_Im(i).Image;
    CC_1 = padarray(CC_1, [1 1]);   % add a frame to the current box, all 0s
%             figure;
%             imshow(CC_1)
    narrow = bwmorph(CC_1, 'thin', inf);
    D1 = bwdist(~CC_1);
    D2 = D1(narrow);
    if Text_Im(i).BoundingBox(4) >= Text_Im(i).BoundingBox(3)
        R = mean(D2)/(Text_Im(i).BoundingBox(4));
    else
        R = mean(D2)/(Text_Im(i).BoundingBox(3));
    end
    R_arry(i) = R;
    % Compute the ratio of mean value of the width and the height of the
    % box. The min value of the bold letters is 0.067, the max value of the
    % normal letters is 0.059.
    if R > 0.0685
        Bold_list(i) = 1;
    end
    
end

% ------------ Create via points ------------------- %

Text001 = bwmorph(BWImage, 'thin', inf);
% figure
% imshow(Text001)
Text_Im = regionprops(Text001, 'BoundingBox', 'Image', 'Centroid');
coords_T = vertcat(Text_Im.Centroid);  % 2-by-18 matrix of centroid data
Centroid_Original = coords_T;

if max(diff(coords_T(:, 2))) > 50
    [~, ~, coords_T(:, 2)] = histcounts(coords_T(:, 2), 3);  % Bin the "y" data
    [~, sortIndex] = sortrows(coords_T, [2 1]);  % Sort by "y" ascending, then "x" ascending
    Text_Im = Text_Im(sortIndex);  % Apply sort index to s
else
    [~, sortIndex] = sortrows(coords_T, 1);  % Sort by "y" ascending, then "x" ascending
    Text_Im = Text_Im(sortIndex);  % Apply sort index to s
end

Sorted = vertcat(Text_Im.Centroid);      % Sorted text
[H, W] = size(I);
Draw = {};

for i = 1:numel(Text_Im)
    CC_1 = Text_Im(i).Image;
    CC_1 = padarray(CC_1, [1 1]);
    EndPoint = bwmorph(CC_1, 'endpoints');
    [E_R, E_C] = find(EndPoint);
    N_End = length(E_R);
    T = regionprops(CC_1, 'BoundingBox', 'Image', 'Centroid');
    Ori_Cen = Sorted(i,:);
    Now_Cen = T.Centroid;
    
    % convert local coordinates to global
    Row_Diff = Ori_Cen(1) - Now_Cen(1);
    Col_Diff = Ori_Cen(2) - Now_Cen(2);
    
    if N_End > 0
        R = E_R(1);
        C = E_C(1);    
    else
        [R,C] = find(CC_1,1);
    end
    
    P = [R,C];
    V = [R,C];
    Branch = [];    
    index = 1;
    total_index = sum(CC_1,'all');
    
    while (~isempty(V)) && (index ~= total_index)
        
        index = index+1;
        CC_1(R,C) = 0;
        Curr_Mx = CC_1(R-1:R+1, C-1:C+1);
        [Off_R, Off_C] = FindNext(Curr_Mx);
        Next_R = R - Off_R;
        Next_C = C - Off_C;
        if isempty(Next_R)
            for ii = 2:N_End
                if sum(ismember(P, [E_R(ii), E_C(ii)], 'rows'))==0
                    Next_R = E_R(ii);
                    Next_C = E_C(ii);
                end
            end  
        end
        if length(Next_R) > 1
            Branch(end+1,:) = [P(end,1), P(end,2)];
        end
        
        V(end, :) = [];
        
        for count = 1:length(Next_R)
            if sum(ismember(P,[Next_R(count), Next_C(count)], 'rows')) == 0
                if(~isempty(V))
                    V(end+1, :) = [Next_R(count),Next_C(count)];
                else
                    V = [Next_R(count), Next_C(count)];
                end
            end
        end
        
        R = V(end,1);
        C = V(end,2);
        P(end+1,:) = [R,C];
        P = unique(P,'rows', 'stable');
        
    end
    
    C = ismember(P, [E_R, E_C], 'rows');
    P(C,:)=[];
    P(:,1) = P(:,1) + Col_Diff;
    P(:,2) = P(:,2) + Row_Diff;
    
    Draw{2,i} = P;
    Draw{1,i} = Bold_list(i);
end

% Load calibration parameter to convert coordinates into world coordinates
fx = load('f_x.mat');
f_x = fx.p_x;
fy = load('f_y.mat');
f_y = fy.p_y;
Traj = {};

fig = figure;
ax = axes;
imshow(I);
title('Final');
hold on;

for i = 1:length(Draw)
    % Red thicker line for Bold font, green thin line for normal font
    if Draw{1,i} == 1
        Boldness = 20;
        style = 'r.';
    else
        Boldness = 10;
        style = 'g.';
    end
    
    Tj = Draw{2,i};
    Idx_clr = [];
    n = 1;
    Flag_clr = 0;
    CC = Tj(:,1);
    RR = Tj(:,2);
    
    % Simplify the trajectory by reducing the way points
    for m = 1:(length(CC)-1)
        if Flag_clr == 0
            cm = m;
        end
        
        if (sqrt((CC(cm) - CC(m+1))^2 + (RR(cm) - RR(m+1))^2) <= 10)
            Idx_clr(n) = m+1;
            n = n + 1;
            Flag_clr = 1;
        else
            Flag_clr = 0;
        end
        
    end
    
    CC(Idx_clr) = [];
    RR(Idx_clr) = [];
    
    % Simulate the trajectory
    for ii = 1:length(RR)
        drawnow
        plot(ax, RR(ii),CC(ii), style, 'Markersize', Boldness);
        pause(0.02)
    end
    
    % Convert into world coordinates
    WP_X = (f_x(1)*CC + f_x(2));
    WP_Y = -(f_y(1)*RR + f_y(2));
    
    Traj{1,i} = Draw{1,i};
    Traj{2,i} = [WP_X, WP_Y];
    
end

save('Traj', 'Traj');


% ----------------- Function ------------------ %
% [Off_R, Off_C] may have multiple values
function [Off_R, Off_C] = FindNext(Curr_Mx)
    Cmp_Mx = [1 1 1; 1 0 1; 1 1 1];
    [Off_R, Off_C] = find(and(Curr_Mx, Cmp_Mx));
    Off_R = 2 - Off_R;
    Off_C = 2 - Off_C;
end

% Image Acquisition from table camera
function MTRN4230_image_capture (varargin)
    close all;
    warning('off', 'images:initSize:adjustingMag');

    if nargin == 0 || nargin == 1
        fig1 =figure(1);
        axe1 = axes ();
        axe1.Parent = fig1;
        vid1 = videoinput('winvideo', 1, 'MJPG_1600x1200');
        video_resolution1 = vid1.VideoResolution;
        nbands1 = vid1.NumberOfBands;
        img1 = imshow(zeros([video_resolution1(2), video_resolution1(1), nbands1]), 'Parent', axe1);
        prev1 = preview(vid1,img1);
        src1 = getselectedsource(vid1);
        src1.ExposureMode = 'manual';
        src1.Exposure = -4;
        cam1_capture_func = @(~,~)capture_image(vid1,'table_img');
        prev1.ButtonDownFcn = cam1_capture_func;
        fig1.KeyPressFcn = cam1_capture_func;
    end
end

% Image capture function  
function capture_image (vid,name)
    snapshot = getsnapshot(vid);
    close;
    imwrite(snapshot1,'text.png');
end
