function main()
    global running;
    running = 0;
    
    global default_table_image default_conveyor_image
    % setup table camera
    [table_camera table_camera_source] = connect_to_camera([]);
    table_camera_parameters = set_camera_parameters(table_camera_source, []);
    table_camera_parameters(1) = -4;
    set_camera_parameters(table_camera_source, table_camera_parameters);
    default_table_image = imread('default_table.jpg');
    
    % setup conveyor camera
    [conveyor_camera, conveyor_camera_source] = connect_to_camera([],[]);
    conveyor_camera_parameters = set_camera_parameters(conveyor_camera_source, []);
    conveyor_camera_parameters(1) = -6;
    set_camera_parameters(conveyor_camera_source, conveyor_camera_parameters);
    default_conveyor_image = imread('default_conveyor.jpg');
    
    % set up TCP, ink and decoration objects
    global TcpIp ink decoration;
    TcpIp = TCP();
    ink = InkPrinting;
    decoration = DecorationPaperConv850;
    
    TcpIp.open('192.168.125.1', 1025);

    % create main figure
    main_window = figure;
    main_window.CloseRequestFcn = @main_window_close;

    % add control panel
    controls = uipanel('Parent', main_window);
    controls.Title = 'Options';
    controls.Position = [ 0 0 0.2 1 ];

    % make quit button
    quit_button = uicontrol('Parent', controls);
    quit_button.String = 'Quit';
    quit_button.Callback = @quit_button_down;
    quit_button.Units = 'normalized';
    quit_button.Position = [ 0.05 0.05 0.9 0.1 ];

    % make maintenance button
    maintenance_button = uicontrol('Parent', controls);
    maintenance_button.String = 'Maintenance';
    maintenance_button.Callback = @maintenance_button_down;
    maintenance_button.Units = 'normalized';
    maintenance_button.Position = [ 0.05 0.2 0.9 0.1 ];
    
    % make stop button
    stop_button = uicontrol('Parent', controls);
    stop_button.String = 'Stop';
    stop_button.Callback = @stop_button_down;
    stop_button.Units = 'normalized';
    stop_button.Position = [ 0.05 0.35 0.9 0.1 ];
    
    % make pause button
    pause_button = uicontrol('Parent', controls);
    pause_button.String = 'Pause';
    pause_button.Callback = @toggle_button_down;
    pause_button.Units = 'normalized';
    pause_button.Position = [ 0.05 0.5 0.9 0.1 ];
    
    % make Print ink button
    ink_button = uicontrol('Parent', controls);
    ink_button.String = 'Print Ink';
    ink_button.Callback = @ink_button_down;
    ink_button.Units = 'normalized';
    ink_button.Position = [ 0.05 0.65 0.9 0.1 ];
    
    % make Print decorations button
    decorations_button = uicontrol('Parent', controls);
    decorations_button.String = 'Print Decorations';
    decorations_button.Callback = @decoration_button_down;
    decorations_button.Units = 'normalized';
    decorations_button.Position = [ 0.05 0.8 0.9 0.1 ];
    
    % make error text panel button
    error_text = uicontrol('Parent', controls);
    error_text.Style = 'text';
    error_text.String = 'Connecting';
    error_text.Units = 'normalized';
    error_text.Position = [ 0.05 0.9 0.9 0.10 ];

    % create panel for output plots
    plots = uipanel('Parent', main_window);
    plots.Title = 'Feedback';
    plots.Position = [ 0.2 0 0.8 1 ];

    feedback_ax = axes('Parent', plots);
    feedback_ax.Position = [ 0 0 1 1 ];

    % prepare axes for camera images
    table_cam_ax = subplot(2, 2, 1, feedback_ax);
    conveyor_cam_ax = subplot(2, 2, 2);
    table_out_ax = subplot(2, 2, 3);
    
    
    global table_image;
    % draw table camera
    table_image = get_image(table_camera, default_table_image);
    table_imshow = imshow(table_image, 'Parent', table_cam_ax);
    
    global conveyor_image;
    % draw conveyor camera
    conveyor_image = get_image(conveyor_camera, default_conveyor_image);
    conveyor_imshow = imshow(conveyor_image, 'Parent', conveyor_cam_ax);
    
    
    table_out_imshow = imshow(table_image, 'Parent', table_out_ax);
    hold on;
    hd01 = plot(table_out_ax, 0,0,'r.');
    hd02 = plot(table_out_ax, 1,1,'g.');
    
    % plot conveyor stuff
    conveyor_out_ax = subplot(2, 2, 4);
    detectedCakeBlocks = [];
    detectedCakeBlocksCentres = [];
    cakeBlockUnmatchedIndex = [];
    detectedConvBlocks = [];
    [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
            prevcake,prevdetectedCakeBlocks,...
            prevdetectedCakeBlocksCentres,detectedConvBlocks] = decoration.update(table_image, conveyor_image,cakeBlockUnmatchedIndex,...
                                                                            detectedCakeBlocks,detectedCakeBlocksCentres,detectedConvBlocks);
    
    conveyor_out_imshow = imshow(conveyor_image, 'Parent', conveyor_out_ax);
    hold on;

    
    % This is when the in ink stuff is complelre
    running = 1;

    while(running)
        % capture new images
        table_image = get_image(table_camera, default_table_image);
        table_imshow.CData = table_image;
        conveyor_image = get_image(conveyor_camera, default_conveyor_image);
        conveyor_imshow.CData = conveyor_image;
        
        table_out_imshow.CData = table_image;
        [~, ~, Draw] = ink.update(table_image);
        Draw_Text(Draw, hd01, hd02);
 
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
    global ink decoration;
    
    maintenance_fig = figure;
    maintenance_fig.CloseRequestFcn = @maintenance_close;
    maintenance_fig.UserData = main_fig;
    
    maintenance_controls = uipanel('Parent', maintenance_fig);
    maintenance_controls.Title = 'Maintenance Options';
    maintenance_controls.Position = [ 0 0 0.2 1 ];

    vision_test = uicontrol('Parent', maintenance_controls);
    vision_test.String = 'Unit test Decoration';
    vision_test.Callback = @decoration.test;
    vision_test.Units = 'normalized';
    vision_test.Position = [ 0.05 0.05 0.9 0.1 ];

    motion_test = uicontrol('Parent', maintenance_controls);
    motion_test.String = 'Unit test Inking';
    motion_test.Callback = @ink.test;
    motion_test.Units = 'normalized';
    motion_test.Position = [ 0.05 0.2 0.9 0.1 ];
    
    main_fig.Parent.Parent.Visible = 'off';
end

function maintenance_close(fig,~)
    main_fig = fig.UserData.Parent.Parent;
    main_fig.Visible = 'on';
    fig;
    closereq;
end

function [camera, cam_source] = connect_to_camera(varargin)
    cams = imaqhwinfo;
    if length(cams.InstalledAdaptors) >= 1
        if nargin == 0 || nargin == 1
            camera = videoinput('winvideo', 1, 'MJPG_1600x1200'); 
%             camera = videoinput('winvideo', 1, 'YUY2_1280x720'); 
            
            cam_source = getselectedsource(camera);
            cam_source.ExposureMode = 'manual';
        end
        if nargin == 0 || nargin == 2
            camera = videoinput('winvideo', 2, 'MJPG_1600x1200'); 
%             camera = videoinput('winvideo', 2, 'YUY2_1280x720');
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

function stop_button_down(~,~)
    fprintf('stop robot\n');
    % TcpIp.send_stop();
end

function toggle_button_down(button,~)
    global TcpIp;
    
    if strcmp(button.String, 'Pause')
        button.String = 'Running';
    else
        button.String = 'Pause';
    end
    
    TcpIp.send_toggle();
end

function ink_button_down(~,~)
    global TcpIp ink;
    global table_image;
    
    [~, b, ~] = ink.update(table_image);
    
    TcpIp.send_ink(b);
    [messageString, messageType] = TcpIp.receive();
    if (messageType == 0)
        fprintf('%s\n', messageString);
    end
end

function decoration_button_down(~,~)
    global TcpIp decoration;
    global table_image;
    global conveyor_image;
    messageType = -1;
    decoration.completeCakeFlag = 0;
    detectedCakeBlocks = [];
    detectedCakeBlocksCentres = [];
    cakeBlockUnmatchedIndex = [];
    detectedConvBlocks = [];
    if decoration.completeCakeFlag == 0
        [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
            prevcake,prevdetectedCakeBlocks,...
            prevdetectedCakeBlocksCentres,detectedConvBlocks] = decoration.update(table_image, conveyor_image,cakeBlockUnmatchedIndex,...
                                                                            detectedCakeBlocks,detectedCakeBlocksCentres,detectedConvBlocks);
        TcpIp.send_decorations(blockOrder,leftOverBlocks);
        while (messageType ~= 3)
            [messageString, messageType] = TcpIp.receive();
            if (messageType == 0)
                fprintf('%s\n', messageString)
                return;
            end
        end
        while UnmatchedBlocksFlag == 1
            messageType = -1;
            conveyor_image = get_image(conveyor_camera, default_conveyor_image);
            [blockOrder,leftOverBlocks,cakeBlockUnmatchedIndex,...
                prevcake,prevdetectedCakeBlocks,...
                prevdetectedCakeBlocksCentres,detectedConvBlocks] = decoration.update(prevcake, conveyor_image,cakeBlockUnmatchedIndex,...
                                                                            prevdetectedCakeBlocks,prevdetectedCakeBlocksCentres,detectedConvBlocks);
            TcpIp.send_decorations(blockOrder,leftOverBlocks);
            while (messageType ~= 3)
                [messageString, messageType] = TcpIp.receive();
                if (messageType == 0)
                    fprintf('%s\n', messageString)
                    return;
                end
            end
        end
    end
    decoration.completeCakeFlag = 1;
    
%     [messageString, messageType] = TcpIp.receive();
%     if (messageType == 0)
%         fprintf('%s\n', messageString);
%     end
end

function Draw_Text(Draw, hd01, hd02)
    
    C_B = [];
    R_B = [];
    
    C_N = [];
    R_N = [];
    
    for i = 1:length(Draw)


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
        
        % Red thicker line for Bold font, green thin line for normal font
        if Draw{1,i} == 1
            C_B(end+1:end+length(CC)) = CC;
            R_B(end+1:end+length(RR)) = RR;
        else
            C_N(end+1:end+length(CC)) = CC;
            R_N(end+1:end+length(RR)) = RR;
        end

    end
   set(hd01, 'xdata', R_B, 'ydata', C_B, 'color', 'red', 'Markersize', 20);
   set(hd02, 'xdata', R_N, 'ydata', C_N, 'color', 'green', 'Markersize', 10);
end
