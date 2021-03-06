function D = extract_laps(Fs,spk,speed,X,Y,events,isIntern,laps,TrialType,wh_speed)
%EXTRACT LAP Takes the HC-5 database and divides the vectors into laps. more
%            information about the database in
%            crcns.org/files/data/hc-5/crcns-hc5-data-description.pdf
%
%            INPUTS:
%            Fs: sampling frequency (Default: 1250)
%            spk: spikes times
%            speed: speed of the animal in during the whole experiment
%            X:  position of the animal in the x-axis for the whole experiment
%            Y:  position of the animal in the y-axis for the whole experiment
%            events: vector containing the time start/end for each lap and section
%                     in the maze
%            isIntern: boolean vector indicating which neuron is interneuron
%            laps: time of start and end of each lap
%            TrialType: vector indicating the type of each laps options are
%                   1: right alternation, 2: left alt., 3: wrong right alt.
%                   4: wrong left alt.
%
%            wh_speed: speed of the runing wheel
%
%
%see also branch2, branch2_cleaned.m
%Revision:  Dec27: disabled the computation of firing rate to save space in
%                  disk since it is not used.
%Ruben Pinzon@2015


numLaps         = length(events);
n_cells         = size(spk,2);
n_pyrs          = sum(isIntern==0);
kernel          = gausswin(0.1*Fs);
color           = hsv(4);

% Extract spks when the mouse is running 
for lap = 1:numLaps  

    
    idx_lap      = [events{lap}(1,1), events{lap}(end,2)];
    X_lap        = X(idx_lap(1):idx_lap(2));
    Y_lap        = Y(idx_lap(1):idx_lap(2));
    acc_dst      = cumsum(sqrt((X_lap - X_lap(1)).^2 + (Y_lap - Y_lap(1)).^2));
    speed_lap    = speed(idx_lap(1):idx_lap(2));
    wh_speed_lap = wh_speed(idx_lap(1):idx_lap(2));

    
    t_lap        = idx_lap(2) - idx_lap(1) + 1;
    cnt          = 0;
    %firing       = zeros(n_pyrs, t_lap); 
    spk_train    = zeros(n_pyrs, t_lap);
    for neu=1:n_cells
        if ~isIntern(neu)
            tmp              = zeros(1, t_lap); 
            cnt              = cnt + 1;
            
            idx              = spk{lap,neu}>=idx_lap(1) & spk{lap,neu}<=idx_lap(end);
            %aligned to the start of the section            
            spikes_lap{cnt}      = spk{lap,neu}(idx) - idx_lap(1) + 1;
            tmp(spikes_lap{cnt}) = 1; 
            %convolve the spike trains with a gauss filter 100 m
            %firing(cnt,:)    = Fs*conv(tmp,kernel, 'same');
            spk_train(cnt, :) = tmp; 
        end
    end        
   
    %Type of trial
    sections                  = events{lap}-events{lap}(1,1)+1;
    sections(sections<0)      = 0;
    
    D(lap).trialId            = lap;
    D(lap).spikes             = spikes_lap;
    D(lap).X                  = X_lap;
    D(lap).Y                  = Y_lap;
    D(lap).speed              = speed_lap;
    D(lap).wh_speed           = wh_speed_lap;
    D(lap).sections           = sections;
    D(lap).type               = TrialType(laps(lap));
    D(lap).color              = color(TrialType(laps(lap)),:);
    D(lap).acc_dist           = acc_dst;
    %D(lap).firing_rate        = firing;
    D(lap).spike_train        = spk_train;
    D(lap).duration           = idx_lap(2) - idx_lap(1);
    D(lap).start              = events{1}(1,1);
    clear spikes *_lap tmp
end    

