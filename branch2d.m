%Branch 2d IDENTIFYING REPLAY EVENTS AFTER ACTIVITY
%
%
%Here the stopping periods after running are analyzed following the
%procedure described in Foster&Wilson 2006 Neuron 36, A spike train was 
%constituted from all spikes (from all cellsin the probe sequence) that 
%occurred during stopping periods while the animal faced in the direction
%in which it had just run. This spike train was then broken between every
%pair of successive spikes separated by more than 50 ms, to form a large 
%set of proto-events. Those proto-events in which at least one-third of 
%the cells in the probe sequence fired at least one spike were then 
%selected as events. The few events longer than 500 ms in duration were 
%rejected as a potential source of spurious correlations. 

clc, close all; clear all;
cd /media/LENOVO/HAS/CODE/Wigner-Pattern

basepath        = '/media/bigdata/';
[files, animals, roots]= get_matFiles(basepath);


%========================Variables of Interest===========================
animal          = 5;
data            = load(files{animal});
clusters        = data.Spike.totclu;
laps            = data.Laps.StartLaps(data.Laps.StartLaps~=0); %@1250 Hz
laps(end+1)     = data.Par.SyncOff;
mazesect        = data.Laps.MazeSection;
events          = data.Par.MazeSectEnterLeft;
Fs              = data.Par.SamplingFrequency;
X               = data.Track.X;
Y               = data.Track.Y;
eeg             = data.Track.eeg;
time            = linspace(0, length(eeg)/1250,length(eeg));
speed           = data.Track.speed;
isIntern        = data.Clu.isIntern;
n_laps          = numel(laps)-1;
[spk, spk_lap]  = get_spikes(clusters, data.Spike.res,laps);
typetrial       = {'left', 'right', 'errorLeft', 'errorRight'};
n_cells         = size(spk_lap,2);
color           = jet(sum(isIntern==0));
removeInh       = true;
%%
% ========================================================================%
%==============   Extract Stopping section after run =====================%
%=========================================================================%

debug           = false; %to show diganostic plots
speed_th        = 200;
%this is to remove/add the section in the middle arm of the maze
sect            = [3 4]; %without middle arm 
sect_in         = [7, 8]; 
sect_out        = [7, 8];
cnt             = 1;
% Extract spks when the mouse is running and in the wheel to calculate
try 
    clear S
end
for lap = 1:n_laps  
    %(a) Runing in the wheel. Detected based on the speed of the wheel that
    %is a better indicator than the EnterSection time stamp
    idx_run                 = [sum(events{lap}(sect,1)), sum(events{lap}(5:6,2))];
    if idx_run(1)>idx_run(2)
        fprintf('WARNING: Lap %d animal gor crazy, skipping\n',lap)
        continue
    end
    idx_stop                = [sum(events{lap}(sect_in,1)), sum(events{lap}(sect_out,2))];
    X_lap{lap}              = X(idx_stop(1):idx_stop(2));
    Y_lap{lap}              = Y(idx_stop(1):idx_stop(2));
    speed_lap               = speed(idx_stop(1):idx_stop(2));
    
    %speed below threshold
    speed_lap(speed_lap<speed_th) = 1;
    speed_lap(speed_lap>=speed_th) = 0;
    
    if debug
        figure(lap)
        plot(speed_lap), hold on
        plot(speed(idx_stop(1):idx_stop(2))./max(speed(idx_stop(1):idx_stop(2))),'r')
    end
    
    if debug
        figure(100)
        plot(X_lap{lap}, Y_lap{lap}, 'color', color(lap,:),...
            'displayname',sprintf('Lap %d',lap))
        hold on       
    end
    %extract regions in which the animal is still
    dist        = diff(speed_lap);
    moved       = -find(dist==1);
    stoped      = find(dist==-1);
    period      = [stoped  moved(1:length(stoped))];
    %select those stoppig periods larger than 1s
    winners     = find(sum(period,2) > 1.0*Fs);
    
    for w = 1:length(winners)
        idx_stop    = [-period(winners(w),2) period(winners(w),1)] + idx_stop(1); 
        
        %spikes
        n_spks_stop  = zeros(1,n_cells);
        n_spks_run   = zeros(1,n_cells);
        c_neu        = 0;
        all_spks     = []; 
        all_spks_id  = []; 
        for neu=1:n_cells
            if isIntern(neu) == 0
                c_neu  = c_neu + 1;

                t_stop = spk_lap{lap,neu}>=idx_stop(1) & spk_lap{lap,neu}<=idx_stop(2);
                %aligned to the start of the section
                n_spks_stop(neu) = sum(t_stop);
                if n_spks_stop(neu) ~= 0
                    t_spks_stop{c_neu} = spk_lap{lap,neu}(t_stop) - idx_stop(1) + 1;
                    all_spks(end+1:end + n_spks_stop(neu))    = t_spks_stop{c_neu};
                    all_spks_id(end+1:end + n_spks_stop(neu)) = c_neu;
                end

                t_run = spk_lap{lap,neu}>=idx_run(1) & spk_lap{lap,neu}<=idx_run(end);
                n_spks_run(neu) = sum(t_run);
                if n_spks_stop(neu) ~= 0
                    %aligned to the start of the section
                    t_spks_run{c_neu} = spk_lap{lap,neu}(t_run) - idx_run(1) + 1;
                end
            end
        end
        S(cnt).t_spks_stop = t_spks_stop;
        S(cnt).t_spks_run  = t_spks_run;
        S(cnt).n_spks_stop = n_spks_stop(isIntern==0);
        S(cnt).n_spks_run  = n_spks_run(isIntern==0);
        S(cnt).TrialId     = lap;
        S(cnt).TrialType   = typetrial{data.Laps.TrialType(laps(lap))};
        S(cnt).TrialTypeNo = data.Laps.TrialType(laps(lap));
        S(cnt).Interval    = idx_stop;
        S(cnt).Dur_stop    = sum(period(winners(w),:));
        S(cnt).Dur_run     = idx_run(end) - idx_run(1);
        S(cnt).Delay       = -period(w,2);
        S(cnt).speed_stop  = speed(idx_stop(1):idx_stop(2));
        S(cnt).speed_run   = speed(idx_run(1):idx_run(2));
        S(cnt).all_spks_stop = [all_spks; all_spks_id];
        cnt                = cnt + 1;
        clear t_* n_sp* all*
    end    
end    
%%
%shows move and stop sequences for control purposes. Saves png of first lap 
t_ids      = [S.TrialId];
unique_tr    = unique(t_ids);
for seq = 1 : 1%length(unique_tr)
   seq_r    = unique_tr(seq); 
   n_events = sum(t_ids == unique_tr(seq));
   figure(seq)
   set(gcf, 'position', [2000 500 1000 500], 'color', 'w'), hold on
   
   %theta
   subplot(1,2 + n_events,[1 2]), hold on
   ele   = find(t_ids==seq_r,1);
   raster(S(ele).t_spks_run)
   plot(S(ele).speed_run./10,'r')
   xlabel(sprintf('Running period lap %d::%s',seq_r,S(ele).TrialType))
   %events
   for n = 1 : n_events
      subplot(1,2 + n_events,2+n), hold on
      raster(S(ele+n-1).t_spks_stop)
      plot(S(ele+n-1).speed_stop./10,'r')
      xlabel('Stopping period')
   end
   drawnow 
end
print(figure(1),[roots{animal} 'Example_Run_stop_spks_lap.png'],'-dpng')

%%
%=========================================================================%
%==============   Extract super vector of spikes     =====================%
%=========================================================================%

%50 ms window to detect disconnected sequences accoding to Foster & Wilson
%60 ms window according to Diba Buszaki 2007
%30% neurons active during hte replay to be considered a replay event 
t_window = 0.05 * Fs;
t_max    = 0.5 * Fs;
n_mincell= 0.3 * sum(isIntern==0); %minimm number of cells active to be 
                                   %replay preplay considered a event
                                   %#TODO: this number is only counting place cells!!

figure(2)
set(gcf,'position',[1988,447,1826,102],'color','w')

for seq = 1 : 1%length(S)
    
    %super spike
    [s_spk,idx]    = sort(S(seq).all_spks_stop(1,:));
    s_spk(2,:)     = S(seq).all_spks_stop(2,idx);
    % show super vector       
    for s = 1 : length(s_spk)
       line(s_spk(1,s)*[1 1],[0 0.8],'color',color(s_spk(2,s),:),'linewidth',2)         
    end
    % calculate distances between spikes in super vector and show those
    %larger than 50 ms;
    dist_s     = diff(s_spk(1,:));
    dist_proto = find(dist_s>t_window);
    
    for p = 1 : length(dist_proto)
        proto_int(:,p) = [s_spk(1,dist_proto(p)) s_spk(1,dist_proto(p)+1)];
        line([s_spk(1,dist_proto(p)) s_spk(1,dist_proto(p)+1)],[0.5 0.5],'color','k','linewidth',2) 
        line(s_spk(1,dist_proto(p))*[1 1],[0.45 0.55],'color','k','linewidth',2)
        line(s_spk(1,dist_proto(p)+1)*[1 1],[0.45 0.55],'color','k','linewidth',2)
    end
    %proto event has to be withing 500 ms. % odd values are disntace
    %within event
    len_proto = diff(proto_int(:)); 
    %interval that fullfils the criteria
    st_pnt_silent  = proto_int(1:2:end);
    en_pnt_silent  = proto_int(2:2:end);
    p_eve          = find(len_proto(2:2:end)<t_max);   
    
    for p = 1 : length(p_eve)
        
        proto(p,:) = [en_pnt_silent(p_eve(p)) st_pnt_silent(p_eve(p)+1)];
        idx_proto  = find(s_spk(1,:)>=proto(p,1) & s_spk(1,:)<=proto(p,2));
        cell_proto{p} = unique(s_spk(2,idx_proto));   
        
        k = 'm';
        if length(cell_proto{p}) > n_mincell
            k = 'r';
        end
        line([en_pnt_silent(p_eve(p)) st_pnt_silent(p_eve(p)+1)],[0.5 0.5],'color',k,'linewidth',2) 
        line(en_pnt_silent(p_eve(p))*[1 1],[0.45 0.55],'color',k,'linewidth',2)
        line(st_pnt_silent(p_eve(p)+1)*[1 1],[0.45 0.55],'color',k,'linewidth',2)
    end
    
    %at least 30% of cells active in proto event to be consider event
    
end
text(sum(xlim)/4,1,sprintf('Silent periods %d ms',t_window*Fs))
text(sum(xlim)/2,1,'Events (>30% cells active)','color','r')
text(3*sum(xlim)/4,1,'Proto Events (<30% cells active)','color','m')
