function [mask] = Hann2(bandreject1,bandpass1,bandpass2,bandreject2,lengthIn,Fs)%pass the the frequencies in in the units used
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here


fBinScaleFactor=Fs/(lengthIn);%calculate the relative "Size" in frequency per frequency bin]\

%Calculate "Bin locations" for respective frequency cuttoffs. 
flow1=floor(bandreject1/fBinScaleFactor)+1;
flow2=floor(bandpass1/fBinScaleFactor)+1;
fhigh1=ceil(bandpass2/fBinScaleFactor)+1;
fhigh2=ceil(bandreject2/fBinScaleFactor)+1;

hannSize1 = 2*(flow2 - flow1);
hannSize2 = 2*(fhigh2 - fhigh1);

%calculate hann bits
low=hann(2*(flow2-flow1))';
high=hann(2*(fhigh2-fhigh1))';
mask=zeros(1,round(lengthIn/2)+1);
mask(flow1:flow2)=low(1:round(length(low)/2)+1);
mask(flow2:fhigh1)=1;
mask(fhigh1:fhigh2)=high(round(length(high)/2:end));
mask=[mask(1:ceil(lengthIn/2)) flip(mask(2:floor(lengthIn/2)+1))];


end

