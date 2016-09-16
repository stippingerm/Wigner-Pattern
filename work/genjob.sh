#!/bin/bash

for dim in {1..12} 15 20 30
do
	for animal in {1..29}
	do
		echo animal=$animal in=all out=all mode=run bin_size=0.05 zDim=$dim fr=0.1 mfunction=gpfa4syntheticSection ./cmdgen.sh
	done
done
