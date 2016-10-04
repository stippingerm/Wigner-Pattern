%TEMPLATE4GPFA This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4batch
%
% Marcell Stippinger, 2016

%directory
settings.basepath        = '~/marcell/_Data_hc-5/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '(.*)_BehavElectrData\.mat';
settings.paradigm        = 'maze';

%dataset
settings.animal          = 4;
settings.debug           = false;

%section in the maze to analyze (specific to HC-5)
%maze: mid_arm, preturn, turn, lat_arm, reward, delay, wheel
settings.section.in      = 'wheel';
settings.section.out     = 'wheel';
%maze: run, wheel
settings.namevar         = 'wheel';
settings.filterTrials    = false; % filter trails with irregular speed/spike count?

%data binning and filtering of silent neurons
settings.bin_size            = 0.04; %duration (s)
settings.minFiringRate       = 0.5; %minimium firing rate (Hz)
settings.medianFiringRate    = 0.1;
settings.interneuron_allowed = false; % specific to maze

% GPFA training
settings.showpred        = false; %show predicted firing rate
settings.testTrial       = 10;
settings.train           = 0; %redo training
settings.nFolds          = 3; %CV folds
settings.zDim            = 10; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit 
