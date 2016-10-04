function [ info ] = model_viewing( fn, settings )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

info = load(fn,  'M', 'modelTrials', 'D', 'inChannels', 'settings');
project         = regexprep(fn,'.*/([^_]*).*','$1');

codes = code_table_view();
digits = codes.(project);

nNormalDigit = 10;
nOverrep = 4;

info.decoder  = cell(nNormalDigit, 1);

fields             = fieldnames(info.M);
for i_model = 1:numel(fields)
    field          = fields{i_model};
    id = -1;
    if strncmp(field,'num',3)
        id = str2double(field(4:end));
    end
    if strncmp(field,'ext',3)
        id = nNormalDigit+str2double(field(4:end))*nOverrep;
    end
    
    if id > 0
        prediction = digits(id);
    else
        prediction = -1;
    end
    
    info.M.(field).prediction = prediction;
    
    % NOTE: in the ordering of fields ext01 is after all numXX
    % therefore the more robust model will be used
    if prediction == 0
        prediction = 10;
    end
    if prediction > 0
        info.decoder{prediction} = info.M.(field);
        info.decoder{prediction}.name = field;
    end

end

end

