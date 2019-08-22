function main()
    global running;
    running = 0;

    main_window = figure;
    main_window.CloseRequestFcn = @main_window_close;

    controls = uipanel('Parent', main_window);
    controls.Title = 'Options';
    controls.Position = [ 0 0 0.2 1 ];

    quit_button = uicontrol('Parent', controls);
    quit_button.String = 'Quit';
    quit_button.Callback = @quit_button_down;
    quit_button.Units = 'normalized';
    quit_button.Position = [ 0.05 0.05 0.9 0.1 ];

    maintenance_button = uicontrol('Parent', controls);
    maintenance_button.String = 'Maintenance';
    maintenance_button.Callback = @maintenance_button_down;
    maintenance_button.Units = 'normalized';
    maintenance_button.Position = [ 0.05 0.2 0.9 0.1 ];

    plots = uipanel('Parent', main_window);
    plots.Title = 'Feedback';
    plots.Position = [ 0.2 0 0.8 1 ];

    feedback_ax = axes('Parent', plots);
    feedback_ax.Position = [ 0 0 1 1 ];

    table_cam_ax = subplot(2, 2, 1, feedback_ax);
    conveyor_cam_ax = subplot(2, 2, 2);
    table_out_ax = subplot(2, 2, 3);
    conveyor_out_ax = subplot(2, 2, 4);
    
    [table_camera table_camera_source] = connect_to_camera(1);
    table_camera_parameters = set_camera_parameters(table_camera_source, []);
    table_camera_parameters(1) = -4;
    set_camera_parameters(table_camera_source, table_camera_parameters);
    default_table_image = imread('3.jpg');
    table_image = get_image(table_camera, default_table_image);
    table_imshow = imshow(table_image, 'Parent', table_cam_ax);
    
    [conveyor_camera, conveyor_camera_source] = connect_to_camera(2);
    conveyor_camera_parameters = set_camera_parameters(conveyor_camera_source, []);
    conveyor_camera_parameters(1) = -6;
    set_camera_parameters(conveyor_camera_source, conveyor_camera_parameters);
    default_conveyor_image = imread('7.jpg');
    conveyor_image = get_image(conveyor_camera, default_conveyor_image);
    conveyor_imshow = imshow(conveyor_image, 'Parent', conveyor_cam_ax);
    
    table_out_imshow = imshow(table_image, 'Parent', table_out_ax);
    
    
    % set up ink and decoration objects
    ink = InkPrinting;
    decoration = Decoration;
    
    [ink_out, Traj] = ink.update(table_image);
    [normal, bold] = parse_letters(ink_out);
    
    [a, b, theta] = decoration.update(table_image, conveyor_image);
    
    conveyor_out_imshow = imshow(conveyor_image, 'Parent', conveyor_out_ax);
    hold on;
    ink_bold = plot(bold.x(:), bold.y(:), 'r');
    ink_normal = plot(normal.x(:), normal.y(:), 'y');
    hold off;

    running = 1;

    while(running)
        % capture new images
        table_image = get_image(table_camera, default_table_image);
        table_imshow.CData = table_image;
        conveyor_image = get_image(conveyor_camera, default_conveyor_image);
        conveyor_imshow.CData = conveyor_image;
        
        table_out_imshow.CData = table_image;
        [ink_out, Traj] = ink.update(table_image);
        [normal, bold] = parse_letters(ink_out);
        
        
    ink_bold.XData = bold.x(:);
    ink_bold.YData = bold.y(:);
    ink_normal.XData = normal.x(:);
    ink_normal.YData = normal.y(:);
        
        drawnow limitrate;
        pause(0.05);
    end
end

function main_window_close(fig,~)
    global running;
    running = 0;
    fig;
    closereq;
end

function quit_button_down(fig,~)
    global running;
    running = 0;
    fprintf('quitting\n');
    fig;
    closereq;
end

function maintenance_button_down(main_fig,~)
    maintenance_fig = figure;
    maintenance_fig.CloseRequestFcn = @maintenance_close;
    maintenance_fig.UserData = main_fig;
    
    maintenance_controls = uipanel('Parent', maintenance_fig);
    maintenance_controls.Title = 'Maintenance Options';
    maintenance_controls.Position = [ 0 0 0.2 1 ];

    vision_test = uicontrol('Parent', maintenance_controls);
    vision_test.String = 'Unit test vision';
    % vision_test.Callback = @vision_test;
    vision_test.Units = 'normalized';
    vision_test.Position = [ 0.05 0.05 0.9 0.1 ];

    motion_test = uicontrol('Parent', maintenance_controls);
    motion_test.String = 'Unit test motion';
    % motion_test.Callback = @motion_test;
    motion_test.Units = 'normalized';
    motion_test.Position = [ 0.05 0.2 0.9 0.1 ];
    
    main_fig.Parent.Parent.Visible = 'off';
end

function maintenance_close(fig,~)
    main_fig = fig.UserData;
    main_fig.Parent.Parent.Visible = 'on';
    fig;
    closereq;
end

function [camera, cam_source] = connect_to_camera(varargin)
    cams = imaqhwinfo;
    if length(cams.InstalledAdaptors) >= 2
        if nargin == 0 || nargin == 1
            camera = videoinput('winvideo', 1, 'MJPG_1600x1200'); 

            cam_source = getselectedsource(camera);
            cam_source.ExposureMode = 'manual';
        end
    else
        camera = [];
        cam_source = [];
    end  
end

function [img] = get_image(camera, default_img)
    if length(camera) == 1
    	img = getsnapshot(camera);
    else
        img = default_img;
    end
end

function params = set_camera_parameters(cam_source, params)
    if length(params) == 3
        cam_source.Exposure = params(1);
        cam_source.Contrast = params(2);
        cam_source.Saturation = params(3);
    else
        if ~isempty(cam_source)
            params(1) = cam_source.Exposure;
            params(2) = cam_source.Contrast;
            params(3) = cam_source.Saturation;
        else
            params(1) = -1;
            params(2) = -1;
            params(3) = -1;
        end
    end
end

function [normal, bold] = parse_letters(letters)
normal.x = inf;
normal.y = inf;
bold.x = inf;
bold.y = inf;
for i = 1:length(letters)
    if letters(i).boldness == 1
        bold.x = [bold.x; letters(i).trajectory(:,1); inf];
        bold.y = [bold.y; letters(i).trajectory(:,2); inf];
    else
        normal.x = [normal.x; letters(i).trajectory(:,1); inf];
        normal.y = [normal.y; letters(i).trajectory(:,2); inf];
    end
end
end

