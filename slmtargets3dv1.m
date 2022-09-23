classdef slmtargets3dv1 < handle
%Spencer Brown, 2022, Hausser Lab

%bugs: 
%1. set max clusters and zones: max zones = 100, max clusters 1000;
%2. resize callback results in dimensions less than zero
%3. make it so you can only load another image of same size
%4. what if zone has no cells? fix this.
    properties (Access = public)
        
        
    end
    
    properties (Access = private)
        
        %to do notes:
        %-ensure range is set before phase_mask generation
        %need safety net for only loading 512x512 images
        %erase out roi data if reload masks
        gui;
        state;
        state_objects = {'editfield'; 'button'};
        state_props   = {'Value';'Enable'};
        
        %figure handles
        f;
        panel;
        label;
        menu;
        editfield;
        button;
        table;
        ax1;
        display;
        interface_textarea;
        scroll_ready = 0;
        defaults;
        dataTable;
        
    end
    
    methods 
        function delete(this)
        end
        
        function this = slmtargets3dv1()
            
            %initalize defaults object
            this.defaults.cmap        = hsv;
            this.defaults.point_color = this.defaults.cmap(1,:);
            this.defaults.cmap32      = repmat(this.defaults.cmap(1:32:end,:),[100 1]);
            this.defaults.cmap12      = circshift(this.defaults.cmap32,0);
            this.defaults.max_zones   = 50;
            
            %initalize gui objects
            this.initialize_gui_objects();
            
            %create ui figure
            screen_size   = get( groot, 'Screensize' );
            figure_width  = 945;
            figure_height = 740;
            figure_left   = (screen_size(3)/2)-(figure_width/2);
            figure_bottom = (screen_size(4)/2)-(figure_height/2);
            this.f      = uifigure('Name','SLM Targets','Position',[figure_left figure_bottom figure_width figure_height],'visible','off');
            this.f.Icon = 'laser.png';
            set(this.f,'WindowButtonMotionFcn', @this.hoverCallback,'WindowKeyPressFcn', @this.KeyPress);
            set(this.f,'WindowScrollWheelFcn',@this.scroll_Callback);
            set(this.f,'AutoResizeChildren','off','ResizeFcn',@(f,event) this.resizeCallback());
            
            %create ui menus
            this.menu.file                   = uimenu('Parent',this.f,'Text','File');
            this.menu.file_reset             = uimenu(this.menu.file,'Text','&New project');
            this.menu.file_reset.Accelerator = 'N';
            this.menu.file_reset.MenuSelectedFcn = @this.menu_reset;
            
            this.menu.file_load    = uimenu(this.menu.file,'Text','&Load project');
            this.menu.file_load.Accelerator = 'L';
            this.menu.file_load.MenuSelectedFcn = @this.menu_load;
            
            this.menu.file_exportImg = uimenu(this.menu.file,'Text','&Export image')
            this.menu.file_exportImg.Accelerator = 'E';
            this.menu.file_exportImg.MenuSelectedFcn = @this.menu_exportImg;
            
            this.menu.file_save = uimenu(this.menu.file,'Text','&Save');
            this.menu.file_save.Accelerator = 'S';
            this.menu.file_save.MenuSelectedFcn = @this.menu_save;
            
            this.menu.file_savedir = uimenu(this.menu.file,'Text','&Change project directory');
            this.menu.file_savedir.Accelerator = 'C';
            
            %create ui panels
            this.panel.image   = uipanel('Parent',this.f,'Position',[20 20 700 700],'BackgroundColor',[0 0 0]);
            set(this.panel.image,'AutoResizeChildren','off');
            this.panel.control = uipanel('Parent',this.f,'Position',[728 20 200 700]);

            %create ui axes
            this.ax1 = uiaxes(this.panel.image);
            set(this.ax1,'Parent',this.panel.image,'Position',[1 1 this.panel.image.Position(3)-2 this.panel.image.Position(3)-2]);
            set(this.ax1,'xtick',[],'ytick',[])
            set(this.ax1,'xlabel',[],'ylabel',[])
            axis(this.ax1,'tight')
            
            %create ui buttons
            top = 675;
            side = 5;
            
            %image control panel

            this.panel.image_control = uipanel('Parent',this.panel.control,'Title','Image controls','FontWeight','bold');
            this.button.load_image = uibutton(this.panel.image_control,'push','Text', 'load image','ButtonPushedFcn', @(button,event) this.load_image_button_pushed() );
            this.editfield.filename = uieditfield(this.panel.image_control,'Enable','on','Editable','off');
            this.button.contrast = uibutton(this.panel.image_control,'push','Text', '+ contrast','ButtonPushedFcn', @(button,event) this.contrast_button_pushed());
            this.button.reset_img = uibutton(this.panel.image_control,'push','Text', 'reset contrast','ButtonPushedFcn', @(button,event) this.reset_img_button_pushed());            
            this.label.z_position = uilabel(this.panel.image_control,'Text','z range:' );
            this.editfield.z_position_above_focus = uieditfield(this.panel.image_control,'numeric','Editable','on','ValueChangedFcn',@(z_position_above_focus_editfield,event) this.z_range_editfieldsChanged()); 
            this.editfield.z_position_below_focus = uieditfield(this.panel.image_control,'numeric','Editable','on','ValueChangedFcn',@(z_position_below_focus_editfield,event) this.z_range_editfieldsChanged());
            this.editfield.z = uieditfield(this.panel.image_control,'numeric','Limits', [-Inf Inf],'Enable','on','Editable','off');
            this.label.current_z = uilabel(this.panel.image_control,'Text','z (µm):');
            this.label.colon = uilabel(this.panel.image_control,'Text',':','FontWeight','bold' );
            this.button.right_arrow = uibutton(this.panel.image_control,'push','Text', '>','ButtonPushedFcn', @(button,event) this.change_image_arrow_button_pushed(button) );
            this.button.left_arrow = uibutton(this.panel.image_control,'push','Text', '<','ButtonPushedFcn', @(button,event) this.change_image_arrow_button_pushed(button) );
            
            this.panel.image_control.Position               = [5 545 190 150];
            this.button.load_image.Position                 = [5 105 80 20];
            this.editfield.filename.Position                = [5 81 180 20];
            this.button.contrast.Position                   = [5 55 70 20];
            this.button.reset_img.Position                  = [80 55 90 20];
            this.label.z_position.Position                  = [5 30 55 15];
            this.editfield.z_position_above_focus.Position  = [55 28 40 20];
            this.editfield.z_position_below_focus.Position  = [105 28 40 20];
            this.label.colon.Position                       = [98 32 10 15];
            this.editfield.z.Position                       = [55 6 40 20];
            this.label.current_z.Position                   = [5 6 40 20];
            this.button.left_arrow.Position                 = [this.editfield.z_position_below_focus.Position(1)-4 ...
                this.editfield.z.Position(2) 40 20];
            this.button.right_arrow.Position                 = [this.button.left_arrow.Position(1)+this.button.left_arrow.Position(3)+2 ...
                this.button.left_arrow.Position(2) 40 20];
            
            %cluster control panel
            this.panel.cluster_control = uipanel('Parent',this.panel.control,'Title','Cluster controls','FontWeight','bold');
            this.editfield.number_of_clusters = uieditfield(this.panel.cluster_control,'numeric','Limits', [0 Inf],'Enable','on','Editable','off');  
            this.label.number_of_clusters = uilabel(this.panel.cluster_control,'Text','no. clusters:' );
            this.editfield.number_of_cells_per_cluster = uieditfield(this.panel.cluster_control,'numeric','Limits', [0 Inf],'Enable','on','Editable','on','ValueChangedFcn',@(editfield,event) this.number_of_cells_per_cluster_editfieldChanged()); 
            this.label.number_of_cells_per_cluster = uilabel(this.panel.cluster_control,'Text','cells/cluster:' );
            %this.button.reset = uibutton(this.panel.cluster_control,'push','Text', 'clear points',...
            %   'ButtonPushedFcn', @(button,event) this.reset_button_pushed());
            this.button.cluster = uibutton(this.panel.cluster_control,'push','Text', 'cluster','ButtonPushedFcn', @(button,event) this.cluster_button_pushed());
            this.editfield.cell_count = uieditfield(this.panel.cluster_control,'numeric','Limits', [0 Inf],'Enable','on','Editable','off');
            this.label.cell_count = uilabel(this.panel.cluster_control,'Text','cell count:' );
            this.editfield.spiral_diameter = uieditfield(this.panel.cluster_control,'numeric','Limits', [5 100],'Enable','on','Editable','on'); 
            this.label.spiral_diameter = uilabel(this.panel.cluster_control,'Text','spiral diam.:' );
            this.button.load_masks_image = uibutton(this.panel.cluster_control,'push','Text', 'load masks','ButtonPushedFcn', @(button,event) this.load_masks_image_button_pushed());
            this.button.load_boundary_image = uibutton(this.panel.cluster_control,'push','Text', 'load zones','ButtonPushedFcn', @(button,event) this.load_boundary_image_button_pushed());
            
            this.button.load_masks_image.Position    = [5 6  80 20];
            this.button.load_boundary_image.Position = [92 6 80 20];
            
            this.panel.cluster_control.Position                  = [5 396 190 145];
            
            this.editfield.number_of_clusters.Position           = [74 77 40 20];
            this.label.number_of_clusters.Position               = [5 80 70 15];
            this.editfield.number_of_cells_per_cluster.Position  = [74 55 40 20];
            this.label.number_of_cells_per_cluster.Position      = [5  59 70 15];
            this.editfield.cell_count.Position                   = [74 99 40 20];
            this.label.cell_count.Position                       = [5 98 70 20];         
            %this.button.reset.Position                           = [5 5 90 20];
            this.button.cluster.Position                         = [119 77 65 20];
            this.editfield.spiral_diameter.Position              = [74 33 40 20];
            this.label.spiral_diameter.Position                  = [5  33 65 20];
            
            %interface panel
            this.panel.interface = uipanel('Parent',this.panel.control,'Title','Interface','FontWeight','bold');
            this.panel.interface.Position = [5 5 190 170];
            this.interface_textarea = uitextarea(this.panel.interface,'Editable','off'); 
            this.interface_textarea.Position = [5 30 180 115];
            this.button.finish = uibutton(this.panel.interface,'push','Position',[5 6 80 20],'Text', 'export all','ButtonPushedFcn', @(button,event) this.finish_button_pushed());
            
            %power panel
            this.panel.power                = uipanel('Parent',this.panel.control,'Title','Power options','FontWeight','bold');
            this.panel.power.Position       = [5 179 190 213];
            this.table.data                 = readtable([this.gui.file_IO.class_path filesep 'power_table.csv']);
            this.table.uit                  = uitable(this.panel.power,'Data',this.table.data,'ColumnWidth',{'1x','1x'},'ColumnEditable',[true true]);
            this.button.save_power          = uibutton(this.panel.power,'push','Text', 'save power','ButtonPushedFcn', @(button,event) this.save_power_button_pushed());
            this.editfield.power_per_cell   = uieditfield(this.panel.power,'numeric','Limits', [0 10],'Enable','on','Editable','on'); 
            this.label.power_per_cell       = uilabel(this.panel.power,'Text','mW/cell:');
            this.table.uit.Position                = [2 10 (this.panel.power.Position(3)/1.8) this.panel.power.Position(4)-27];
            this.button.save_power.Position        = [this.table.uit.Position(1)+this.table.uit.Position(3)+6 131 70 20];
            this.editfield.power_per_cell.Position = [this.button.save_power.Position(1) ...
                                                      this.button.save_power.Position(2)+this.button.save_power.Position(4)+5 ...
                                                      70 20];
            this.label.power_per_cell.Position     = [this.button.save_power.Position(1) this.editfield.power_per_cell.Position(2)+this.editfield.power_per_cell.Position(4) ...
                                                        55 20];
            %initialize power object
            this.gui.power.units        = table2array(this.table.data(:,'units'));
            this.gui.power.mW           = table2array(this.table.data(:,'mW'));
            [~,max_index]               = max(this.gui.power.units);
            this.gui.power.units        = this.gui.power.units(1:max_index);
            this.gui.power.mW           = this.gui.power.mW(1:max_index);
            this.gui.power.interp_units = 1:this.gui.power.units(end);
            this.gui.power.interp_mW    = interp1(this.gui.power.units,this.gui.power.mW,this.gui.power.interp_units,'spline');

%             figure(1)
%                 plot(this.gui.power.units,this.gui.power.mW,'o-')
%                 hold on
%                 plot(this.gui.power.interp_units,this.gui.power.interp_mW,'.')
            
            %initialize display object
            this.display.main_img = imshow(squeeze(this.gui.display.img(:,:,1,:)),'Colormap',[],'Parent', this.ax1);
            hold(this.ax1,'on')
            
            this.display.current_point             = [];
            this.display.move_point                = 0;
            this.display.moving_point_index        = [];
            this.display.plot_handles.zone_txt     = text(this.ax1,repmat([NaN],[this.defaults.max_zones 1]), repmat([NaN],[this.defaults.max_zones 1]), repmat({''},[this.defaults.max_zones 1]),'Color',[1 1 1]);
            this.display.plot_handles.points1      = scatter(this.ax1,NaN,NaN,'+','SizeData',100,'LineWidth',1); 
            this.display.plot_handles.points2      = scatter(this.ax1,NaN,NaN,'o','SizeData',40,'LineWidth',1); 
            this.display.plot_handles.moving_point = scatter(this.ax1,NaN,NaN,'+','MarkerEdgeColor',this.defaults.point_color,'SizeData',100,'LineWidth',1);

            
            this.display.main_img.ButtonDownFcn                  = @this.display_clicked; %required for clicking on image?
            this.display.masks.ButtonDownFcn                     = @this.display_clicked;
            this.display.plot_handles.points1.ButtonDownFcn      = @this.display_clicked; %required for picking up / deleting points?
            this.display.plot_handles.points2.ButtonDownFcn      = @this.display_clicked; %required for picking up / deleting points?
            this.display.plot_handles.moving_point.ButtonDownFcn = @this.display_clicked;
            
            for i = 1:this.defaults.max_zones
                this.display.plot_handles.zone_txt(i).ButtonDownFcn       = @this.display_clicked;
                this.display.plot_handles.zone_txt(i).HorizontalAlignment = 'center';
                this.display.plot_handles.zone_txt(i).FontSize            = 12;
            end
            
            %search window for callbacks
            this.display.x_search = [0 this.gui.main_image.dim(2) this.gui.main_image.dim(2) 0];
            this.display.y_search = [0 0 this.gui.main_image.dim(1) this.gui.main_image.dim(1)];
            
            %introduce yourself
            this.interface_textarea.Value = '_____________________';
            this.update_textarea          ('|          SLM Targets          |');
            this.update_textarea           ('¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯')
            this.update_textarea('Author: Spencer T. Brown')
            this.update_textarea('last update: 07/10/2022')
            
            % start
            this.initialize_gui_controls();
            this.initiate_experiment();
            set(this.f,'visible','on');
            
        end
    end
    
    methods (Access = private)
        
        function menu_exportImg(this,src,event)
            
            %number_of_digits = length(num2str(size(this.gui.display.img,3)));
            cd(this.gui.file_IO.experiment_dir);
            
            filename = 'display_image.tif';
            
            for i = 1:size(this.gui.display.img,3)
                %filename = ['display_image' sprintf(['%0' num2str(number_of_digits) 'd'],i-1) '.tif'];
                img = double(squeeze(this.gui.display.img(:,:,i,:)))*(255/65535);
                if i == 1
                    imwrite(uint8(img),filename);
                else
                    imwrite(uint8(img),filename,'WriteMode','append');
                end
                    
            end
            this.update_textarea(['• display image saved'])

        end
        
        
        function change_image_arrow_button_pushed(this,src,event)
            
            if strcmp(src.Text,'>')
                this.gui.main_image.current_idx = this.gui.main_image.current_idx + 1;
            elseif strcmp(src.Text,'<')
                this.gui.main_image.current_idx = this.gui.main_image.current_idx - 1;
            end
            
               
           if this.gui.main_image.current_idx < 1
               this.gui.main_image.current_idx = 1;
           elseif this.gui.main_image.current_idx > this.gui.main_image.num_imgs
               this.gui.main_image.current_idx = this.gui.main_image.num_imgs;
           end
                
           this.update_img();
           this.update_plotted_points();
           
        end
        
        function save_power_button_pushed(this)
            writetable(this.table.uit.Data,[this.gui.file_IO.class_path filesep 'power_table.csv']);
            this.update_textarea(['• power_table.csv saved'])
        end
        
        function menu_save(this,src,event)
            this.save();
        end
        
        function save(this)
            gui = this.gui;
            this.get_gui_state();
            state = this.state;
            save('gui.mat','gui','state');
        end
        
        function menu_load(this,src,event)
            
            [filename path] = uigetfile(pwd);
            cd(path);
            figure(this.f);
            
            try
                load([path 'gui.mat']);
            catch
                return
            end

            this.full_reset();
            gui.file_IO = this.gui.file_IO; %do not use old file_IO properties, use new
            this.gui   = gui;
            this.state = state;
            this.load_gui_state();
            this.update_plotted_points();
            this.boundary_indices(); %required for making zone labels.
            this.make_display_image();
            
        end
        
        function menu_reset(this,src,event)
            this.full_reset();
        end
        
        function full_reset(this)
            this.initialize_gui_objects();
            this.initialize_gui_controls();
            this.reset_display();
            this.initiate_experiment();            
        end
        
        function initialize_gui_objects(this)
            %initialize final io object
            this.gui.file_IO.class_path     = fileparts(which('slmtargets3d.m'));
            this.gui.file_IO.save_path      = [];
            this.gui.file_IO.load_path      = [];
            this.gui.file_IO.filename       = 'blank.tif';
            this.gui.file_IO.experiment_dir = [];
            
            %initialize main image object
            this.gui.main_image.loaded       = 0;
            this.gui.main_image.img          = zeros(512,512,'uint16');
            this.gui.main_image.dim          = size(this.gui.main_image.img);
            this.gui.main_image.num_dim      = numel(this.gui.main_image.dim);
            this.gui.main_image.num_imgs     = 1;
            this.gui.main_image.current_idx  = 1;
            this.gui.main_image.contrast_top = 1;
            this.gui.main_image.z_ready      = 0;
            this.gui.main_image.z_positions  = 0;
            
            
            %initialize masks object
            this.gui.masks.loaded        = 0;
            this.gui.masks.img           = zeros(512,512);
            this.gui.masks.rgb_img       = zeros(512,512,3);
            this.gui.masks.roi_color_idx = [];
            this.gui.masks.roi_pixel_idx = [];
            this.gui.masks.num_rois      = 0;
            this.gui.masks.roi_centroids = [];
            
            %initialize boundary object
            this.gui.boundary.loaded       = 0;
            this.gui.boundary.img          = ones(512,512);
            this.gui.boundary.num_sections = 1;
            this.boundary_indices();                  %get boundary indices
            this.gui.boundary.rgb_img      = ones(512,512,3)*65535;
            this.gui.boundary.cmap         = this.defaults.cmap12;
            
            
            %initialize clusters object
            this.gui.clusters.positions   = [];
            this.gui.clusters.num         = 0;
            this.gui.clusters.yxpb        = []; %[y, x, plane, boundary]
            this.gui.clusters.assignments = [];
            
            %display
            this.gui.display.img      = zeros(512,512,1,3,'uint16');
            
        end
        
        function initialize_gui_controls(this)
            this.editfield.filename.Value                    = '';
            this.button.contrast.Enable                      = 'off';
            this.button.reset_img.Enable                     = 'off';
            this.button.load_masks_image.Enable              = 'off';
            this.button.load_boundary_image.Enable           = 'off';
            this.editfield.z_position_above_focus.Value      = 0;
            this.editfield.z_position_below_focus.Value      = 0;
            this.editfield.z_position_above_focus.Enable     = 'off';
            this.editfield.z_position_below_focus.Enable     = 'off';
            this.editfield.z.Value                           = 0;
            this.editfield.cell_count.Value                  = 0;
            this.editfield.number_of_clusters.Value          = 0;
            this.editfield.number_of_cells_per_cluster.Value = 0;
            this.editfield.spiral_diameter.Value             = 20;
            this.button.finish.Enable                        = 'off';
        end
        
        function get_gui_state(this)
            for i = 1:numel(this.state_objects)
                top_field = this.state_objects{i};
                subfields = fields(this.(top_field));
                for j = 1:numel(subfields)
                    for k = 1:numel(this.state_props)
                        if isprop(this.(top_field).(subfields{j}),this.state_props{k})
                            this.state.(top_field).(subfields{j}).(this.state_props{k}) = this.(top_field).(subfields{j}).(this.state_props{k});
                        end
                    end
                end
            end
        end
        
        function load_gui_state(this)
            for i = 1:numel(this.state_objects)
                top_field = this.state_objects{i};
                subfields = fields(this.(top_field));
                for j = 1:numel(subfields)
                    for k = 1:numel(this.state_props)
                        if isprop(this.(top_field).(subfields{j}),this.state_props{k})
                            this.(top_field).(subfields{j}).(this.state_props{k}) = this.state.(top_field).(subfields{j}).(this.state_props{k});
                        end
                    end
                end
            end
        end
        
        function reset_display(this)
            this.display.main_img.CData = squeeze(this.gui.display.img);
            this.update_plotted_points();
        end
        

        function resizeCallback(this,src,event)
            this.panel.control.Position = [this.f.Position(3)-20-200 20 200 this.f.Position(4)-40];
            this.panel.image.Position   = [20 20 ...
                this.f.Position(3)-this.panel.control.Position(3)-40-8 ...
                this.f.Position(4)-40];
            if this.panel.image.Position(3) <= this.panel.image.Position(4) %shorter width
                image_width = this.panel.image.Position(3)-2;
                image_bottom = (this.panel.image.Position(4)/2) - (this.panel.image.Position(3)/2);
                this.ax1.Position = [1 image_bottom image_width image_width]; 
            else %shorter height
                image_left = (this.panel.image.Position(3)/2) - (this.panel.image.Position(4)/2);
                image_width = this.panel.image.Position(4)-2;
                this.ax1.Position = [image_left 1 image_width image_width];
            end
        end
        
        %button callbacks--------------------------------------------------    
        function initiate_experiment(this)
            
            %make experiment directory
            try
                load([this.gui.file_IO.class_path filesep 'save_path.mat'])
            catch
                save_path = uigetdir;
            end
            
            save([this.gui.file_IO.class_path filesep 'save_path'], 'save_path')
            this.gui.file_IO.save_path = save_path;
            
            cd(this.gui.file_IO.save_path)
            date_dir = date;
            this.cdmkdir(date_dir)
            
            d = dir('SLM_Targets_*');
            
            if isempty(d)
                next_experiment_number = 0;
            else
                newest_experiment       = d(end).name;
                newest_experiment_split = strsplit(newest_experiment,'_');
                next_experiment_number  = str2double(newest_experiment_split{3})+1;
            end
            
            this.gui.file_IO.experiment_dir = [save_path filesep date_dir filesep 'SLM_Targets_' sprintf('%04d',next_experiment_number)];
            this.cdmkdir(this.gui.file_IO.experiment_dir);
            
            this.gui.file_IO.load_path = [this.gui.file_IO.experiment_dir filesep];
            
            %initiate points
            this.initiate_data();
            this.update_z();
            pause(1);
            this.update_textarea('• initiating experiment')
            
        end
        
        function [file_path] = load_image(this)
            
            this.update_textarea('• select an image file')

            [filename file_path] = uigetfile([this.gui.file_IO.load_path '*.tif']);
            
            if ~isnumeric(file_path)
                this.gui.file_IO.load_path = file_path;
            end
            
            file_path = [file_path filesep filename];
            
            figure(this.f);
            
        end
        
        function make_display_image(this)
            
            max_scale = double( max(this.gui.main_image.img(:)) );
            boundary = this.gui.boundary.rgb_img;
            
            %defaults in case masks file not loaded
            masks   = zeros(512,512,3);
            ROI_img = zeros(512,512);

            for i = 1:size(this.gui.display.img,3)
    
                img = double(this.gui.main_image.img(:,:,i));
                
                if this.gui.masks.loaded
                    masks   =  squeeze(this.gui.masks.rgb_img(:,:,i,:));
                    ROI_img = this.gui.masks.img(:,:,i);
                end
                
                ROI_logical   = ROI_img > 0;
                other_logical = ROI_img == 0;

                img_w_ROIs    = img.*(ROI_logical);
                img_no_ROIs = img.*(other_logical);
                
                boundary_alpha = other_logical.*( img / max_scale );
                img_no_ROIs    = boundary.*boundary_alpha;

                combined_img =  img_no_ROIs + (0.6.*img_w_ROIs) + (0.4.*masks);

                this.gui.display.img(:,:,i,:) = combined_img;

            end
            
            this.update_img();
            
        end
        
        function load_image_button_pushed(this,src,event)
           
            try
               file_path = this.load_image();
               img = read_image(file_path); 
            catch
                return;
            end

            if size(img,1) ~= 512 || size(img,2) ~= 512
                this.update_textarea('WARNING: image dimensions are not 512x512.');
                return;
            end
            
            if this.gui.main_image.loaded
                if ~isequal(size(this.gui.main_image.img),size(img))
                    this.update_textarea('WARNING: image dimensions do not match currently loaded image.');
                    return;
                end
                
                
            end
            
            this.gui.main_image.img       = img;
            this.gui.main_image.orig_img  = this.gui.main_image.img;
            this.gui.main_image.num_imgs  = size(this.gui.main_image.img,3);
            this.editfield.filename.Value = file_path;
            
            if length(size(this.gui.main_image.img)) < 3
                this.gui.display.img = zeros([size(this.gui.main_image.img) 1 3],'uint16');
            else
                this.gui.display.img = zeros([size(this.gui.main_image.img) 3],'uint16');
            end
            
            if numel(size(this.gui.main_image.img)) == this.gui.main_image.num_dim
                %do nothing
            else
                %update this.number_of_image_dimensions with new dimensions and reset data
                this.gui.main_image.num_dim = numel(size(this.gui.main_image.img));
                this.gui.main_image.current_idx = 1;
                this.reset_data();
            end

            %update ui elements
            if this.gui.main_image.num_imgs > 1
                this.enable_disable_z_range_editfields('on');
            else
                this.enable_disable_z_range_editfields('off');
            end
            
            this.button.contrast.Enable            = 'on';
            this.button.reset_img.Enable           = 'on';
            this.button.load_masks_image.Enable    = 'on';
            this.button.load_boundary_image.Enable = 'on';
            this.update_textarea(['loaded image file: ' this.editfield.filename.Value]);
            
            this.make_display_image();
            this.update_plotted_points();
            this.gui.main_image.loaded  = 1;
            
        end 
        
        
        function load_boundary_image_button_pushed(this)
            
            try
               img = double(read_image(this.load_image())); 
            catch
                return;
            end
             
             this.gui.boundary.loaded                = 1;
             this.gui.boundary.img                   = img;
             this.gui.boundary.num_sections          = double(max(this.gui.boundary.img(:)));
             this.boundary_indices();
             this.gui.boundary.rgb_img               = ones(512,512,3);
             this.set_boundary_layer_colors();
             this.add_boundary_labels2pts();
             this.make_display_image();
        end
        
        function set_boundary_layer_colors(this)
            
            red   = this.gui.boundary.rgb_img(:,:,1);
            green = this.gui.boundary.rgb_img(:,:,2);
            blue  = this.gui.boundary.rgb_img(:,:,3);
            
            for i = 1:this.gui.boundary.num_sections
                red(this.gui.boundary.idx{i})   = this.gui.boundary.cmap(i,1);
                green(this.gui.boundary.idx{i}) = this.gui.boundary.cmap(i,2);
                blue(this.gui.boundary.idx{i})  = this.gui.boundary.cmap(i,3);
            end
            
            this.gui.boundary.rgb_img(:,:,1) = red;
            this.gui.boundary.rgb_img(:,:,2) = green;
            this.gui.boundary.rgb_img(:,:,3) = blue;
            
            this.gui.boundary.rgb_img = this.gui.boundary.rgb_img*65535;
            
            this.update_img();
            
        end
        
        function boundary_indices(this)
            
            this.gui.boundary.idx = {};
            
            for i = 1:this.defaults.max_zones
                 this.display.plot_handles.zone_txt(i).Position = [NaN NaN NaN];
                 this.display.plot_handles.zone_txt(i).String = '';
            end
            
            for i = 1:this.gui.boundary.num_sections
                 
                 [idx] = find(this.gui.boundary.img == i);
                 
                 this.gui.boundary.idx = [this.gui.boundary.idx; idx(:)];
                 
                 [y x] = ind2sub(size(this.gui.boundary.img),idx);

                 if this.gui.boundary.loaded
                     this.display.plot_handles.zone_txt(i).Position = [mean(x) mean(y) 0];
                     this.display.plot_handles.zone_txt(i).String   = ['zone ' num2str(i)];
                 end
                 
            end
             
            
            
        end
        
        function add_boundary_labels2pts(this)
            
            sizeBoundary = size(this.gui.boundary.img);

            if this.editfield.cell_count.Value > 0
                
                for i = 1:numel(this.gui.data.plane)
                    
                    x = this.gui.data.plane(i).XData;
                    y = this.gui.data.plane(i).YData;
                    
                    if isempty(x)
                        continue
                    end
                    
                    idx = sub2ind(sizeBoundary,y,x);
                    this.gui.data.plane(i).boundary = zeros(size(x));
                    
                    for j = 1:this.gui.boundary.num_sections
                        mem_idx = find( ismember(idx, this.gui.boundary.idx{j}) == 1); % find   
                        this.gui.data.plane(i).boundary(mem_idx,1) = j;
                        for k = 1:numel(mem_idx)
                            this.gui.data.plane(i).CData(mem_idx(k),:)    = this.defaults.cmap32(j,:);
                        end
                    end
                end  
                
                this.update_masks_color();
                this.update_plotted_points();
                
            end
            
        end
        
        function boundary_assignment = assign_point2boundary(this,x,y)
            sizeBoundary = size(this.gui.boundary.img);
            
            idx = sub2ind(sizeBoundary,y,x);

            for j = 1:this.gui.boundary.num_sections
                mem_idx = find( ismember(idx, this.gui.boundary.idx{j}) == 1);    
                
                if sum(mem_idx) > 0
                    boundary_assignment = j;
                    break;
                end
            end
        end
        
        
        function load_masks_image_button_pushed(this)
            
            try
               masks_img = double(read_image(this.load_image())); 
            catch
                return;
            end

            if isequal(size(this.gui.main_image.img),size(masks_img))
                this.gui.masks.img = masks_img;
                this.gui.masks.loaded = 1;
            else
                this.update_textarea('WARNING: mask image size does not match')
                return
            end   
             
            this.gui.masks.num_rois      = double(max(this.gui.masks.img(:)));
            this.gui.masks.roi_pixel_idx = cell(this.gui.masks.num_rois,1);
            this.gui.masks.rgb_img       = zeros([size(this.gui.masks.img(:,:,1)) size(this.gui.masks.img,3) 3]);
            this.gui.masks.roi_centroids = zeros(this.gui.masks.num_rois,3);
            
            all_idx  = find(this.gui.masks.img > 0);
            ROI_name = this.gui.masks.img(all_idx);
            
            size_masks_img = size(this.gui.masks.img);
            
            %clear old masks data
            for i = 1:length(this.gui.data.plane)
                ROI_data = this.gui.data.plane(i).ROI(:);
                del = ~isnan(ROI_data(:,1));
                this.delete_point(del,i);
            end
            
            for i = 1:this.gui.masks.num_rois
               
                [y,x,z] = ind2sub(size_masks_img, all_idx(ROI_name == i));

                this.gui.masks.roi_pixel_idx{i}    = [x(:) y(:) z(:)];
                this.gui.masks.roi_centroids(i,:) = round([mean(x) mean(y) mean(z)]); %simplify with above line
                
                img_index = this.gui.masks.roi_centroids(i,3);
                
                this.gui.data.plane(img_index).XData             = [this.gui.data.plane(img_index).XData; this.gui.masks.roi_centroids(i,1)];
                this.gui.data.plane(img_index).YData             = [this.gui.data.plane(img_index).YData; this.gui.masks.roi_centroids(i,2)];
                this.gui.data.plane(img_index).CData             = [this.gui.data.plane(img_index).CData; this.defaults.point_color];
                this.gui.data.plane(img_index).ROI               = [this.gui.data.plane(img_index).ROI; i];
                this.gui.data.plane(img_index).boundary          = [this.gui.data.plane(img_index).boundary; this.assign_point2boundary(this.gui.masks.roi_centroids(i,1),this.gui.masks.roi_centroids(i,2))]; 
                
            end
            
            this.gui.masks.roi_color_idx = ones(this.gui.masks.num_rois,1);
            this.color_masks();
            this.update_plotted_points();
            this.count_cells();
            
        end
        
        function update_masks_color(this)
            
            if this.gui.masks.loaded == 0
                return
            end
            
            ROI_data  = [];
            for i = 1:length(this.gui.data.plane)
                ROI_data = [ROI_data; this.gui.data.plane(i).ROI(:) this.gui.data.plane(i).CData];
            end
            
            del = isnan(ROI_data(:,1));
            ROI_data(del,:) = [];
            
            [A idx] = sort(ROI_data(:,1));
            ROI_data = ROI_data(idx,:);
            
            this.gui.masks.roi_color_idx = zeros(size(this.gui.masks.roi_color_idx));
            
            for i = 1:size(ROI_data,1)
                ROI = ROI_data(i,1);
                for j = 1:size(this.defaults.cmap32 ,1)
                    if isequal(this.defaults.cmap32(j,:), ROI_data(i,2:4))
                        this.gui.masks.roi_color_idx(ROI) = j;
                        break; 
                    end
                end
            end
            
            this.color_masks();
            
        end
        
        function color_masks(this)
            
            red    = squeeze(this.gui.masks.rgb_img(:,:,:,1));
            green  = squeeze(this.gui.masks.rgb_img(:,:,:,2));
            blue   = squeeze(this.gui.masks.rgb_img(:,:,:,3));
                
            for i = 1:this.gui.masks.num_rois
                
                if this.gui.masks.roi_color_idx(i) > 0
                    color = this.defaults.cmap32 ( this.gui.masks.roi_color_idx(i),:);
                else
                    color = [0 0 0];
                end
                
                x = this.gui.masks.roi_pixel_idx{i}(:,1);
                y = this.gui.masks.roi_pixel_idx{i}(:,2);
                z = this.gui.masks.roi_pixel_idx{i}(:,3);
                
                idx = sub2ind(size(this.gui.masks.img),y,x,z);
                
                red(idx)   = color(1);
                green(idx) = color(2);
                blue(idx)  = color(3);
                
            end
            
            this.gui.masks.rgb_img(:,:,:,1) = red;
            this.gui.masks.rgb_img(:,:,:,2) = green;
            this.gui.masks.rgb_img(:,:,:,3) = blue;
            
            this.gui.masks.rgb_img = this.gui.masks.rgb_img.*65535;
            
            this.make_display_image();
            
        end    
        
        function initiate_data(this)
            this.gui.data = [];
            for i = 1:this.gui.main_image.num_imgs
                this.gui.data.plane(i).XData             = [];
                this.gui.data.plane(i).YData             = [];
                this.gui.data.plane(i).CData             = [];
                this.gui.data.plane(i).ROI               = [];
                this.gui.data.plane(i).boundary          = [];
            end
            this.update_plotted_points();
        end
        
        function reset_data(this)
            this.initiate_data();
            this.count_cells();
            this.button.finish.Enable = 'off';  
        end
        
        function update_img(this)

            this.display.main_img.CData = squeeze(this.gui.display.img(:,:,this.gui.main_image.current_idx,:));
            this.update_z();

        end
        
        function update_textarea(this,text)
            if this.scroll_ready
                this.interface_textarea.Value = this.interface_textarea.Value(1:end-3);
            end
            this.interface_textarea.Value = [this.interface_textarea.Value; text];
            this.interface_textarea.Value = [this.interface_textarea.Value; '  ';'  ';'  '];
            this.scroll_ready = 1;
            scroll(this.interface_textarea,'Bottom')
        end
        
        function update_plotted_points(this)

            fieldnames = {'points1', 'points2'};
            for i = 1:numel(fieldnames)
                this.display.plot_handles.(fieldnames{i}).XData = this.gui.data.plane(this.gui.main_image.current_idx).XData;
                this.display.plot_handles.(fieldnames{i}).YData = this.gui.data.plane(this.gui.main_image.current_idx).YData;
                this.display.plot_handles.(fieldnames{i}).CData = this.gui.data.plane(this.gui.main_image.current_idx).CData;
            end

            
        end
        
        function reset_img_button_pushed(this,src,event)
            
            this.gui.main_image.img = this.gui.main_image.orig_img;
            this.make_display_image();
            this.gui.main_image.contrast_top = 1;
            
        end
        
        function contrast_button_pushed(this,src,event)
            
            this.gui.main_image.contrast_top = this.gui.main_image.contrast_top - 0.005;
            
            for i = 1:this.gui.main_image.num_imgs
                this.gui.main_image.img(:,:,i) = imadjust(this.gui.main_image.img(:,:,i), stretchlim(this.gui.main_image.img(:,:,i),[0.01 this.gui.main_image.contrast_top]));
            end
            
            if this.gui.main_image.contrast_top < 0.01
                this.gui.main_image.contrast_top = 0.01;
            end
            
            this.make_display_image();
            
        end
        
        function cluster_points = get_cluster_points(this,cluster_id)
            cluster_indices = (this.gui.clusters.assignments == cluster_id);
            cluster_points = this.gui.clusters.yxpb(cluster_indices,:);
        end
        
        function finish_button_pushed(this,src,event)
            
            this.update_z();
            if ~this.gui.main_image.z_ready
                this.update_textarea('WARNING: cannot export because z range is not specified.')
                return
            end
            
            this.update_textarea('• exporting files')
            %1. generate phase masks
            
            cd(this.gui.file_IO.experiment_dir);
            disp([this.gui.file_IO.experiment_dir])
            this.delete_dir_contents(this.gui.file_IO.experiment_dir);

            
            clusters = [];
            z_range = [this.editfield.z_position_above_focus.Value this.editfield.z_position_below_focus.Value];
            
            %initialize zone struct
            for i = 1:this.gui.boundary.num_sections
                zone(i).galvo.x         = [];
                zone(i).galvo.y         = [];
                zone(i).num_cells       = [];
            end
            
            for i = 1:this.gui.clusters.num
                
                this.update_textarea(['cluster ' num2str(i) ':'])
                cluster_points = this.get_cluster_points(i);
                
                orig_img      = zeros(size(this.gui.main_image.img));
                x             = this.gui.clusters.positions(i).img.x;
                y             = this.gui.clusters.positions(i).img.y;
                z             = this.gui.clusters.positions(i).plane;
                idx           = sub2ind(size(orig_img),y,x,z);
                orig_img(idx) = 1;
                
                target_img = zeros(size(this.gui.main_image.img));
                x          = this.gui.clusters.positions(i).slm.x;
                y          = this.gui.clusters.positions(i).slm.y;
                z          = this.gui.clusters.positions(i).plane;
                boundary   = this.gui.clusters.positions(i).boundary(1);
                
                idx = sub2ind(size(target_img),y,x,z);
                target_img(idx) = 1;
                    
                zone_dir = ['zone' num2str(boundary)];
                file_id = ['cluster' num2str(i) 'zone' num2str(boundary)];
                
                %orig targets
                this.cdmkdir('ImageTargets');
                this.cdmkdir(zone_dir);
                TiffWriter2(uint8(orig_img*255),[file_id '_ImageTargets.tif'],8,0);
                this.update_textarea(['✓ image targets saved'])
                cd(this.gui.file_IO.experiment_dir);
                
                %input targets
                this.cdmkdir('SLMTargets');
                this.cdmkdir(zone_dir);
                TiffWriter2(uint8(target_img*255),[file_id '_InputTargets.tif'],8,0);
                this.update_textarea(['✓ input targets saved'])
                cd(this.gui.file_IO.experiment_dir);
                
                %phase masks
                this.cdmkdir('PhaseMasks')
                this.cdmkdir(zone_dir);
               [phase_mask, transformed_img] = phasemask_3D(target_img, 'Transform','3D','AdjustWeights','yes','ZRange',z_range); %will have to modify this so it can take either single or multiplane images
                imwrite(uint8(phase_mask),[file_id '_PhaseMask.tif']);
                this.update_textarea(['✓ phase masks saved'])

                cd(this.gui.file_IO.experiment_dir);
                
                %transformed targets
                this.cdmkdir('TransformedSLMTargets')
                this.cdmkdir(zone_dir);
                TiffWriter2(uint8(transformed_img*255),[file_id '_TransformedTargets.tif'],8,0);
                this.update_textarea(['✓ transformed targets saved'])
                cd(this.gui.file_IO.experiment_dir);
                
                zone(boundary).galvo.x    = [zone(boundary).galvo.x;   this.gui.clusters.positions(i).galvo.x];
                zone(boundary).galvo.y    = [zone(boundary).galvo.y;   this.gui.clusters.positions(i).galvo.y];
                zone(boundary).num_cells  = [zone(boundary).num_cells; numel(this.gui.clusters.positions(i).slm.x)];
                
            end
            
            this.cdmkdir('PrairieView')

            for i = 1:length(zone)
                
                if isempty(zone(i).galvo.x)%temp fix!!!!!!!!!!!!!!!!
                    continue
                end
                
                this.update_textarea(['zone ' num2str(i) ':'])
                zone_dir = ['zone' num2str(i)];
                this.cdmkdir(zone_dir);
                
                %make .gpl
                 [~] = MarkPoints_GPLMaker(zone(i).galvo.x, zone(i).galvo.y, 'True' , this.editfield.spiral_diameter.Value, 3, zone_dir);
                this.update_textarea(['✓ PrairieView .gpl saved']);
                
                %make .xml
                num_masks      = numel(zone(i).galvo.x);
                ayncSyncFreq   = repmat({'First Repetition'},[num_masks*2 1]);
                trigFreq       = repmat({'Never'},[num_masks*2 1]); 
                trigFreq{1}    = 'First Repetition';
                points         = {};
                power          = [];
                repetitions    = [];
                duration       = [];
                voltageOutputExpName = {};
                voltageOutputCatName = {};
                
                for j = 1:num_masks
                    
                    point = ['Point ' num2str(j)];
                    cluster_power  = this.editfield.power_per_cell.Value*zone(i).num_cells(j);
                    [~,idx]        = min(abs(this.gui.power.interp_mW - cluster_power));
                    points         = [points; point];
                    points         = [points; point];
                    power          = [power;  [0; this.gui.power.interp_units(idx)]];
                    repetitions    = [repetitions; [1; 3]];
                    duration       = [duration     [15; 10]];
                    voltageOutputCatName = [voltageOutputCatName; 'Current'];
                    voltageOutputCatName = [voltageOutputCatName; 'None']; 
                    

                end
                
                [~] = MarkPoints_XMLMaker('AddDummy',0, ...
                'Points', points, ... 
                'Repetitions',repetitions, ...
                'UncagingLaserPower', power, ...
                'AsyncSyncFrequency', ayncSyncFreq, ...
                'TriggerFrequency', trigFreq, ...
                'NumRows',num_masks*2,...
                'SaveName',zone_dir,...
                'Duration', duration,...
                'VoltageOutputExperimentName',voltageOutputExpName, ...
                'VoltageOutputCategoryName', voltageOutputCatName);
                this.update_textarea(['✓ PrairieView .xml saved']);
                
                cd ..
                
            end
            
             cd(this.gui.file_IO.experiment_dir);
             clusters = this.gui.clusters.positions;
             save('clusters.mat','clusters')      

             this.save();
        end
        
        function cdmkdir(this,directory)
            try
                cd(directory)
            catch
                mkdir(directory)
                cd(directory)
            end
        end
        
        function delete_dir_contents(this,dir_name)
            
            directories2delete = {'PhaseMasks','SLMTargets','TransformedSLMTargets','ImageTargets','PrairieView'};
            
            dinfo = dir(fullfile(dir_name,'*.*'));
            
            keep = strcmp({dinfo.name},'.') | strcmp({dinfo.name},'..');
            dinfo(keep) = [];
            
            if isempty(dinfo)
                return
            end
            
            for k = 1 : length(dinfo)
                
                thisFile = fullfile(dir_name, dinfo(k).name);
                
                if ~dinfo(k).isdir
                    delete(thisFile);
                end
                
            end
            
            for i = 1:length(directories2delete)
                try
                    rmdir([this.gui.file_IO.experiment_dir filesep directories2delete{i}],'s');
                end
            end
            
            pause(1);
            
        end
        
        function collect_xy_points(this)
            this.gui.clusters.yxpb = [];
            for i = 1:this.gui.main_image.num_imgs
                this.gui.clusters.yxpb = [this.gui.clusters.yxpb; this.gui.data.plane(i).YData(:) this.gui.data.plane(i).XData(:) ones(length(this.gui.data.plane(i).XData),1)*i this.gui.data.plane(i).boundary(:)];
            end
            this.gui.clusters.yxpb = round(this.gui.clusters.yxpb);
        end
        
        function cluster_button_pushed(this,src,event)
            
            if this.editfield.number_of_clusters.Value < 1
                return
            end 
            
            this.update_textarea(['• clustering ' num2str(this.count_cells)  ' cells in x-y space using kmeans'])
            this.collect_xy_points();
            num_iterations = 150;
            equal = 1;
            
            this.gui.clusters.assignments = zeros(size(this.gui.clusters.yxpb,1),1);
            
            for i = 1:this.gui.boundary.num_sections
                
                boundary_idx = this.gui.clusters.yxpb(:,4) == i;
                
                num_cells_in_boundary = sum(boundary_idx);
                if num_cells_in_boundary < 1 %no cells within boundary!
                    continue
                end
                
                num_clusters_in_boundary = num_cells_in_boundary/this.editfield.number_of_cells_per_cluster.Value;
                
                yx = this.gui.clusters.yxpb(boundary_idx,1:2);
                
                if num_clusters_in_boundary <= 1 %less than or equal to 1 cluster in boundary - no clustering necessary
                    cluster_assignments = ones(size(yx,1),1);
                else %more than 1 cluster in boundary
                    [cluster_assignments, centroids, varargout] = ekmeans(yx, ceil(num_clusters_in_boundary), num_iterations, equal);
                end
                
                this.gui.clusters.assignments(boundary_idx,1) = cluster_assignments + max(this.gui.clusters.assignments);
                
            end

            this.gui.clusters.num = max(this.gui.clusters.assignments);
            
            %assign points to color clusters
            for i = 1:this.gui.main_image.num_imgs
                
                plane_indices = (this.gui.clusters.yxpb(:,3) == i);
                color_idx = this.gui.clusters.assignments(plane_indices);
                
                for j = 1:length(color_idx)
                    if color_idx(j) ~= 0
                        this.gui.data.plane(i).CData(j,:) = this.defaults.cmap32(color_idx(j),:);
                    else  
                        this.gui.data.plane(i).CData(j,:) = [1 1 1];
                    end
                end
                
            end
                
            %gather cluster data
            this.gui.clusters.positions = [];
            
            yaml = ReadYaml('settings.yml');
            ZeroOrderSLMCoordinates = [yaml.SLM_Pixels_X/2 yaml.SLM_Pixels_Y/2];
            SLMDimensions = [yaml.SLM_Pixels_X, yaml.SLM_Pixels_Y];
            ZeroOrderSizePixels = yaml.ZeroOrderBlockSize_PX;
            Translate = true;
            OutputType = 'points';
            
            for i = 1:this.gui.clusters.num
                
                cluster_points = this.get_cluster_points(i);
                [OffsetPoints,GroupCentroid,Translation] = zo_block_avoider(cluster_points(:,1:2),...
                    ZeroOrderSLMCoordinates, ZeroOrderSizePixels, SLMDimensions,...
                    Translate, OutputType);
                
                this.gui.clusters.positions(i).img.x     = cluster_points(:,2);
                this.gui.clusters.positions(i).img.y     = cluster_points(:,1);
                this.gui.clusters.positions(i).galvo.x   = GroupCentroid(2);
                this.gui.clusters.positions(i).galvo.y   = GroupCentroid(1);
                this.gui.clusters.positions(i).slm.x     = OffsetPoints(:,2);
                this.gui.clusters.positions(i).slm.y     = OffsetPoints(:,1);
                this.gui.clusters.positions(i).plane     = cluster_points(:,3);
                this.gui.clusters.positions(i).boundary  = cluster_points(:,4);
                
            end
            
            this.update_textarea(['• result: ' num2str(this.gui.clusters.num) ' cluster(s)'])
            this.update_plotted_points();
            
            if this.gui.masks.loaded
                this.update_masks_color();
            end
            this.button.finish.Enable = 'on';
            
        end
        
        function number_of_cells_per_cluster_editfieldChanged(this,src,event)
            
            this.editfield.number_of_cells_per_cluster.Value = round(this.editfield.number_of_cells_per_cluster.Value);
             
            this.count_cells();
            
        end
        
        function reset_cluster_editfields(this)
            this.editfield.number_of_clusters.Value = 0;
            this.editfield.number_of_cells_per_cluster.Value = 0;
        end
        
        function z_range_editfieldsChanged(this,src,event)
            this.update_z();
        end
        
        function update_z(this)
            this.gui.main_image.z_ready = 0; 
            if this.gui.main_image.num_imgs == 1
                this.editfield.z.Value = 0;
                this.gui.main_image.z_ready = 1; %all checks performed.. ready for phase mask generation
                
            else %there is more than 1 image so z can be zero or non-zero
                
                z_distance = sqrt( (this.editfield.z_position_above_focus.Value - this.editfield.z_position_below_focus.Value)^2 );

                if z_distance == 0 %this is impossible if more than one image, so the z range editfields have not been set properly or set at all.
                    this.editfield.z.Value = 0;
                    return
                end

                z_spacing = z_distance / (this.gui.main_image.num_imgs -1);
                
                this.gui.main_image.z_positions = this.editfield.z_position_above_focus.Value:z_spacing:this.editfield.z_position_below_focus.Value; 
                
                if isempty(this.gui.main_image.z_positions) %z range directionality is wrong, should go from less positive / negative to more positive
                    this.editfield.z.Value = 0;
                    return
                end

                this.editfield.z.Value = this.gui.main_image.z_positions(this.gui.main_image.current_idx);
                this.gui.main_image.z_ready = 1; %all checks performed.. ready for phase mask generation    
            end
            
        end
        
        function enable_disable_z_range_editfields(this,action)
            this.editfield.z_position_above_focus.Enable = action;
            this.editfield.z_position_below_focus.Enable = action;
            this.editfield.z_position_above_focus.Value = 0;
            this.editfield.z_position_below_focus.Value = 0;
        end
        
        function cell_count = count_cells(this)
            
            cell_count = 0;
            
            for i = 1:numel(this.gui.data.plane)
                cell_count = cell_count + length(this.gui.data.plane(i).XData);
            end
            
            this.editfield.cell_count.Value = cell_count;
            
            if this.editfield.number_of_cells_per_cluster.Value > this.editfield.cell_count.Value
                
                this.editfield.number_of_cells_per_cluster.Value = this.editfield.cell_count.Value;
                
            end
            
            if cell_count < 2
                this.reset_cluster_editfields();
            end
%             
            this.update_number_of_clusters_editfield();
            
        end
        
        function update_number_of_clusters_editfield(this)
            
            if this.editfield.number_of_cells_per_cluster.Value > 0
                this.editfield.number_of_clusters.Value = this.editfield.cell_count.Value / this.editfield.number_of_cells_per_cluster.Value; 
            else
                this.editfield.number_of_clusters.Value = 0;
            end
            
        end
        
        %point management callbacks----------------------------------------
        function this = KeyPress(this,src,event) %not sure if this does anything... might delete
            
            if event.Key == 'p'
               for i = 1:this.gui.main_image.num_imgs
                   this.gui.main_image.current_idx = i;
                   this.update_img();
                   this.update_plotted_points();
                   pause(0.1);
               end
            end
            
            if this.display.move_point == 1
                this.display.move_point = 0;
            end
            
        end     
        
        function display_clicked(this,src,event) %not sure if this does anything... might delete and simply call point_tool
            this.point_tool(src,event);
        end
        
        function scroll_Callback(this,src,event)
            
            if this.gui.main_image.num_imgs < 2
                return
            end
            
            mousePointax1 = get(this.ax1, 'CurrentPoint');

            if inpolygon(mousePointax1(1,1),mousePointax1(1,2),this.display.x_search,this.display.y_search)

               this.gui.main_image.current_idx = this.gui.main_image.current_idx - event.VerticalScrollCount;
               
               if this.gui.main_image.current_idx < 1
                   this.gui.main_image.current_idx = 1;
               elseif this.gui.main_image.current_idx > this.gui.main_image.num_imgs
                   this.gui.main_image.current_idx = this.gui.main_image.num_imgs;
               end
                
               this.update_img();
               this.update_plotted_points();

            end

        end
        
        
        function point_tool(this,src,event)
            
            
            if this.display.move_point == 1
                this.display.move_point = 0;
                this.add_point(this.display.plot_handles.moving_point.XData,this.display.plot_handles.moving_point.YData);
                this.display.plot_handles.moving_point.XData = [];
                this.display.plot_handles.moving_point.YData = [];
                this.update_plotted_points();
                this.count_cells();
               return; %i.e. clicking any of the mouse buttons will drop the moving point
            end
            
            x = event.IntersectionPoint(1)+0.75;
            y = event.IntersectionPoint(2)-0.4;
            
            switch event.Button
                
                case 1 %add new point
                    this.add_point(x,y);
                    this.button.finish.Enable = 'off';
                    this.update_plotted_points();
                    this.count_cells();
                case 2 %pick up point and begin moving it
                    [x_circ, y_circ] = this.circle_fcn(x,y);
                    in = find(inpolygon(this.gui.data.plane(this.gui.main_image.current_idx).XData, this.gui.data.plane(this.gui.main_image.current_idx).YData, x_circ, y_circ) == 1);
                    
                    if length(in) > 0
                        
                        %check if ROI
                        if isnan(this.gui.data.plane(this.gui.main_image.current_idx).ROI(in)) %is not ROI, can move
                            this.display.moving_point_index = in(1);
                            this.delete_point(this.display.moving_point_index,this.gui.main_image.current_idx);
                            this.update_plotted_points();
                            this.display.move_point = 1;
                            this.button.finish.Enable = 'off';
                            this.hoverCallback();
                        else %is ROI cannot move
                            return
                        end
                        
                    else
                        this.display.moving_point_index = [];
                    end
                    
                case 3 %delete point in close proximity
                    [x_circ, y_circ] = this.circle_fcn(x,y);
                    in = find(inpolygon(this.gui.data.plane(this.gui.main_image.current_idx).XData, this.gui.data.plane(this.gui.main_image.current_idx).YData, x_circ, y_circ) == 1);
                    if isempty(in)
                        %do nothing
                    else
                        this.delete_point(in(1),this.gui.main_image.current_idx);
                        this.button.finish.Enable = 'off';
                        this.update_plotted_points();
                        this.count_cells();
                    end

                otherwise
                    disp('no action associated with this button')
                    
            end
            

            
        end
        
        function delete_point(this,index,img_index)
            this.gui.data.plane(img_index).XData(index)      = [];
            this.gui.data.plane(img_index).YData(index)      = [];
            this.gui.data.plane(img_index).CData(index,:)    = [];
            this.gui.data.plane(img_index).ROI(index)        = [];
            this.gui.data.plane(img_index).boundary(index)   = [];
        end
        
        function add_point(this,x,y)
            x = round(x);
            y = round(y);
            this.gui.data.plane(this.gui.main_image.current_idx).XData             = [this.gui.data.plane(this.gui.main_image.current_idx).XData; x];
            this.gui.data.plane(this.gui.main_image.current_idx).YData             = [this.gui.data.plane(this.gui.main_image.current_idx).YData; y];
            this.gui.data.plane(this.gui.main_image.current_idx).CData             = [this.gui.data.plane(this.gui.main_image.current_idx).CData; this.defaults.point_color];
            this.gui.data.plane(this.gui.main_image.current_idx).ROI               = [this.gui.data.plane(this.gui.main_image.current_idx).ROI; NaN];
            this.gui.data.plane(this.gui.main_image.current_idx).boundary          = [this.gui.data.plane(this.gui.main_image.current_idx).boundary; this.assign_point2boundary(x,y)]; 
        end
        
        function [x_circ, y_circ] = circle_fcn(this,x,y)
            r = 3;
            th = 0:pi/50:2*pi;
            x_circ = r * cos(th) + x;
            y_circ = r * sin(th) + y;
        end
        
        function hoverCallback(this,src,event)
            
            mousePointax1 = get(this.ax1, 'CurrentPoint');
            
            if inpolygon(mousePointax1(1,1),mousePointax1(1,2),this.display.x_search,this.display.y_search)
                this.display.current_point = [mousePointax1(1,1) mousePointax1(1,2)];
            end
            
            if this.display.move_point == 1 
                this.display.plot_handles.moving_point.XData = this.display.current_point(1);
                this.display.plot_handles.moving_point.YData = this.display.current_point(2);
            end
        end
       
  
    end
    
    
end
