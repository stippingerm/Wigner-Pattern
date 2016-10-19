%TEMPLATE4GPFA This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4batch
%
% Marcell Stippinger, 2016

%directory
settings.basepath        = '~/marcell/_Data_PassiveViewing/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '(.*)_MUA\.mat';
settings.paradigm        = 'viewing';

%dataset
settings.animal          = 5;
settings.debug           = false;

%interval in the viewing to analyze (specific to passive viewing)
%viewing: start trans_on view trans_off end - indexed by pos. integers
settings.section.in      = 1;
settings.section.out     = 5;
%viewing: whole
settings.namevar         = 'view';


%data binning and filtering of silent neurons
settings.bin_size            = 0.01; %duration (s)
settings.minFiringRate       = 0.5; %minimium firing rate (Hz)
settings.medianFiringRate    = 0.1;
settings.filterParametrization = 'auto'; % specific to viewing
settings.channelsFromDB      = true; % specific to viewing

% GPFA training
settings.showpred        = false; %show predicted firing rate
settings.filterTrials    = false; % filter trails with irregular spike count?
settings.testTrial       = 10;
settings.train           = 0; %redo training
settings.nFolds          = 3; %CV folds
settings.zDim            = 10; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit 
