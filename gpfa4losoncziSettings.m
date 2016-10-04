%TEMPLATE4GPFA This script contains settings for GPFA training and procesing
%
%        DESCRIPTION: This script is loaded by gpfa4batch
%
% Marcell Stippinger, 2016
 
%directory
settings.basepath        = '~/marcell/_Data_Losonczi/';
settings.workpath        = '~/marcell/napwigner/work/';
settings.pattern         = '(msa.*)\.mat';
settings.paradigm        = 'losonczi';

%dataset
settings.animal          = 1;
settings.debug           = false;

%phase in the trial to analyze (specific to Losonczi)
%Losonczi phases: water, CS, trace, US, wait
settings.section.in      = 'CS';
settings.section.out     = 'trace';
%Losonczi: whole
settings.namevar         = 'whole';


%data binning and filtering of silent neurons
settings.bin_size            = 0.05; %duration (s)
settings.minFiringRate       = 0.1; %minimium firing rate (Hz)
settings.medianFiringRate    = 0.1;


% GPFA training
settings.showpred        = false; %show predicted firing rate
settings.testTrial       = 10;
settings.train           = 0; %redo training
settings.nFolds          = 3; %CV folds
settings.zDim            = 5; %latent dimension
settings.maxTime         = 0; %maximum segmentation time, 0 if use all
settings.maxLength       = 100; %maximum unsplitted time series length, 0 if no limit 
