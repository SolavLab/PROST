function save_all_open_figures(file_path)       
    if nargin == 0
        file_path = "./figures/ROS Analysis";
    end
   
    % Save figures
    fig_handles = findall(0, 'Type', 'figure');
    disp("Saving figures...")
    for k = 1:numel(fig_handles)
        f = fig_handles(k);
        file_name = sprintf('%s.png', f.Name);
        if isempty(dir(file_path))
            mkdir(file_path);
        end
        exportgraphics(f, fullfile(file_path, file_name), 'Resolution',300); % 300 DPI
    end
end
