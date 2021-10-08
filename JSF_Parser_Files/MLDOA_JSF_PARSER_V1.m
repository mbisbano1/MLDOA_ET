clear variables ;
close all ;
clc       ;
%% Path Setup and File Open
[JSFfpath, CSVfpath] = MB_FPATH_SET();
%fpath = RF_FPATH_SET();
%fpath = DL_FPATH_SET();

try
    [JSFfilename,JSFfpath]=uigetfile([JSFfpath '/*.jsf'], 'Which file to process?'); %open file and assign handle
catch
    [JSFfilename,JSFfpath]=uigetfile('*.jsf', 'Which file to process?'); %open file and assign handle
end
JSFfp = fopen([JSFfpath,JSFfilename],'r');

CSVfiles = split(JSFfilename, ".jsf");
CSVfilePort = strcat(CSVfiles{1,1}, '_port.xlsx');
CSVfileStbd = strcat(CSVfiles{1,1}, '_stbd.xlsx');
CSVfilenamePort = fullfile(CSVfpath, CSVfilePort);
CSVfilenameStbd = fullfile(CSVfpath, CSVfileStbd);
%% Output File Matrix setup
%numPings = 88723
%numSamplesPerPing = 4340
%numChannelsPerSample = 20
%OutMat = uint32(NaN(1000*4340*20, 15));
OutMat = NaN(1288*4340, 32);




%% Message List Declaration
    % Stave Data:   Message 80                  [1]
    % Roll Data:    Message 2020 or 3001        [5] or [43]
    % Sound Speed:  Message 2060                [6]
    % Bathy Data:   Message 3000                [42]
    % 
messageList = [1, 5, 6, 42];
   
%                                       readJSFv3_small(JSFfp,  messageList)                                    
%function [messageHeader,data,header] = readJSFv3_small(fileid,reqDataType,concatChannels)



%% Extract Message 80 Data:
% Create Pings Structure, which holds each ping and its corresponding data.

% User defineable parameters

    SamplesPerPing = 4340 ;     % 4340 samples per ping (IN FIRST TEST FILE)
    PingCtr = 1 ;
    MaxPingCtr = 10 ;
    NumChannelsPerSample = 20 ; %[1,2, ... 10] Port ||| [11, 12, ... 20] Stbd
                                    % 1 and 11 being the closest to seabed

    %Port_Stbd = 0 ;     % This determines if we parse out Port (0) or Stbd
        %(1) data *NOT IMPLEMENTED*

% Initialize Message 80 Pings() elements for efficiency
    
    %   PingNum(Ping#)      %not sure the use of this, but will be helpful
    %   to determine if we are off by an index of one!
    Pings.PingNum = NaN(MaxPingCtr, 1) ;
                % First PingNum:    87437
                % Last PingNum:     88723
    
    %   NumSamples(Ping#)
    Pings.NumSamples = NaN(MaxPingCtr, 1) ;

    %   PingTimeStamps(Ping#)
    Pings.PingTimeStamps = NaN(MaxPingCtr, 1) ;
    
    %                                           1       2
    %   StaveData(Ping#, Channel#, Sample#, Timestamp/Data)  Channels 1-10 port, 11-20 stbd
    Pings.StaveData = NaN(MaxPingCtr, NumChannelsPerSample, SamplesPerPing, 2) ; 
    % EX. t = Ping 3, Stbd Channel 9, Sample 206, Timestamp: 
    %   t = Pings.StaveData(3, 19, 206, 1) ;
    % EX. d = Ping 3, Stbd Channel 9, Sample 206, Data: 
    %   d = Pings.StaveData(3, 19, 206, 2) ;


% Loop through all Message 80!    
while PingCtr <= MaxPingCtr
    [mH, data, header] = readJSFv3_small(JSFfp,[1]) ; % read all types of data
    
    if mH.contentType < 1 % should check for cause of error to display information about break condition
        
        break
    
    elseif mH.contentType == 1 
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
    
    end
    
end

%% Extract Message 3000 Data:
% Create Measurements Structure, which holds each measurement and its corresponding data.

% User defineable parameters
figureOffset = 0 ;
MeasurementCtr = 1 ;
PoBathyCtr = 1 ;
StBathyCtr = 1 ;
PortRange = NaN(5000,5000) ;
PortAngle = NaN(5000,5000) ;
PortAmp = NaN(5000,5000) ;
PortMaxSound = -1 ;

StbdRange = NaN(5000,5000) ;
StbdAngle = NaN(5000,5000) ;
StbdAmp = NaN(5000,5000) ;
StbdMaxSound = -1 ;
%PortHeader = 0 ;
%StbdHeader = 0 ;
% Initialize Message 3000 Measurements() elements for efficiency

Measurements.PingNum = NaN(MaxPingCtr, 1) ;
Measurements.NumSamples = NaN(MaxPingCtr, 1) ;


while MeasurementCtr <= MaxPingCtr 
   
    [mH, data, header] = readJSFv3_small(JSFfp,[1]) ; % read all types of data
    
    if mH.contentType < 1 % should check for cause of error to display information about break condition
        
        break
    
    elseif mH.contentType == 42 % bathy data
        
        if header.channel == 0 % port
            PortRange(PoBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            PortAngle(PoBathyCtr,1:header.nsamps) = -data.Angle ;
            PortAmp(PoBathyCtr,1:header.nsamps) = data.Amp ;
            PortHeader(PoBathyCtr) = header ;
            if header.nsamps > PortMaxSound
                PortMaxSound = header.nsamps ;
            end
            PoBathyCtr = PoBathyCtr + 1 ;
            if ~mod(PoBathyCtr,100)
                fprintf('.')
            end
        elseif header.channel == 1 % Stbd
            StbdRange(StBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
            StbdAngle(StBathyCtr,1:header.nsamps) =  data.Angle  ;
            StbdAmp(StBathyCtr,1:header.nsamps) = data.Amp ;
            StbdHeader(StBathyCtr) = header ;
            if header.nsamps > StbdMaxSound
                StbdMaxSound = header.nsamps ;
            end
            
            StBathyCtr = StBathyCtr + 1 ;
            
        end
        
    end
end


%Roll = NaN(40000, 2)

%while RollNum < 100

% while PoBathyCtr < 100
%     [mH, data, header] = readJSFv3_small(JSFfp,messageList) ; % read all types of data
%     
%     if mH.contentType < 1 % should check for cause of error to display information about break condition
%         break
%     end
%     
%     if mH.contentType == 42 % bathy data
%         if header.channel == 0 % port
%             PortRange(PoBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
%             PortAngle(PoBathyCtr,1:header.nsamps) = -data.Angle ;
%             PortAmp(PoBathyCtr,1:header.nsamps) = data.Amp ;
%             PortHeader(PoBathyCtr) = header ;
%             if header.nsamps > PortMaxSound
%                 PortMaxSound = header.nsamps ;
%             end
%             PoBathyCtr = PoBathyCtr + 1 ;
%             if ~mod(PoBathyCtr,100)
%                 fprintf('.')
%             end
%         elseif header.channel == 1 % Stbd
%             StbdRange(StBathyCtr,1:header.nsamps) = data.TWTT .* cs / 2.0;
%             StbdAngle(StBathyCtr,1:header.nsamps) =  data.Angle  ;
%             StbdAmp(StBathyCtr,1:header.nsamps) = data.Amp ;
%             StbdHeader(StBathyCtr) = header ;
%             if header.nsamps > StbdMaxSound
%                 StbdMaxSound = header.nsamps ;
%             end
%             
%             StBathyCtr = StBathyCtr + 1 ;
%             
%         end
% %     elseif mH.contentType == 1 % could be sidescan, need to check subsystem ID to locate stave data
% %         if mH.subsystem == 40 || mH.subsystem == 40 % stave data combining port and starboard
% %             pingNum = header.pingNum
% %             numSamples = header.samples
% %             stavePort = data.samples(1:10,:) ; % stave order: stave 1 closest to seabed stave 10 closest to surface
% %             staveStarboard = data.samples(11:20,:) ; % % stave order: stave 11 closest to seabed stave 20 closest to surface
% %             timestamp = header.timeStamp ;
% %             % apply your processing here
% %         end
% %     elseif mH.contentType == 5 % Pitch/Roll/Yaw Data...
%         
%     end
% end
% fprintf('\n')

%disp(numSamples)



%% Format all this information into OutMat


%% Write Output CSV File

% Will break OutMat into smaller pieces to send into XLSX's so we can view
% it and verify data. Later, we can output the full OutMat into a .CSV,
% which shouldn't have a length limit!

msgbox('Done.') ;

% Replace A with actual CSV output data!
%A = ones(4);
%writematrix(A, CSVfilenamePort);
%message = strcat('CSV File Written to:   ',' ', ' "', CSVfilenamePort, '"');
%msgbox(message);