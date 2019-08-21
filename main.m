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
    plot1 = subplot(2, 2, 3);
    plot2 = subplot(2, 2, 4);


    tp = imread('3.jpg');
    table_image = imshow(tp, 'Parent', table_cam_ax);

    cc = imread('7.jpg');
    table_image = imshow(cc, 'Parent', conveyor_cam_ax);


    plot(plot1, 0, 0);
    title(plot1, 'p1');

    plot(plot2, 0, 0);
    title('p2');

    running = 1;

    while(running)
        % do loop stuff

        drawnow limitrate;
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
    global running;
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
