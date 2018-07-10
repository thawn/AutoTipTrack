addpath('bfmatlab')
addpath('imageprocessing')
addpath(fullfile('imageprocessing','Fit2D'))
addpath(fullfile('imageprocessing','debug'))
mcc -m evaluateManyExperiments.m -a bfmatlab/bioformats_package.jar -a assets
