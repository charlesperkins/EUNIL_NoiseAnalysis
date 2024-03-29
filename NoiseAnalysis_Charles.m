%%% NOISE ANALYSIS SCRIPT %%%
% Written By: Charles Perkins
% As part of EUNIL LAB, 3/18/2021
% Last Modified:  3/18/2021
%
% Description: 
%   This script will analyze noise data from either the photosound or
%   national instruments data aquisition setups used by EUNIL Lab.


%% Run main Function
main
function main
import mlreportgen.ppt.*
%%  Set Parameters

%%% General Parameters
eqRes=1000;         %This is the equivalent resistance resistor. It will be used to create the "Johnson Noise"
scanPt=1;           %Scan point is one because we are expecting single point raw data

%%%%%% Filepath parameters  TODO: CHARLES CHANGE to make this generalized
addpath 'C:\Users\Akinga\OneDrive - University of Arizona\OrganizingFolder\Work\University of Arizona\Witte Lab\Analysis and Software\My Code'
addpath 'F:\2021-02-25\ExpData'

%%%%%% Filter Parameters
subMeanBool=true;                   %Flag to subtract mean
filtFastBool=true;                  %Flag to filter fast time
filtSlowBool=true;                  %Flag to filter slow time
fastTimeFiltCut=[0.75 1.35 1.65 2.3]  %Fast Time Filter Cuttoffs p4-1: [1 1.5 3.5 4]      ;  H235: [0.3 0.54 0.66 0.9]   ; H247: [0.75 1.35 1.65 2.3] 
slowTimeFiltCut=[80 150 250 300];  %Slow Time Filter Cuttoffs P4-1: [100 150 250 300]  ;  H235: [100 150 250 300]     ; H247: [100 150 250 300] 

%%%%%% Analysis, Plotting, and Saving Parameters
generalAnalysis=true;
spectrumAnalysis=true;
correlationAnalysis=false;

showALine=true;     %Plot A-Line
showMMode=true;     %Plot MMode
show2DFFT=false;     %Plot 2D FFT magnitude

figIdx=400;         %Starting Index for figures
plotAllChan=1;      %Plot all channels on the Average Spectral Density 
defaultSlideVal=2;  %pick which channel the slider defaults to. 
calcUnAvg=1;        %If true, this looks at unaveraged data from the set and looks at stats. 
global numPreAvg;
numPreAvg=10;       %Number of sets collected for pre Average
psChannels=[1,4,17,18]; %indicates channels used
slowTimeROI=[0 30]; %Total Slow time region of Interest, in ms
fastTimeROI=[20 50];%Total Fast time region of Interest, in us
calcSNR=true;       %Flag to calculate SNR from selected Signal and Noise ROIs
drawROI=false;       %Flag to allow user to draw ROI
defaultROI=[26 31 0 30];    %ROI in terms of [fastTimeStart(us), fastTimeEnd(us), slowTimeStart(ms), slowTimeEnd(ms)]
savePlots=false;     %Save plots to files
saveData=false;     %Save data to files
saveXCorr=false;    %Save Cross Correlation of MModes
useH5=false;         %determine if you want to use the created h5 files 
%%%%%% Display Range Parameters
displayUnits="uV";
pwr=0;
if strcmp(displayUnits, "nV")
    pwr=9;
elseif strcmp(displayUnits, "uV")
    pwr=6;
elseif strcmp(displayUnits, "mV")
    pwr=3;
elseif strcmp(displayUnits, "V")
    pwr=0;
end


%%% NI Parameters(SET THESE)
niQuantization=1;       %Scaling factor from NI System quanta to Volts
niGain=440;


%%% Photosound Parameters(SET THESE)
ps=false;               %Flag if Using Photosound;
psQuantization=1/(0.427*10^-6);   %Scaling factor from photosound quanta to Volts. this is in Units/Volt 
psGain=446;              %Gain of Photosound


%%% Scaling and Gain Parameters
if ps 
    gain=psGain*psQuantization;
    
else
    gain=niGain*niQuantization;
end




%% Main Loop
while true
    %% Ask User for Input
    if ~strcmpi(input("Use Defaults? (y/n):  ",'s'),"y")
        savePlots=strcmpi(input("Save Plots? (y/n):  ",'s'),"y");
        spectrumAnalysis=strcmpi(input("Perform Spectrum Analysis? (y/n):  ",'s'),"y");
        correlationAnalysis=strcmpi(input("Perform Correlation Analysis? (y/n):  ",'s'),"y");

        showALine=strcmp(lower(input("Show A-Line? (y/n):  ",'s')),"y");
        showMMode=strcmp(lower(input("Show MMode? (y/n):  ",'s')),"y");
        show2DFFT=strcmp(lower(input("Show 2DFFT? (y/n):  ",'s')),"y");
    end
    
    useDFChan=strcmp(lower(input("Use Default Channels? (y/n):  ",'s')),"y");
    if ~useDFChan
        psChannels=input("Use Channel: ");
        numChannels=numPreAvg;
    end 
    
    %% Read in, Process, Plot, and Save Data
        if ps
            [file path]=uigetfile("*.mat",'Select One or more files','MultiSelect','on');
        else
            [file path]=uigetfile("*_info.mat",'Select One or more files','MultiSelect','on');
        end
        
        if iscell(file)
            numFiles=size(file,2);
        else
            numFiles=1;
        end
        if savePlots
            import mlreportgen.ppt.*
            [pptfile pptpath]= uiputfile("*.pptx");
            
            %Create Power point Presentations based on user selections. 
            pptRaw = Presentation([pptpath 'Raw_' pptfile]);                            %Raw MMode
            if generalAnalysis
                pptGenAnalysis = Presentation([pptpath 'GeneralAnalysis_' pptfile]);    %General Analysis Tables
            end
            if spectrumAnalysis
                pptSpect= Presentation([pptpath 'Spect_' pptfile]);                     %Spectrogram MMode
                pptAvg_SD_ALine= Presentation([pptpath 'SpectRMS_ALines_' pptfile]);                 %Average Spectral Density(Spectrogram RMS
                pptAvg_SD= Presentation([pptpath 'SpectRMS_' pptfile]);                 %Average Spectral Density(Spectrogram RMS
                pptST_RMS= Presentation([pptpath 'ST_RMS_' pptfile]); 
            end
            if correlationAnalysis
                pptCorr1= Presentation([pptpath 'Corr1_' pptfile]);                     %Cross Correlation MMode
                pptCorr2= Presentation([pptpath 'Corr2_' pptfile]);                     %Cross Correlation Peak
                pptCorr3= Presentation([pptpath 'Corr3_' pptfile]);                     %Corrolellogram
            end
        end
    tic;
    for fileIdx=1:numFiles
        %% Read Data 
        %%% Read data from file
        if numFiles==1
            currentFile=char(string(file));
        else 
            currentFile=char(string(file(fileIdx)));
        end
        
        if useH5
                [rawData,scanParam]=readH5(path,currentFile);
        else
            if ps
                [rawData,scanParam]=readPS([path currentFile]);
                
                rawDataTemp=zeros(size(rawData,1),size(rawData,2)/numPreAvg,size(rawData,3),numPreAvg);% Convert data from [FastTime,Slowtime*NumAvg,Channel] to [FastTime,SlowTime,Channel,NumAvg]
                for k=1:numPreAvg
                    rawDataTemp(:,:,:,k)=rawData(:,(1+(k-1)*120):k*120,:);
                end
                rawData=squeeze(rawDataTemp(:,:,psChannels,:)); 
                if ~calcUnAvg
                    rawData=squeeze(mean(rawData,4));
                end
                
            else
                [rawData,scanParam]=readNI([path currentFile]);
            end 
        end
        
        %%% Set Parameters from files
            fsFastTime=scanParam.fsFastTime;                %Fast time Frequency
            numSamplesFastTime=scanParam.numSamplesFastTime;%Number of Fast time Samples
            fsSlowTime = scanParam.fsSlowTime;               %Slow Time 
            numSamplesSlowTime=scanParam.numSamplesSlowTime;

            fastTimeRange=scanParam.fastTimeRange;
            fastTime=scanParam.fastTime;
            fastTimeFreq=scanParam.fastTimeFreq;
            slowTimeRange=scanParam.slowTimeRange;
            slowTime=scanParam.slowTime;
            slowTimeFreq=scanParam.slowTimeFreq;
            numChannels=scanParam.numChannels;
            scanSize=scanParam.scanSize;
            
            if useH5 || ~useDFChan
                numChannels=numPreAvg;
            end
            

            
        %% Data Preprocessing
        %%% Adjust Gain and Units
        rawData=rawData*10^(pwr)/(2*gain);      %Scale raw Data Appropriately
        
        %%% Adjust Arrays to only include ROI
        [~, stROIstartIDX]=min(abs(slowTime-slowTimeROI(1)));
        [~, stROIendIDX]=min(abs(slowTime-slowTimeROI(2)));
        [~, ftROIstartIDX]=min(abs(fastTime-fastTimeROI(1)));
        [~, ftROIendIDX]=min(abs(fastTime-fastTimeROI(2)));
        rawData=rawData(ftROIstartIDX:ftROIendIDX,stROIstartIDX:stROIendIDX,:);
        
        slowTime=slowTime(stROIstartIDX:stROIendIDX);
        slowTimeFreq=linspace(-fsSlowTime/2,fsSlowTime/2,size(rawData,2));
        fastTime=fastTime(ftROIstartIDX:ftROIendIDX);
        fastTimeFreq=linspace(-fsFastTime/2,fsFastTime/2,size(rawData,1));
        
        %%% Subtract mean
        if subMeanBool
            rawData=rawData-mean(mean(rawData));
        end
        
        %%% Filter Data
            ft=zeros(size(rawData));
            for i=1:size(rawData,3)
                ft(:,:,i)=fft2(rawData(:,:,i));%Create 2D fft.
            end

            fastFilt=Hann2(fastTimeFiltCut(1),fastTimeFiltCut(2),fastTimeFiltCut(3),fastTimeFiltCut(4),size(rawData,1),fsFastTime);
            slowFilt=Hann2(slowTimeFiltCut(1),slowTimeFiltCut(2),slowTimeFiltCut(3),slowTimeFiltCut(4),size(rawData,2),fsSlowTime);

            if filtFastBool && filtSlowBool
                %2D filter based on parameters
                for i=1:size(rawData,3)
                    rawData(:,:,i)=ifft2(slowFilt.*ft(:,:,i).*fastFilt');
                end
            elseif filtFastBool&& ~filtSlowBool
                %1D filter on fast time only based on parameters
        %         rawData=filter(fFast,rawData);
                for i=1:size(rawData,3)
                    rawData(:,:,i)=ifft2(ft(:,:,i).*fastFilt');
                end
            elseif ~filtFastBool && filtSlowBool
                %1D filter on slow time only based on parameters
                for i=1:size(rawData,3)
                     rawData(:,:,i)=ifft2(slowFilt.*ft(:,:,i));
                end
                display("Using Filtered Data");
            else 
                %no filter
                display("Using Raw Data");
            end
        
            
            
            
        %% Analysis and Plotting
        %%% Plot A-Line
        if showALine
            fh=figure(figIdx+10);clf;
            hscrollbar=uicontrol('style','slider','units','normalized'...
                                                      ,'UserData',rawData...
                                                      ,'position',[0 0 1 .05]...
                                                      ,'callback',@hscroll_MMode_Callback...
                                                      ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                                      ,'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
            if scanSize>1
                plot(fastTime,rawData(:,1,defaultSlideVal));
            else
                plot(fastTime,rawData(:,1,defaultSlideVal));
            end
            title(sprintf("A-Line(t=0+), Electrode # %i,",defaultSlideVal));
            xlabel("Fast Time (us)");
            ylabel("Amplitude"+displayUnits);ytickformat('%3.3f');
        end
        %%% Plot MMode
        if showMMode
            fh=figure(figIdx+11);clf;
            hscrollbar=uicontrol('style','slider','units','normalized'...
                                                      ,'UserData',rawData...
                                                      ,'position',[0 0 1 .05]...
                                                      ,'callback',@hscroll_MMode_Callback...
                                                      ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                                      ,'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
            if scanSize>1
                imagesc(slowTime,fastTime,rawData(:,:,defaultSlideVal));colormap jet;cb=colorbar;cb.Label.String="Amplitude ("+displayUnits+")";%previously included scan point as last dim
            else
                imagesc(slowTime,fastTime,rawData(:,:,defaultSlideVal));colormap jet;cb=colorbar;cb.Label.String="Amplitude ("+displayUnits+")";
            end
            title(sprintf("Raw Data, Electrode # %i",defaultSlideVal));
            xlabel("Slow Time(ms)");
            ylabel("Fast Time(μs)");
        end
        
        
        %%% Determine signal and Noise regions
        idxFind=@(Arr,Val)find(min(abs(Arr-Val))==abs(Arr-Val));
        if drawROI
            
            %%% Select Signal ROI and Determine associated variables
            disp("Select Signal ROI");
            rSignal=drawrectangle('Label','Signal','Color',[1,0,0]);
            rSignalPos=rSignal.Position;       % Get actual rectangle Position
           
            %%% Select Noise ROI
            disp("Select Noise ROI");
            rNoise=drawrectangle('Label','Noise','Color',[1,0,1]);
            rNoisePos=rNoise.Position;          % Get actual rectangle Position
           
            

        else
            disp("Using Default ROI");
             %%% Using Signal ROI and Determine associated variables
             rSignalPos=[-0.0604   26.6544   20.1024    3.3588];% TODO: Make this not Hard coded
             %%% Using Noise ROI
             rNoisePos=[-0.1261   32.6086   20.1681   17.3664];% TODO: Make this not hard coded
        end
            %%% Get ROI positions for Signal
             rSignalPos=[idxFind(slowTime,rSignalPos(1))...
                ,idxFind(fastTime,rSignalPos(2))...
                ,idxFind(slowTime,rSignalPos(1)+rSignalPos(3))...
                ,idxFind(fastTime,rSignalPos(2)+rSignalPos(4))];  %Find Indices for ROI
            %%%Create new Signal Array based off of ROI
            rawDataSignal=rawData(min(rSignalPos(2),rSignalPos(4)):max(rSignalPos(2),rSignalPos(4))...
                ,min(rSignalPos(1),rSignalPos(3)):max(rSignalPos(1),rSignalPos(3)),:,:,:);
            %%%Get slow and fast time arrays for Signal array
            signalSlowTime=slowTime(min(rSignalPos(1),rSignalPos(3)):max(rSignalPos(1),rSignalPos(3)));
            signalFastTime=fastTime(min(rSignalPos(2),rSignalPos(4)):max(rSignalPos(2),rSignalPos(4)));
            
            %%% Get ROI positions for Noise
             rNoisePos=[idxFind(slowTime,rNoisePos(1))...
                ,idxFind(fastTime,rNoisePos(2))...
                ,idxFind(slowTime,rNoisePos(1)+rNoisePos(3))...
                ,idxFind(fastTime,rNoisePos(2)+rNoisePos(4))]; %Find Indices for ROI
            %%%Create New Noise array based on ROI
            rawDataNoise=rawData(min(rNoisePos(2),rNoisePos(4)):max(rNoisePos(2),rNoisePos(4))...
                 ,min(rNoisePos(1),rNoisePos(3)):max(rNoisePos(1),rNoisePos(3)),:,:,:);
            %%%Get slow and fast time arrays for Signal array
            noiseSlowTime=slowTime(min(rNoisePos(1),rNoisePos(3)):max(rNoisePos(1),rNoisePos(3)));
            noiseFastTime=fastTime(min(rNoisePos(2),rNoisePos(4)):max(rNoisePos(2),rNoisePos(4)));

        
        
        %%% General Analysis
        if generalAnalysis
            %Peak of entire MMode
                rawMin=squeeze(min(min(rawData))).';
                rawMax=squeeze(max(max(rawData))).';
                rawPtP=rawMax-rawMin;%This is for each electrode.
                rawMinMean=mean(rawMin);
                rawMinSTD=std(rawMin);
                rawMaxMean=mean(rawMax);
                rawMaxSTD=std(rawMax);
                rawPtPMean=mean(rawPtP);
                rawPtPSTD=std(rawPtP);
                rawAllMin=min(rawPtP);
                rawAllMax=max(rawPtP);
                rawAllPtP=rawAllMax-rawAllMin;
            %Mean(to show if voltage offset) of entire MMode
                rawMean=squeeze(mean(mean(rawData))).';
                rawAllMean=squeeze(mean(rawMean));
            %RMS of entire MMode
                rawRMS=squeeze(rms(rms(rawData))).';
                rawRMSmean=mean(rawRMS);
                rawRMSSTD=std(rawRMS);
                rawAllRMS=squeeze(rms(rawRMS));
                
            %SNR calculations 
            if calcSNR
                signalPP=squeeze(max(max(rawDataSignal)))-squeeze(min(min(rawDataSignal)));
                noisePP=squeeze(max(max(rawDataNoise)))-squeeze(min(min(rawDataSignal)));
                snrPP=20*log10(signalPP./noisePP);
                snrMeanPP=mean(snrPP);
                snrStdPP=std(snrPP);
                signalRMS=squeeze(rms(rms(rawDataSignal)));
                noiseRMS=squeeze(rms(rms(rawDataNoise)));
                snrRMS=20*log10(signalRMS./noiseRMS);
                snrMeanRMS=mean(snrRMS);
                snrSTDRMS=std(snrRMS);
                
                snrPP_RMS=20*log10(signalPP./(noiseRMS));
                pp_rmsMean=mean(snrPP_RMS);
                pp_rmsSTD=std(snrPP_RMS);
                disp("Signal Peak/noise dB: "+string(snrRMS));
                disp("Signal Mean Peak/noise dB: "+string(pp_rmsMean));
                disp("Signal STD Peak/noise dB: "+string(pp_rmsSTD));
            end
            
            
            %PrintGeneral information/analysis out along with electrode numbering
                rGA=[rawMin;rawMax;rawPtP;rawMean;rawRMS];
                rawGenAnalysis=[rGA(:,1:numChannels) [rawAllMin;rawAllMax;rawAllPtP;rawAllMean;rawAllRMS] [rawMinMean;rawMaxMean;rawPtPMean;0;rawRMSmean] [rawMinSTD;rawMaxSTD;rawPtPSTD;0;rawRMSSTD]];%Charles Changed: rGA was originally rGA(:,1:numChannels)
                analysisTable=array2table(rawGenAnalysis);
           
                varNames{numChannels+3}=[];
                for k=1:numChannels
                    varNames{k}=['Ch' char(string(k))];
                end
                varNames{numChannels+1}= 'Overall';
                varNames{numChannels+2}= 'Mean';
                varNames{numChannels+3}= 'STD';
                
                
                analysisTable.Properties.VariableNames=varNames;
                analysisTable.Properties.RowNames={'Minimum','Maximum','Peak to Peak','Mean','RMS'};
                %%% Alter numeric precision of table
                    % set desired precision in terms of the number of decimal places
                    n_decimal = 4;
                    % create a new table
                    new_T = varfun(@(x) num2str(x, ['%' sprintf('.%df', n_decimal)]), analysisTable);
                    new_T.Properties.VariableNames = analysisTable.Properties.VariableNames;
                    new_T.Properties.RowNames = analysisTable.Properties.RowNames;
                    analysisTable=new_T;
                %Display Table    
                display("Raw Data Evaluation");
                display(analysisTable);
                display("Note: Table units are in "+displayUnits);

        end
        
        %%% SPECTRUM ANALYSIS
        if spectrumAnalysis
            %%% Spectrogram(Fast Time FFT)
            rawDataFFT=fftshift(fft(rawData),2)/size(rawData,1);%Calc FFt along fast time for MMode
            fh=figure(figIdx+20);clf;%all other figures after the first one will be indexed based on previous
            hscrollbar=uicontrol('style','slider','units','normalized'...    %Scroll bar for plot 
                                              ,'UserData',abs(rawDataFFT(1:round(size(rawDataFFT,1)/2),:,:))...
                                              ,'position',[0 0 1 .05]...
                                              ,'callback',@hscroll_MMode_Callback...
                                              ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                              , 'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
            imagesc(slowTime,fastTimeFreq(round(size(rawDataFFT,1)/2)+1:end),20*log10(abs(rawDataFFT(1:round(size(rawDataFFT,1)/2),:,defaultSlideVal))));colormap jet;cb=colorbar;cb.Label.String="Amplitude (dB-"+displayUnits+")";
            title(sprintf("Spectrogram(Fast Time FFT) Electrode # %d",defaultSlideVal));
            xlabel("Time(ms)");
            ylabel("Frequency(MHz)");
            
            
             %%% Average Spectral Density Lines
            rawFFT_FastRMS=squeeze(rms(abs(rawDataFFT),2));%This is basically finding the average power of each frequency 
            fh=figure(figIdx+28);clf;%all other figures after the first one will be indexed based on previous
            hscrollbar=uicontrol('style','slider','units','normalized'...    %Scroll bar for plot 
                                              ,'UserData',rawFFT_FastRMS(1:round(size(rawFFT_FastRMS,1)/2),:,:)...
                                              ,'position',[0 0 1 .05]...
                                              ,'callback',@hscroll_ALine_Callback...
                                              ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                              , 'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
            if plotAllChan==1
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),rawFFT_FastRMS(1:round(size(rawFFT_FastRMS,1)/2),:));%Plot Electrode 1;
            else
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),rawFFT_FastRMS(1:round(size(rawFFT_FastRMS,1)/2),defaultSlideVal));
            end
            title("Average Spectral Density across A-Lines");
            xlabel("Frequency (MHz)");
            ylabel("Amplitude ("+displayUnits+"/$\sqrt{Hz}$ )",'Interpreter','latex');ytickformat('%3.3f');
            legend(string(varNames));
            
            
            %%% Average Spectral Density Lines, Mean and STD
            rawFFT_FastRMS=squeeze(rms(abs(rawDataFFT),2));%This is basically finding the average power of each frequency 
            RMSmean=mean(rawFFT_FastRMS,2);
            RMSstd=std(rawFFT_FastRMS,0,2);
            
            fh=figure(figIdx+21);clf;%all other figures after the first one will be indexed based on previous
            hscrollbar=uicontrol('style','slider','units','normalized'...    %Scroll bar for plot 
                                              ,'UserData',RMSmean(1:round(size(rawFFT_FastRMS,1)/2),:,:)...
                                              ,'position',[0 0 1 .05]...
                                              ,'callback',@hscroll_ALine_Callback...
                                              ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                              , 'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
            if plotAllChan==1
                hold on;
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),RMSmean(1:round(size(rawFFT_FastRMS,1)/2)),'color','k','LineWidth',2);%Plot Mean;
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),RMSmean(1:round(size(rawFFT_FastRMS,1)/2))+RMSstd(1:round(size(rawFFT_FastRMS,1)/2)),'color','r');%Plot STD+;
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),RMSmean(1:round(size(rawFFT_FastRMS,1)/2))-RMSstd(1:round(size(rawFFT_FastRMS,1)/2)),'color','b');%Plot STD-;
            else
                plot(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),RMSmean(1:round(size(rawFFT_FastRMS,1)/2)));
            end
            title("Average Spectral Density across A-Lines, 10 MModes");
            xlabel("Frequency (MHz)");
            ylabel("Amplitude ("+displayUnits+"/$\sqrt{Hz}$ )",'Interpreter','latex');ytickformat('%3.3f');
            legend(["Mean","STD+","STD-"]);
            
            
           
               
            
            %Average Spectral Density all channels
            fh=figure(figIdx+22);clf;%all other figures after the first one will be indexed based on previous
            hscrollbar=uicontrol('style','slider','units','normalized'...    %Scroll bar for plot 
                                              ,'UserData',rawFFT_FastRMS(1:round(size(rawFFT_FastRMS,1)/2),:,:)...
                                              ,'position',[0 0 1 .05]...
                                              ,'callback',@hscroll_ALine_Callback...
                                              ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                              , 'Value',defaultSlideVal/(2*(numChannels-1)));
            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);

            imagesc(fastTimeFreq(floor(size(rawFFT_FastRMS,1)/2)+1:end),(1:numChannels),rawFFT_FastRMS(1:round(size(rawFFT_FastRMS,1)/2),:)');
            colormap jet;cb=colorbar;cb.Label.Interpreter='latex';cb.Label.String="Amplitude("+displayUnits+"/$\sqrt{Hz}$)";
            title("Average Spectral Density across A-Lines, Electrode # "+string(defaultSlideVal));
            xlabel("Frequency (MHz)");
            ylabel("Channel #");
            
            
            %%% Slow Time RMS A Line
            stRMS=squeeze(rms(rawData,1));
            fh=figure(figIdx+23);clf;%all other figures after the first one will be indexed based on previous
            imagesc(slowTime,(1:numChannels),stRMS.');colormap jet;cb=colorbar;cb.Label.String="RMS Amplitude("+displayUnits+")";
            title("A-Line RMS per Electrode");
            xlabel("Slow Time A-Lines(ms)");
            ylabel("Channel #");
            
            
            %%% 2D FFT(Fast and Slow Time FFT)
            if show2DFFT
                rawDataFFT2=zeros(size(rawData));
                for i=1:size(rawData,3);
                rawDataFFT2(:,:,i)=fftshift(fft2(rawData(:,:,i)))/(size(rawData,1)*size(rawData,2));%Calc FFt along fast time for MMode
                end
                fh=figure(figIdx+24);clf;%all other figures after the first one will be indexed based on previous
                hscrollbar=uicontrol('style','slider','units','normalized'...    %Scroll bar for plot 
                                                  ,'UserData',abs(rawDataFFT2)...
                                                  ,'position',[0 0 1 .05]...
                                                  ,'callback',@hscroll_MMode_Callback...
                                                  ,'SliderStep',[1/(numChannels-1) 1/(numChannels-1)]...
                                                  , 'Value',defaultSlideVal/(2*(numChannels-1)));
                set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
                imagesc(slowTimeFreq(round(size(slowTimeFreq,2)/2)+1:end),...
                    fastTimeFreq(round(size(fastTimeFreq,2)/2)+1:end),...
                    abs(rawDataFFT2(round(size(rawDataFFT2,1)/2):end,round(size(rawDataFFT2,2)/2):end,defaultSlideVal)));...
                    colormap jet;cb=colorbar;cb.Label.String="Amplitude ("+displayUnits+")";
                title("Raw Data Fast and Slow Time FFT Electrode # "+string(defaultSlideVal));
                xlabel("Frequency(kHz)");
                ylabel("Frequency(MHz)");
            end 
        end
        
        
        %%% CORRELATION ANALYSIS
        if correlationAnalysis
            %%% Fast Time Correlation
                corrTot=zeros(size(rawData,1)*2-1,size(rawData,2),size(rawData,3),size(rawData,3));%(Correlation,Slow Index,Electrode)
                for i=1:size(rawData,2)
                    [tmp,lags]=xcorr(hilbert(rawData(:,i,:)),'norm');%tmp is (corrArray,corrIdx) or (FastTime, Electrode)
                    tmp2      = reshape(tmp,[],numChannels,numChannels);%magnitude
                    corrTot(:,i,:,:)=tmp2;

                end
            %%% Peak Correlation Corrollelogram
                mxMag=zeros(size(corrTot,3,4));
                mxAng=zeros(size(corrTot,3,4));

                for i=1:size(corrTot,3)
                    for j=1:size(corrTot,4)
                        mxMag(i,j)=max(max(abs(corrTot(:,:,i,j))));%find the max for a particular electrode pair "MMode fast time correlation"
                        mxAng(i,j)=max(max(abs(angle(corrTot(:,:,i,j)))));%Find max Angle
                    end
                end
                fh=figure(figIdx+30);clf;
                b=heatmap(mxMag);colormap(hot);%Give heatmap of max magnitude
                title("Cross Correlation Max Magnitude between electrodes");
            %%% Show Max Correlation Location on Electrode Pair
                [val1 idx1]=max(corrTot(:,:,1,2));
                [val2 idx2]=max(val1);
                sz=size(corrTot);
                fh=figure(figIdx+31);clf;
                imagesc(abs(corrTot(round(sz(1)/3):2*round(sz(1)/3),:,1,2)));colormap jet;cb=colorbar;cb.Label.String="Amplitude ("+displayUnits+")";
                title("MMode Correlation of ALines between electrodes"+string(1)+" , "+string(2)); 
                xlabel("Slow Time (ms)");
                ylabel("Cross Correlation Offset");
                %get max location and show that on "MMode Correlation"
                            [val1 idx1]=max(corrTot(round(sz(1)/3):2*round(sz(1)/3),:,1,2));
                            [val2 idx2]=max(val1);
                            pos=[idx2-1,idx1(idx2)-10,2,20];
                            rectangle('Position',pos,'EdgeColor',[0,0,0],'Curvature',[0.1,0.1],'LineWidth',3);
                            fh=figure(figIdx+32);clf;
                            set(axes,'Units','normalized','Position',[0.1300 0.18 0.7750 0.7500]);
                            plot(abs(corrTot(:,idx2,1,2)));
                            title(sprintf("XCorr of Electrodes %i&%i at line with peak correlation"));
                            xlabel("Cross Correlation Offset");
                            ylabel("Normalized Cross Correlation Value");
        end %%CORRELATION ANALYSIS
        
        
        
        %% Saving Plots and Data to Files
        %%% Save Plots to Files
        if savePlots
            
        %%% Write to Power point Presentations based on user selections. 
            %%% Raw MMode
                %Add Title Slide
                if fileIdx==1 
                        add(pptRaw,'Title Slide');
                        contents = find(pptRaw,'Title');
                        replace(contents(1),'Raw MMode');
                end
                %%% Add Data Slide
                figure(figIdx+11);
                exportgraphics(gca,[char(currentFile(1:end-4)) '___MMode.png'])
                tempPlot=Picture([char(currentFile(1:end-4)) '___MMode.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                temp_Slide=add(pptRaw,'Title and Content');
                replace(temp_Slide,'Title',[currentFile(length(path):end) 'MMode']);
                add(temp_Slide,tempPlot);
                
            %%% General Analysis Tables
            if generalAnalysis
                %Add Title Slide
                if fileIdx==1 
                        add(pptGenAnalysis,'Title Slide');
                        contents = find(pptGenAnalysis,'Title');
                        replace(contents(1),'General Analysis');
                end
                %%% Add Data Slide
                temp_Slide=add(pptGenAnalysis,'Title and Table');
                replace(temp_Slide,'Title',[currentFile(length(path):end) ' Gen An']);
                colSpecs(1)=ColSpec('1.5in');
                for c=2:numChannels+4
                    colSpecs(c)=ColSpec('1in');
                end
                pptTable=Table(analysisTable);
                pptTable.ColSpecs=colSpecs;
                replace(temp_Slide,'Table',pptTable);
            end
            
            %%% Spectrum Analysis
            if spectrumAnalysis
                %%% Spectrogram
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptSpect,'Title Slide');
                            contents = find(pptSpect,'Title');
                            replace(contents(1),'Spectrogram');
                    end
                    %%% Add Data Slide
                    figure(figIdx+20);
                    exportgraphics(gca,[char(currentFile(1:end-4)) '___Spect.png']);
                    tempPlot=Picture([char(currentFile(1:end-4)) '___Spect.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptSpect,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' Spectrogram']);
                    add(temp_Slide,tempPlot);

                %%% Average Spectral Density, A Line
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptAvg_SD_ALine,'Title Slide');
                            contents = find(pptAvg_SD_ALine,'Title');
                            replace(contents(1),'Average Spectral Density');
                    end
                    %%% Add Data Slide
                    figure(figIdx+21);
                    exportgraphics(gca,[char(currentFile(1:end-4)) '___ASDA.png']);
                    tempPlot=Picture([char(currentFile(1:end-4)) '___ASDA.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptAvg_SD_ALine,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' Average SD: A-Line']);
                    add(temp_Slide,tempPlot);
                %%% Average Spectral Density
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptAvg_SD,'Title Slide');
                            contents = find(pptAvg_SD,'Title');
                            replace(contents(1),'Average Spectral Density');
                    end
                    %%% Add Data Slide
                    figure(figIdx+22);
                    exportgraphics(gca,[char(currentFile(1:end-4)) '___ASD.png']);
                    tempPlot=Picture([char(currentFile(1:end-4)) '___ASD.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptAvg_SD,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' Average SD']);
                    add(temp_Slide,tempPlot);
                    
                %%% Slow Time RMS of A-Lines
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptST_RMS,'Title Slide');
                            contents = find(pptST_RMS,'Title');
                            replace(contents(1),'RMS of A-Lines for Each Electrode');
                    end
                    %%% Add Data Slide
                    figure(figIdx+23);
                    exportgraphics(gca,[char(currentFile(1:end-4)) '___STRMS.png']);
                    tempPlot=Picture([char(currentFile(1:end-4)) '___STRMS.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptST_RMS,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' RMS']);
                    add(temp_Slide,tempPlot);
            end
            
            %%% Cross Correlation Analysis
            if correlationAnalysis
                %%% Cross Correlation MMode
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptCorr1,'Title Slide');
                            contents = find(pptCorr1,'Title');
                            replace(contents(1),'Cross Corrolation MMode');
                    end
                    %%% Add Data Slide
                    figure(figIdx+30);
                    exportgraphics(gca,[char(currentFile(length(path)+1:end-4)) '___CCMM.png']);
                    tempPlot=Picture([char(currentFile(length(path)+1:end-4)) '___CCMM.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptCorr1,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' CC MMode']);
                    add(temp_Slide,tempPlot);
                
                %%% Cross Correlation Peak
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptCorr2,'Title Slide');
                            contents = find(pptCorr2,'Title');
                            replace(contents(1),'Cross Correlation Peak');
                    end
                    %%% Add Data Slide
                    figure(figIdx+31);
                    exportgraphics(gca,[char(currentFile(length(path)+1:end-4)) '___CCP.png']);
                    tempPlot=Picture([char(currentFile(length(path)+1:end-4)) '___CCP.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptCorr2,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' Correlation Peak']);
                    add(temp_Slide,tempPlot);
                
                %%% Cross Correlation MMode
                    %Add Title Slide
                    if fileIdx==1 
                            add(pptCorr3,'Title Slide');
                            contents = find(pptCorr3,'Title');
                            replace(contents(1),'Cross Correlation Correlelogram');
                    end
                    %%% Add Data Slide
                    figure(figIdx+33);
                    exportgraphics(gca,[char(currentFile(length(path)+1:end-4)) '___CCC.png']);
                    tempPlot=Picture([char(currentFile(length(path)+1:end-4)) '___CCC.png']);tempPlot.Width='6.8in';tempPlot.Height='4.8in';tempPlot.X='6in';tempPlot.Y='2in';
                    temp_Slide=add(pptCorr3,'Title and Content');
                    replace(temp_Slide,'Title',[currentFile(length(path):end) ' Correlelogram']);
                    add(temp_Slide,tempPlot);
            end
        end
            
        %%% Save Raw/Filtered Data to file. 
        %%% Save Correlation Data to file
    end % End For loop for Files
    if savePlots
        close(pptRaw);
            if generalAnalysis
                close(pptGenAnalysis);
            end
            if spectrumAnalysis
                close(pptSpect);
                close(pptAvg_SD);
                close(pptAvg_SD_ALine);
                close(pptST_RMS);
            end
            if correlationAnalysis
                close(pptCorr1);
                close(pptCorr2);
                close(pptCorr3);
            end
        delete *.png
    end
    toc;
    
    %% Repeat Program if Desired
    if lower(input("Repeat?(Y/N): ",'s'))=="y"
        display("Another Round");
    else
        display("Goodbye");
        clear;
        close all;
        break
    end
end
end

%% Functions
    %% Processing Functions
    
        %% Reading Functions
        %%%% Read Photosound Data
        function [rawData,scanParam]=readPS(filename)
            %%% Read in Data from Photosound
            global numPreAvg;
            load(filename);%load in data into workspace.
            
            %%% Get Scan parameters
            scanParam.fsFastTime=double(sample_rate/10^6);%Fast Time Sampling Frequency
            scanParam.numSamplesFastTime=double(size(data_0,1));% Number of Fast time samples
            scanParam.fsSlowTime=4000;%input("Slow Time Sampling Rate(Hz)? ");%Slow Time Sampling Frequency  TODO: CHARLES CHANGE to an automatic input
            display("Charles Fix This!");
            scanParam.numSamplesSlowTime=double(size(packet_number,1)/numPreAvg);% Number of Slow Time Samples

            scanParam.fastTimeRange=[0 (round(scanParam.numSamplesFastTime)-1)/(scanParam.fsFastTime)];%get fast time range, does not include actual delay for transducer
            scanParam.fastTime=linspace(scanParam.fastTimeRange(1),scanParam.fastTimeRange(2),scanParam.numSamplesFastTime);
            scanParam.fastTimeFreq=linspace(-scanParam.fsFastTime/2,scanParam.fsFastTime/2,round(scanParam.numSamplesFastTime));
            scanParam.slowTimeRange=[0 scanParam.numSamplesSlowTime/scanParam.fsSlowTime];%get slow time range
            scanParam.slowTime=1000*linspace(scanParam.slowTimeRange(1),scanParam.slowTimeRange(2),scanParam.numSamplesSlowTime);
            scanParam.slowTimeFreq=linspace(-scanParam.fsSlowTime/1000/2,scanParam.fsSlowTime/1000/2,scanParam.numSamplesSlowTime);%frequencies, in kHz
            scanParam.scanSize=1;% TODO: Change this to not be hard coded
            
            %%% Reformat Data  TODO: CHARLES CHANGE for scan points
            scanParam.numChannels=size(data_0,2)*size(data_0,3);
            rawData=zeros(size(data_0,1),double(size(packet_number,1)),scanParam.numChannels);
            for i=1:double(size(packet_number,1))
                    temp=eval(['data_' char(string(i-1))]);

                    if(scanParam.numChannels==32&&(size(data_0,2)>16))
                        rawData(:,i,1:floor(scanParam.numChannels/2))=temp(:,:,1);
                        rawData(:,i,ceil(scanParam.numChannels/2):end)=temp(:,:,2);
                    elseif(scanParam.numChannels==32&&(size(data_0,2)*size(data_0,3)==32))
                        rawData(:,i,1:floor(scanParam.numChannels/2))=temp(:,:,1);
                        rawData(:,i,floor(scanParam.numChannels/2)+1:end)=temp(:,:,2);
                    else
                        rawData(:,i,1:scanParam.numChannels)=temp(:,:,2);%Do this temporarily CHARLES REMOVE. 
                    end
            end
            
        end
        
        %%%% Read National Instruments Data
        function [rawData,scanParam]=readNI(filename)
            %%%Read in Data from NI
            %Get scan parameters
            scanInfo=matfile(filename).bScanParm;
            
            scanParam.fsFastTime=scanInfo.Daq.HF.Rate_mhz;%Fast Time Sampling Frequency
            scanParam.numSamplesFastTime=round(scanInfo.Daq.HF.Samples);% Number of Fast time samples
            scanParam.fsSlowTime=scanInfo.Daq.HF.PulseRate;%input("Slow Time Sampling Rate(Hz)? ");%Slow Time Sampling Frequency  TODO: CHARLES CHANGE to an automatic input
            display("Charles Fix This!");
            scanParam.numSamplesSlowTime=scanInfo.Scan.Tpt;% Number of Slow Time Samples

            scanParam.fastTimeRange=[0 (round(scanInfo.Daq.HF.Samples)-1)/(scanInfo.Daq.HF.Rate_mhz)];%get fast time range, does not include actual delay for transducer
            scanParam.fastTime=linspace(scanParam.fastTimeRange(1),scanParam.fastTimeRange(2),round(scanInfo.Daq.HF.Samples));
            scanParam.fastTimeFreq=linspace(-scanInfo.Daq.HF.Rate_mhz/2,scanInfo.Daq.HF.Rate_mhz/2,round(scanInfo.Daq.HF.Samples));
            scanParam.slowTimeRange=[0 scanInfo.Scan.Duration_ms];%get slow time range
            scanParam.slowTime=linspace( scanParam.slowTimeRange(1), scanParam.slowTimeRange(2),scanInfo.Scan.Tpt);
            scanParam.slowTimeFreq=linspace(-scanInfo.Daq.HF.PulseRate/1000/2,scanInfo.Daq.HF.PulseRate/1000/2,scanInfo.Scan.Tpt);%frequencies, in kHz


            %Get hf Data
            scanParam.scanSize=scanInfo.Scan.Xpt*scanInfo.Scan.Ypt;
            scanParam.numChannels=str2num(scanInfo.Daq.HF.Channels(end))-str2num(scanInfo.Daq.HF.Channels(1))+1;
            hfDataTemp=Read_Data([filename],1);%Read in Hf data for particular point (Fast, Slow, Channel)
            rawData=zeros([size(hfDataTemp)]);% scanSize was included as a last dimension
            rawData(:,:,:)=Read_Data(filename,scanInfo.Scan.Xpt);%   TODO: Charles change... It should be scan point...

        end
        
         %%%% Read H5 File
        function [rawData,scanParam]=readH5(path,filename)
            %%%Read in Data 
            %Get scan parameters
            rootFolder=path(1:findstr(path,"ExpData")+7);
            postIdx=findstr(filename,"Raw");
            infoFilename=filename(1:findstr(filename,"Raw")-1)+"info.mat";
            scanInfo=matfile(string(rootFolder)+string(infoFilename)).bScanParm;
            
            scanParam.fsFastTime=scanInfo.Daq.HF.Rate_mhz;%Fast Time Sampling Frequency
            scanParam.numSamplesFastTime=round(scanInfo.Daq.HF.Samples);% Number of Fast time samples
            scanParam.fsSlowTime=scanInfo.Daq.HF.PulseRate;%input("Slow Time Sampling Rate(Hz)? ");%Slow Time Sampling Frequency  TODO: CHARLES CHANGE to an automatic input
            display("Charles Fix This!");
            scanParam.numSamplesSlowTime=scanInfo.Scan.Tpt;% Number of Slow Time Samples

            scanParam.fastTimeRange=[0 (round(scanInfo.Daq.HF.Samples)-1)/(scanInfo.Daq.HF.Rate_mhz)];%get fast time range, does not include actual delay for transducer
            scanParam.fastTime=linspace(scanParam.fastTimeRange(1),scanParam.fastTimeRange(2),round(scanInfo.Daq.HF.Samples));
            scanParam.fastTimeFreq=linspace(-scanInfo.Daq.HF.Rate_mhz/2,scanInfo.Daq.HF.Rate_mhz/2,round(scanInfo.Daq.HF.Samples));
            scanParam.slowTimeRange=[0 scanInfo.Scan.Duration_ms];%get slow time range
            scanParam.slowTime=linspace( scanParam.slowTimeRange(1), scanParam.slowTimeRange(2),scanInfo.Scan.Tpt);
            scanParam.slowTimeFreq=linspace(-scanInfo.Daq.HF.PulseRate/1000/2,scanInfo.Daq.HF.PulseRate/1000/2,scanInfo.Scan.Tpt);%frequencies, in kHz


            %Get hf Data
            scanParam.scanSize=scanInfo.Scan.Xpt*scanInfo.Scan.Ypt;
            scanParam.numChannels=str2num(scanInfo.Daq.HF.Channels(end))-str2num(scanInfo.Daq.HF.Channels(1))+1;
            rawData=h5read(string(path)+string(filename),'/HF');% scanSize was included as a last dimension

        end
        
        
        %% Write Data
    %% CallBacks
    
function hscroll_MMode_Callback(src,event,handles)
%get figure and axis data(the ticker values
fg=figure(src.Parent);
axes=gca;%Get Current Axes Object
axObj=findobj(fg,'-property','YData');
xAxis=axObj.XData;
yAxis=axObj.YData;
axes=gca;
xLabelOld=axes.XLabel.String;
yLabelOld=axes.YLabel.String;

poundInd=strfind(axes.Title.String,'#');
titleOld=axes.Title.String(1:poundInd+1);%Finds the # symbol and doesnt use electrode number

colorBarOld=axes.Colorbar.Label.String;
tempD=src.UserData;
val=get(src,'value');
numChan=size(tempD,3)-1;
val=round(val*(numChan));
set(src,'value',(val)/(numChan));
val=val+1;

timePlotData=tempD(:,:,val);
imagesc(xAxis,yAxis,timePlotData);
title(titleOld+string(val));;colormap jet;cb=colorbar;cb.Label.String=colorBarOld;

end

function hscroll_ALine_Callback(src,event,handles)
%get figure and axis data(the ticker values
fg=figure(src.Parent);
axes=gca;%Get Current Axes Object
axObj=findobj(fg,'-property','YData');
xAxis=axObj.XData;%XValues
poundInd=strfind(axes.Title.String,'#');
titleOld=axes.Title.String(1:poundInd+1);%Finds the # symbol and doesnt use electrode number
ylabelOld=axes.YLabel.String;
xlabelOld=axes.XLabel.String;

tempD=src.UserData;%Data from src
%Get Data from Event

val=get(src,'value');
numChan=size(tempD,2)-1;
val=round(val*(numChan));
set(src,'value',(val)/(numChan));
val=val+1;

timePlotData=tempD(:,val);
plot(xAxis,timePlotData);
title(titleOld+string(val));
ylabel(ylabelOld,'Interpreter','latex');
xlabel(xlabelOld,'Interpreter','latex');
end

%Correlation Plots Callback
function heatmapY_MModeCorr_Callback(src,event,handles)
%get figure and axis data(the ticker values
fg=figure(src.Parent);
get(gca,'CurrentPoint');
axes=gca;%Get Current Axes Object
axObj=findobj(fg,'-property','YData');
xAxis=axObj.XData;
yAxis=axObj.YData;
axes=gca;
xLabelOld=axes.XLabel.String;
yLabelOld=axes.YLabel.String;
colorBarOld=axes.Colorbar.Label.String;
tempD=src.UserData;
val=get(src,'value');
numChan=5;
val=round(val*(numChan));
set(src,'value',(val)/(numChan));
val=val+1;

timePlotData=tempD(:,:,val);
imagesc(xAxis,yAxis,timePlotData);
title(sprintf("Raw Data, Electrode # %i",val));colormap jet;cb=colorbar;cb.Label.String=colorBarOld;

end

