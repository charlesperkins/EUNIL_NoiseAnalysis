# EUNIL_NoiseAnalysis
Noise Analysis Program for The EUNIL group to investigate noise, characterize acquisitions systems and for debugging

# Introduction
This is a user manual for the noise analysis program created in matlab for the EUNIL lab. It contains the instructions
for getting started as well as in depth information about how the program actually works. This program is designed to read
in M-Mode data(fast time samples at regular intervals). Currently, it can import data from the labs National Intruments acquisition 
setup, or also the Photosound acquisition system. 


# Overview
This program will perform several analysis and create various plots that can help the user understand the noise/spectral content and patterns 
in their mmodes. This can be used with mmodes that contain noise or noise and signal. Depending on input from the user, figures plotted can be saved to a ppt. 
This capability is especially meant for processing multiple input files at a time. Each figure type will be put in a powerpoint for that figure type. 
for example, all the MMode images would be saved to the file "MMODE_filename.pptx". 
# Getting Started
## Running the program
This program requires you to have matlab installed on your computer so you can open the file with matlab and run it. 

Once you have opened the file in matlab, you can change parameters or skip this step if you will use the defaults.
![image](https://user-images.githubusercontent.com/45602872/112206200-e36e9400-8bd2-11eb-9c45-4e2651120625.png)

Next, you can run the program
    If you want to choose which analysis plots to graph/save, enter 'y' for the default settings prompt

Choose a file
    You can choose any .mat data file from the EUNIL NI system or the PS data. 
    If you want to select files and save the charts to power point, you can choose to save the file. 
    You should select the base name for the power point files you want to save to. In the future, this may just be a folder. 
    
After the user input selections, the program will run and plot/save charts. 
# Interpreting graphs
Perhaps the most relevant information is how to actually interpret the graphs and understand how the graphs are made. 
## Chart Overview
There are three main type of graphs that this program can display:
Data Plotting

### Data Plotting
### Spectrum Graphs
### Correlation Graphs
## How Plots are made
## Ways to interpret graphs
# Appendix
## Variables
## Functions
## Calculations
