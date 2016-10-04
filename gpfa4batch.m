%GPFA4BATCH This script contains a general data loading mechanism and the
%        training of the GPFA model along with saving the learned model.
%
%        DESCRIPTION: This script uses a settings file (see template) to
%        set the parameters for the database and the GPFA model. It first
%        discovers all available data files then loads the selected one
%        using the database-specific function given in the settings. Then
%        it fits a GPFA model with the given parameters (latent dimension,
%        etc.) and saves the results.
%
%Version 1.0 Marcell Stippinger, 2016.


clc, close all; %clear all;

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4viewSectionSettings.m';
end

run(settings_file);


%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});

project         = regexprep(animals{settings.animal},settings.pattern,'$1');
savepath        = [workpath project '/'];
fn              = [project '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
if ~exist(savepath,'dir')
    mkdir(savepath);
end

trained         = false;


%========================Paramteres and variables==========================
loader = str2func(sprintf('load_%s',settings.paradigm));
[D, inChannels, modelTrials] = loader(files{settings.animal}, settings);

% FIXME: put gpfaChannels in reshape_laps
% also deal with field names spk_count -> y and duaration -> T

%%
% ========================================================================%
%============== (4)         Train GPFA            ========================%
%=========================================================================%

cluster.MeanFiringRate = mean([D([D.valid]).spike_freq],2);
cluster.MedianFiringRate = median([D([D.valid]).spike_freq],2);

gpfaChannels = (settings.minFiringRate<cluster.MeanFiringRate) & ...
    (settings.medianFiringRate<cluster.MedianFiringRate) & ...
    (inChannels);
fprintf('%d neurons fulfil the criteria for GPFA\n',sum(gpfaChannels));

if settings.filterTrials
    train_laps         = filter_laps(D);
else
    train_laps         = true;
end 

try
    clear M
    fields             = fieldnames(modelTrials);
    for i_model = 1:numel(fields)
        field          = fields{i_model};
        fprintf('%s\n',field);
        M.(field)      = trainGPFA(D, gpfaChannels & inChannels, ...
                                   train_laps & modelTrials.(field), ...
                                   settings.zDim, settings.showpred, ...
                                   settings.nFolds, ...
                                   'max_length', settings.maxLength,...
                                   'spike_field','spike_count');
    end
    
    trained = true;
catch ME
    fprintf('Error training GPFA for %s: %s\n', field, ME.identifier);
    rethrow(ME);
end

%%
% ========================================================================%
%============== (5)    Save / Use saved data      ========================%
%=========================================================================%

if trained
    fprintf('Will save at %s\n', [savepath fn]);
    save([savepath fn], 'M', 'modelTrials', 'D', 'inChannels', 'settings');
    trained = false; %#ok<NASGU>
    if ~isCommandWindowOpen
        exit;
    end
else
    M = info.M; %#ok<UNRCH>
end

