# AutoTipTrack
A software algorithm for the automated analysis of in vitro gliding motility assays.

## quick start:

1. Put your movie stacks belonging to the same experiment in a directory on your computer. You can also put the data in subdirectories. Any directory named `ignore` or `eval-old` will be ignored. Supported data formats are: tiff stack (.tif), a folder with many single tiff images, MataMorph stack (.stk), Nikon NIS-Elements Advanced Research (.nd2).
1. start Matlab and make the AutoTipTrack directory your working directory.
1. execute the following command in Matlab:
```Matlab
evaluateManyExperiments('Path\to\your\data\windows or /path/to/your/data/mac/unix')
```

First a configuration window will appear. There you should change the pixel size and time interval to the correct values for your experiment. All other configuration values should be fine if left at their respective defaults. The configuration window only appears on first start. If you would like to change the configuration later, run:
```Matlab
createConfigGui('Path\to\your\data')
```
After the configuration window, you get a window that shows the tracking progress.
After te dracking is finished, you will get pdf files with speed evaluation in your data directory and in a newly created `eval` subdirectory.

The `eval` directory also contains matlab .mat files for each data stack. You can open these files with matlab. They contain data on the velocity and length of your filaments in the `Results` struct object. They also contain data about the tracking results of each tip in the `Objects` struct and data about the connected tracks in the `Molecules` struct.

You can also open the matlab files created for each stack with FIESTA (first load your data with "file->load stack' and then load the tracking data in the matlab file with "file->load tracks) and check out the individual tracking results: https://www.bcube-dresden.de/fiesta/wiki/FIESTA
On the FIESTA wiki you can also find more information about the data structure of the `Objects` and `Molecules`.