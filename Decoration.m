% Author: 
% ID: 
% Date: 
% Description: 
% MTRN4230 Group Assignment
% Computer Vision program for ink printing 
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


function [Decor_copy] = Decoration()
    % do your setup stuff here
    global Decor;
    Decor.private = 10;

    
    Decor.update = @your_decoration_function;
    Decor.test = @your_decoration_unit_test_function;
    Decor_copy = Decor;
end

function [from, to, angle] = your_decoration_function(table, conveyor)
    global Decor;

    fprintf('%f\n', Decor.private);
    Decor.private = Decor.private + 10;
    from = [0 0 0];
    to = [1 1 1];
    angle = [3.141/2];
end

function your_decoration_unit_test_function(~,~)
    fprintf('decoration test complete\n');
end

% ----------------- Function ------------------ %
% INTERNAL FUNCTIONS HERE
