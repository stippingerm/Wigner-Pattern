%BRANCH2_CLEANED This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4run
%
% Marcell Stippinger, 2016

%directory
settings.basepath        = '~/marcell/_Data_PassiveViewing/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '(.*_MUA)\.mat';
%dataset
settings.animal          = 5;
%section in the maze to analyze (specific to HC-5)
settings.section.in      = 'run';
settings.section.out     = 'run';
settings.debug           = false;
settings.namevar         = 'run';
%segmentation and filtering of silent neurons
settings.train           = true;
settings.filterParametrization = 'standard';
settings.bin_size        = 0.01; %duration (s)
settings.min_firing      = 0.5; %minimium firing rate (Hz)
settings.median_firing   = 0.1;
settings.interneuron_allowed = false;
settings.filterTrails    = false; % filter trails with irregular speed/spike count?
% GPFA training
settings.showpred        = false; %show predicted firing rate
settings.test_lap        = 10;
settings.n_folds         = 3; %CV folds
settings.zDim            = 10; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit
