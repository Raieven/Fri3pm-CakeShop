% Author: WENJIE MAO
% ID: z5097983
% Date: 23/08/2019
% Description: Detect letters in the text and generate the trajectory.
% MTRN4230 Group Assignment
% Computer Vision program for ink printing 
%
% Objectification by Jesse Falzon
%
% Usage:
%       make object with:
%   >> IP = InkPrinting();
%
%       call vision code with
%   >> Image = imread('path/to.jpg');
%   >> [letters, Traj, Draw] = IP.update(Image);
%
%  Input: 
%   Image - Image taken from table camera
%   eg: Image = '1.png';
%
%  Output:
%   Traj - Boldness & XY coordinates
%   Traj{2,i}(:,1) - X coordinates of the i-th letter
%   Traj{2,i}(:,2) - Y coordinates of the i-th letter
%   Traj{1,i}      - Boldness of the i-th letter
%
%   letters(i).boldness         - boldness of the i-th letter
%   letters(i).trajectory(:,1)  - X coords of the i-th letter
%   letters(i).trajectory(:,2)  - Y coords of the i-th letter
%
%   Draw - to simulate trajectory in MATLAB

function [IP_copy] = InkPrinting()
    % Load calibration parameter to convert coordinates into world coordinates
    global IP;
    fx = load('f_x.mat');
    IP.f_x = fx;
    fy = load('f_y.mat');
    IP.f_y = fy;
    
    IP.update = @InkPrinting_run;
    IP.test = @InkPrinting_unit_test;
    IP_copy = IP;
end

function [letters, Traj, Draw] = InkPrinting_run(Image)
%close all;clear;clc;
% MTRN4230_image_capture();
% pause;
global IP;
f_x = IP.f_x;
f_y = IP.f_y;

I = rgb2gray(Image);
% figure;
% imshow(colorImage);
% title("Original Image");

% Binarize the image
threshold = graythresh(I);
BWImage = ~im2bw(I,threshold);
%BWImage = ~imbinarize(I);

% Extract the region of interest
Mask = zeros(size(BWImage));
Mask(250:850,500:1100) = 1;

% Apply filters
BWImage = BWImage & Mask;
BWImage = bwareafilt(BWImage,[50,14000]);
BWImage = bwpropfilt(BWImage,'MajorAxisLength',[70,250]);
BWImage = bwpropfilt(BWImage,'MinorAxisLength',[5,250]);
BWImage = bwpropfilt(BWImage,'Solidity',[0.2,1]);
BWImage = bwpropfilt(BWImage,'Extent',[0.2,1]);

% figure;
% imshow(BWImage);
% title("Binarized Image");

% --------------- Check boldness --------------------%

CC = bwconncomp(BWImage);
Text_Im = regionprops(CC, 'BoundingBox', 'Image', 'Centroid');

% Check if there is text in the image
if isempty(Text_Im)
    fprintf('No letters detected!\n');
    letters = []; Traj = {}; Draw = {};
    return; 
end

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
    total_index = sum(sum(CC_1));
    
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

Traj = {};

for i = 1:length(Draw)
    % Red thicker line for Bold font, green thin line for normal font
    %if Draw{1,i} == 1
    %    Boldness = 20;
    %    style = 'r.';
    %else
    %    Boldness = 10;
    %    style = 'g.';
    %end
    
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
%     for ii = 1:length(RR)
%         drawnow
%         plot(ax, RR(ii),CC(ii), style, 'Markersize', Boldness);
%         pause(0.02)
%     end
    
    % Convert into world coordinates
    WP_X = (f_x.p_x(1)*CC + f_x.p_x(2));
    WP_Y = (f_y.p_y(1)*RR + f_y.p_y(2));
    
    Traj{1,i} = Draw{1,i};
    Traj{2,i} = [WP_X, WP_Y];
    
end

boldness = Traj{1,i};

for i = 1:length(boldness)
    letters(i).trajectory = [Traj{2,i}(:,1) Traj{2,i}(:,2)];
    letters(i).boldness = boldness(i);
end

end

function InkPrinting_unit_test(~,~)

    img = imread('table__08_22_16_56_44.jpg');

    [~, ~, Draw] = InkPrinting_run(img);
    
    fig = figure;
    ax = axes;
    imshow(img);
    title('Simulation');
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

    end
    fprintf('ink test complete\n');
end

% ----------------- Function ------------------ %
% [Off_R, Off_C] may have multiple values
function [Off_R, Off_C] = FindNext(Curr_Mx)
    Cmp_Mx = [1 1 1; 1 0 1; 1 1 1];
    [Off_R, Off_C] = find(and(Curr_Mx, Cmp_Mx));
    Off_R = 2 - Off_R;
    Off_C = 2 - Off_C;
end
