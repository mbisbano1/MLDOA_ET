clear all
close all
clc

% This code is designed to take in a CSV of data output by MLDOA, 
% primarily the DOA outputs accompanied by Ping Number, Sample Number, 
% Sample Time Delay, and Port/Stbd flag.

%% Output CSV Importing
    % JSFfpath and CSVfpath are unused in this script.

[JSFfpath, CSVfpath, AIOUTPUTCSVfpath] = MB_FPATH_SET();
%[JSFfpath, CSVfpath, AIOUTPUTCSVfpath] = RF_FPATH_SET();
%[JSFfpath, CSVfpath, AIOUTPUTCSVfpath] = DL_FPATH_SET();

try
    [AIOutputfilename_port,AIOUTPUTCSVfpath]=uigetfile([AIOUTPUTCSVfpath '/*.csv'], 'Which file to process for Port Side DOA Predictions?'); %open file and assign handle
catch
    [AIOutputfilename_port,AIOUTPUTCSVfpath]=uigetfile('*.csv', 'Which file to process for Port Side DOA Predictions?'); %open file and assign handle
end
AI_Port_DOA_fp = fullfile(AIOUTPUTCSVfpath, AIOutputfilename_port);
%AI_Port_DOA_fp = fopen([AIOutputfilename_port,AIOUTPUTCSVfpath],'r');

try
    [AIOutputfilename_stbd,AIOUTPUTCSVfpath]=uigetfile([AIOUTPUTCSVfpath '/*.csv'], 'Which file to process for Starboard Side DOA Predictions?'); %open file and assign handle
catch
    [AIOutputfilename_stbd,AIOUTPUTCSVfpath]=uigetfile('*.csv', 'Which file to process for Starboard Side DOA Predictions?'); %open file and assign handle
end
AI_Stbd_DOA_fp = fullfile(AIOUTPUTCSVfpath, AIOutputfilename_stbd);
%AI_Stbd_DOA_fp = fopen([AIOutputfilename_stbd,AIOUTPUTCSVfpath],'r');

Port_DOA_Array = readmatrix(AI_Port_DOA_fp);
Stbd_DOA_Array = readmatrix(AI_Stbd_DOA_fp);
% column 1: row index (starting @ 0)
% column 2: Absolute ping #
% column 3: Absolute Sample #
% column 4: Port/Stbd (0 == port, 1 == stbd)
% column 5: TWTT
% column 6: AI Predicted DOA


%% Fill in gaps on port and starboard arrays:
minimumPortSampleNumber = min(Port_DOA_Array(:,3));
maximumPortSampleNumber = max(Port_DOA_Array(:,3));
minimumStbdSampleNumber = min(Stbd_DOA_Array(:,3));
maximumStbdSampleNumber = max(Stbd_DOA_Array(:,3));

minPortPingNumber = min(Port_DOA_Array(:,2));
maxPortPingNumber = max(Port_DOA_Array(:,2));
numPortPings = maxPortPingNumber-minPortPingNumber+1;
minStbdPingNumber = min(Stbd_DOA_Array(:,2));
maxStbdPingNumber = max(Stbd_DOA_Array(:,2));
numStbdPings = maxStbdPingNumber-minStbdPingNumber+1;

maxSampNum = max(maximumPortSampleNumber, maximumStbdSampleNumber);
numPings = max(numPortPings, numStbdPings);
minPingNum = min(minPortPingNumber, minStbdPingNumber);
maxPingNum = max(maxPortPingNumber, maxStbdPingNumber);
        %       port  stbd    ping# sample# TWTT  InitialPingNumber
numColumns =    1 +   1 +     1 +   1 +     1 +   1    ;

    % Preallocate output Array
output3DMatrix = nan(numPings, maxSampNum, numColumns);
output3DMatrix(:,:,6) = minPingNum;
output3DMatrix(:,:,4) = repmat(1:maxSampNum, numPings, 1);
output3DMatrix(:,:,3) = repmat((minPingNum:maxPingNum)', 1, maxSampNum);
TWTT_Mat = nan(numPings, maxSampNum, 2);    % one for port & stbd

%
pingNumbers = minPingNum:maxPingNum;

for i = 1:numPings
    thisPingNum = pingNumbers(i);
    [frows, fcols] = find(Port_DOA_Array(:,2)==thisPingNum);
    PortArrayThisPing = Port_DOA_Array(frows, :);
    numSampsThisPingPort = length(PortArrayThisPing);
    for j = 1:numSampsThisPingPort
        output3DMatrix(i,PortArrayThisPing(j,3),1) = PortArrayThisPing(j,6);
        TWTT_Mat(i, PortArrayThisPing(j,3), 1) = PortArrayThisPing(j, 5);
    end
    
    [frows, fcols] = find(Stbd_DOA_Array(:,2)==thisPingNum);
    StbdArrayThisPing = Stbd_DOA_Array(frows, :);
    numSampsThisPingStbd = length(StbdArrayThisPing);    
    for j = 1:numSampsThisPingStbd
        output3DMatrix(i,StbdArrayThisPing(j,3),2) = StbdArrayThisPing(j,6);
        TWTT_Mat(i, StbdArrayThisPing(j,3), 2) = StbdArrayThisPing(j, 5);
        if isnan(TWTT_Mat(i, StbdArrayThisPing(j,3),1)) && ~isnan(TWTT_Mat(i, StbdArrayThisPing(j,3),2))
            output3DMatrix(i, StbdArrayThisPing(j,3),5) = TWTT_Mat(i, StbdArrayThisPing(j,3), 2);
        else
            output3DMatrix(i, StbdArrayThisPing(j,3),5) = TWTT_Mat(i, StbdArrayThisPing(j,3), 1);
        end
        
    end
    %if TWTT_Mat(i,:,1) == TWTT_Mat(i,:,2)
        %output3DMatrix(i,:,5) = TWTT_Mat(i,:,1);
    %else
        %output3DMatrix(i,:,5) = TWTT_Mat(i,:,2);
    %end
    fprintf('Ping Index: %d \n', i);
    
end
%%
% if TWTT_Mat(:,:,1) == TWTT_Mat(:,:,2)
%     fprintf("TWTT's Synchronize between Port and Starboard \n\n");
%     output3DMatrix(:,:,5) = TWTT_Mat(:,:,1);
% end
%filledPort_DOA_Array = NaN(maximumPortSampleNumber*numPortPings, 6);
%filledStbd_DOA_Array = NaN(maximumStbdSampleNumber*numStbdPings, 6);


AI_Predicted_DOA_Array = output3DMatrix;

%% Save Outputs to .mat file to make life easier:
%msgbox('Job Done!');
[file,path] = uiputfile('MLDOAPredictions1.mat', 'Save file in the AIOutput_CSV_Files folder');
%save MLDOAPredictions.mat AI_Predicted_DOA_Array
outputFP = fullfile(path, file);
save(outputFP, 'AI_Predicted_DOA_Array');
