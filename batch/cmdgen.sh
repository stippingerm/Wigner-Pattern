#!/bin/bash

# Run Matlab with the template settings substituted with corresponding command line parameters:
# * animal (int)
# * mode (string): nur, wheel
# * in, out (string): section names
# * zDim (int): GPFA latent dimensionality
# * bin_size (float): bin size in s
# * fr (float): required minimum firing rate
# * tmp_settings (string): by which name to save temporary settings

tmp_to_del=DoIt

if [ -z "$animal" ]
then
  animal=1
fi
if [ -z "$mode" ]
then
  mode=run
fi
if [ -z "$in" ]
then
  in=mid_arm
fi
if [ -z "$out" ]
then
  out=lat_arm
fi
if [ -z "$folds" ]
then
  folds=3
fi
if [ -z "$zDim" ]
then
  zDim=5
fi
if [ -z "$bin_size" ]
then
  bin_size=0.04
fi
if [ -z "$program" ]
then
  program=synthetic
fi
if [ -z "$fr" ]
then
  fr=0.10
fi
if [ -z "$tmp_settings" ]
then
  tmp_to_del=DoIt
  tmp_settings=$(mktemp --suffix=.m tmppar_XXXXXX)
fi
# whether to actually run calculation
if [ -z "$run" ]
then
  run=1
fi

# Matlab setting
PREFDIR=/home/umat/.matlab/R2013a/users/stippinger/
# Matlab commands
PRECOMMAND="addpath(genpath('~/marcell/_DataHigh1.2/'),genpath('~/marcell/napwigner/'));"
ERRHANDLING="fprintf('ERR: %s\\n',ME.identifier); fprintf('%s\\n',ME.message); disp(struct2table(ME.stack)); celldisp(ME.cause);"

# Substitute variables into the template
printf -v pattern "s/|animal|/$animal/;s/|mode|/$mode/;s/|in|/$in/;s/|out|/$out/;s/|zDim|/$zDim/;s/|folds|/$folds/;s/|program|/$program/;s/|bin_size|/$bin_size/;s/|fr|/$fr/;"
sed "$pattern" ../template4gpfa.txt > ${tmp_settings}

# Run simulation
if [ "$run" == "1" ]
then
  MATLAB_PREFDIR=$PREFDIR matlab -nodisplay -r "$PRECOMMAND; settings_file='${tmp_settings}'; try; gpfa4batch; catch ME; $ERRHANDLING; end; exit;"
else
  echo MATLAB_PREFDIR=$PREFDIR matlab -nodisplay -r "$PRECOMMAND; settings_file='${tmp_settings}'; try; gpfa4batch; catch ME; $ERRHANDLING; end; exit;"
fi

#sed "s/|animal|/$animal/;s/|mode|/$mode/;s/|in|/$in/;s/|out|/$out/;s/|zDim|/$zDim/;" gpfa4runTemplate.txt > gpfa4runSettings.m
#matlab -nodisplay -r "addpath(genpath('~/marcell/_DataHigh1.2/'),genpath('~/marcell/napwigner/')); try; gpfa4runSection; catch ME; fprintf('ERR: %s',ME.identifier); end; exit;"

if [ ! -z "$tmp_to_del" ]
then
  rm $tmp_settings
fi
