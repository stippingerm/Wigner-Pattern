%TEMPLATE4GPFA This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4batch
%
% Marcell Stippinger, 2016

%directory
settings.basepath        = '~/marcell/_Data_ubi_hpc/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '(spike_.*)\.dat';
settings.paradigm        = 'synthetic';

%dataset
settings.animal          = 28;
settings.debug           = false;

%segmentation of the run (specific to synthetic data)
settings.nTrials         = 12; % specific to synthetic data: how to split data into trials
%synthetic: run
settings.namevar         = 'run';
settings.filterTrials    = false; % filter trails with irregular speed/spike count?

%data binning and filtering of silent neurons
settings.bin_size            = 0.05; %duration (s)
settings.minFiringRate       = 0.1; %minimium firing rate (Hz)
settings.medianFiringRate    = 0.1;


% GPFA training
settings.showpred        = false; %show predicted firing rate
settings.testTrial       = 10;
settings.train           = 0; %redo training
settings.nFolds          = 3; %CV folds
settings.zDim            = 3; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit 
