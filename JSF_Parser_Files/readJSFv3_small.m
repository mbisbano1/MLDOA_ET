% Rev 1,    added Array spacing info ...

% Rev 2,    simplified output and get full 10x stave data out of file,
%           NOTE: will fail on 8 stave systems like 4600

% Rev 2.1:  added support for DVL assuming subsystem 50, added support for sidescan subsystem 20
% Rev 2.2:  changed calling parameters

% Rev 3:    changed output format, added timeStamp to header
% Rev 3.1:  renumbered message types to reflect complexity of 3004
%           
% Rev 3.2:  More comprehensive parsing of message 80 to help writing of 80 from existing files
%           Added flag to concatenate channels (default = true) or not
%           Unified 80 reading for known subsystems
%
% Rev 3.3:  Make sure the requested data type is provided by current message before parsing, otherwise skip
%
% Rev 3.4:  Added message 2081 and 2000 for TSS1, GGA and VTG
%           Fixed bug in reading of 2020 flags that prevented headind parsing (added fliplr)
%           Added Doppler frequency parsing in record 2081, first of the 5
%           last reserved fields
%
%

function [messageHeader,data,header] = readJSFv3_small(fileid,reqDataType,concatChannels)
%Use fopen to open file for reading prior to calling.

% [messageHeader,data,header] = readJSFv3(fileid,dataType)

% Input Parms:
%       fileid    : MATLAB FID (file ID) from inputfile=fopen(....);
%       dataType  : if specified looks for a specific type of data
%                   can be an enumeration, in that case first data matching type in list is returned

% Return:
%      messageHeader: Structure with fields:
%         contentType:
%                 = -ve = errors
%                 = 1  == PING DATA
%                 = 2  == PITCH AND ROLL DATA
%                 = 3  == LAT/LONG DATA
%                 = 4  == HEADING ONLY
%                 = 5  == HEAVE, PITCH AND ROLL DATA
%                 = 6  == SV DATA ONLY
%                 = 7  == HVE,PITCH,ROLL,HDG,DEPTH,LAT&LONG(phins)
%                 = 8  == ARRAY SPACING INFO DATA
%                 = 9  == LAT, LON, HEADING, DEPTH, SV (ETC)
%                 = 10 == ARRAY CALIBRATION DATA
%                 = 11 == MOTION, POSITION, VELOCITY, ENVIRONMENT (Situation Comprehensive)
%                 = 12 == EDGETECH DVL OUTPUT
%                 = 13 == HEADING AND SPEED
%                 = 42 == BATHYMETRY
%                 = 43 == MOTION FROM BATHY PROCESSOR
%                 = 44 == POSITION (PLUS SOME) FROM BATHY PROCESSOR
%                 = 45 == CTD from bathy processor
%                 = 46 == Altitude from bathy processor

%                 = 99999 == not parsed data
%           startOfMessage
%           version
%           sessionId
%           messageType
%           commandType
%           subSystem
%           channel
%           sequenceNo
%           byteCount
%
%         data = structure with appropriate data fields
%
%         header =  all information in header of specific record

global dataloc

if nargin == 1
    reqDataType = 0:10000 ;
end
if nargin == 2
    concatChannels = true ;
end
data =[];
messageHeader.contentType=-1;
header = [] ;



mDataType{80} = [1] ;
mDataType{182} = [200] ;
mDataType{1009} = [8] ;
mDataType{1011} = [10] ;
mDataType{2000} = [2,3,4,6,7,9,13] ;
mDataType{2002} = [2,3,4,6,7,9] ;
mDataType{2020} = [5] ;
mDataType{2060} = [6] ;
mDataType{2081} = [12] ;
mDataType{2091} = [11] ;
mDataType{3000} = [42] ;
mDataType{3001} = [43] ;
mDataType{3003} = [46] ;
mDataType{3004} = [44] ;


mDataType{10000} = [] ;
mDataType{10080} = [] ;
mDataType{11203} = [] ;

%start , look for SonarMessageHeaderType
while 1==1
    messageHeader.startOfMessage = fread(fileid,1,'int16');
    messageHeader.version = fread(fileid,1,'int8');
    [messageHeader.sessionId,cnt] = fread(fileid,1,'int8');
    
    %check if we read any data ....  (EOF ?)
    if cnt == 0
        messageHeader.contentType = -4 ;
        return
    end
    
    %Check if valid message
    if (messageHeader.startOfMessage ~= hex2dec('1601') )
        messageHeader.contentType =-1;  %Not valid JSF format data or lost sync!
        return
    end
    
    messageHeader.messageType = fread(fileid,1,'int16');
    messageHeader.commandType = fread(fileid,1,'int8');
    messageHeader.subsystem = fread(fileid,1,'int8');  %0 = SB, 20 = SSL, 21 = SSH, 40 = bathy
    messageHeader.channel= fread(fileid,1,'uint8');  %0=port, 1 = stbd for SS systems
    messageHeader.sequenceNo = fread(fileid,1,'int8');
    fread(fileid,1,'int16');%Reserved field, 16 bits
    
    [messageHeader.byteCount,cnt] = fread(fileid,1,'uint32'); %Size of data block  which follows
    
    if isempty(messageHeader.messageType) || cnt == 0
        messageHeader.contentType = -4;
        return
    end
    
    % a bit of redundancy
    header.subsystem =  messageHeader.subsystem ;
    header.channel = messageHeader.channel ;
    
    %fprintf(1,'Message type: %d\n',messageType)
    match = 0 ;
    for id = 1 : length(reqDataType)
        try
        match = match + sum(reqDataType(id) == mDataType{messageHeader.messageType}) ;
        catch
            fred = 2 ;
        end
    end
    if match > 0
        switch messageHeader.messageType
            case 80  %Sonar Trace Data (JsfDefs.h)
                messageHeader.contentType = 1 ;
                parsePing = true ;
                if concatChannels == false
                    nChan = 1 ;
                else
                    switch header.subsystem
                        case 0 % SBP data
                            nChan = 1 ;
                        case {20, 21, 120} %SSL or SSH or GF
                            nChan = 2 ;
                        case {40, 41}   %This is the bathy data, lo or hi
                            nChan = 20 ;
                        case 50   %This is the DVL data
                            nChan = 4 ;
                        case 70  % Motion tolerant sidescan
                            nChan = 2 ;
                        otherwise
                            parsePing = false ;
                    end
                end
                if sum(reqDataType == 1) == 0 % ping data not requested, skip long parsing process
                    parsePing = false ;
                end
                if parsePing == true
                    header.seconds = fread(fileid,1,'uint32'); %in seconds
                    header.startDepth = fread(fileid,1,'int32'); %in samples
                    header.pingNum = fread(fileid,1,'uint32');
                    header.reserved0 = fread(fileid,1,'int32');
                    
                    
                    header.MSB = fread(fileid,1,'uint16');                                %bytes 16-17
                    %decode for Freq MSBs
                    header.startFreqAdd=bitand(header.MSB,15);
                    header.endFreqAdd = bitand(header.MSB,240)/16;
                    header.addSamples = bitand(header.MSB,3840)/256;
                    
                    header.LSB = fread(fileid,1,'uint16');                                 %bytes 18-19
                    header.addSampleInterval = bitand(header.LSB,255);
                    header.fractionalCourse = bitshift(header.LSB,-8) ;
                    header.LSB2 = fread(fileid,1,'uint16');                                %bytes 20-21
                    header.reserved1 = fread(fileid,3,'int16');                            %bytes 22-27
                    header.iDCode = fread(fileid,1,'int16');                               %bytes 28-29 (always = 1)
                    header.validityFlag = fread(fileid,1,'uint16');                        %bytes 30-31
                    header.reserved2 = fread(fileid,1,'uint16');                           %bytes 32-33
                    header.dataFormat = fread(fileid,1,'int16');                           %bytes 34-35
                    % 0 = 1 short/sample Env dat
                    % 1 = 2 shorts/sample Analytic
                    % 2 = 1 short/sample RAW
                    header.AntennaDist1 = fread(fileid,1,'int16');                          %bytes 36-37
                    header.AntennaDist2 = fread(fileid,1,'int16');                          %bytes 38-39
                    header.reserved3 = fread(fileid,2,'uint16');                            %bytes 40-43
                    header.KP = fread(fileid,1,'float32');                                  %bytes 44-47
                    header.heave = fread(fileid,1,'float32');                               %bytes 48-51
                    header.reserved4 = fread(fileid,12,'uint8');                            %bytes 52-63
                    header.pulseInfo = fread(fileid,2,'float32');                           %bytes 64-71
                    header.reserved5 = fread(fileid,1,'int32');                             %bytes 72-75
                    header.gapFillerLateralPositionOffset = fread(fileid,1,'single');       %bytes 76-79
                    header.lon = fread(fileid, 1, 'int32') ; % Longiture or X               %bytes 80-83
                    header.lat = fread(fileid, 1, 'int32') ; % Latitude or Y                %bytes 84-87
                    header.positionunit = fread(fileid, 1, 'int16') ; % Coordinate Units    %bytes 88-89
                    % 1 = X, Y in millimeters
                    % 2 = Latitude, longitude in minutes of arc times 10000
                    % 3 = X, Y in decimeters
                    if header.positionunit == 2
                        header.lon = (header.lon / 10000) / 60 ; % convert to degrees
                        header.lat = (header.lat / 10000) / 60 ; % convert to degrees
                    end
                    
                    header.annotation = fread(fileid,24,'uint8');                           %bytes 90-113
                    header.samples = fread(fileid,1,'uint16');                              %bytes 114-115
                    header.sampleInterval = fread(fileid,1,'uint32'); %ns                   %bytes 116-119
                    header.ADCGain = fread(fileid,1,'uint16');                              %bytes 120-121
                    header.transmitlevel = fread(fileid,1,'int16');           
                  %bytes 122-123
                    header.reserved6 = fread(fileid,1,'int16');                             %bytes 124-125
                    header.startf = fread(fileid,1,'uint16');                               %bytes 126-127
                    %Starting frequency in DecaHz
                    header.startf= (header.startf + header.startFreqAdd*2^16)*10;  %Hz
                    header.stopf = fread(fileid,1,'uint16');                               %bytes 128-129
                    %ie multiply this value by 10 for Hz.
                    header.stopf=(header.stopf + header.endFreqAdd*2^16)*10;  %Hz
                    if mod(messageHeader.channel,2) == 0 % needed since concatinating all channels irrespective of side
                        header.portstartf =  header.startf ;
                        header.portstopf =  header.stopf ;
                    else
                        header.stbdstartf =  header.startf ;
                        header.stbdstopf =  header.stopf ;
                    end
                    header.pulselength = fread(fileid,1,'uint16');                          %bytes 130-131
                    header.pulselength = header.pulselength * 1e-3 + bitshift(header.LSB2,-4) * 1e-6;
                    header.pressure = fread(fileid,1,'int32');                              %bytes 132-135
                    header.depth = fread(fileid,1,'int32');                                 %bytes 136-139
                    header.fs = fread(fileid,1,'uint16');                                   %bytes 140-141
                    header.pulse_id=fread(fileid,1,'uint16');                               %bytes 142-143
                    header.altitude   = fread(fileid,1,'uint32');                           %bytes 144-147
                    header.soundspeed = fread(fileid,1,'float32');                          %bytes 148-151
                    header.mixerFreq  = fread(fileid,1,'float32');                          %bytes 152-155
                    header.date.year = fread(fileid,1,'int16');                             %bytes 156-157
                    header.date.day = fread(fileid,1,'uint16');                             %bytes 158-159
                    header.daytime.hours = fread(fileid,1,'uint16');                           %bytes 160-161
                    %Note,hour, m, secs are not to be used
                    %must use millisecondsToday for better resolution. !
                    header.daytime.minutes = fread(fileid,1,'uint16');                         %bytes 162-163
                    header.daytime.seconds = fread(fileid,1,'uint16');                         %bytes 164-165
                    header.timeBasis = fread(fileid,1,'int16');                             %bytes 166-167
                    header.weight = fread(fileid,1,'int16'); %  = block floating exponent   %bytes 168-169
                    header.numpulses=fread(fileid,1,'int16');                               %bytes 170-171
                    header.compassHeading = fread(fileid,1,'uint16');                       %bytes 172-173
                    header.compassHeading = header.compassHeading / 100.0 ;
                    header.pitch = fread(fileid,1,'int16');                                 %bytes 174-175
                    header.pitch = header.pitch * 180.0 / 32768.0 ;
                    header.roll = fread(fileid,1,'int16');                                  %bytes 176-177
                    header.roll = header.roll * 180.0 / 32768.0 ;
                    header.reserved7 = fread(fileid,2,'int16');                            %bytes 178-181
                    header.triggerSource = fread(fileid,1,'int16');                         %bytes 182-183
                    header.markNumber = fread(fileid,1,'int16');                            %bytes 184-185
                    header.posFixHours = fread(fileid,1,'int16');                           %bytes 186-187
                    header.posFixMinutes = fread(fileid,1,'int16');                         %bytes 188-189
                    header.posFixSeconds = fread(fileid,1,'int16');                         %bytes 190-191
                    header.course = fread(fileid,1,'int16');                                %bytes 192-193
                    header.speed = fread(fileid,1,'int16');                                 %bytes 194-195
                    header.posFixDay = fread(fileid,1,'int16');                             %bytes 196-197
                    header.posFixYear = fread(fileid,1,'int16');                            %bytes 198-199
                    header.millisecondsToday = fread(fileid,1,'uint32');                    %bytes 200-203
                    header.milliseconds = mod(header.millisecondsToday,1000);
                    header.timeStamp = header.seconds + header.milliseconds/1e3 ;
                    header.maxADCValue = fread(fileid,1,'uint16');                          %bytes 204-205
                    header.reserved8 = fread(fileid,2,'uint16');                            %bytes 206-209
                    header.SonarVersion = fread(fileid,6,'int8');                           %bytes 210-215
                    header.sphericalCorection = fread(fileid,1,'int32');                    %bytes 216-219
                    header.packetNumber = fread(fileid,1,'uint16');                         %bytes 220-221
                    header.ADCDecimation = fread(fileid,1,'int16');                         %bytes 222-223
                    header.reserved9 = fread(fileid,1,'int16');                             %bytes 224-225
                    header.waterTemperature = fread(fileid,1,'uint16');                     %bytes 226-227
                    header.layback = fread(fileid,1,'float32');                             %bytes 228-231
                    header.reserved10 = fread(fileid,1,'int32');                             %bytes 232-235
                    header.cableOut = fread(fileid,1,'uint16');                             %bytes 236-237
                    header.reserved11 = fread(fileid,1,'int16');                            %bytes 238-239
                    
                    switch header.dataFormat
                        case {0, 2, 3}    % 16 bit sampes, real only
                            %Note numOfSamples should = to numSamples
                            numSamples = (messageHeader.byteCount - 240)/2;  %bytes - sizeof header by 2
                            temp = fread(fileid,[1,numSamples],'int16');
                            sample_data = temp * 2^-header.weight ;
                        case 6    % 32 Bit samples Real
                            %Note numOfSamples should = to numSamples
                            numSamples = (messageHeader.byteCount - 240)/4;  %bytes - sizeof header by 2
                            temp = fread(fileid,[1,numSamples],'int32');
                            sample_data = temp * 2^-header.weight ;
                        case {1, 9}   % 16 bit IQ
                            numSamples = (messageHeader.byteCount - 240)/4;  %bytes - sizeof header by 4
                            temp = fread(fileid,[2,numSamples],'int16');
                            %Make this [2,N] array, a complex [1x N] array
                            sample_data = ( temp(1,:)  + 1i * temp(2,:)) * 2^-header.weight;
                        case 7   %Complex FPoint
                            numSamples = (messageHeader.byteCount - 240)/8;  %bytes - sizeof header by 4
                            temp = fread(fileid,[2,numSamples],'float32');
                            %Make this [2,N] array, a complex [1x N] array
                            sample_data = ( temp(1,:)  + 1i * temp(2,:));
                        otherwise
                            %Read in the junk
                            numSamples = (messageHeader.byteCount - 240)/2;  %bytes - sizeof header by 2
                            sample_data = fread(fileid,[1,numSamples],'int16');
                            
                            
                    end
                    if concatChannels
                        data.samples(messageHeader.channel+1,1:length(sample_data)) = sample_data ;   %Store one messageHeader.channel of data
                    else
                        data.samples = sample_data ;   %Store one messageHeader.channel of data
                    end
                    header.fsample=1/(header.sampleInterval*1e-9);  %Note granularity is 1 ns....
                    messageHeader.contentType = 1;  %Set ping data flag
                    if (messageHeader.channel == nChan-1 || nChan == 1)
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                        end
                    end
                else
                    %skip ahead in file   chew up block of data ...
                    [dummy,cnt] = fread(fileid,(messageHeader.byteCount),'int8');
                    if isempty(cnt) || isempty(dummy)
                        messageHeader.contentType= -4;  % signal end of file, data not found
                        return
                    end
                end  %
                
                
            case 88
                dabu = fread(fileid, messageHeader.byteCount, '*uchar'); % data buffer
                if messageHeader.subsystem == 40
                    % ================================================
                    % SONAR_MESSAGE_DATA_PING_HEADER : SonarHeaderType
                    % ================================================
                    timeS= double(round(typecast(dabu(1:8), 'uint64'))) ;
                    timeNs = double(typecast(dabu(9:12), 'uint32') ) ;
                    timeStamp = timeS +  timeNs / 1e9;
                    sonarHeader = struct('timeStamp', timeStamp,...
                        'pingNumber', typecast(dabu(17:20), 'int32'),...
                        'channels', typecast(dabu(23:24), 'int16'),...
                        'mpxNum', dabu(27), 'mpx', dabu(28),...
                        'pulseID', typecast(dabu(29:32), 'int32'),...
                        'freqKHz', typecast(dabu(45:48), 'single') / 1000.0,...
                        'srKHz', typecast(dabu(49:52), 'single') / 1000.0,...
                        'samples', typecast(dabu(57:60), 'int32'),...
                        'format', dabu(67), 'compression', dabu(68));
                    sonarHeader.time.seconds = timeS ;
                    sonarHeader.time.milliseconds = timeNs / 1e6 ;
                    sonarHeader.time.nanoseconds = timeNs / 10 ;
                    data = zeros(sonarHeader.samples, sonarHeader.channels);
                    sonarHeader.freqKHz = double(sonarHeader.freqKHz) ;
                    sonarHeader.srKHz = double(sonarHeader.srKHz) ;
                    messageHeader.contentType = 101 ; % expecting a full series of channels to follow
                    sonarDataChannel = 0;
                    
                end
            case 89
                dabu = fread(fileid, messageHeader.byteCount, '*uchar'); % data buffer
                if (messageHeader.subsystem == 40) % && (sonarDataChannel == messageHeader.channel) % removed test to accomodate bug in channel counter due to 8-bit depth counter in MBsonar
                    % ================================================
                    % SONAR_MESSAGE_DATA_CHANNEL_DATA : SonarChannelDataType
                    % ================================================
                    sonarChanHeader = struct('pingNumber', typecast(dabu(1:4), 'int32'),...
                        'format', dabu(13), 'compression', dabu(14));
                    if sonarHeader.pingNumber == sonarChanHeader.pingNumber
                        sonarDataChannel = sonarDataChannel + 1 ;
                    else
                        error('Lost track of channels') ; % Should not happen
                    end
                    % Assume compressed 14-bit : 4 bit exponent, 14-bits Q, 14-bits I
                    if sonarChanHeader.compression == 4 % 16 Bit no compression IQ
                        samples = (messageHeader.byteCount - 24) / 4;
                        dabu = typecast(dabu(25:end), 'int16');
                        ival = dabu(1:2:end);
                        qval = dabu(2:2:end);
                    elseif sonarChanHeader.compression == 5 % 14 Bit compressed IQ
                        samples = (messageHeader.byteCount - 24) / 4;
                        compressedData = typecast(dabu(25:end), 'uint32');
                        expo = bitshift(compressedData, -28);
                        ival = bitand(compressedData, 16383);
                        qval = bitand(bitshift(compressedData,-14), 16383);
                        ival = (single(ival) - single(bitand(ival, 8192) * 2)) .* (2 .^ -(0 - single(expo) + 4)) / 256.0;
                        qval = (single(qval) - single(bitand(qval, 8192) * 2)) .* (2 .^ -(0 - single(expo) + 4)) / 256.0;
                    elseif sonarChanHeader.compression == 6 % 10 Bit compressed IQ
                        samples = 3 * ((messageHeader.byteCount - 24) / 8);
                        compressedData = typecast(dabu(25:end), 'uint32');
                        expo = zeros(samples, 1);
                        expo(1:3:end) = bitshift(compressedData(1:2:end), -30) + bitshift(compressedData(2:2:end), -30) * 4;
                        expo(2:3:end) = expo(1:3:end);
                        expo(3:3:end) = expo(1:3:end);
                        ival = zeros(samples, 1);
                        qval = zeros(samples, 1);
                        ival(1:3:end) = bitand(compressedData(1:2:end), 1023);
                        qval(1:3:end) = bitand(bitshift(compressedData(1:2:end),-10), 1023);
                        ival(2:3:end) = bitand(bitshift(compressedData(1:2:end),-20),1023);
                        qval(2:3:end) = bitand(compressedData(2:2:end), 1023);
                        ival(3:3:end) = bitand(bitshift(compressedData(2:2:end),-10),1023);
                        qval(3:3:end) = bitand(bitshift(compressedData(2:2:end),-20), 1023);
                        ival = (single(ival) - single(bitand(ival, 512) * 2)) .* (2 .^ -(0 - single(expo) + 0)) / 256.0;
                        qval = (single(qval) - single(bitand(qval, 512) * 2)) .* (2 .^ -(0 - single(expo) + 0)) / 256.0;
                    elseif sonarChanHeader.compression == 7 % 7 Bit compressed IQ
                        samples = 2 * ((messageHeader.byteCount - 24) / 4);
                        compressedData = typecast(dabu(25:end), 'uint32');
                        expo = zeros(samples, 1);
                        expo(1:2:end) = bitshift(compressedData, -28);
                        expo(2:2:end) = expo(1:2:end, 1);
                        ival = zeros(samples, 1);
                        qval = zeros(samples, 1);
                        ival(1:2:end) = bitand(compressedData, 127);
                        qval(1:2:end) = bitand(bitshift(compressedData,-7), 127);
                        ival(2:2:end) = bitand(bitshift(compressedData,-14),127);
                        qval(2:2:end) = bitand(bitshift(compressedData,-21), 127);
                        ival = (single(ival) - single(bitand(ival, 64) * 2)) .* (2 .^ -(0 - single(expo) - 3)) / 256.0;
                        qval = (single(qval) - single(bitand(qval, 64) * 2)) .* (2 .^ -(0 - single(expo) - 3)) / 256.0;
                    end
                    
                    timeData = ival + 1i * qval;
%                     if messageHeader.channel == 0 
%                         data = [] ;
%                     end
                    data(:, messageHeader.channel + 1) = timeData;
                end
                if sonarDataChannel == sonarHeader.channels
                    if sum(messageHeader.contentType == reqDataType) == 1
                        header = sonarHeader ;
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
            case 182
                %This is just an initial info record
                
                messageHeader.contentType = 200 ; % Unused
                header.systemType   = fread(fileid,1,'int32');   % bytes 1-4
                header.lowRateIO    = fread(fileid,1,'int32');   % bytes 5-8
                header.sonarVersion = fread(fileid,1,'int32');   % bytes 9-12
                header.numSubSystem = fread(fileid,1,'int32'); % bytes 13-16
                header.numSerial    = fread(fileid,1,'int32');      % bytes 17-20
                header.towNo        = fread(fileid,1,'int32');          % bytes 21-24
                [dummy,cnt]         = fread(fileid,(messageHeader.byteCount-24),'int8');
                if isempty(cnt) || isempty(dummy)
                    messageHeader.contentType= -4;  % signal end of file, data not found
                    return
                end
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                    
                end
            case 1009  %Array info message (Private)
                
                data.Nport=fread(fileid,1,'uint32');  %Number of elements              % bytes 0-3
                data.Nstbd=fread(fileid,1,'uint32');  %= 8/10                          % bytes 4-7
                
                data.portspacing=fread(fileid,1,'float32');                            % bytes 8-11
                data.stbdspacing=fread(fileid,1,'float32');                            % bytes 12-15
                
                dummy=fread(fileid,16,'*char');  %Part no                              % bytes 16-31
                data.pnport=str2double(dummy.') ;
                dummy=fread(fileid,16,'*char');  %Part no                              % bytes 32-47
                data.pnstbd=str2double(dummy.') ;
                dummy=fread(fileid,16,'char');                                         % bytes 48-63
                data.serialnoport = str2double(char(dummy).'); %#ok<*FREAD>
                dummy=fread(fileid,16,'char');                                         % bytes 64-79
                data.serialnostbd = str2double(char(dummy).');
                data.freqport=fread(fileid,1,'float32');  %freq of array nominal port  % bytes 80-83
                data.freqstbd=fread(fileid,1,'float32');  %freq of array nominal stbd  % bytes 84-87
                data.installAnglePort=fread(fileid,1,'float32');                       % bytes 88-91
                data.installAngleStbd=fread(fileid,1,'float32');                       % bytes 92-95
                data.installDirectionPort=fread(fileid,1,'uint8');                     % byte 96
                data.installDirectionStbd=fread(fileid,1,'uint8');                     % byte 97
                fread(fileid,2,'int8');   %Alignment bytes                             % bytes 98-99
                data.portOffset=fread(fileid,1,'float32');    %Port Horizontal offset  % bytes 100-103
                data.stbdOffset=fread(fileid,1,'float32');                             % bytes 104-107
                
                [dummy,cnt]=fread(fileid,20,'int8');                                   % bytes 108-127
                if isempty(cnt) || isempty(dummy)
                    messageHeader.contentType= -4;  % signal end of file, data not found
                    fclose(rafile);
                    return
                else
                    messageHeader.contentType = 8 ;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
                
            case 1011   %Array Cal message
                
                dummy=fread(fileid,16,'char');
                data.partNo=str2double(char(dummy).');
                dummy=fread(fileid,16,'char');
                data.serialNo=str2double(char(dummy).');
                data.freq=fread(fileid,1,'float32');
                data.elementSpacing=fread(fileid,1,'float32');
                numTables=fread(fileid,1,'int32');  %int
                numberOfEntries=fread(fileid,1,'int32'); %int
                
                
                header.beamformLevel=fread(fileid,12,'int16'); %short int
                angleScaleFactor=fread(fileid,12,'float32');
                anglecorrection=zeros(numTables+1,numberOfEntries);
                fread(fileid,4,'int32');  %Reserved
                anglecorrection(1,:) = fread(fileid,numberOfEntries,'int16')/100;   %Lookup angles
                for iloop = 1: numTables
                    anglecorrection(iloop+1,:)=fread(fileid,numberOfEntries,'int16')*...
                        angleScaleFactor(iloop);
                end
                % Table is row 1 = lookup angles
                %          row 2 = angle correction for beamform 1
                %          row 3 = angle correction for beamform 2 etc.
                data.angleCorrection=anglecorrection;
                data.angleScaleFactor = angleScaleFactor ;
                messageHeader.contentType = 10;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                end
                
            case 2000   %Process NMEA for Navigation
                %get time stamp
                header.time.seconds = fread(fileid,1,'uint32');%in seconds
                header.time.milliseconds= fread(fileid,1,'uint32');%in milliseconds
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                fread(fileid,4,'uint8');  %Reserved
                
                NMEAmess=fread(fileid,messageHeader.byteCount-12 ,'uint8')'; %RS232 chars
                NMEAstr = char(NMEAmess) ;
                indx=strfind(NMEAstr,',');
                try % got one OceanServer file with a 2 character message, would crash the parser
                    if strcmp(NMEAstr(1),':') % TSS1
                        data.hAcc = str2double(NMEAstr(2:3)) * 0.0383 ;
                        data.vAcc = str2double(NMEAstr(4:7)) * 0.0625 ;
                        data.heave = str2double(NMEAstr(9:13)) * 0.01 ;
                        header.status = NMEAstr(14) ;
                        data.roll = str2double(NMEAstr(15:19)) * 0.01 ;
                        data.pitch = str2double(NMEAstr(21:25)) * 0.01 ;
                        messageHeader.contentType = 2;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                        end
                        
                    end
                    if  strcmp(NMEAstr(4:6),'GGA')
                        d = str2double(NMEAstr(indx(2)+1:indx(2)+2)) ;
                        m = str2double(NMEAstr(indx(2)+3:indx(2)+10)) ;
                        data.lat = d + m / 60 ;
                        if NMEAstr(indx(3)+1) == 'S'
                            data.lat = -data.lat ;
                        end
                        d = str2double(NMEAstr(indx(4)+1:indx(4)+3)) ;
                        m = str2double(NMEAstr(indx(4)+4:indx(4)+11)) ;
                        data.lon = d + m / 60 ;
                        if NMEAstr(indx(5)+1) == 'W'
                            data.lon = -data.lon ;
                        end
                        data.quality = NMEAstr(indx(6)+1) ;
                        data.alt = str2double(NMEAstr(indx(9)+1:indx(9)+5)) ;
                        messageHeader.contentType = 3 ;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                        end
                    end
                    if  strcmp(NMEAstr(4:6),'VTG')
                        data.heading = str2double(NMEAstr(indx(1)+1:indx(2)-1)) ;
                        data.speed = str2double(NMEAstr(indx(7)+1:indx(8)-1)) / 3.6 ;
                        messageHeader.contentType = 13 ;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                        end
                    end
                    if strcmp('$__ETC',char(NMEAstr(1:6))) ||   strcmp('$--ETC',char(NMEAstr(1:6)))  %OS ETC message
                        indx=strfind(NMEAstr,',');  %finds ' , '
                        data.lat     =  str2double(char(NMEAstr((indx(6)+1):indx(7)-1)));
                        data.lon     =  str2double(char(NMEAstr((indx(7)+1):indx(8)-1)));
                        data.heading =  str2double(char(NMEAstr((indx(8)+1):indx(9)-1)));
                        data.roll =  str2double(char(NMEAstr((indx(9)+1):indx(10)-1)));
                        data.pitch =  str2double(char(NMEAstr((indx(10)+1):indx(11)-1)));
                        data.depth   =  str2double(char(NMEAstr((indx(11)+1):indx(12)-1)));
                        data.altitude   =  str2double(char(NMEAstr((indx(12)+1):indx(13)-1)));
                        data.sv      =  str2double(char(NMEAstr((indx(16)+1):indx(17)-1)));
                        messageHeader.contentType = 9;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                            
                        end
                    end
                catch
                    data = [] ;
                    header = [] ;
                end
                fred = 1 ;
            case 2002   %Process NMEA for Navigation
                %get time stamp
                header.time.seconds = fread(fileid,1,'uint32');%in seconds
                header.time.milliseconds= fread(fileid,1,'uint32');%in milliseconds
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                fread(fileid,4,'uint8');  %Reserved
                
                NMEAstr=fread(fileid,messageHeader.byteCount-12 ,'uint8')'; %RS232 chars
                
                %Check if SVP mssg
                if strcmp(' 1', char(NMEAstr(1:2))) && strcmp('.',char(NMEAstr(6)))
                    % = SVP Mssg
                    data.sv=str2double(char(NMEAstr)) ;
                    data.flag=0 ; % no pressure
                    messageHeader.contentType = 6;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
                
                indx=strfind(NMEAstr,',');
                try
                    if ~isempty(indx) && strcmp('GGK',char(NMEAstr(4:6))) || strcmp('GGK',char(NMEAstr(indx(1)+1:indx(2)-1)))
                        if strcmp('$PTNL',char(NMEAstr(1:indx(1)-1)))
                            londeg = str2double(char(NMEAstr((indx(6)+1):indx(6)+3)));  %Degrees
                            lonmin = str2double(char(NMEAstr((indx(6)+4):indx(7)-1)));  %Mins
                            if strcmp(char(NMEAstr(indx(7)+1)),'W'), londeg=londeg*-1; lonmin=lonmin*-1; end
                            latdeg = str2double(char(NMEAstr((indx(4)+1):indx(4)+2)));  %Degrees
                            latmin = str2double(char(NMEAstr((indx(4)+3):indx(5)-1)));  %Mins
                            if strcmp(char(NMEAstr(indx(6)+1)),'S'), latdeg=latdeg*-1; latmin=latmin*-1; end
                            data.lon = londeg+lonmin/60;
                            data.lat = latdeg+latmin/60;
                            rtk= str2double(char(NMEAstr( (indx(8)+1) : indx(9)-1) ));
                            if rtk >=  2
                                indx2= strfind(NMEAstr,'EHT');
                                data.height = str2double(char(NMEAstr((indx2+3):indx(12)-1)));
                            end
                        else
                            londeg = str2double(char(NMEAstr((indx(5)+1):indx(5)+3)));  %Degrees
                            lonmin = str2double(char(NMEAstr((indx(5)+4):indx(6)-1)));  %Mins
                            if strcmp(char(NMEAstr(indx(6)+1)),'W'), londeg=londeg*-1; lonmin=lonmin*-1; end
                            latdeg = str2double(char(NMEAstr((indx(3)+1):indx(3)+2)));  %Degrees
                            latmin = str2double(char(NMEAstr((indx(3)+3):indx(4)-1)));  %Mins
                            if strcmp(char(NMEAstr(indx(5)+1)),'S'), latdeg=latdeg*-1; latmin=latmin*-1; end
                            data.lon = londeg+lonmin/60;
                            data.lat = latdeg+latmin/60;
                            rtk= str2double(char(NMEAstr( (indx(7)+1) : indx(8)-1) ));
                            if rtk >=  2
                                indx2= strfind(NMEAstr,'EHT');
                                data.height = str2double(char(NMEAstr((indx2+3):indx(11)-1)));
                            end
                        end
                        messageHeader.contentType = 3;
                        header.GPSsource = 10;  %set flag to show source
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                            
                        end
                    end
                catch
                    fred = 1 ;
                end
                
                if ~isempty(indx) && strcmp('$PTNL,GGK',char(NMEAstr(1:indx(2)-1)))  %PTNL Message
                    if size(indx,2) ==12  %Valid GGK Message
                        londeg = str2double(char(NMEAstr((indx(6)+1):indx(6)+3)));  %Degrees
                        lonmin = str2double(char(NMEAstr((indx(6)+4):indx(7)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(7)+1)),'W'), londeg=londeg*-1; lonmin=lonmin*-1; end
                        latdeg = str2double(char(NMEAstr((indx(4)+1):indx(4)+2)));  %Degrees
                        latmin = str2double(char(NMEAstr((indx(4)+3):indx(5)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(5)+1)),'S'), latdeg=latdeg*-1; latmin=latmin*-1; end
                        data.lon = londeg+lonmin/60;
                        data.lat = latdeg+latmin/60;
                    end
                    rtk= str2double(char(NMEAstr( (indx(8)+1) : indx(9)-1) ));
                    if rtk == 3 || rtk >=  6
                        indx2= strfind(NMEAstr,'EHT');
                        data.height = str2double(char(NMEAstr((indx2+3):indx(12)-1)));
                    end
                    messageHeader.contentType = 3;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                    
                end
                
                if strcmp('RMC',char(NMEAstr(4:6)))   %Parse Posistion message
                    indx=strfind(NMEAstr,',');  %finds ' , '
                    if size(indx,2) ==12 || size(indx,2) ==13 %Valid GMRMC Message
                        londeg = str2double(char(NMEAstr((indx(5)+1):indx(5)+3)));  %Degrees
                        lonmin = str2double(char(NMEAstr((indx(5)+4):indx(6)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(6)+1)),'W'), londeg=londeg*-1; lonmin=lonmin*-1; end
                        latdeg = str2double(char(NMEAstr((indx(3)+1):indx(3)+2)));  %Degrees
                        latmin = str2double(char(NMEAstr((indx(3)+3):indx(4)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(4)+1)),'S'), latdeg=latdeg*-1; latmin=latmin*-1; end
                        data.lon = londeg+lonmin/60;
                        data.lat = latdeg+latmin/60;
                        
                        %Speed, course
                        %data.speed = str2double(char(NMEAstr((indx(7)+1):indx(8)-1)));
                        %data.track = str2double(char(NMEAstr((indx(8)+1):indx(9)-1)));
                        %not used
                        
                        messageHeader.contentType = 3;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                            
                        end
                    else
                        disp('Bad GPRMC Sentence');
                    end
                end  %if strcmp
                
                if strcmp('GGA',char(NMEAstr(4:6)))   %Parse Posistion message
                    indx=strfind(NMEAstr,',');  %finds ' , '
                    if size(indx,2) ==14  %Valid GMRMC Message
                        londeg = str2double(char(NMEAstr((indx(4)+1):indx(4)+3)));  %Degrees
                        lonmin = str2double(char(NMEAstr((indx(4)+4):indx(5)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(5)+1)),'W'), londeg=londeg*-1; lonmin=lonmin*-1; end
                        latdeg = str2double(char(NMEAstr((indx(2)+1):indx(2)+2)));  %Degrees
                        latmin = str2double(char(NMEAstr((indx(2)+3):indx(3)-1)));  %Mins
                        if strcmp(char(NMEAstr(indx(3)+1)),'S'), latdeg=latdeg*-1; latmin=latmin*-1; end
                        data.lon = londeg+lonmin/60;
                        data.lat = latdeg+latmin/60;
                        rtk= str2double(char(NMEAstr(indx(6)+1)));
                        if rtk==4
                            data.height = str2double(char(NMEAstr((indx(9)+1):indx(10)-1)));
                        end
                        
                        messageHeader.contentType = 3;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                            
                        end
                    else
                        disp('Bad GGA Sentence');
                    end
                end  %if strcmp
                
                %PROCESS HEADING
                if strcmp('HDT',char(NMEAstr(4:6)))   %Parse heading message
                    indx=strfind(NMEAstr,',');  %finds ' , '
                    heading = str2double(char(NMEAstr((indx(1)+1):indx(2)-1)));  %Degrees True
                    if ~isempty(heading)  % Some readings maybe empty... no heading
                        data.hdg = heading;
                        messageHeader.contentType = 4;
                        if sum(messageHeader.contentType == reqDataType) == 1
                            return
                        else
                            data = [] ;
                            header = [] ;
                            
                        end
                    end
                end  %if strcmp
                
                if strcmp('HYDRO',char(NMEAstr(2:6)))   %PHINS HYDRO message
                    indx=strfind(NMEAstr,',');  %finds ' , '
                    starindx=strfind(NMEAstr,'*');
                    data.heave = -1*str2double(char(NMEAstr((indx(7)+1):starindx(1)-1)));% +Heave dnwards in meters in our fmt
                    data.roll  =    str2double(char(NMEAstr((indx(2)+1):indx(3)-1)));
                    data.pitch = -1*str2double(char(NMEAstr((indx(3)+1):indx(4)-1)));
                    data.heading =  str2double(char(NMEAstr((indx(1)+1):indx(2)-1)));
                    data.lat     =  str2double(char(NMEAstr((indx(4)+1):indx(5)-1)));
                    tem          =  str2double(char(NMEAstr((indx(5)+1):indx(6)-1)));
                    if tem > 180, tem= tem-360; end
                    data.lon = tem;
                    data.depth   =-1*str2double(char(NMEAstr((indx(6)+1):indx(7)-1)));
                    messageHeader.contentType = 7;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
                
                
                %%%%ETC Message parse
                if strcmp('$__ETC',char(NMEAstr(1:6))) ||   strcmp('$--ETC',char(NMEAstr(1:6)))  %OS ETC message
                    indx=strfind(NMEAstr,',');  %finds ' , '
                    data.lat     =  str2double(char(NMEAstr((indx(6)+1):indx(7)-1)));
                    data.lon     =  str2double(char(NMEAstr((indx(7)+1):indx(8)-1)));
                    data.heading =  str2double(char(NMEAstr((indx(8)+1):indx(9)-1)));
                    data.roll =  str2double(char(NMEAstr((indx(9)+1):indx(10)-1)));
                    data.pitch =  str2double(char(NMEAstr((indx(10)+1):indx(11)-1)));
                    data.depth   =  str2double(char(NMEAstr((indx(11)+1):indx(12)-1)));
                    data.altitude   =  str2double(char(NMEAstr((indx(12)+1):indx(13)-1)));
                    data.sv      =  str2double(char(NMEAstr((indx(16)+1):indx(17)-1)));
                    messageHeader.contentType = 9;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
                
                %TSS motion sensor format...
                if exist('NMEAstr','var')  && NMEAstr(1) == ':' && size(NMEAstr,2) == 28  %TSS1 data
                    %%%%%  Parse string for TSS1 format (Heave opposite of ET fmt)
                    data.heave = -1*str2double(char(NMEAstr( 9:13)))/100;%+Heave dnwards in meters
                    data.roll  = str2double(char(NMEAstr(15:19)))/100;
                    data.pitch = str2double(char(NMEAstr(21:25)))/100;
                    messageHeader.contentType = 2;
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                end
                % message was not parsed, clear variables
                data = [] ;
                header = [] ;
            case 2020   %Process for Roll & Pitch
                %get time stamp
                header.time.seconds = fread(fileid,1,'uint32');%in seconds
                header.time.milliseconds= fread(fileid,1,'uint32');%in milliseconds
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                fread(fileid,4,'uint8');  %Reserved
                data.AccX = fread(fileid,1,'uint16')*(20/1.5)/32768;  %gyro rates
                data.AccY = fread(fileid,1,'uint16')*(20/1.5)/32768;  %gyro rates
                data.AccZ = fread(fileid,1,'uint16')*(20/1.5)/32768;  %gyro rates
                data.RateX = fread(fileid,1,'uint16')*(500/1.5)/32768;  %gyro rates
                data.RateY = fread(fileid,1,'uint16')*(50/1.5)/32768;  %gyro rates
                data.RateZ = fread(fileid,1,'uint16')*(50/1.5)/32768;  %gyro rates
                data.pitch = fread(fileid,1,'int16')/32768*180; %signed !
                data.roll = fread(fileid,1,'int16')/32768*180; %signed !
                data.temperature = fread(fileid,1,'int16')/10;
                fread(fileid,1,'int16');
                data.heave = fread(fileid,1,'int16')/1000; %signed !
                data.heading = fread(fileid,1,'uint16')*.01; %signed !clc
                toto = fread(fileid,1,'int32') ;
                flags = fliplr(dec2bin(toto));
                data.yaw = fread(fileid,1,'int16')*0.01; %signed !
                fread(fileid,1,'int16');
                if size(flags,2) >= 10    % check if heading is present... (from PosMv)
                    if flags(10) == '0'
                        data.heading = [];
                    end
                else
                    data.heading = [];
                end
                data.flags=flags;
                messageHeader.contentType = 5;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                    
                end
                
            case 2060    %Pressure message for SV
                %get time stamp
                header.time.seconds = fread(fileid,1,'uint32');%in seconds
                header.time.milliseconds= fread(fileid,1,'uint32');%in milliseconds
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                fread(fileid,1,'int32');  %Reserved
                tem1= fread(fileid,1,'int32');  %pressure,temp,salinity not used
                fread(fileid,1,'int32');
                fread(fileid,1,'int32');
                flags =(fread(fileid,1,'int32'));
                data.flag=flags;
                if bitget(flags,1)
                    data.press=tem1/1000;
                else
                    data.press=0;
                end
                data.conductivity = fread(fileid,1,'int32');  %conductivity
                tem = fread(fileid,1,'int32')/1000;  %SV
                if bitget(flags,5)
                    data.sv= tem;
                    messageHeader.contentType = 6;
                    fread(fileid,10,'int32');  %
                    if sum(messageHeader.contentType == reqDataType) == 1
                        return
                    else
                        data = [] ;
                        header = [] ;
                        
                    end
                else
                    fread(fileid,10,'int32');
                end
                
            case 2081  %DVL  (DEVETDVLType)
                messageHeader.contentType = 12 ;
                header.time.seconds = fread(fileid,1,'uint32') ; % in seconds
                header.time.milliseconds= fread(fileid,1,'uint32') ; % in milliseconds
                [~] = fread(fileid,4,'uint8');  %Reserved
                data.flags=fread(fileid,1,'uint32'); %                                          Bytes: 1:4
                % Bit  0 : Bottom velocities and quality valid                         */
                % Bit  1 : Beam distances and status valid                             */
                % Bit  2 : Water velocities and quality valid                          */
                % Bit  3 : Water sound velocity valid                                  */
                % Bit  4 : Altitude valid                                              */
                % Bit  5 : Depth valid                                                 */
                % Bit  6 : Mounting angle valid                                        */
                % Bit  7 : Frequency valid                                             */
                
                data.stbdvelocity =fread(fileid,1,'float32');  %stbd speed m/s                  Bytes: 5:8
                data.fwdvelocity  =fread(fileid,1,'float32');  %fwd speed m/s                   Bytes: 9:12
                data.velZ  =fread(fileid,1,'float32');  %vert speed m/s                         Bytes: 13:16
                data.velX =fread(fileid,1,'float32');  %!!!!  These need to be swapped in C     Bytes: 17:20
                data.velY =fread(fileid,1,'float32');  %                                        Bytes: 21:24
                data.velocityQuality =fread(fileid,1,'float32'); %                              Bytes: 25;28
                data.distances  =fread(fileid,4,'float32'); %                                   Bytes: 29:44
                data.detectstatus  =fread(fileid,4,'uint8');%                                   Bytes: 45:48
                % Bit 0 : depth is less than the minimum range setting or greater than */
                %         the maximum range setting                                    */
                % Bit 1 : gating inconsistency detected                                */
                % Bit 2 : length of reflected transmit pulse does not match pulse used */
                % Bit 3 : start of first reflection of transmit pulse not detected     */
                % Bit 4 : end of first reflection of transmit pulse not detected       */
                % Bit 5 : depth too shallow for pulse sample                           */
                % Bit 6 : data sample length too short for successful bottom detection */
                % Bit 7 : SNR below acceptable threshold                               */
                [~]        =fread(fileid,3,'float32'); %water speed in m/s, ship                Bytes: 49:60
                [~]        =fread(fileid,2,'float32'); %water speed in m/s, dvl                 Bytes: 61:68
                [~]        =fread(fileid,1,'float32'); %water speed quality                     Bytes: 69:72
                data.sv =fread(fileid,1,'float32'); %                                           Bytes: 73:76
                data.altitude =fread(fileid,1,'float32');%                                      Bytes: 77:80
                data.depth  =fread(fileid,1,'float32');%                                        Bytes: 81:84
                data.installangledeg=fread(fileid,1,'float32'); %degrees%                       Bytes: 85:88
                data.dvlfreq=fread(fileid,1,'float32');%                                        Bytes: 89:92
                data.stbdacc = fread(fileid,1,'float32');% accelaration                         Bytes: 93:96
                data.fwdacc = fread(fileid,1,'float32');% accelaration                          Bytes: 97:100
                data.dwnacc = fread(fileid,1,'float32');% accelaration                          Bytes: 101:104
                data.dopest      = fread(fileid,4,'float32');  % Doppler Frequency (Hz)         Bytes: 105:120
                data.rsvd       =fread(fileid,1,'int32');  %rsrvd%                              Bytes: 120:124
                header.ping =fread(fileid,1,'int32');%                                          Bytes: 125:128
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                    
                end
            case 2091
                messageHeader.contentType = 11 ;
                header.time.seconds = fread(fileid,1,'uint32');               %byte 0-3
                header.time.milliseconds = fread(fileid,1,'uint32') ;         %byte 4-7
                data.reserved = fread(fileid,4,'uint8');                      %byte 8-11
                data.flags = fread(fileid,1,'uint32');                        %byte 12-15
                data.velocity12 = fread(fileid,1,'uint8');                    %byte 16
                data.reserved2 = fread(fileid,3,'uint8');                     %byte 17-19
                data.timestamp = fread(fileid,1,'uint64') / 1e7;              %byte 20-27
                data.lat = fread(fileid,1,'double');                          %byte 28-35
                data.lon = fread(fileid,1,'double');                          %byte 36-43
                data.depth = fread(fileid,1,'float');                         %byte 44-47
                data.altitude = fread(fileid,1,'float');                      %byte 48-51
                data.heave = fread(fileid,1,'float');                         %byte 52-55
                data.velocity1 = fread(fileid,1,'float');                     %byte 56-59
                data.velocity2 = fread(fileid,1,'float');                     %byte 60-63
                data.velocityDown = fread(fileid,1,'float');                  %byte 64-67
                data.pitch = fread(fileid,1,'float');                         %byte 68-71
                data.roll = fread(fileid,1,'float');                          %byte 72-75
                data.heading = fread(fileid,1,'float');                       %byte 76-79
                data.soundSpeed = fread(fileid,1,'float');                    %byte 80-83
                data.waterTemperature = fread(fileid,1,'float');              %byte 84-87
                data.reserved3 = fread(fileid,3,'float');                     %byte 88-99
                
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                    
                end
            case 3000
                data = [] ;   % could get there after a partial 80 message (missing  a channel)
                header = [] ; %  --> need to wipe out partial structures
                
                header.time.seconds = fread(fileid,1,'uint32');           %byte 0
                header.time.milliseconds = fread(fileid,1,'uint32') / 1e6 ;  %byte 4
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                header.pingNum = fread(fileid,1,'uint32');
                header.nsamps = fread(fileid,1,'uint16');
                header.channel = fread(fileid,1,'uint8');
                header.algo = fread(fileid,1,'uint8');                       %Algorithm used
                header.numPulses = fread(fileid,1,'uint8');              %byte 16
                header.pulsePhase = fread(fileid,1,'uint8');              %byte 17
                header.pulseID = fread(fileid,1,'uint16');                %byte 18
                header.pulsePower = fread(fileid,1,'float32'); %pulsepower       %byte 20
                header.startf = fread(fileid,1,'float32');         %byte 24
                header.stopf = fread(fileid,1,'float32');          %byte 28
                fread(fileid,1,'float32');                 %byte 32
                header.fsample = fread(fileid,1,'float32');                  %byte 36
                header.timeToFirstSample = fread(fileid,1,'uint32');      %byte 40         ! was firstSampleNo-1
                header.timeUncertainty = fread(fileid,1,'float32');                  %byte 44 timedelay uncertainty
                header.timeScaleFactor = fread(fileid,1,'float32');           %byte 48 timeScaleFactor
                %%%%%%   /2 above because we will double and fix the Delay_indexes...
                fread(fileid,1,'float32');                  %byte 52 sclfactor error in%
                header.angleScaleFactor = fread(fileid,1,'float32');                %byte 56,
                fread(fileid,1,'float32');                     %byte 60-63, Reserved
                %compute time to first return
                header.timeToBottom = fread(fileid,1,'uint32');             %byte 64, first echo
                fread(fileid,1,'uint8');                       % Rev Level of format = 2
                header.binData = fread(fileid,1,'uint8');                 %byte 69
                header.TVG = fread(fileid,1,'uint16');                      %byte 70-71
                header.swath = fread(fileid,1,'float32');        %byte 72-75
                header.binSize = fread(fileid,1,'float32');                      %byte 76-79
                
                %Format Rev 4
                
                SNRQUAL = zeros(header.nsamps,1) ;
                
                databuffer = fread(fileid, header.nsamps * 8,'*uchar') ;
                dataloc = 1 ;
                for lop = 1:header.nsamps
                    count = 2 ; data.DelayIndex(lop) = double(typecast(databuffer(dataloc:dataloc+count-1),'uint16'));  dataloc = dataloc+count ;  %!Index error corrected 2/9/10
                    count = 2 ; data.Angle(lop) = double(typecast(databuffer(dataloc:dataloc+count-1),'int16')); dataloc = dataloc+count ;
                    count = 1 ; data.Amp(lop) = double(typecast(databuffer(dataloc:dataloc+count-1),'uint8')); dataloc = dataloc+count ;
                    count = 1 ; data.Sigma(lop) = double(typecast(databuffer(dataloc:dataloc+count-1),'uint8')); dataloc = dataloc+count ;
                    count = 1 ; data.Filter_flag(lop) = double(typecast(databuffer(dataloc:dataloc+count-1),'uint8')); dataloc = dataloc+count ;
                    count = 1 ; SNRQUAL(lop)  = double(typecast(databuffer(dataloc:dataloc+count-1),'uint8')); dataloc = dataloc+count ;
                end
                %             for lop = 1:data.nsamps
                %                 data.DelayIndex(lop) = fread(fileid,1,'uint16');      %!Index error corrected 2/9/10
                %                 data.Angle(lop) = fread(fileid, 1 , 'int16');
                %                 data.Amp(lop) = fread(fileid, 1 ,'uint8');
                %                 data.Sigma(lop) = fread(fileid, 1,'uint8');
                %                 data.Filter_flag(lop) = fread(fileid, 1, 'uint8');
                %                 SNRQUAL(lop)  = fread(fileid, 1,'uint8');
                %             end
                
                data.TWTT = header.timeToFirstSample/1e9 + data.DelayIndex * header.timeScaleFactor ;
                data.Angle = header.angleScaleFactor * data.Angle/180*pi ;
                data.SNR = bitand(SNRQUAL,31)' ;
                data.QUAL = bitshift(SNRQUAL,-5)' ;
                messageHeader.contentType = 42 ;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                    
                end
                
            case 3001 % motion from bathy processor
                header.time.seconds = fread(fileid, 1,'uint32') ;           %byte 0
                header.time.milliseconds = fread(fileid, 1,'uint32') / 1e6 ;  %byte 4
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                header.flags = fread(fileid, 1,'uint32') ;            %byte 8
                data.heading = fread(fileid, 1,'float32') ;               %byte 12
                data.heave = fread(fileid, 1,'float32') ;       %byte 16
                data.pitch = fread(fileid, 1,'float32') ;       %byte 20
                data.roll = fread(fileid, 1,'float32') ;         %byte 24
                data.yaw = fread(fileid, 1,'float32');                 %byte 28
                messageHeader.contentType = 43 ;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                end
            case 3002 % CTD from bathy processor
                header.time.seconds = fread(fileid, 1, 'uint32');              %byte 0
                header.time.milliseconds  = fread(fileid, 1, 'uint32') / 1e6;  %byte 4
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                header.flags =fread(fileid, 1, 'uint32');                     %byte 8
                data.absolutePressure = fread(fileid, 1, 'single');            %byte 12
                data.waterTemperature = fread(fileid, 1, 'single');            %byte 16
                data.salinity = fread(fileid, 1, 'single');                    %byte 20
                data.conductivity = fread(fileid, 1, 'single');                %byte 24
                data.soundSpeed = fread(fileid, 1, 'single');                  %byte 28
                data.depth = fread(fileid, 1, 'single');                       %byte 32
                messageHeader.contentType = 45 ;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                end
            case 3003 % altitude from bathy processor
                header.time.seconds = fread(fileid, 1, 'uint32');              %byte 0
                header.time.milliseconds  = fread(fileid, 1, 'uint32') / 1e6;  %byte 4
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                header.flags = fread(fileid, 1, 'uint32');                     %byte 8
                data.altitude = fread(fileid, 1, 'single');            %byte 12
                data.speed = fread(fileid, 1, 'single');            %byte 16
                data.heading = fread(fileid, 1, 'single');            %byte 16
                messageHeader.contentType = 46 ;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                end
            case 3004 % situation from bathy processor
                header.time.seconds = fread(fileid, 1,'uint32') ;             %byte 0
                header.time.milliseconds = fread(fileid, 1,'uint32') / 1e6 ;  %byte 4
                header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
                header.flags = fread(fileid, 1,'uint16') ;                    %byte 8
                data.UTMzone = fread(fileid, 1,'uint16') ;                    %byte 10
                data.easthing = fread(fileid, 1,'double') ;                    %byte 12
                data.northing = fread(fileid, 1,'double') ;                   %byte 20
                data.lat = fread(fileid, 1,'double') ;                   %byte 28
                data.lon = fread(fileid, 1,'double') ;                  %byte 36
                data.speed = fread(fileid, 1,'float32');                      %byte 44
                data.heading = fread(fileid, 1,'float32');                    %byte 48
                data.height = fread(fileid, 1,'float32');                     %byte 52
                messageHeader.contentType = 44 ;
                if sum(messageHeader.contentType == reqDataType) == 1
                    return
                else
                    data = [] ;
                    header = [] ;
                end           
        end
    else
        [dummy,cnt] = fread(fileid,(messageHeader.byteCount),'int8');
        if isempty(cnt) || isempty(dummy)
            messageHeader.contentType= -4;  % signal end of file, data not found
            return
        end
    end
end

