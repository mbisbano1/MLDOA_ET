% Script to read a JSF file, modify it, and write results in new file

% current mod: changes the values of the soundings range and angle
fprintf('\n\n');
try 
    fclose(infileid) ;
    fprintf('in cleared\n');
catch
    fprintf('no in to clear\n');
end
try 
    fclose(outfileid) ;
    fprintf('out cleared\n');
catch
    fprintf('no out to clear\n');
end
%%
clear
%msgbox('Load your AI_Predicted_DOA_Array variable into workspace before starting')

% Check if last folder location exists and is valid
defaultAI_Array_path = 'D:\OneDrive\OneDrive - University of Massachusetts Dartmouth\ECE457_Senior_Design_ECE5\AIOutput_CSV_Files';

%%% BEGIN CODE BY MBISBANO
try
    [AI_Array_filename,AI_Array_path]=uigetfile([defaultAI_Array_path '/*.mat'], 'Which file to replace JSF DOA values with?'); %open file and assign handle
catch
    [AI_Array_filename,AI_Array_path]=uigetfile('*.mat', 'Which file to replace JSF DOA values with?'); %open file and assign handle
end


load(fullfile(AI_Array_path, AI_Array_filename));
%AI_Port_DOA_fp = fullfile(AIOUTPUTCSVfpath, AIOutputfilename_port);
firstPingInAI = PullPingOutOf3DMatrix(AI_Predicted_DOA_Array, -1);
lastPingInAI = PullPingOutOf3DMatrix(AI_Predicted_DOA_Array, 9999999999999);
%%% END CODE BY MBISBANO

try
  %load lastJSFdir
  %load 
  load fpath
  fpath = fpathMB;
  dummy = dir(fpath) ;
  if isempty(dummy)
    fpath = './' ;
  end
catch
  lastJSFdir = './' ;
end

% Load file to process..
[filename,fpath]=uigetfile([fpath '*.jsf'], 'Which file to process?'); %open file and assign handle
if fpath ~= 0
  save lastJSFdir.mat 'fpath'
end

infileid = fopen([fpath,filename],'r');

defaultNewFileName = cat(2,filename(1:end-4),'_AI_DOA.jsf');
[outfile,outpath] = uiputfile(defaultNewFileName, 'Save file in the "JSF_Files/AI_DOA_VALUES" folder');
%save MLDOAPredictions.mat AI_Predicted_DOA_Array
outputFP = fullfile(outpath, outfile);
outfileid = fopen(outputFP, 'wb');
%save(outputFP, 'AI_Predicted_DOA_Array');
%outfileid = fopen([fpath,filename(1:end-4) '_fixed.jsf'],'wb');
%%
oldtime = 0 ;
ip = 0 ;

while 1==1 && ip < 500
  startOfMessage = fread(infileid,1,'int16');
  version = fread(infileid,1,'int8');
  [sessionId,cnt] = fread(infileid,1,'int8');

  %check if we read any data ....  (EOF ?)
  if cnt ==0
    errflag = -4;
    break
  end

  %Check if valid message
  if (startOfMessage ~= hex2dec('1601') )
    errflag =-1;  %Not valid JSF format data !
    break
  end

  messageType = fread(infileid,1,'int16');
  commandType = fread(infileid,1,'int8');
  subSystem = fread(infileid,1,'int8');  %0 = SB, 20 = SSL, 21 = SSH, 40 = bathy
  channel= fread(infileid,1,'int8');  %0=port, 1 = stbd for SS systems
  sequenceNo = fread(infileid,1,'int8');
  reserved = fread(infileid,1,'int16');%Reserved field, 16 bits
  byteCount = fread(infileid,1,'uint32'); %Size of data block  which follows

  [message,cnt] = fread(infileid,(byteCount),'uint8');
  if isempty(cnt) || isempty(message)
    errflag= -4;  % signal end of file, data not found
    fprintf('break, line 95\n');
    break
  end
  if messageType == 3000
    %
    % parse existing record
    %
    data = [] ;   
    header = [] ;
    dataloc = 1 ;
    count = 4 ; header.time.seconds = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint32')); dataloc = dataloc + count ;           %byte 0
    count = 4 ;  header.time.milliseconds = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint32') / 1e6 ); dataloc = dataloc + count ;           %byte 0

    header.timeStamp = header.time.seconds + header.time.milliseconds / 1e3 ;
    count = 4 ; header.pingNum = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint32')); dataloc = dataloc + count ;
    count = 2 ; header.nsamps = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint16')); dataloc = dataloc + count ;
    count = 1 ; header.channel = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;
    count = 1 ; header.algo = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;                       %Algorithm used
    count = 1 ; header.numPulses = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;              %byte 16
    count = 1 ; header.pulsePhase = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;              %byte 17
    count = 2 ; header.pulseID = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint16')); dataloc = dataloc + count ;                %byte 18
    count = 4 ; header.pulsePower = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ; %pulsepower       %byte 20
    count = 4 ; header.startf = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;         %byte 24
    count = 4 ; header.stopf = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;          %byte 28
    count = 4 ; header.mixerf = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;  ;                 %byte 32
    count = 4 ; header.fsample = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;                  %byte 36
    count = 4 ; header.timeToFirstSample = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint32')); dataloc = dataloc + count ;      %byte 40         ! was firstSampleNo-1
    count = 4 ; header.timeUncertainty = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;                  %byte 44 timedelay uncertainty
    count = 4 ; header.timeScaleFactor = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;           %byte 48 timeScaleFactor
    %%%%%%   /2 above because we will double and fix the Delay_indexes...
    count = 4 ; header.timeScaleAccuracy = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;                    %byte 52 sclfactor error in%
    count = 4 ; header.angleScaleFactor = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;                %byte 56,
    count = 4 ; dataloc = dataloc + count ;                     %byte 60-63, Reserved
    %compute time to first return
    count = 4 ; header.timeToBottom = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint32')); dataloc = dataloc + count ;             %byte 64, first echo
    count = 1 ; header.revlevel = uint8(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;                       % Rev Level of format = 2
    count = 1 ; header.binData = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;                 %byte 69
    count = 2 ; header.TVG = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint16')); dataloc = dataloc + count ;                      %byte 70-71
    count = 4 ; header.swath = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;        %byte 72-75
    count = 4 ; header.binSize = double(typecast(uint8(message(dataloc:dataloc+count-1)),'single')); dataloc = dataloc + count ;                      %byte 76-79

    %Format Rev 4

    for lop = 1:header.nsamps
      count = 2 ; data.DelayIndex(lop) = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint16')); dataloc = dataloc + count ;      %!Index error corrected 2/9/10
      count = 2 ; data.Angle(lop) = double(typecast(uint8(message(dataloc:dataloc+count-1)),'int16')); dataloc = dataloc + count ;
      count = 1 ; data.Amp(lop) = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;
      count = 1 ; data.Sigma(lop) = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;
      count = 1 ; data.Filter_flag(lop) = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;
      count = 1 ; data.SNRQUAL(lop)  = double(typecast(uint8(message(dataloc:dataloc+count-1)),'uint8')); dataloc = dataloc + count ;
    end

    
    %
    
    % modify values here
    %
    
    %%% THIS IS THE START OF CODE INSERTED BY MBISBANO
    
    %USEFUL PARAMETERS
    % header.Channel == 0 (port)
    % header.Channel == 1 (stbd)
    % header.pingNum 
    % header.nsamps
    % header.angleScaleFactor 
    % This is how I scaled to our CSV file, needs to be undone here to
    % write back into JSF:
        % Soundings.Angle(stbdPings, 2, RNSSP(stbdSamps)+1) = Measurements.Angle(stbdPings, 1, stbdSamps).*(180/pi);
    
    TWTT = header.timeToFirstSample/1e9 + data.DelayIndex * header.timeScaleFactor ;
    fs = header.fsample;
    FirstSampleOffset = round(TWTT(1)./(1/fs));    
        
    scaleFactor = header.angleScaleFactor;
    portStbd = header.channel;    
    currPing = header.pingNum;
    fprintf('\nPing = %d\n', currPing)
    numSamplesPerPing = header.nsamps;
    % check to see if currPing is within bounds of firstPingInAI and
    % lastPingInAI..
    if header.channel == 1
        %posNeg = -1;
        posNeg = 1;
    elseif header.channel == 0
        posNeg = 1;
    end
    % check twtt scaling.
    %if ((currPing >= firstPingInAI) && (currPing <= lastPingInAI) && ...
    %        (unique(max(AI_Predicted_DOA_Array(:,:,4),[], 2)) <= numSamplesPerPing))
    if ((currPing >= firstPingInAI) && (currPing <= lastPingInAI))
        %AnglesArray = NaN(numSamplesPerPing, 1);
        PingArray = PullPingOutOf3DMatrix(AI_Predicted_DOA_Array, currPing);
        AnglesArray = PingArray(:, 1+portStbd);
        ScaledAnglesArray = posNeg.*AnglesArray./scaleFactor;
        
        ScaledTypecastAngles = double(cast(ScaledAnglesArray, 'int16'));
        for lop = 1:(numSamplesPerPing)
            if ~isnan(AnglesArray(lop+FirstSampleOffset)) % if the AI prediction is not missing,
                                        % replace old DOA with new DOA
                %data.Angle(lop) = (AnglesArray(lop).*(pi/180));   % bring angle back to JSF scaled format               
                data.Angle(lop) = ScaledAnglesArray(lop+FirstSampleOffset);
                data.Filter_flag(lop) = double(cast(0, 'uint8'));   % clear Filter Flag on data (good)
            else 
                data.Filter_flag(lop) = double(cast(16, 'uint8'));  % set Filter Flag on data (bad)
                data.Angle(lop) = nan;
            end            
            fprintf('Ping# %d, Samp# %d, DOA %d \n', currPing, lop, data.Angle(lop));
        end        
        fprintf('Replaced DOA in Ping# %d \n', currPing);
    else
        fprintf('Not Replacing DOA in Ping# %d \n', currPing);
    end            
    %%% THIS IS THE END OF CODE INSERTED BY MBISBANO
    
    %
    % write modified record
    %
    fwrite(outfileid,startOfMessage,'int16');
    fwrite(outfileid,version,'int8');
    fwrite(outfileid,sessionId,'int8');
    fwrite(outfileid,messageType,'int16');
    fwrite(outfileid,commandType,'int8');
    fwrite(outfileid,subSystem,'int8');  %0 = SB, 20 = SSL, 21 = SSH, 40 = bathy
    fwrite(outfileid,channel,'int8');  %0=port, 1 = stbd for SS systems
    fwrite(outfileid,sequenceNo,'int8');
    fwrite(outfileid,reserved,'int16');%Reserved field, 16 bits
    fwrite(outfileid,byteCount,'uint32'); %Size of data block  which follows
    fwrite(outfileid,header.time.seconds,'uint32');           %byte 0
    fwrite(outfileid,header.time.milliseconds*1e6,'uint32');  %byte 4
    fwrite(outfileid,header.pingNum,'uint32');
    fwrite(outfileid,header.nsamps,'uint16');
    fwrite(outfileid,header.channel,'uint8');
    fwrite(outfileid,header.algo,'uint8');                       %Algorithm used
    fwrite(outfileid,header.numPulses,'uint8');              %byte 16
    fwrite(outfileid,header.pulsePhase,'uint8');              %byte 17
    fwrite(outfileid,header.pulseID,'uint16');                %byte 18
    fwrite(outfileid,header.pulsePower,'float32'); %pulsepower       %byte 20
    fwrite(outfileid,header.startf,'float32');         %byte 24 NOTE: startf should be populated in Herz, not deca-hertz, so no need to x10
    fwrite(outfileid,header.stopf,'float32');          %byte 28
    fwrite(outfileid,header.mixerf,'float32');                 %byte 32
    fwrite(outfileid,header.fsample,'float32');                  %byte 36
    fwrite(outfileid,header.timeToFirstSample,'uint32');      %byte 40         ! was firstSampleNo-1
    fwrite(outfileid,header.timeUncertainty,'float32');                  %byte 44 timedelay uncertainty
    fwrite(outfileid,header.timeScaleFactor,'float32');           %byte 48 timeScaleFactor
    fwrite(outfileid,header.timeScaleAccuracy,'float32');               %byte 52 sclfactor error in%
    fwrite(outfileid,header.angleScaleFactor,'float32');                %byte 56,
    fwrite(outfileid,1,'float32');                     %byte 60-63, Reserved
    fwrite(outfileid,header.timeToBottom,'uint32');             %byte 64, first echo
    fwrite(outfileid,header.revlevel,'uint8');                       % Rev Level of format = 2
    fwrite(outfileid,header.binData,'uint8');                 %byte 69
    fwrite(outfileid,floor(header.TVG),'uint16');                      %byte 70-71
    fwrite(outfileid,header.swath,'float32');        %byte 72-75
    fwrite(outfileid,0,'uint32');                      %byte 76-79

    %Format Rev 4

    for lop = 1:length(data.DelayIndex)
      fwrite(outfileid,round(data.DelayIndex(lop)),'uint16');
      fwrite(outfileid,data.Angle(lop)            , 'int16');
      fwrite(outfileid,data.Amp(lop)              ,'uint8');
      fwrite(outfileid,data.Sigma(lop)            ,'uint8');
      fwrite(outfileid,data.Filter_flag(lop)      , 'uint8');
      fwrite(outfileid,data.SNRQUAL(lop)              ,'uint8');
    end

  else  % not message 3000
    fwrite(outfileid,startOfMessage,'int16');
    fwrite(outfileid,version,'int8');
    fwrite(outfileid,sessionId,'int8');
    fwrite(outfileid,messageType,'int16');
    fwrite(outfileid,commandType,'int8');
    fwrite(outfileid,subSystem,'int8');  %0 = SB, 20 = SSL, 21 = SSH, 40 = bathy
    fwrite(outfileid,channel,'int8');  %0=port, 1 = stbd for SS systems
    fwrite(outfileid,sequenceNo,'int8');
    fwrite(outfileid,reserved,'int16');%Reserved field, 16 bits
    fwrite(outfileid,byteCount,'uint32'); %Size of data block  which follows
    fwrite(outfileid,message,'uint8');
  end
end
% CLOSE FILES IF THERE IS AN ERROR : 
    % So you don't need to restart MatLab to clear the read/write block
fclose(infileid) ;
fclose(outfileid) ;
