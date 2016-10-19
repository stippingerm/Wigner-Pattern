function [ info ] = model_viewing( fn, settings )
%MODEL_VIEWING loads the saved GPFA model and provides a robst digit
%predictor

info = load(fn,  'M', 'modelTrials', 'D', 'inChannels', 'settings');
project         = regexprep(fn,'.*/([^_]*).*','$1');

codes = code_table_view();
type2digit = codes.(project);

nNormalDigit = 10;
nOverrep = 4;

info.labelField = 'digit';
info.decoder    = cell(nNormalDigit+1, 1);

fields             = fieldnames(info.M);

% build a predictor by scanning and using availabl models
for i_model = 1:numel(fields)
    field          = fields{i_model};
    
    % code of the stimulus
    type = -1;
    if strncmp(field,'num',3)
        type = str2double(field(4:end));
    end
    if strncmp(field,'ext',3)
        type = nNormalDigit+str2double(field(4:end))*nOverrep;
    end
    
    % predicted digit (or model not included into prediction, e.g. all)
    if type > 0
        prediction = type2digit(type);
    else
        prediction = -2;
    end
    
    info.M.(field).prediction = prediction;
    
    % NOTE: in the ordering of fields ext01 is after all numXX
    % therefore the more robust model will be used
    if prediction == 0
        % digit zero must get a valid array index
        prediction = 10;
    end
    if prediction == -1
        % prediction of blanks
        prediction = length(info.decoder);
    end
    if prediction > 0
        info.decoder{prediction} = info.M.(field);
        info.decoder{prediction}.name = field;
    end

end

end

