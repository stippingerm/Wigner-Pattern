function codes = code_table_view()
codes.spontaneous  = [-1];
codes.repetition0  = [0 1 2 3 4 5 6 7 8 9 0 0 0 0 -1];
codes.repetition1  = [0 1 2 3 4 5 6 7 8 9 1 1 1 1 -1];
codes.repetition2  = [0 1 2 3 4 5 6 7 8 9 2 2 2 2 -1];
codes.repetition45 = [0 1 2 3 4 5 6 7 8 9 4 4 4 4 5 5 5 5 -1];

codes.atoc247a02  = codes.spontaneous;
codes.atoc247a03  = codes.repetition0;
codes.atoc247a04  = codes.spontaneous;
codes.atoc247a05  = codes.spontaneous;

codes.atoc248a01  = codes.spontaneous;
codes.atoc248a02  = codes.repetition0;
codes.atoc248a03  = codes.spontaneous;

codes.atoc249a02  = codes.spontaneous;
codes.atoc249a03  = codes.repetition1;
codes.atoc249a04  = codes.spontaneous;

codes.atoc250a02  = codes.spontaneous;
codes.atoc250a03  = codes.repetition1;
codes.atoc250a04  = codes.spontaneous;

codes.atoc277a01  = codes.spontaneous;
codes.atoc277a02  = codes.repetition45;
codes.atoc277a03  = codes.spontaneous;

codes.atoc278a01  = codes.spontaneous;
codes.atoc278a02  = codes.repetition45;
codes.atoc278a03  = codes.spontaneous;


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

assignin('base','viewing_codes',codes);

