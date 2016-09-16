function R = reshape_laps(D, max_length)
%RESHAPE_LAPS is a utility to split long laps into smaller units
%             improving the speed of GPFA
%
% Author:
% Marcell Stippinger, 2016

%TODO: implement overlapping splittings to simulate continuity over time

n_laps          = length(D);
separators      = cell(1,n_laps);
n_pieces        = 0;

for i_lap = 1 : n_laps
    lap_length  = D(i_lap).T;
    lap_pieces  = ceil(lap_length*1./max_length);
    n_pieces    = n_pieces + lap_pieces;

    separators{i_lap} = round(linspace(1,lap_length+1,lap_pieces+1));
end

% copy only the field names from D
R               = struct(D(1:0));
n_pieces        = 0;

for i_lap = 1 : n_laps
    lap_sepa    = separators{i_lap};
    lap_pieces  = length(lap_sepa)-1;

    %R(n_pieces+1:n_pieces+lap_pieces) = repmat(D(i_lap),lap_pieces);
    
    for j = 1 : lap_pieces
        R(n_pieces+j) = D(i_lap);
        R(n_pieces+j).T = lap_sepa(j+1)-lap_sepa(j);
        R(n_pieces+j).y = D(i_lap).y(:,lap_sepa(j):lap_sepa(j+1)-1);
    end
    n_pieces = n_pieces + lap_pieces;
end

