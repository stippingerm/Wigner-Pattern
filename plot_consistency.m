function result = plot_consistency(events, cvdata, spikes, Fs, settings, varargin)
%PLOTCONSISTENCY is an auxiliary function to plot the firing and log Likelihood
%           and display the real class and predicted classification of events.
%
%           INPUTS:
%           P           : DataHigh type struct of dimension (1 x num events)
%           models      : cell containing trained GPFA models with dimension (1 x num models)
%
%           OPTIONS:
%           scaleK      : scale GPFA kernel (scale the speed of internal dynamics)
%           scaleRate   : scale the firing rate
%           useAllTrials: evaluate both training and test trials
%
%           OUTPUT:
%           stats       : a struct with dimensions (1 x folds) including the fields
%                       conf_matrix, class_output, real_label, and posterior, which are
%                       the classification confusion matrix where positive samples correspond
%                       to right alternations whereas negative samples are left alternations;
%                       output of the classifier {1:right, 2:left}, real label, and the
%                       log posterior P(data|model).%
%see also branch2, branch2_cleaned.m
%Stippinger Marcell, 2016

nlaps = length(events);

% Construct blurring window.
gaussFilter = gausswin(3);
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.

quantiles = [0.025 0.25 0.50 0.75 0.975];

%tot_times = (1:length(varargin{1}))/Fs;
tot_likelihood = [];

fig = figure('position',[100,100,1536,512]);

ax1 = subplot(1,6,1:5);
hold on
ax2 = subplot(1,6,6);
hold on

for ilap = 1 : nlaps
    lap_likelihood = cvdata(ilap).likelihood;
    lap_tolerance = cvdata(ilap).tolerance;
    lap_rate = sum(settings.bin_size * spikes(ilap).y .^ 2,1);

    % Do the blur.
    %smoothedVector = conv(lap_rate, gaussFilter, 'same');
    smoothedVector = lap_rate;

    T = length(lap_likelihood);
    lap_time_grid = events{ilap}(1,1)/Fs + (1:T)*settings.bin_size;

    h1 = plot(ax1, lap_time_grid,lap_likelihood,'k-','DisplayName','logLike');
    hold on
    h2 = plot(ax1, lap_time_grid,smoothedVector,'g-','DisplayName','Spike Count');
    plot(ax1, lap_time_grid,lap_likelihood-0.5*lap_tolerance,'k-');
    plot(ax1, lap_time_grid,lap_likelihood+0.5*lap_tolerance,'k-');
    tot_likelihood = [tot_likelihood; lap_likelihood];
    if ilap == 1
        hvector = [h1, h2];
    end
end

xlabel(ax1,'Time (s)');
ylabel(ax1, 'Log likelihood  &  Spike frequency');

tot_class = zeros(size(tot_likelihood));
result = struct('all_mean', []);

state.all = ones(length(tot_likelihood),1)>0;
tot_times = (1:length(tot_likelihood)).*settings.bin_size;
Xtra = length(varargin);
if Xtra > 2
    win = varargin{3};
else
    win = 1;
end
if Xtra>0
    state.spw = varargin{1} & true;
    state.spk = ~conv(state.spw+0,ones(win,1),'same');
    state.replay = varargin{1} == 1;
    state.incons = varargin{1} == 2;
else
    state.spw = ones(length(tot_likelihood),1)<1;
    state.spk = ones(length(tot_likelihood),1)<1;
    state.repaly = ones(length(tot_likelihood),1)<1;
    state.incons = ones(length(tot_likelihood),1)<1;
end

varname = { 'all', 'spk', 'spw', 'replay', 'incons' };
dispname = { 'All activity', 'Normal spiking', 'Sharp wave', 'Replay', 'Inconsistent' };
plotrow = { NaN, NaN, 1, 2, 3};
linetype = { 'ks', 'k.', 'c+', 'bo', 'rx' };

for i = 1:length(varname)
    sel = find(state.(varname{i}));
    if ~isnan(plotrow{i})
        h = plot(ax1, tot_times(sel),-5*plotrow{i}*ones(size(sel)),...
            linetype{i},'DisplayName',dispname{i});
        hvector = [hvector, h];
    end

    tot_class(sel) = i;
    result.([ varname{i} '_quan']) = quantile(tot_likelihood(sel),quantiles);
    result.([ varname{i} '_mean']) = nanmean(tot_likelihood(sel));
    result.([ varname{i} '_stdev']) = nanstd(tot_likelihood(sel));
    
    errorbar(ax2,i,result.([ varname{i} '_mean']),result.([ varname{i} '_stdev']),...
        linetype{i},'DisplayName',dispname{i});
end

%hAnnotation = get(object_handle,'Annotation');
%hLegendEntry = get(hAnnotation','LegendInformation');
%set(hLegendEntry,'IconDisplayStyle','off')

spwclass = fitcdiscr(tot_likelihood,tot_class);
pred_class = predict(spwclass,tot_likelihood);
result.cm = confusionmat(tot_class,pred_class);

for i = 3:5
    sel = pred_class==i;
    sel = find(sel);
    if ~isempty(sel)
        plot(ax1,tot_times(sel),-20-i*5*ones(size(sel)),linetype{i});
    end
end

hold off
xlim(ax1,[0,240]);
ylim(ax1,[-300,50]);
xlim(ax2,[0,length(varname)+1]);
linkaxes([ax1,ax2],'y');

% WONTFIX: We need to place legend into subplot 2 because subplot 1 spans
% several fields and some Matlab callback function is broken, zoom throws.
hl = legend(ax2, hvector);

