function [codes, channels] = code_table_view()
codes.spontaneous  = [-1];
codes.repetition0  = [0 1 2 3 4 5 6 7 8 9 0 0 0 0 -1];
codes.repetition1  = [0 1 2 3 4 5 6 7 8 9 1 1 1 1 -1];
codes.repetition2  = [0 1 2 3 4 5 6 7 8 9 2 2 2 2 -1];
codes.repetition45 = [0 1 2 3 4 5 6 7 8 9 4 4 4 4 5 5 5 5 -1];
codes.identity     = 1:20;

codes.atoc247a02   = codes.spontaneous;
codes.atoc247a03   = codes.repetition0;
codes.atoc247a04   = codes.repetition0;
codes.atoc247a05   = codes.spontaneous;

codes.atoc248a01   = codes.spontaneous;
codes.atoc248a02   = codes.repetition0;
codes.atoc248a03   = codes.spontaneous;

codes.atoc249a02   = codes.spontaneous;
codes.atoc249a03   = codes.repetition1;
codes.atoc249a04   = codes.spontaneous;

codes.atoc250a02   = codes.spontaneous;
codes.atoc250a03   = codes.repetition1;
codes.atoc250a04   = codes.spontaneous;

codes.atoc277a01   = codes.spontaneous;
codes.atoc277a02   = codes.repetition45;
codes.atoc277a03   = codes.spontaneous;

codes.atoc278a01   = codes.spontaneous;
codes.atoc278a02   = codes.repetition45;
codes.atoc278a03   = codes.spontaneous;


codes.isisc166a03  = codes.spontaneous;
codes.isisc166a04  = codes.repetition1;
codes.isisc166a05  = codes.spontaneous;

codes.isisc169a01  = codes.spontaneous;
codes.isisc169a02  = codes.repetition0;
codes.isisc169a03  = codes.spontaneous;

codes.isisc178a02  = codes.spontaneous;
codes.isisc178a03  = codes.repetition2;
codes.isisc178a04  = codes.spontaneous;

codes.isisc183a04  = codes.spontaneous;
codes.isisc183a05  = codes.repetition2;
codes.isisc183a06  = codes.spontaneous;

codes.isisc204a03  = codes.spontaneous;
codes.isisc204a04  = codes.repetition45;
codes.isisc204a05  = codes.spontaneous;

codes.isisc205a03  = codes.spontaneous;
codes.isisc205a04  = codes.repetition45;
codes.isisc205a06  = codes.spontaneous;

codes.atoc251a01   = codes.identity;
codes.atoc252a02   = codes.identity;
codes.isisc163a01  = codes.identity;
codes.isisc165a04  = codes.identity;


% channels.all         = ones(1,32) == 1;
% channels.atoc        = [ 1 0 1 0 0 1 1 0 0 0 0 1 1 1 0 1 0 1 1 1 0 0 1 0 1 0 1 0 1 1 1 0 ] == 1;
% channels.isis        = [ 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 0 0 0 1 1 0 0 0 1 0 0 1 0 0 ] == 1;
% 
% 
% channels.atoc247a02  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1;
% channels.atoc247a03  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1;
% channels.atoc247a04  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1;
% 
% channels.atoc248a01  = [ 1 0 0 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 0 1 0 1 1 1 1 1 1 ] == 1;
% channels.atoc248a02  = [ 1 0 0 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 0 1 0 1 1 1 1 1 1 ] == 1;
% channels.atoc248a03  = [ 1 0 0 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 0 1 0 1 1 1 1 1 1 ] == 1;
% 
% channels.atoc249a02  = [ 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 1 1 1 0 1 1 0 1 0 1 1 1 1 0 1 ] == 1;
% channels.atoc249a03  = [ 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 1 1 1 0 1 1 0 1 0 1 1 1 1 0 1 ] == 1;
% channels.atoc249a04  = [ 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 1 1 1 0 1 1 0 1 0 1 1 1 1 0 1 ] == 1;
% 
% channels.atoc250a02  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 0 0 1 1 1 1 1 1 1 0 1 1 0 1 1 1 1 0 0 ] == 1;
% channels.atoc250a03  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 0 0 1 1 1 1 1 1 1 0 1 1 0 1 1 1 1 0 0 ] == 1;
% channels.atoc250a04  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 0 0 1 1 1 1 1 1 1 0 1 1 0 1 1 1 1 0 0 ] == 1;
% 
% channels.atoc277a01  = [ 1 1 0 0 0 1 1 0 0 0 0 1 1 1 0 0 0 0 1 1 0 0 0 0 1 0 1 0 0 1 0 0 ] == 1;
% channels.atoc277a02  = [ 1 1 0 0 0 1 1 0 0 0 0 1 1 1 0 0 0 0 1 1 0 0 0 0 1 0 1 0 0 1 0 0 ] == 1;
% channels.atoc277a03  = [ 1 1 0 0 0 1 1 0 0 0 0 1 1 1 0 0 0 0 1 1 0 0 0 0 1 0 1 0 0 1 0 0 ] == 1;
% 
% channels.atoc278a01  = [ 1 0 1 0 0 1 1 0 0 0 0 1 1 1 0 1 0 1 1 1 0 0 1 0 1 0 1 0 1 1 1 0 ] == 1;
% channels.atoc278a02  = [ 1 0 1 0 0 1 1 0 0 0 0 1 1 1 0 1 0 1 1 1 0 0 1 0 1 0 1 0 1 1 1 0 ] == 1;
% channels.atoc278a03  = [ 1 0 1 0 0 1 1 0 0 0 0 1 1 1 0 1 0 1 1 1 0 0 1 0 1 0 1 0 1 1 1 0 ] == 1;
% 
% channels.isisc166a03 = [ 0 1 0 1 1 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 1 0 0 1 0 1 1 0 0 ] == 1;
% channels.isisc166a04 = [ 0 1 0 1 1 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 1 0 0 1 0 1 1 0 0 ] == 1;
% channels.isisc166a05 = [ 0 1 0 1 1 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 1 0 0 1 0 1 1 0 0 ] == 1;
% 
% channels.isisc169a01 = [ 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 1 0 0 ] == 1;
% channels.isisc169a02 = [ 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 1 0 0 ] == 1;
% channels.isisc169a03 = [ 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 1 0 0 ] == 1;
% 
% channels.isisc178a02 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 ] == 1;
% channels.isisc178a03 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 ] == 1;
% channels.isisc178a04 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 ] == 1;
% 
% channels.isisc183a04 = [ 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 0 0 0 1 1 0 0 0 1 0 0 1 0 0 ] == 1;
% channels.isisc183a05 = [ 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 0 0 0 1 1 0 0 0 1 0 0 1 0 0 ] == 1;
% channels.isisc183a06 = [ 0 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 0 0 0 1 1 0 0 0 1 0 0 1 0 0 ] == 1;
% 
% channels.isisc204a03 = [ 0 1 1 0 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 ] == 1;
% channels.isisc204a04 = [ 0 1 1 0 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 ] == 1;
% channels.isisc204a05 = [ 0 1 1 0 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 ] == 1;
% 
% channels.isisc205a03 = [ 0 1 1 0 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 1;
% channels.isisc205a04 = [ 0 1 1 0 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 1;
% channels.isisc205a06 = [ 0 1 1 0 0 0 0 1 1 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ] == 1;
% 
% channels.atoc251a01 = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 0 0 1 1 1 1 1 0 1 0 1 1 0 1 1 1 ] == 1;
% channels.atoc252a02 = [ 1 0 0 0 0 1 1 0 0 0 0 1 1 1 0 1 0 0 1 0 0 1 1 0 1 0 1 1 0 0 0 1 ] == 1;
% 
% channels.isisc163a01 = [ 0 1 1 0 0 0 0 1 1 1 0 0 1 1 1 0 1 1 0 0 0 1 1 1 1 1 1 0 1 1 0 1 ] == 1;
% channels.isisc165a04 = [ 0 0 1 1 0 0 0 1 1 1 0 0 1 0 1 1 1 1 1 0 0 1 0 0 1 0 1 0 1 1 0 0 ] == 1;


channels.all         = ones(1,32) == 1;
channels.atoc        = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1;
channels.isis        = [ 1 1 1 1 1 0 0 1 1 1 0 0 1 1 1 1 1 1 0 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1;


channels.atoc247a02  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 10 
channels.atoc247a03  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 23 
channels.atoc247a04  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 15 

channels.atoc248a01  = [ 1 1 0 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 3 
channels.atoc248a02  = [ 1 1 0 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 24 
channels.atoc248a03  = [ 1 1 0 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 0 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 6 

channels.atoc249a02  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 10 
channels.atoc249a03  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 25 
channels.atoc249a04  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 12 

channels.atoc250a02  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 16 
channels.atoc250a03  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 25 
channels.atoc250a04  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 9 

channels.atoc277a01  = [ 1 1 1 1 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 ] == 1; % 7 
channels.atoc277a02  = [ 1 1 1 1 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 ] == 1; % 18 
channels.atoc277a03  = [ 1 1 1 1 0 1 1 0 0 0 1 1 1 1 1 1 1 1 0 0 0 1 0 0 0 0 1 0 1 0 1 0 ] == 1; % 11 

channels.atoc278a01  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 0 0 1 1 0 1 0 1 1 1 1 1 0 ] == 1; % 12 
channels.atoc278a02  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 0 0 1 1 0 1 0 1 1 1 1 1 0 ] == 1; % 21 
channels.atoc278a03  = [ 1 1 1 1 0 1 1 0 0 0 0 1 1 1 1 1 1 1 0 0 0 1 1 0 1 0 1 1 1 1 1 0 ] == 1; % 10

channels.isisc166a03 = [ 1 1 1 1 1 0 0 1 1 1 0 0 1 1 1 1 1 1 0 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 3 
channels.isisc166a04 = [ 1 1 1 1 1 0 0 1 1 1 0 0 1 1 1 1 1 1 0 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 20 
channels.isisc166a05 = [ 1 1 1 1 1 0 0 1 1 1 0 0 1 1 1 1 1 1 0 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 21 

channels.isisc169a01 = [ 0 1 0 1 1 1 0 1 1 1 0 0 1 0 0 0 0 1 1 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 17 
channels.isisc169a02 = [ 0 1 0 1 1 1 0 1 1 1 0 0 1 0 0 0 0 1 1 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 16 
channels.isisc169a03 = [ 0 1 0 1 1 1 0 1 1 1 0 0 1 0 0 0 0 1 1 0 0 1 0 0 1 1 1 0 1 1 0 0 ] == 1; % 9 

channels.isisc178a02 = [ 0 1 1 1 0 0 1 1 1 0 0 0 1 1 1 1 1 0 1 0 0 1 0 0 0 1 1 0 0 1 0 0 ] == 1; % 7 
channels.isisc178a03 = [ 0 1 1 1 0 0 1 1 1 0 0 0 1 1 1 1 1 0 1 0 0 1 0 0 0 1 1 0 0 1 0 0 ] == 1; % 16 
channels.isisc178a04 = [ 0 1 1 1 0 0 1 1 1 0 0 0 1 1 1 1 1 0 1 0 0 1 0 0 0 1 1 0 0 1 0 0 ] == 1; % 4 

channels.isisc183a04 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 1 0 1 0 0 1 0 1 ] == 1; % 2 
channels.isisc183a05 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 1 0 1 0 0 1 0 1 ] == 1; % 14 
channels.isisc183a06 = [ 0 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 1 0 1 0 0 1 0 1 ] == 1; % 10 

channels.isisc204a03 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 1 1 0 0 1 0 0 0 1 1 0 1 0 0 0 ] == 1; % 3 
channels.isisc204a04 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 1 1 0 0 1 0 0 0 1 1 0 1 0 0 0 ] == 1; % 16 
channels.isisc204a05 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 1 1 0 0 1 0 0 0 1 1 0 1 0 0 0 ] == 1; % 10 

channels.isisc205a03 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 ] == 1; % 0 
channels.isisc205a04 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 ] == 1; % 12 
channels.isisc205a06 = [ 1 1 1 1 0 0 0 1 1 0 0 0 1 1 1 0 1 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 ] == 1; % 15 

channels.atoc251a01  = [ 1 1 1 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 25 
channels.atoc252a02  = [ 1 1 0 0 0 1 1 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 1 1 1 1 1 1 ] == 1; % 24 

channels.isisc163a01 = [ 0 1 1 1 0 0 0 1 1 1 0 0 1 0 1 1 1 1 0 0 0 1 1 0 1 1 1 0 1 1 0 1 ] == 1; % 19 
channels.isisc165a04 = [ 1 1 1 1 0 0 0 1 1 1 1 0 1 0 1 1 1 1 0 0 0 1 0 0 1 1 1 0 1 1 0 1 ] == 1; % 20 

assignin('base','viewing_codes',codes);
assignin('base','viewing_channels',channels);

