%BRANCH2_CLEANED This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4run
%
% Marcell Stippinger, 2016

%directory
settings.basepath        = '~/marcell/_Data_hc-5/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '.*_BehavElectrData\.mat';
%dataset
settings.animal          = 4;
%section in the maze to analyze (specific to HC-5)
settings.section.in      = 'wheel';
settings.section.out     = 'wheel';
settings.debug           = false;
settings.namevar         = 'wheel';
%segmentation and filtering of silent neurons
settings.bin_size        = 0.04; %duration (s)
settings.min_firing      = 0.5; %minimium firing rate (Hz)
settings.median_firing   = 0.1;
settings.interneuron_allowed = false;

settings.filterTrails    = false; % filter trails with irregular speed/spike count?
% GPFA training
settings.n_folds         = 3; %CV folds
settings.zDim            = 10; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit
