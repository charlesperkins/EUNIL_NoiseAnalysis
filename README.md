# EUNIL_NoiseAnalysis
Noise Analysis Program for The EUNIL group to investigate noise, characterize acquisitions systems and for debugging

# Introduction
This is a user manual for the noise analysis program created in matlab for the EUNIL lab. It contains the instructions
for getting started as well as in depth information about how the program actually works. This program is designed to read
in M-Mode data(fast time samples at regular intervals). Currently, it can import data from the lab's National Intruments acquisition 
setup as well as the Photosound acquisition system. 


# Overview
This program will perform several analysis and create various plots that can help the user understand the noise/spectral content and patterns 
in their mmodes. This can be used with mmodes that contain noise or noise and signal. Depending on input from the user, figures plotted can be saved to a ppt. 
This capability is especially meant for processing multiple input files at a time. Each figure type will be put in a powerpoint for that figure type. 
for example, all the MMode images would be saved to the file "MMODE_filename.pptx". 
# Getting Started
## Running the program
This program requires you to have matlab installed on your computer so you can open the script with matlab and run it. 

Once you have opened the script in matlab, you can change parameters or skip this step if you will use the defaults.
![image](https://user-images.githubusercontent.com/45602872/112206200-e36e9400-8bd2-11eb-9c45-4e2651120625.png)

Next, you can run the program
    If you want to choose which analysis plots to graph/save, enter 'y' for the default settings prompt

Choose a file
    You can choose any .mat data file from the EUNIL NI system or the PS data. 
    If you want to select files and save the charts to power point, you can choose to save the file. 
    You should select the base name for the power point files you want to save to. In the future, this may just be a folder. 
    
After the user input selections, the program will run and plot/save charts. 
## Important Variables to set
There are several variables that require manual entry. These can all be found at the beginning of the script under "General Parameters" "Filter Parameters", "Analysis, Plotting, and Saving Parameters", "Display Range Parameters", "NI Parameters", "Photosound Parameters", and "Scaling and Gain Parameters". 


| Variable | Parameter Category | Description | Allowed types+Range | Notes |
| -------- | ------------------ | ----------- | ------------------- | ----- |
| scanPt | General | Number of scan points | Integer > 0 | The program can only do single point scans at the moment |
| addpath | Filepath | Adds file path locations for additional scripts used and default filepaths | String, File path | This is not a variable, but still somethign the user will want to change. |
| fastTimeFiltCut | Filter | Fast time filter cuttoffs for bandpas filter in MHz | float > 0 | Cuttoffs are in a 4 element vector [cuttoff region low, passband low, oassband high, cuttoff region high] |
| slowTimeFiltCut | Filter | Slow time filter cuttoffs for bandpas filter in MHz | float > 0 | Cuttoffs are in a 4 element vector [cuttoff region low, passband low, oassband high, cuttoff region high] |
| numPreAvg | Analysis, Plotting, and Saving | Number of Averages | Integer > 0 | This is just the number of averages for the scan you are analyzing |
| defaultROI | Analysis, Plotting, and Saving | Select the region to analyze and graph | float >0 | ROI in terms of [fastTimeStart(us), fastTimeEnd(us), slowTimeStart(ms), slowTimeEnd(ms)] |
| niGain | NI | Gain of the NI system | Integer > 0 | Note: gain is in terms of scaling factor, not decibels. This usually never changes for NI |
| psGain | Photosound | Gain of Photosound | Integer > 0 | Note: gain is in terms of scaling factor, not decibels. The photosound describes gain as decibels and so this will need to be converted |
|  |  |  |  |  |

These variables are the ones the user will likely need to set. There are additional variables/parameters which can be set. The script contains short descriptions of these variables in the different parameter sections. 
 
### 
# Interpreting graphs
Perhaps the most relevant information is how to actually interpret the graphs and understand how the graphs are made. 
## Chart Overview
There are three main type of graphs that this program can display:
Data Plotting: These are just plots and graphs of the time domain signal, such as A-Line and MMode images
Spectral Graphs: These are various graphs showing the spectral content of the data
Correlation Graphs: These are various graphs showing cross correlation between electrodes. 
### Data Plotting
These are graphs are created by plotting the raw data directly.
#### A-Line
![A_Line](https://user-images.githubusercontent.com/45602872/112210315-c7212600-8bd7-11eb-8d51-5e1fbf78d8e9.png)
#### MMode
![MMode](https://user-images.githubusercontent.com/45602872/112210336-cd170700-8bd7-11eb-9698-30927a6efc36.png)

### Spectrum Graphs
There are several charts here.
Spectrogram: Shows a "Spectrogram" or A-Line frequency content for the entire MMode
Average Spectral Density: This shows the Spectral densities averaged across all frequncies in the spectrogram
Slow Time RMS: This shows the RMS value of each A-Line for each channel. 
#### Spectrogram
The spectrogram is made by performing the FFT on each column in the MMode to create a spectrogram. 
The spectrogram is useful for seeing spectral patterns that change with each A-Line
![Spectrogram](https://user-images.githubusercontent.com/45602872/112212753-9b536f80-8bda-11eb-9d67-4d9e54ce3f19.png)

#### Average Spectral Density
The average spectral density is created by taking the RMS of each frequency in the Spectrogram which effectively "squishes" the MMode into 
a single spectral density A-Line. This gives a "summary" of the fast time spectral content for the entire MMode. 
![AverageSpectralDensity](https://user-images.githubusercontent.com/45602872/112212778-a0b0ba00-8bda-11eb-8df9-e621c8c2664e.png)

#### Slow Time RMS
The slow time RMS is created by taking the RMS of each A-Line of the MMode. The resulting chart is one that shows how the average power in each line differs from others on the same channel as well as other channels. This visual gives a summary of the power that each channel experiences and can be used to catch outlier channels/ visual events that happen across all channels(such as a strong increase in noise for each). 
![SlowTimeRMS](https://user-images.githubusercontent.com/45602872/112212790-a5756e00-8bda-11eb-95a3-1395427afd66.png)

### Correlation Graphs
As with the Spectral analysis, there are several correlation graphs that can be plotted. 
Cross Correlation MMode: Creates an "MMode" Correlation Depiction between 2 particular channels. 
Cross Correlation A-Line: Plots the "A-Line" with the peak correlation
Cross Correlelogram: Creates a matrix that shows the peak correlation between each channel. 

NOTE: This analysis can take a lot of processing time and isnt always useful. Only opt to use this if you are sure you want them

#### Cross Correlation MMode
This is created by correlating respective A-Lines from the MModes of 2 channels. It is like correlating two A_lines for two different channels at some particular slow time, repeating this for all a-lines and combining those cross correlations back together in a single A-Line. This is potentially useful to see phased signals(signals both channels see but arrive at different times). 
![MModeCorrelation](https://user-images.githubusercontent.com/45602872/112212838-b32af380-8bda-11eb-8a2c-7851ea15493a.png)

#### Cross Correlation A-Line
This Chart is created by finding the peak value of the correlation MMode and plotting the "A-Line" for that value. This is useful for understanding the shapes of the correlations. 

![CrossCorr_ALine](https://user-images.githubusercontent.com/45602872/112212855-b8883e00-8bda-11eb-8e84-ecda950f8cc5.png)
#### Cross Correlelogram
This Chart show the max correlation value between each channel. This is useful to see which electrodes have a large amount of correlation(or lack correlation) between them.  ![Correlelogram](https://user-images.githubusercontent.com/45602872/112212879-c047e280-8bda-11eb-8d1b-868e2f1d9a88.png)


# Appendix
## Variables
%%% General Parameters
eqRes: This is the equivalent resistance resistor. It will be used to create the "Johnson Noise"
scanPt: Scan point is one because we are expecting single point raw data

%%%%%% Filter Parameters
subMeanBool: Flag to subtract mean
filtFastBool: Flag to filter fast time
filtSlowBool: Flag to filter slow time
fastTimeFiltCut: Fast Time Filter Cuttoffs 
slowTimeFiltCut: Slow Time Filter Cuttoffs 

%%%%%% Analysis, Plotting, and Saving Parameters
generalAnalysis: Flag indicating to perform general analysis(create the General Analysis Table)
spectrumAnalysis: Flag indicating to perform spectrum analysis
correlationAnalysis: Flag indicating to perform correlation

showALine: Plot A-Line
showMMode: Plot MMode
show2DFFT: Plot 2D FFT magnitude
figIdx: Starting Index for figures
plotAllChan: Plot all channels on the Average Spectral Density 
defaultSlideVal: pick which channel the slider defaults to. 
bigBangStart: Number of initial bins for big bang TODO: CHARLES CHANGE to us
fastTimeEndCut: This is number of bins to cuttoff at Fast Time End TODO: CHARLES CHANGE to us
savePlots: Save plots to files
saveData: Save data to files
saveXCorr: Save Cross Correlation of MModes

%%%%%% Display Range Parameters
displayUnits: The units to scale everything to. This can be 'V','mV','uV','nV'

%%% NI Parameters(SET THESE)
niQuantization:Scaling factor from NI System quanta to Volts
niGain: Gain of the NI System


%%% Photosound Parameters(SET THESE)
ps: Flag if Using Photosound;
psQuantization: Scaling factor from photosound quanta to Volts. this is in Units/Volt 
psGain: Gain of Photosound
## Functions
## Calculations
