%GPFA4BATCH This script collects the channels allowed for evaluation
%
%        DESCRIPTION: This script uses a settings file (see template) to
%        set the parameters for the database and the GPFA model. It first
%        discovers all available data files then loads the selected one
%        using the database-specific function given in the settings. Then
%        it fits a GPFA model with the given parameters (latent dimension,
%        etc.) and saves the results.
%
%Version 1.0 Marcell Stippinger, 2016.


clc, close all; %clear all

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4viewSectionSettings.m';
end

run(settings_file);
settings.channelsFromDB = false;

%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);

summary = struct([]);
clear summary;

for i_animal = 1:length(animals)
    fprintf('\nSelecting %d: %s\n',i_animal,files{i_animal});

    project     = regexprep(animals{i_animal},settings.pattern,'$1');
    savepath    = [workpath project '/'];
    fn_model    = [project '_' ...
                       name_save_file '_' settings.namevar '_' ...
                       sprintf('%02d',settings.zDim) '.mat'];

    if ~exist(savepath,'dir')
        mkdir(savepath);
    end


    %========================Paramteres and variables==========================
    loader = str2func(sprintf('load_%s',settings.paradigm));
    modeler = str2func(sprintf('model_%s',settings.paradigm));
    [D, inChannels, modelTrials] = loader(files{i_animal}, settings);

    summary.(project) = inChannels;
    
end

for i_animal = 1:length(animals)
    project     = regexprep(animals{i_animal},settings.pattern,'$1');
    fprintf('channels.%s = [ ', project)
    fprintf('%d ', summary.(project)+0)
    fprintf('] == 1; %% %d \n', sum(summary.(project)))
end
