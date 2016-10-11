#!/bin/bash

for dim in {1..10} # {1..12} 15 20 30
do
	for animal in {1..40}
	do
		#echo animal=$animal in=all out=all mode=run bin_size=0.05 zDim=$dim fr=0.1 mfunction=gpfa4syntheticSection ./cmdgen.sh
		echo animal=$animal mode=view bin_size=0.01 zDim=$dim fr=0.1 mfunction=gpfa4view_${dim}_${animal}_ program=view ./cmdgen.sh
	done
done
