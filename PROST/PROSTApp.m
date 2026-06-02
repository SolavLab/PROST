classdef PROSTApp < matlab.apps.AppBase

    % UI components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        TabGroup           matlab.ui.container.TabGroup

        DatasetsTab        matlab.ui.container.Tab
        DatasetList        matlab.ui.control.ListBox
        AddDatasetButton   matlab.ui.control.Button
        DeleteDatasetButton matlab.ui.control.Button

        SamplesTab         matlab.ui.container.Tab
        SamplesTable       matlab.ui.control.Table
        AddRowButton       matlab.ui.control.Button
        DeleteRowButton    matlab.ui.control.Button
        CommitButton       matlab.ui.control.Button

        PlotsTab           matlab.ui.container.Tab
        PlotROSButton      matlab.ui.control.Button
    end

    % App state
    properties (Access = private)
        Analyzer PROST.PROSTAnalyzer
        CurrentDataset string
        Dirty logical = false
    end

    % App lifecycle
    methods (Access = private)

        function startupFcn(app)
            app.Analyzer = PROST.PROSTAnalyzer({});
            app.refreshDatasetList();
        end

        function refreshDatasetList(app)
            names = app.Analyzer.get_dataset_names();
            app.DatasetList.Items = names;
            if ~isempty(names)
                app.DatasetList.Value = names(1);
                app.loadDataset(names(1));
            end
        end

        function loadDataset(app, name)
            app.CurrentDataset = string(name);
            samples = app.Analyzer.get_IPD_samples(name);
            app.SamplesTable.Data = samples;
            app.Dirty = false;
        end

    end

    % Callbacks
    methods (Access = private)

        function DatasetListValueChanged(app, ~)
            app.loadDataset(app.DatasetList.Value);
        end

        function AddDatasetButtonPushed(app, ~)
            answer = inputdlg("Dataset name:");
            if isempty(answer); return; end
            app.Analyzer.add_dataset(answer{1});
            app.refreshDatasetList();
        end

        function DeleteDatasetButtonPushed(app, ~)
            name = app.DatasetList.Value;
            app.Analyzer.delete_dataset(name);
            app.refreshDatasetList();
        end

        function SamplesTableCellEdit(app, ~)
            app.Dirty = true;
        end

        function AddRowButtonPushed(app, ~)
            data = app.SamplesTable.Data;
            data(end+1,:) = missing;
            app.SamplesTable.Data = data;
            app.Dirty = true;
        end

        function DeleteRowButtonPushed(app, ~)
            idx = app.SamplesTable.Selection;
            if isempty(idx); return; end
            app.SamplesTable.Data(idx(1),:) = [];
            app.Dirty = true;
        end

        function CommitButtonPushed(app, ~)
            name = app.CurrentDataset;
            app.Analyzer.delete_samples(name, "all");
            app.Analyzer.add_samples(name, app.SamplesTable.Data);
            app.Dirty = false;
        end

        function PlotROSButtonPushed(app, ~)
            app.Analyzer.plot_ros(app.CurrentDataset);
        end

    end

    % Component construction
    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure('Name','PROST GUI');
            app.TabGroup = uitabgroup(app.UIFigure);

            % Datasets tab
            app.DatasetsTab = uitab(app.TabGroup,'Title','Datasets');
            app.DatasetList = uilistbox(app.DatasetsTab,...
                'Position',[10 60 200 300],...
                'ValueChangedFcn',@app.DatasetListValueChanged);

            app.AddDatasetButton = uibutton(app.DatasetsTab,...
                'Text','Add',...
                'Position',[10 20 90 30],...
                'ButtonPushedFcn',@app.AddDatasetButtonPushed);

            app.DeleteDatasetButton = uibutton(app.DatasetsTab,...
                'Text','Delete',...
                'Position',[120 20 90 30],...
                'ButtonPushedFcn',@app.DeleteDatasetButtonPushed);

            % Samples tab
            app.SamplesTab = uitab(app.TabGroup,'Title','Samples');
            app.SamplesTable = uitable(app.SamplesTab,...
                'Position',[10 60 600 300],...
                'CellEditCallback',@app.SamplesTableCellEdit);

            app.AddRowButton = uibutton(app.SamplesTab,...
                'Text','Add Row',...
                'Position',[10 20 90 30],...
                'ButtonPushedFcn',@app.AddRowButtonPushed);

            app.DeleteRowButton = uibutton(app.SamplesTab,...
                'Text','Delete Row',...
                'Position',[110 20 90 30],...
                'ButtonPushedFcn',@app.DeleteRowButtonPushed);

            app.CommitButton = uibutton(app.SamplesTab,...
                'Text','Commit',...
                'Position',[520 20 90 30],...
                'ButtonPushedFcn',@app.CommitButtonPushed);

            % Plots tab
            app.PlotsTab = uitab(app.TabGroup,'Title','Plots');
            app.PlotROSButton = uibutton(app.PlotsTab,...
                'Text','Plot ROS',...
                'Position',[10 20 100 30],...
                'ButtonPushedFcn',@app.PlotROSButtonPushed);
        end
    end

    % App constructor
    methods (Access = public)

        function app = PROSTApp
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)
        end

    end
end
