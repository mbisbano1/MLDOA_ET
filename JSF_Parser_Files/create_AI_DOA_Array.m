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
%% Combine Port/Stbd Arrays into one array:

% Find num samples per ping.
numSamplesPerPingPort = max(Port_DOA_Array(:,2));
numSamplesPerPingStbd = max(Stbd_DOA_Array(:,2));
if numSamplesPerPingPort ~= numSamplesPerPingStbd
    msgbox('ERROR: Port & Stbd Files incompatible');
else
    numSamplesPerPing = numSamplesPerPingPort;
    clear numSamplesPerPingPort
    clear numSamplesPerPingStbd
end


% Find minimum Ping # and Sample # from both Port/Stbd arrays
PortMinPingNum = Port_DOA_Array(1,1);
StbdMinPingNum = Stbd_DOA_Array(1,1);

PortMinSampNum = Port_DOA_Array(1,2);
StbdMinSampNum = Stbd_DOA_Array(1,2);
firstSide = -1;
StartingPingNum = -1;
StartingSampNum = -1;
if PortMinPingNum ~= StbdMinPingNum
    StartingPingNum = min([PortMinPingNum, StbdMinPingNum]);
    if PortMinPingNum < StbdMinPingNum
        firstSide = 0; 
    else
        firstSide = 1;
    end
else
    StartingPingNum = PortMinPingNum;
end



if PortMinSampNum ~= StbdMinSampNum
    StartingSampNum = min([PortMinSampNum, StbdMinSampNum]);
    if firstSide == -1
        if PortMinSampNum < StbdMinSampNum
            firstSide = 0;
        else
            firstSide = 1;
        end
    end
else
    StartingSampNum = PortMinSampNum;
end
% Find maximum Ping # and Sample # from both Port/Stbd arrays

PortMaxPingNum = Port_DOA_Array(end,1);
StbdMaxPingNum = Stbd_DOA_Array(end,1);

PortMaxSampNum = Port_DOA_Array(end,2);
StbdMaxSampNum = Stbd_DOA_Array(end,2);

EndingPingNum = max([PortMaxPingNum, StbdMaxPingNum]); 
EndingSampNum = max([PortMaxSampNum, StbdMaxSampNum]);

% Determine Number of Rows in Output Array
TotalNumRows = -1;
if EndingSampNum ~= numSamplesPerPing   
    msgbox('ERROR: Last Ping has incomplete data!');
    TotalNumRows = (EndingPingNum-StartingPingNum)*numSamplesPerPing + EndingSampNum;
else
    TotalNumRows = (EndingPingNum-StartingPingNum+1)*numSamplesPerPing;
end
if StartingSampNum ~= 1
    msgbox('ERROR: First Ping has incomplete data!');
    TotalNumRows = TotalNumRows - StartingSampNum + 1;
end


% Determine Number of Columns in Output Array
                % port  stbd    ping# sample# TWTT
TotalNumColumns = 1 +   1 +     1 +   1 +     1;

% Pre-allocate The Combined Array
CombinedArray = NaN(TotalNumRows, TotalNumColumns);

%% Populate all fields of Combined Array:

%CombinedArray(1:TotalNumRows, 1) = StartingPingNum:EndingPingNum;

currentPingNum = StartingPingNum;
currentSampNum = StartingSampNum;

validPortData = 0;
validStbdData = 0;
portCtr = 1;
stbdCtr = 1;
portDone = 0;
stbdDone = 0;

for r = 1:TotalNumRows
    % fill in easy info
    CombinedArray(r, 3) = currentPingNum;
    CombinedArray(r, 4) = currentSampNum;
    
    % Determine when to start writing real data
    if  validPortData == 0  % Port Valid Data Test
        if PortMinPingNum <= currentPingNum && StbdMinSampNum <= currentSampNum && PortMaxSampNum >= currentSampNum && ~portDone
            validPortData = 1;
        end        
    end
    if  validStbdData == 0  % Stbd Valid Data Test
        if StbdMinPingNum <= currentPingNum && StbdMinSampNum <= currentSampNum && StbdMaxSampNum >= currentSampNum && ~stbdDone
            validStbdData = 1;
        end
    end
    
    % Write DOA Data, collect TWTT data
    portTWTT = NaN;
    if validPortData
        CombinedArray(r,1) = Port_DOA_Array(portCtr, 5);
        portTWTT = Stbd_DOA_Array(portCtr, 4);
        portCtr = portCtr+1;
        if portCtr > length(Port_DOA_Array)
            validPortData = 0;
            portDone = 1;
        end
    end
    stbdTWTT = NaN;
    if validStbdData
        CombinedArray(r,2) = Stbd_DOA_Array(stbdCtr, 5);
        stbdTWTT = Stbd_DOA_Array(stbdCtr, 4);
        stbdCtr = stbdCtr+1;
        if stbdCtr > length(Stbd_DOA_Array)
            validStbdData = 0;
            stbdDone = 1;
        end
    end
    
    % Check TWTT Data matches:
    TWTT_Data = -1;
    if ~isnan(stbdTWTT) && ~isnan(portTWTT)     % neither nan
        if stbdTWTT == portTWTT     % the case we want
            TWTT_Data = stbdTWTT;               
        else                        % the case we DON'T want
            disp(['WARNING: Row ', num2str(r), ' Has Different TWTT data for P/S'])
            TWTT_Data = nan;
        end      
    elseif isnan(stbdTWTT) || isnan(portTWTT)   % one nan
        if isnan(stbdTWTT)
            TWTT_Data = portTWTT;
        else
            TWTT_Data = stbdTWTT;
        end
    else                                        % both nan
        TWTT_Data = nan;    % do nothing
    end
    
    % Write TWTT Data to array:
    CombinedArray(r, 5) = TWTT_Data;
    
    % increment the things
    if numSamplesPerPing == currentSampNum
        currentSampNum = 1;
        currentPingNum = currentPingNum+1;
    else
        currentSampNum = currentSampNum + 1;
    end 
end


%% Call Split Function to make 3DMatrix Variable:
AI_Predicted_DOA_Array = splitArrayIntoMatrixOnThirdColumnValues(CombinedArray);

%% Save Outputs to .mat file to make life easier:
%msgbox('Job Done!');
[file,path] = uiputfile('MLDOAPredictions1.mat', 'Save file in the AIOutput_CSV_Files folder');
%save MLDOAPredictions.mat AI_Predicted_DOA_Array
outputFP = fullfile(path, file);
save(outputFP, 'AI_Predicted_DOA_Array');
