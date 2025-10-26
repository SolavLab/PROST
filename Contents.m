% ROSAnalyzer Toolbox
%
% Description:
%   ROSAnalyzer is a MATLAB toolbox designed for unified analysis of multiple
%   datasets containing gait cycle measurements. It includes preprocessing scripts to transform raw
%   data into a standardized format, aggregation logic to combine datasets, and
%   an object-oriented class for analysis and visualization.
%
% Features:
%   - Load and manage multiple transformed datasets (.mat files)
%   - Aggregate datasets into a unified structure
%   - Perform statistical analysis and generate visualizations
%   - Encapsulated private methods for internal computations
%   - Static utility functions for reusable operations
%
% Usage:
%   1. Use preprocessing scripts to convert raw datasets into .mat format.
%   2. Instantiate the main analysis class to load and aggregate datasets.
%   3. Call public methods to analyze and visualize the data.
%
% Example:
%   analyzer = ROSAnalyzer();
%   analyzer.loadDatasets('path/to/mat/files'); --- change
%   analyzer.plotSummary(); --- change
%
% Author: Chen Reichsbouscher
% Version: 1.0
% Date: 07.08.2025