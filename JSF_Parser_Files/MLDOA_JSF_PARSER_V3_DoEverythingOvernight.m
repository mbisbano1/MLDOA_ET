format long ;
clear variables ;
close all ;
clc       ;
%% Path Setup and File Open
[JSFfpath, CSVfpath, AIOUTPUTCSVfpath] = MB_FPATH_SET();
%[JSFfpath, CSVfpath] = RF_FPATH_SET();
%[JSFfpath, CSVfpath] = DL_FPATH_SET();


try
    [JSFfilename,JSFfpath]=uigetfile([JSFfpath '/*.jsf'], 'Which file to process for Stave Data?'); %open file and assign handle
catch
    [JSFfilename,JSFfpath]=uigetfile('*.jsf', 'Which file to process for Stave Data?'); %open file and assign handle
end
JSF_Stave_fp = fopen([JSFfpath,JSFfilename],'r');


try
    [JSFfilename2,JSFfpath]=uigetfile([JSFfpath '/*.jsf'], 'Which file to process for Bathy Measurements Data?'); %open file and assign handle
catch
    [JSFfilename2,JSFfpath]=uigetfile('*.jsf', 'Which file to process for Bathy Measurements Data?'); %open file and assign handle
end
JSF_Processed_fp = fopen([JSFfpath,JSFfilename2],'r');



CSVfiles = split(JSFfilename, "_Stave.jsf");
CSVfilePort = strcat(CSVfiles{1,1}, '_port_new.CSV');
CSVfileStbd = strcat(CSVfiles{1,1}, '_stbd_new.CSV');
defaultCSVfilenamePort = fullfile(CSVfpath, CSVfilePort);
defaultCSVfilenameStbd = fullfile(CSVfpath, CSVfileStbd);

[OutputFileNamePort,CSVfpath] = uiputfile(defaultCSVfilenamePort, 'Where to save Port Output CSV?');
[OutputFileNameStbd,CSVfpath] = uiputfile(defaultCSVfilenameStbd, 'Where to save Stbd Output CSV?');



beep
%% Output File Matrix setup

	%OutMat = -69.*ones(1287*4340, 32);
    OutMat = -69.*ones(888*6508, 32);
	%OutMat = -69.*ones(11*4340, 32);
	
%% Acoustic Frequency and Sample Frequency Test setup:
    ReportedAcousticStartFrequency = nan;
    ReportedAcousticStopFrequency = nan;
    ReportedAcousticMixerFrequency = nan;
    
    ReportedSampleFrequency = nan;
    
    
%% Message 2020 Data:

% Create Rolls Matrix, which holds every Roll measurement and timestamp;
% User defineable parameters
    RollCnt = 1 ;
% Initialize Message 2020 Rolls() elements for efficiency
    Rolls = NaN(20000, 2) ;
	
	
%% Message 2060 Data:
% Create SoundSpeeds Matrix, which holds every speed of sound measurement and
% timestamp;

% User defineable parameters
    SoundCnt = 1 ;
% Initialize Message 2060 Speeds() elements for efficiency
    SoundSpeeds = NaN(1000, 2) ;
    % timestamp = SoundSpeeds(Count number, 1)
    % soundspeed = SoundSpeeds(Count number, 2)
	
	
	
%% Message 80 Data:
% Create Pings Structure, which holds each ping and its corresponding data.

% User defineable parameters

    %SamplesPerPing = 4340 ;     % 4340 samples per ping (IN FIRST TEST FILE)
    SamplesPerPing = 6508 ; 
    PingCtr = 1 ;
    %MaxPingCtr = 10 ;
    %MaxPingCtr = 1287 ;
    MaxPingCtr = 888 ;
    NumChannelsPerSample = 20 ; %[1,2, ... 10] Port ||| [11, 12, ... 20] Stbd
                                    % 1 and 11 being the closest to seabed

% Initialize Message 80 Pings() elements for efficiency
    % PingIndex refers to the indexes, starting at 1 to MaxPingCtr

    %   PingNum(PingIndex)      %not sure the use of this, but will be helpful
    %   to determine if we are off by an index of one!
    Pings.PingNum = NaN(MaxPingCtr, 1) ;
                % First PingNum:    87437
                % Last PingNum:     88723
    
    %   NumSamples(PingIndex)
    Pings.NumSamples = NaN(MaxPingCtr, 1) ;

    %   PingTimeStamps(PingIndex)
    Pings.PingTimeStamps = NaN(MaxPingCtr, 1) ;
    
    %                                           1       2
    %   StaveData(PingIndex, Channel#, Sample#, Timestamp/Data)  Channels 1-10 port, 11-20 stbd
    Pings.StaveData = NaN(MaxPingCtr, NumChannelsPerSample, SamplesPerPing, 2) ; 
    % EX. t = Ping 3, Stbd Channel 9, Sample 206, Timestamp: 
    %   t = Pings.StaveData(3, 19, 206, 1) ;
    % EX. d = Ping 3, Stbd Channel 9, Sample 206, Data: 
    %   d = Pings.StaveData(3, 19, 206, 2) ;    
    Pings.SampleFreq = NaN(MaxPingCtr, 1);
while PingCtr <= MaxPingCtr
    
    [mH, data, header] = readJSFv3_small(JSF_Stave_fp, [1, 5, 6]) ; % read all types of data
    
    if mH.contentType < 1 % should check for cause of error to display information about break condition
        
        break
    elseif ((mH.contentType == 1) && (mH.messageType == 80))  % Message 80!
        if mH.subsystem == 40 || mH.subsystem == 40 % stave data combining port and starboard
            pingnumby = header.pingNum ;
            Pings.PingNum(PingCtr, 1) = header.pingNum ;
            Pings.NumSamples(PingCtr, 1) = header.samples ;
            Pings.PingTimeStamps(PingCtr, 1) = header.timeStamp ;
            
            
            
            df = header.dataFormat ;
            fs = header.fs;
            if df == 2
               fs = header.fs / 2; 
            end
            ReportedAcousticStartFrequency = header.startf;
            ReportedAcousticStopFrequency = header.stopf;
            ReportedAcousticMixerFrequency = header.mixerFreq;
            ReportedSampleFrequency = fs;
            
            Pings.SampleFreq(PingCtr, 1) = fs;
            %x = 1:20 ;
            %y = 1:header.samples ;
            Pings.StaveData(PingCtr, 1:20, 1:header.samples, 2) = data.samples(1:20, 1:header.samples) ; 
            %numSamples = header.samples ;
            %stavePort = data.samples(1:10,:) ; % stave order: stave 1 closest to seabed stave 10 closest to surface
            %staveStarboard = data.samples(11:20,:) ; % % stave order: stave 11 closest to seabed stave 20 closest to surface
            %timestamp = header.timeStamp ;
            
            
            PingCtr = PingCtr+1;
            % apply your processing here
        end    
        
    elseif ((mH.contentType == 5) && (mH.messageType == 2020))  % Message 2020
        %data.flags
        % 49 is the ASCII num for '1' char, so if ROLL flag is '1' !
        if 49 == double(data.flags(8))
            Rolls(RollCnt, 1) = header.timeStamp ;
            Rolls(RollCnt, 2) = data.roll ;
            RollCnt = RollCnt + 1 ; 
        end 
        
    elseif ((mH.contentType == 6) && (mH.messageType == 2060))  % Message 2060
        if bitget(data.flag, 5)
        SoundSpeeds(SoundCnt, 1) = header.timeStamp ;
        SoundSpeeds(SoundCnt, 2) = data.sv ;
        SoundCnt = SoundCnt + 1 ;
        end
    end
    if ~mod(PingCtr,100)
                fprintf('.')
    end
    
end
beep
fprintf('\nStave Data Processed\n')

%% Extract Message 3000 Data:
% Create Measurements Structure, which holds each measurement and its corresponding data.

% User defineable parameters
    figureOffset = 0 ;
    M_Ctr_Port = 1 ;
    M_Ctr_Stbd = 1 ;
    PoBathyCtr = 1 ;
    StBathyCtr = 1 ;
    PortRange = NaN(5000,5000) ;
    PortRTT = NaN(5000, 5000) ;
    PortAngle = NaN(5000,5000) ;
    PortAmp = NaN(5000,5000) ;
    PortMaxSound = -1 ;

    StbdRange = NaN(5000,5000) ;
    StbdRTT = NaN(5000, 5000) ;
    StbdAngle = NaN(5000,5000) ;
    StbdAmp = NaN(5000,5000) ;
    StbdMaxSound = -1 ;

% Initialize Message 3000 Measurements() elements for efficiency

    %                                       Port/Stbd
    Measurements.PingNum = NaN(MaxPingCtr, 2) ;
    %                                       Port/Stbd
    Measurements.NumSamples = NaN(MaxPingCtr, 2) ;
    %                                       Port/Stbd
    Measurements.PingTimeStamps = NaN(MaxPingCtr, 2) ;
    %                                       Port/Stbd
    Measurements.timeToFirstSample = NaN(MaxPingCtr, 2) ;
    %Measurements.AngleScaleFactor = NaN(MaxPingCtr, 2) ;
    
    Measurements.SampleTimeStamp = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.TWTT = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.Angle = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.Amplitude = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.AngleUncertainty = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.SampleRate = NaN(MaxPingCtr, 2, SamplesPerPing);
    Measurements.DelayIndex = NaN(MaxPingCtr, 2, SamplesPerPing);
%                              (1   2)              (1       2    3       4            5             6)                                
% MeasurementData(PingIndex , Port/Stbd, Sample#, TimeStamp/RTT/Angle/Amplitude/AngleUncertainty/SampleRate)
    %Measurements.MeasurementData = NaN(MaxPingCtr, 2, SamplesPerPing, 6) ;
    
    %********************RYAN********************************************
    %the RTT represents the measured round trip time (between the instant
    %the ping went out and the sample was recorded. This needs to be
    %divided by 2 and multiplied by the most recent measurement of the
    %sound speed to get the RANGE!
    %********************************************************************
    
while ((M_Ctr_Port <= MaxPingCtr) || (M_Ctr_Stbd <= MaxPingCtr))
   
    [mH, data, header] = readJSFv3_small(JSF_Processed_fp, [42]) ; % read all types of data
    
    if mH.contentType < 1 % should check for cause of error to display information about break condition
        
        break
    
    elseif ((mH.contentType == 42) && (mH.messageType == 3000)) % bathy data
        
        if ((header.channel == 0) && (M_Ctr_Port <= MaxPingCtr))  % port
            Measurements.PingNum(M_Ctr_Port, 1) = header.pingNum ;
            Measurements.NumSamples(M_Ctr_Port, 1) = header.nsamps ;
            Measurements.PingTimeStamps(M_Ctr_Port, 1) = header.timeStamp ;
            Measurements.timeToFirstSample(M_Ctr_Port, 1) = header.timeToFirstSample ;
            %Measurements.AngleScaleFactor(M_Ctr_Port, 1) = header.angleScaleFactor;
            %PortRange(PoBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            
            Measurements.DelayIndex(M_Ctr_Port, 1, 1:header.nsamps) = data.DelayIndex ;
            %PortRTT(PoBathyCtr, 1:header.nsamps) = data.TWTT ;         
            %Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 2) = data.TWTT ;
            Measurements.TWTT(M_Ctr_Port, 1, 1:header.nsamps) = data.TWTT ;
            
            %PortAngle(PoBathyCtr,1:header.nsamps) = -data.Angle ;
            %Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 3) = -data.Angle ;
            Measurements.Angle(M_Ctr_Port, 1, 1:header.nsamps) = data.Angle ;
            
            %PortAmp(PoBathyCtr,1:header.nsamps) = data.Amp ;
            %Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 4) = data.Amp ;
            Measurements.Amplitude(M_Ctr_Port, 1, 1:header.nsamps) = data.Amp ;
            
            %Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 5) = data.Sigma ;
            Measurements.AngleUncertainty(M_Ctr_Port, 1, 1:header.nsamps) = data.Sigma ;
            
            %Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 6) = header.fsample ;
            Measurements.SampleRate(M_Ctr_Port, 1, 1:header.nsamps) = header.fsample ;
            
            PortHeader(PoBathyCtr) = header ;
            if header.nsamps > PortMaxSound
                PortMaxSound = header.nsamps ;
            end
            PoBathyCtr = PoBathyCtr + 1 ;
            if ~mod(PoBathyCtr,100)
                fprintf('.')
            end
            
            M_Ctr_Port = M_Ctr_Port + 1 ;
            
        elseif ((header.channel == 1) && (M_Ctr_Stbd <= MaxPingCtr)) % Stbd
            Measurements.PingNum(M_Ctr_Stbd, 2) = header.pingNum ;
            Measurements.NumSamples(M_Ctr_Stbd, 2) = header.nsamps ;
            Measurements.PingTimeStamps(M_Ctr_Stbd, 2) = header.timeStamp ;
            Measurements.timeToFirstSample(M_Ctr_Stbd, 2) = header.timeToFirstSample ;
            %Measurements.AngleScaleFactor(M_Ctr_Stbd, 2) = header.angleScaleFactor;
            
            %StbdRange(StBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            
            Measurements.DelayIndex(M_Ctr_Stbd, 2, 1:header.nsamps) = data.DelayIndex ;
            
            %StbdRTT(StBathyCtr, 1:header.nsamps) = data.TWTT ;
            %Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 2) = data.TWTT ;
            Measurements.TWTT(M_Ctr_Stbd, 2, 1:header.nsamps) = data.TWTT ;
            
            %StbdAngle(StBathyCtr,1:header.nsamps) =  data.Angle  ;
            %Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 3) = -data.Angle ;
            Measurements.Angle(M_Ctr_Stbd, 2, 1:header.nsamps) = data.Angle ;  
            
            %StbdAmp(StBathyCtr,1:header.nsamps) = data.Amp ;
            %Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 4) = data.Amp ;
            Measurements.Amplitude(M_Ctr_Stbd, 2, 1:header.nsamps) = data.Amp ;
            
            %Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 5) = data.Sigma ;
            Measurements.AngleUncertainty(M_Ctr_Stbd, 2, 1:header.nsamps) = data.Sigma ;
            
            
            %Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 6) = header.fsample ;
            Measurements.SampleRate(M_Ctr_Stbd, 2, 1:header.nsamps) = header.fsample ;
            
            StbdHeader(StBathyCtr) = header ;
            
            
            if header.nsamps > StbdMaxSound
                StbdMaxSound = header.nsamps ;
            end
            M_Ctr_Stbd = M_Ctr_Stbd + 1 ;
            StBathyCtr = StBathyCtr + 1 ;
            
        end
        
    end
end

fprintf('\nBathy Data Processed\n');
beep

%% 
figure(1);
plot(Measurements.NumSamples(:,1));
hold on;
plot(Measurements.NumSamples(:,2));
legend('Port', 'Stbd');
title('Number of Samples Per Each Ping');
xlabel('Ping Number');
ylabel('Number of Samples');
hold off;
%% TWTT Time Synchronization

fs=Measurements.SampleRate(1,1, 1);     % Sample Frequency taken from Measurements
%fs = Pings.SampleFreq(1,1,1) ;
% this is implemented just for the first ping..
ThisPingNumber = 1; % ping 1
PortOrStarboard = 1; % port
%TWTTs = squeeze(Measurements.TWTT(ThisPingNumber, PortOrStarboard, :));
%NumOfSampleSincePing = TWTTs./(1/fs);
% round and then remove NaN values..
%RoundedNumOfSampleSincePing = rmmissing(round(NumOfSampleSincePing));
NumSoundings = length(rmmissing(unique(squeeze(Measurements.DelayIndex(1,1,:))))) ;

%

%                                       Port/Stbd
%Measurements.PingNum = NaN(MaxPingCtr, 2) ;
%                                       Port/Stbd
%Measurements.NumSamples = NaN(MaxPingCtr, 2) ;
%                                       Port/Stbd
%Measurements.PingTimeStamps = NaN(MaxPingCtr, 2) ;
%                                       Port/Stbd
%Measurements.timeToFirstSample = NaN(MaxPingCtr, 2) ;

Soundings.NumSamples = Measurements.NumSamples;
Soundings.PingNum = Measurements.PingNum;
Soundings.PingTimeStamps = Measurements.PingTimeStamps;
Soundings.TWTT = NaN(MaxPingCtr, 2, SamplesPerPing);
Soundings.Angle = NaN(MaxPingCtr, 2, SamplesPerPing);
Soundings.Amplitude = NaN(MaxPingCtr, 2, SamplesPerPing);
Soundings.AngleUncertainty = NaN(MaxPingCtr, 2, SamplesPerPing);
Soundings.SampleRate = NaN(MaxPingCtr, 2, SamplesPerPing);
%Soundings.Range = NaN(MaxPingCtr, 2, SamplesPerPing); 

for portPings = 1:MaxPingCtr
   TWTTs = squeeze(Measurements.TWTT(portPings, 1, :));
   %RNSSP = Rounded Number Of Samples Since Ping
   RNSSP = rmmissing(round(TWTTs./(1/fs)));
   for portSamps = 1:length(RNSSP)
        Soundings.TWTT(portPings, 1, RNSSP(portSamps)+1) = Measurements.TWTT(portPings, 1, portSamps);
        Soundings.Angle(portPings, 1, RNSSP(portSamps)+1) = Measurements.Angle(portPings, 1, portSamps).*(180/pi);    % now in degrees
        Soundings.Amplitude(portPings, 1, RNSSP(portSamps)+1) = Measurements.Amplitude(portPings, 1, portSamps);
        Soundings.AngleUncertainty(portPings, 1, RNSSP(portSamps)+1) = Measurements.AngleUncertainty(portPings, 1, portSamps);
        Soundings.SampleRate(portPings, 1, RNSSP(portSamps)+1) = Measurements.SampleRate(portPings, 1, portSamps);
   end
end

for stbdPings = 1:MaxPingCtr
   TWTTs = squeeze(Measurements.TWTT(stbdPings, 2, :));
   %RNSSP = Rounded Number Of Samples Since Ping
   RNSSP = rmmissing(round(TWTTs./(1/fs)));
   for stbdSamps = 1:length(RNSSP)
        Soundings.TWTT(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.TWTT(stbdPings, 2, stbdSamps);
        Soundings.Angle(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.Angle(stbdPings, 2, stbdSamps).*(180/pi);
        Soundings.Amplitude(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.Amplitude(stbdPings, 2, stbdSamps);      % now in degrees
        Soundings.AngleUncertainty(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.AngleUncertainty(stbdPings, 2, stbdSamps);
        Soundings.SampleRate(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.SampleRate(stbdPings, 2, stbdSamps);
   end
end

fprintf('TWTT to SampleNumber Synchronization done\n\n');
beep
%% Extract Port and Stbd Stave Data Arrays
    %compensate for unintuitive array indices.
    portIndices = 1:2:size(Pings.StaveData, 2);
    stbdIndices = size(Pings.StaveData, 2):-2:2;
    Pings.PortStaveData = Pings.StaveData(:, portIndices, :, 2);
    Pings.StbdStaveData = Pings.StaveData(:, stbdIndices, :, 2);
beep

%% Format all this information into OutMat
% Data Formatting

% Sample Delay Column
fs=Measurements.SampleRate(1,1, 1);     % Sample Frequency taken from MeasurementData.. Much higher resolution
    %fs = Pings.SampleFreq(1,1,1);
SDA = zeros(Pings.NumSamples(1),2);               % Array to allocate Sample Delay Info
TSA = zeros(Pings.NumSamples(1),2);                % Array to allocate Time Stamps. Used for comparing timings for roll and Sound Speed Data
for p = 1:length(Pings.PingTimeStamps) % the amount of pings we need data from
        sdr = 0:1/fs:(Pings.NumSamples(p)-1)/fs; %double(Pings.PingTimeStamps(p):1/fs:(Pings.PingTimeStamps(p) + ((Pings.NumSamples(p)-1)/fs))); % row vector for sample delay of ping p
        SDA(:,p) = sdr(1,:)'; % array with all time delays. Column i corresponds to ping i
        %vp = vpa(TSC);
end

% Bring Formatted Data into OutMat
row=1; % Instantiation of a row. Keeps track of which row in OutMat the system is currently on
b=1;
s=1;
rollTime=1;
SoundTime=1;
%port_or_stbd = input('Create "port" or "stbd" CSV  ', 's');
prompt = 'Create port or stbd CSV? Enter p or s:   ';
port_or_stbd = 'p';%input(prompt, 's');
port_stbd_value = -1;
if isequal(port_or_stbd, 'p')
    port_stbd_value = 0;
elseif isequal(port_or_stbd, 's')
    port_stbd_value = 1;    
end 
%for i = 1:length(Pings.PingTimeStamps) % total iterations needed for each ping in a .jsf
for CurrentPing = 1:MaxPingCtr
	fprintf('CurPing(port) = %d\n', CurrentPing);
    for CurrentSample = 1:Pings.NumSamples(CurrentPing)
     
        OutMat(row,1) = CurrentPing;    % Ping Number Column. Is adjusted directly by MaxPingCtr
        OutMat(row,1) = Soundings.PingNum(CurrentPing, 1+port_stbd_value);
        %pNum=pNum+1;
        
        OutMat(row,2) = CurrentSample;    % Sample Number Column
        %sNum=sNum+1;
        
        OutMat(row,3) = port_stbd_value;    % Port/Stbd. 0 -> Port, 1 -> Stbd.
        
        OutMat(row,4) = SDA(CurrentSample,CurrentPing); % Sample Delay data brought into OutMat
        %sDelay = sDelay + 1;
        
        chanI = 1;   % Variable to keep track of Port side I and Q channel (I)
        chanQ = 1;   % Variable to keep track of Port side I and Q channel (Q)
        
        if isequal(port_or_stbd, 'p')
            for c=5:24  %Columns for I and Q channel Data
                if (mod(c,2)==1)  % odd columns recieve the real part of I and Q data (I)
                    OutMat(row,c) = real(Pings.PortStaveData(CurrentPing,chanI,CurrentSample)); % real I and Q data brought into OutMat
                    chanI = chanI + 1;
                else             % even columns receive the imaginary part of I and Q Data (Q)
                    OutMat(row,c) = imag(Pings.PortStaveData(CurrentPing,chanQ,CurrentSample)); % Imaginary I and Q data brought into OutMat
                    chanQ = chanQ + 1;
                end               
            end        
        elseif isequal(port_or_stbd, 's')
            for c=5:24  %Columns for I and Q channel Data
                if (mod(c,2)==1)  % odd columns recieve the real part of I and Q data (I)
                    OutMat(row,c) = real(Pings.StbdStaveData(CurrentPing,chanI,CurrentSample)); % real I and Q data brought into OutMat
                    chanI = chanI + 1;
                else             % even columns receive the imaginary part of I and Q Data (Q)
                    OutMat(row,c) = imag(Pings.StbdStaveData(CurrentPing,chanQ,CurrentSample)); % Imaginary I and Q data brought into OutMat
                    chanQ = chanQ + 1;
                end               
            end
        end
        
        % Next bit is for Roll and Sound Speed Column
        NumSecondsThisPing = POSIX1970_TO_DAY(Pings.PingTimeStamps(CurrentPing));
        tsr = NumSecondsThisPing:1/fs:(NumSecondsThisPing +((Pings.NumSamples(CurrentPing)-1)/fs));    % Row array of time stamps for each ping
        
        %tsr = Pings.PingTimeStamps(CurrentPing):1/fs:(Pings.PingTimeStamps(CurrentPing) + ((Pings.NumSamples(CurrentPing)-1)/fs));    % Row array of time stamps for each ping
        
        TSA = tsr' ;            % Row array is converted to column array for easy comparison between time stamps of roll and sound speed
        
        % Roll
        NumSecondsRolls = POSIX1970_TO_DAY(Rolls(b, 1));
        NumSecondsNextRolls = POSIX1970_TO_DAY(Rolls(b+1, 1));
        %if ((TSA(CurrentSample,1)>= Rolls(b,1))&&(TSA(CurrentSample,1) < Rolls(b+1, 1)))                 % If Ping Time Stamp is less than that of the current roll time
        if ((TSA(CurrentSample,1)>= NumSecondsRolls)&&(TSA(CurrentSample,1) < NumSecondsNextRolls))                 % If Ping Time Stamp is less than that of the current roll time
            OutMat(row,25) = Rolls(b,2);                % That current roll data is sent to that row of OutMat
        
        elseif (TSA(CurrentSample,1) < NumSecondsRolls)
            OutMat(row,25) = NaN ;
            
        else                % ELSE 
            b=b+1;                 % increase roll row by 1   
            if  b>RollCnt-1     % check if row does not excede valid data
                b=RollCnt-1;
            end
            OutMat(row,25) = Rolls(b, 2); %Rolls(b,2);  % New role data is sent to that current row of OutMat
               
        end
        
        % Sound Speed
        NumSecondsSoundSpeeds = POSIX1970_TO_DAY(SoundSpeeds(s,1));
        NumSecondsNextSoundSpeeds = POSIX1970_TO_DAY(SoundSpeeds(s+1,1));
        %if ((TSA(CurrentSample,1)>= SoundSpeeds(s,1)&&(TSA(CurrentSample,1) < SoundSpeeds(s+1, 1))))      % same exact structure as Roll column
        if ((TSA(CurrentSample,1)>= NumSecondsSoundSpeeds&&(TSA(CurrentSample,1) < NumSecondsNextSoundSpeeds)))      % same exact structure as Roll column
            OutMat(row,26) = SoundSpeeds(s,2);
        elseif (TSA(CurrentSample,1) < NumSecondsSoundSpeeds)
            OutMat(row,26) = NaN ;
        else
            s=s+1;
            if  s>SoundCnt-1
                s=SoundCnt-1;
            end
            OutMat(row,26) = SoundSpeeds(s,2);
               
        end
        msg3000portstbd = -1;
        if isequal(port_or_stbd, 'p')
            msg3000portstbd = 1;
        elseif isequal(port_or_stbd, 's')
            msg3000portstbd = 2;
        end
        % DOA: col 27 (Should be 28 but Ryan is strange)
        OutMat(row, 27) = Soundings.Angle(CurrentPing, msg3000portstbd, CurrentSample);
        % TWTT: col 28
        OutMat(row, 28) = Soundings.TWTT(CurrentPing, msg3000portstbd, CurrentSample);
        % Amplitude : col 29
        OutMat(row, 29) = Soundings.Amplitude(CurrentPing, msg3000portstbd, CurrentSample);
        % angle uncertainty : col 30
        OutMat(row, 30) = Soundings.AngleUncertainty(CurrentPing, msg3000portstbd, CurrentSample);
        % sample rate : col 31
        OutMat(row, 31) = Soundings.SampleRate(CurrentPing, msg3000portstbd, CurrentSample);
        % range : col 32        
        %Range is the Speed of sound (col 26) * TWTT/2
        OutMat(row, 32) = OutMat(row, 26).*(Soundings.TWTT(CurrentPing, msg3000portstbd, CurrentSample)./2);
        
        
        
        
        row=row+1;
    end
end

%end
msgbox('Hey dont forget to change the ping numbers!')
fprintf('Sonar Data merged into Port output matrix. \n')
beep
PortOutMat = OutMat;
clear OutMat
OutMat = -69.*ones(888*6508, 32);

% Bring Formatted Data into OutMat
row=1; % Instantiation of a row. Keeps track of which row in OutMat the system is currently on
b=1;
s=1;
rollTime=1;
SoundTime=1;
%port_or_stbd = input('Create "port" or "stbd" CSV  ', 's');
prompt = 'Create port or stbd CSV? Enter p or s:   ';
port_or_stbd = 's';%input(prompt, 's');
port_stbd_value = -1;
if isequal(port_or_stbd, 'p')
    port_stbd_value = 0;
elseif isequal(port_or_stbd, 's')
    port_stbd_value = 1;    
end 
%for i = 1:length(Pings.PingTimeStamps) % total iterations needed for each ping in a .jsf
for CurrentPing = 1:MaxPingCtr
	fprintf('CurPing(stbd) = %d\n', CurrentPing);
    for CurrentSample = 1:Pings.NumSamples(CurrentPing)
     
        OutMat(row,1) = CurrentPing;    % Ping Number Column. Is adjusted directly by MaxPingCtr
        OutMat(row,1) = Soundings.PingNum(CurrentPing, 1+port_stbd_value);
        %pNum=pNum+1;
        
        OutMat(row,2) = CurrentSample;    % Sample Number Column
        %sNum=sNum+1;
        
        OutMat(row,3) = port_stbd_value;    % Port/Stbd. 0 -> Port, 1 -> Stbd.
        
        OutMat(row,4) = SDA(CurrentSample,CurrentPing); % Sample Delay data brought into OutMat
        %sDelay = sDelay + 1;
        
        chanI = 1;   % Variable to keep track of Port side I and Q channel (I)
        chanQ = 1;   % Variable to keep track of Port side I and Q channel (Q)
        
        if isequal(port_or_stbd, 'p')
            for c=5:24  %Columns for I and Q channel Data
                if (mod(c,2)==1)  % odd columns recieve the real part of I and Q data (I)
                    OutMat(row,c) = real(Pings.PortStaveData(CurrentPing,chanI,CurrentSample)); % real I and Q data brought into OutMat
                    chanI = chanI + 1;
                else             % even columns receive the imaginary part of I and Q Data (Q)
                    OutMat(row,c) = imag(Pings.PortStaveData(CurrentPing,chanQ,CurrentSample)); % Imaginary I and Q data brought into OutMat
                    chanQ = chanQ + 1;
                end               
            end        
        elseif isequal(port_or_stbd, 's')
            for c=5:24  %Columns for I and Q channel Data
                if (mod(c,2)==1)  % odd columns recieve the real part of I and Q data (I)
                    OutMat(row,c) = real(Pings.StbdStaveData(CurrentPing,chanI,CurrentSample)); % real I and Q data brought into OutMat
                    chanI = chanI + 1;
                else             % even columns receive the imaginary part of I and Q Data (Q)
                    OutMat(row,c) = imag(Pings.StbdStaveData(CurrentPing,chanQ,CurrentSample)); % Imaginary I and Q data brought into OutMat
                    chanQ = chanQ + 1;
                end               
            end
        end
        
        % Next bit is for Roll and Sound Speed Column
        NumSecondsThisPing = POSIX1970_TO_DAY(Pings.PingTimeStamps(CurrentPing));
        tsr = NumSecondsThisPing:1/fs:(NumSecondsThisPing +((Pings.NumSamples(CurrentPing)-1)/fs));    % Row array of time stamps for each ping
        
        %tsr = Pings.PingTimeStamps(CurrentPing):1/fs:(Pings.PingTimeStamps(CurrentPing) + ((Pings.NumSamples(CurrentPing)-1)/fs));    % Row array of time stamps for each ping
        
        TSA = tsr' ;            % Row array is converted to column array for easy comparison between time stamps of roll and sound speed
        
        % Roll
        NumSecondsRolls = POSIX1970_TO_DAY(Rolls(b, 1));
        NumSecondsNextRolls = POSIX1970_TO_DAY(Rolls(b+1, 1));
        %if ((TSA(CurrentSample,1)>= Rolls(b,1))&&(TSA(CurrentSample,1) < Rolls(b+1, 1)))                 % If Ping Time Stamp is less than that of the current roll time
        if ((TSA(CurrentSample,1)>= NumSecondsRolls)&&(TSA(CurrentSample,1) < NumSecondsNextRolls))                 % If Ping Time Stamp is less than that of the current roll time
            OutMat(row,25) = Rolls(b,2);                % That current roll data is sent to that row of OutMat
        
        elseif (TSA(CurrentSample,1) < NumSecondsRolls)
            OutMat(row,25) = NaN ;
            
        else                % ELSE 
            b=b+1;                 % increase roll row by 1   
            if  b>RollCnt-1     % check if row does not excede valid data
                b=RollCnt-1;
            end
            OutMat(row,25) = Rolls(b, 2); %Rolls(b,2);  % New role data is sent to that current row of OutMat
               
        end
        
        % Sound Speed
        NumSecondsSoundSpeeds = POSIX1970_TO_DAY(SoundSpeeds(s,1));
        NumSecondsNextSoundSpeeds = POSIX1970_TO_DAY(SoundSpeeds(s+1,1));
        %if ((TSA(CurrentSample,1)>= SoundSpeeds(s,1)&&(TSA(CurrentSample,1) < SoundSpeeds(s+1, 1))))      % same exact structure as Roll column
        if ((TSA(CurrentSample,1)>= NumSecondsSoundSpeeds&&(TSA(CurrentSample,1) < NumSecondsNextSoundSpeeds)))      % same exact structure as Roll column
            OutMat(row,26) = SoundSpeeds(s,2);
        elseif (TSA(CurrentSample,1) < NumSecondsSoundSpeeds)
            OutMat(row,26) = NaN ;
        else
            s=s+1;
            if  s>SoundCnt-1
                s=SoundCnt-1;
            end
            OutMat(row,26) = SoundSpeeds(s,2);
               
        end
        msg3000portstbd = -1;
        if isequal(port_or_stbd, 'p')
            msg3000portstbd = 1;
        elseif isequal(port_or_stbd, 's')
            msg3000portstbd = 2;
        end
        % DOA: col 27 (Should be 28 but Ryan is strange)
        OutMat(row, 27) = Soundings.Angle(CurrentPing, msg3000portstbd, CurrentSample);
        % TWTT: col 28
        OutMat(row, 28) = Soundings.TWTT(CurrentPing, msg3000portstbd, CurrentSample);
        % Amplitude : col 29
        OutMat(row, 29) = Soundings.Amplitude(CurrentPing, msg3000portstbd, CurrentSample);
        % angle uncertainty : col 30
        OutMat(row, 30) = Soundings.AngleUncertainty(CurrentPing, msg3000portstbd, CurrentSample);
        % sample rate : col 31
        OutMat(row, 31) = Soundings.SampleRate(CurrentPing, msg3000portstbd, CurrentSample);
        % range : col 32        
        %Range is the Speed of sound (col 26) * TWTT/2
        OutMat(row, 32) = OutMat(row, 26).*(Soundings.TWTT(CurrentPing, msg3000portstbd, CurrentSample)./2);
        
        
        
        
        row=row+1;
    end
end
StbdOutMat = OutMat;
clear OutMat;
fprintf('Sonar Data merged into Stbd output matrix. \n')
%
% Port OutMat removing samples with missing sounding information:
    % find all rows with missing DOA.
    % These next 3 lines are the old (flawed) method of doing this.
    
    NewOutMatPort = PortOutMat;
    RowIndexMissingDOAPort(:, 1) = isnan(NewOutMatPort(:,27)) ;
    NewOutMatPort(RowIndexMissingDOAPort==1, :) = [];
    
    NewOutMatStbd = StbdOutMat;
    RowIndexMissingDOAStbd(:, 1) = isnan(NewOutMatStbd(:,27)) ;
    NewOutMatStbd(RowIndexMissingDOAStbd==1, :) = [];

%%
% OutMat removing samples with missing roll or soundspeed info:
    % The next 6 lines are the old (potentially flawed) way of testing this:
    
    %firstGoodRow = 1;
    %row = 1;
    %while isnan(NewOutMat(row,26))    
    %    row=row+1;
    %    firstGoodRow = row;
    %end
    
    % This is the new solution using find() - MBisbano, 2/20/22
    %[firstGoodRow, necColParam] = find((NewOutMat(:,2)==minimumUsableSampleNumber)&(~isnan(NewOutMat(:,26))), 1, 'first');   
    %FinalOutMat = NewOutMat(firstGoodRow:length(NewOutMat), :);
%%    
% find all rows with missing data
    RowIndexMissingDataPort = [];
    FinalOutMatPort = NewOutMatPort;
    RowIndexMissingDataPort(:, 1) = (isnan(FinalOutMatPort(:,25)) | isnan(FinalOutMatPort(:, 26)));
    [frow, fcol] = find(RowIndexMissingDataPort(:,1) == 1, 1, 'last');
    FinalOutMatPort(1:frow, :) = [];
%    
    RowIndexMissingDataStbd = [];
    FinalOutMatStbd = NewOutMatStbd;
    RowIndexMissingDataStbd(:, 1) = (isnan(FinalOutMatStbd(:,25)) | isnan(FinalOutMatStbd(:, 26)));
    [frow, fcol] = find(RowIndexMissingDataStbd(:,1) == 1, 1, 'last');
    FinalOutMatStbd(1:frow, :) = [];
%%
% Write Output CSV File
% Output Management

    %disp('Saving All data into mat file')
    %save stbdJSFparsed2_20_22.mat
    save JSF038_cleaned_parsed3_26_22.mat
    %   specify output name
    %OutputFileName = input('Input Output Filename: ', 's');
    %OutputFileName = 'PortTraining_1404_002.csv';
    %OutputFileName = 'StbdTesting_1404_002.csv';
    %defaultNewFileName = cat(2,filename(1:end-4),'_AI_DOA.jsf');
    %

    %save MLDOAPredictions.mat AI_Predicted_DOA_Array
    %outputFP = fullfile(outpath, outfile);
    %outfileid = fopen(outputFP, 'wb');
    [OutputFileNamePort,CSVfpath] = uiputfile(defaultCSVfilenamePort, 'Where to save Port Output CSV?');
    [OutputFileNameStbd,CSVfpath] = uiputfile(defaultCSVfilenameStbd, 'Where to save Stbd Output CSV?');
    
    CSVPortfilename = fullfile(CSVfpath, OutputFileNamePort);
    CSVStbdfilename = fullfile(CSVfpath, OutputFileNameStbd);


%msgbox('Done.') ;

% Replace A with actual CSV output data!
%A = ones(4);
fprintf('Writing Output Matrix into CSV. Be Patient! \n')
ColumnNames = {'PingNum', 'SampleNum', 'PortStbd', 'SampleTimeDelay', ...
        'I1','Q1', 'I2', 'Q2', 'I3', 'Q3', 'I4', 'Q4',...
        'I5', 'Q5', 'I6', 'Q6', 'I7', 'Q7', 'I8', 'Q8',...
        'I9', 'Q9', 'I10', 'Q10', 'Roll', 'C', ...
        'DOA', 'TWTT', 'Amplitude', 'AngleUncertainty', 'SampleRate', 'Range'};


%ColumnNames = {'Ping#', 'Sample#', 'Port/Stbd', 'SampleTimeDelay', ...
%        'I1','Q1', 'I2', 'Q2', 'I3', 'Q3', 'I4', 'Q4',...
%        'I5', 'Q5', 'I6', 'Q6', 'I7', 'Q7', 'I8', 'Q8',...
%        'I9', 'Q9', 'I10', 'Q10', 'Roll', 'C', ...
%        'DOA', 'TWTT', 'Amplitude', 'AngleUncertainty', 'SampleRate', 'Range'};
writecell(ColumnNames, CSVPortfilename)
%writematrix(FinalOutMat, CSVfilename, 'WriteMode', 'append');
writematrix(FinalOutMatPort, CSVPortfilename, 'WriteMode', 'append');
message = strcat('Port CSV File Written to:   ',' ', ' "', CSVPortfilename, '"');
disp(message);

writecell(ColumnNames, CSVStbdfilename)
%writematrix(FinalOutMat, CSVfilename, 'WriteMode', 'append');
writematrix(FinalOutMatStbd, CSVStbdfilename, 'WriteMode', 'append');
message = strcat('Stbd CSV File Written to:   ',' ', ' "', CSVStbdfilename, '"');
disp(message);
%msgbox(message);

disp('Acoustic and Sample Frequency Test:');
disp(['-     Reported Acoustic Start Frequency: ', num2str(ReportedAcousticStartFrequency), ' Hz']);
disp(['-     Reported Acoustic Stop Frequency: ', num2str(ReportedAcousticStopFrequency), ' Hz']);
disp(['-     Reported Acoustic Mixer Frequency: ', num2str(ReportedAcousticMixerFrequency), ' Hz']);
disp(['-     Reported Sample Frequency: ', num2str(ReportedSampleFrequency), ' Hz']);
disp('Acoustic Frequency should be ~540 kHz, Sample Frequency should be ~60kHz');