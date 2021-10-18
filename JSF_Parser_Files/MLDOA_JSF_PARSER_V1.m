format long ;
clear variables ;
close all ;
clc       ;
%% Path Setup and File Open
[JSFfpath, CSVfpath] = MB_FPATH_SET();
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
CSVfilePort = strcat(CSVfiles{1,1}, '_port.CSV');
CSVfileStbd = strcat(CSVfiles{1,1}, '_stbd.CSV');
CSVfilenamePort = fullfile(CSVfpath, CSVfilePort);
CSVfilenameStbd = fullfile(CSVfpath, CSVfileStbd);
%% Output File Matrix setup
%numPings = 88723
%numSamplesPerPing = 4340
%numChannelsPerSample = 20
%OutMat = uint32(NaN(1000*4340*20, 15));
OutMat = -69.*ones(1287*4340, 32);
%OutMat = -69.*ones(11*4340, 32);


%% Message List Declaration
    % Stave Data:   Message 80                  [1]
    % Roll Data:    Message 2020 or 3001        [5] or [43]
    % Sound Speed:  Message 2060                [6]
    % Bathy Data:   Message 3000                [42]
    % 
    % messageList = [1, 5, 6, 42];
    
%                                       readJSFv3_small(JSFfp,  messageList)                                    
%function [messageHeader,data,header] = readJSFv3_small(fileid,reqDataType,concatChannels)

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

    SamplesPerPing = 4340 ;     % 4340 samples per ping (IN FIRST TEST FILE)
    PingCtr = 1 ;
    MaxPingCtr = 1287 ;
    NumChannelsPerSample = 20 ; %[1,2, ... 10] Port ||| [11, 12, ... 20] Stbd
                                    % 1 and 11 being the closest to seabed

    %Port_Stbd = 0 ;     % This determines if we parse out Port (0) or Stbd
        %(1) data *NOT IMPLEMENTED*

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
            %if df == 2
            %   fs = header.fs / 2; 
            %end
            %Pings.SampleRate(PingCtr, 1) = header.
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
    
%                              (1   2)              (1       2    3       4            5             6)                                
% MeasurementData(PingIndex , Port/Stbd, Sample#, TimeStamp/RTT/Angle/Amplitude/AngleUncertainty/SampleRate)
    Measurements.MeasurementData = NaN(MaxPingCtr, 2, SamplesPerPing, 6) ;
    
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
            
            %PortRange(PoBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            
            %PortRTT(PoBathyCtr, 1:header.nsamps) = data.TWTT ;         
            Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 2) = data.TWTT ;
            
            
            %PortAngle(PoBathyCtr,1:header.nsamps) = -data.Angle ;
            Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 3) = -data.Angle ;
            
            
            %PortAmp(PoBathyCtr,1:header.nsamps) = data.Amp ;
            Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 4) = data.Amp ;
            
            
            Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 5) = data.Sigma ;
            
            Measurements.MeasurementData(M_Ctr_Port, 1, 1:header.nsamps, 6) = header.fsample ;
            
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
            
            
            %StbdRange(StBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            
            %StbdRTT(StBathyCtr, 1:header.nsamps) = data.TWTT ;
            Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 2) = data.TWTT ;
            
            %StbdAngle(StBathyCtr,1:header.nsamps) =  data.Angle  ;
            Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 3) = -data.Angle ;
                                   
            %StbdAmp(StBathyCtr,1:header.nsamps) = data.Amp ;
            Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 4) = data.Amp ;
            
            Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 5) = data.Sigma ;
            
            Measurements.MeasurementData(M_Ctr_Stbd, 2, 1:header.nsamps, 6) = header.fsample ;
            
            
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




%% Format all this information into OutMat
% Data Formatting

% Sample Delay Column
fs=Measurements.MeasurementData(1,1, 1, 6);     % Sample Frequency taken from MeasurementData
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
%for i = 1:length(Pings.PingTimeStamps) % total iterations needed for each ping in a .jsf
for CurrentPing = 1:MaxPingCtr
    for CurrentSample = 1:Pings.NumSamples(CurrentPing)
     
        OutMat(row,1) = CurrentPing;    % Ping Number Column. Is adjusted directly by MaxPingCtr
        %pNum=pNum+1;
        
        OutMat(row,2) = CurrentSample;    % Sample Number Column
        %sNum=sNum+1;
        
        OutMat(row,3) = 0;    % Port/Stbd. This OutMat array is only for port side. For stbd, change 0->1. New OutMat will be generated later.
        
        OutMat(row,4) = SDA(CurrentSample,CurrentPing); % Sample Delay data brought into OutMat
        %sDelay = sDelay + 1;
        
        % EX. d = Ping 3, Stbd Channel 9, Sample 206, Data: 
        %   d = Pings.StaveData(3, 19, 206, 2) ;
        %OutMat(row,5) = real(Pings.StaveData(j, 1, k, 2));
        %OutMat(row,6) = imag(Pings.StaveData(j, 1, k, 2));
        
        %OutMat(row,7) = real(Pings.StaveData(j, 2, k, 2));
        %OutMat(row,8) = imag(Pings.StaveData(j, 2, k, 2));
        
        %OutMat(row,9) = real(Pings.StaveData(j, 3, k, 2));
        %OutMat(row,10) = imag(Pings.StaveData(j, 3, k, 2));
        
        %OutMat(row,11) = real(Pings.StaveData(j, 4, k, 2));
        %OutMat(row,12) = imag(Pings.StaveData(j, 4, k, 2));
        
        %OutMat(row,13) = real(Pings.StaveData(j, 5, k, 2));
        %OutMat(row,14) = imag(Pings.StaveData(j, 5, k, 2));
        
        %OutMat(row,15) = real(Pings.StaveData(j, 6, k, 2));
        %OutMat(row,16) = imag(Pings.StaveData(j, 6, k, 2));
        
        %OutMat(row,17) = real(Pings.StaveData(j, 7, k, 2));
        %OutMat(row,18) = imag(Pings.StaveData(j, 7, k, 2));
        
        %OutMat(row,19) = real(Pings.StaveData(j, 8, k, 2));
        %OutMat(row,20) = imag(Pings.StaveData(j, 8, k, 2));
        
        %OutMat(row,21) = real(Pings.StaveData(j, 9, k, 2));
        %OutMat(row,22) = imag(Pings.StaveData(j, 9, k, 2));
        
        %OutMat(row,23) = real(Pings.StaveData(j, 10, k, 2));
        %OutMat(row,24) = imag(Pings.StaveData(j, 10, k, 2));
        
        chanI_p = 1;   % Variable to keep track of Port side I and Q channel (I)
        chanQ_p = 1;   % Variable to keep track of Port side I and Q channel (Q)
        ChanI_s = 11;  % Variable to keep track of STBD side I and Q channel (I)
        ChanQ_s = 11;  % Variable to keep track of STBD side I and Q channel (Q)
        for c=5:24 % Columns for I and Q channel Data
           if (mod(c,2)==1)  % odd columns recieve the real part of I and Q data (I)
               OutMat(row,c) = real(Pings.StaveData(CurrentPing,chanI_p,CurrentSample,2)); % real I and Q data brought into OutMat
               chanI_p = chanI_p + 1;
           else             % even columns receive the imaginary part of I and Q Data (Q)
               OutMat(row,c) = imag(Pings.StaveData(CurrentPing,chanQ_p,CurrentSample,2)); % Imaginary I and Q data brought into OutMat
               chanQ_p = chanQ_p + 1;
           end
        end
        % Next bit is for Roll and Sound Speed Column
        tsr = Pings.PingTimeStamps(CurrentPing):1/fs:(Pings.PingTimeStamps(CurrentPing) + ((Pings.NumSamples(CurrentPing)-1)/fs));    % Row array of time stamps for each ping
        TSA = tsr' ;            % Row array is converted to column array for easy comparison between time stamps of roll and sound speed
        
        % Roll
        if ((TSA(CurrentSample,1)>= Rolls(b,1))&&(TSA(CurrentSample,1) < Rolls(b+1, 1)))                 % If Ping Time Stamp is less than that of the current roll time
            OutMat(row,25) = Rolls(b,2);                % That current roll data is sent to that row of OutMat
        
        elseif (TSA(CurrentSample,1) < Rolls(b,1))
            OutMat(row,25) = NaN ;
            
        else                % ELSE 
            b=b+1;                 % increase roll row by 1   
            if  b>RollCnt-1     % check if row does not excede valid data
                b=RollCnt-1;
            end
            OutMat(row,25) = Rolls(b, 2); %Rolls(b,2);  % New role data is sent to that current row of OutMat
               
        end
        
        % Sound Speed
        if ((TSA(CurrentSample,1)>= SoundSpeeds(s,1)&&(TSA(k,1) < SoundSpeeds(s+1, 1))))      % same exact structure as Roll column
            OutMat(row,26) = SoundSpeeds(s,2);
        elseif (TSA(CurrentSample,1) < SoundSpeeds(s,1))
            OutMat(row,26) = NaN ;
        else
            s=s+1;
            if  s>SoundCnt-1
                s=SoundCnt-1;
            end
            OutMat(row,26) = SoundSpeeds(s,2);
               
        end
        row=row+1;
 
    end
end

%end
msgbox('Hey dont forget to change the ping numbers!')
fprintf('Sonar Data merged into output matrix. \n')

%% Write Output CSV File

% Will break OutMat into smaller pieces to send into XLSX's so we can view
% it and verify data. Later, we can output the full OutMat into a .CSV,
% which shouldn't have a length limit!

%msgbox('Done.') ;

% Replace A with actual CSV output data!
%A = ones(4);
fprintf('Writing Output Matrix into CSV. Be Patient! \n')
writematrix(OutMat, CSVfilenamePort);
message = strcat('CSV File Written to:   ',' ', ' "', CSVfilenamePort, '"');
msgbox(message);