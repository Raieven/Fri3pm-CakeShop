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


function [decor] = Decoration()
    decor.update = @update;
    
    % do your setup stuff here
    decor.private = 'private variable\n';
    
    function [from, to, angle] = update(table, conveyor)
        [from, to, angle] = your_decoration_function(decor, table, conveyor);
    end
end

function [from, to, angle] = your_decoration_function(decor, table, conveyor)
    fprintf(decor.private);
    
    from = [0 0 0];
    to = [1 1 1];
    angle = [3.141/2];
end

% ----------------- Function ------------------ %
% INTERNAL FUNCTIONS HERE
