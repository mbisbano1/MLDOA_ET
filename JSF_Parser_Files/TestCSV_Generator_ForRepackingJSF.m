% Michael Bisbano 2/19/2022
% Generate 5 column 
clear all
close all
clc
PortStbd = input('Port or Starboard CSV (Port = 0, Stbd = 1):\n     =');
inputMode = input('Specify Input Mode (Default Values = 0, User Specified = 1):\n   =');

if inputMode == 1
    
    FirstPingNum = input('First Ping Number:\n  =');
    FinalPingNum = input('Final Ping Number:\n  =');
    FirstSampNum = input('First Sample Number:\n  =');
    FinalSampNum = input('Final Sample Number:\n  =');
    SampsPerPing = FinalSampNum-FirstSampNum+1;
    %SampsPerPing = input('Number Samples Per Ping:\n  =');
else    
    %PortStbd = 0;   %Port = 0, Stbd = 1;
    FirstPingNum = 87443;
    FinalPingNum = 88723;
    if PortStbd == 0
        FirstSampNum = 5;
    else 
        FirstSampNum = 24;
    end    
    FinalSampNum = 4301;
    SampsPerPing = FinalSampNum-FirstSampNum+1;
    fprintf("Using Default Values for '0001_1404.002*.jsf' files:\n    FirstPingNum = %d \n    FinalPingNum = %d \n    FirstSampNum = %d \n    FinalSampNum = %d \n    SampsPerPing = %d \n", FirstPingNum, FinalPingNum, FirstSampNum, FinalSampNum, SampsPerPing);
end

[file,path] = uiputfile('PredictionTest1.csv', 'Save file in the AIOutput_CSV_Files folder');
%save MLDOAPredictions.mat AI_Predicted_DOA_Array
outputFP = fullfile(path, file);


Pings = FirstPingNum:FinalPingNum;
Samps = FirstSampNum:FinalSampNum;

% Determine Number of Columns in Output Array
                % PingNum   SampleNum   PortStbd    sample time DOA(degrees)
TotalNumColumns = 1 +       1 +         1 +         1 +         1;

TotalNumRows = (FinalSampNum-FirstSampNum+1)*(length(Pings));% + FinalSampNum-FirstSampNum+1 + (FinalSampNum-FirstSampNum+1);
%5504457

CSV_Matrix = nan(TotalNumRows, TotalNumColumns);
CSV_Matrix(:, 1) = repelem(Pings,SampsPerPing);
%CSV_Matrix(:, 2) = SampleNumbersColumn;
CSV_Matrix(:, 3) = PortStbd;
CSV_Matrix(:, 4) = 0; %SampleTime;
%CSV_Matrix(:, 5) = DOAs;

DOA_Vals = nan(SampsPerPing, 1);
if PortStbd == 0    %port
    DOA_Vals = linspace(0, 90, SampsPerPing);
else                %stbd   
    DOA_Vals = linspace(90, 0, SampsPerPing); 
end


CSV_Matrix(1+SampsPerPing, 1);
for i = 1:length(Pings)
    ridx1 = (i-1)*SampsPerPing + 1;
    ridx2 = (i)*SampsPerPing;
    
    CSV_Matrix(ridx1:ridx2, 2) = Samps;
    CSV_Matrix(ridx1:ridx2, 5) = DOA_Vals;
    
end
%colLabels = nan(1,5);
%colLabels(1,1) = "PingNum";
%colLabels(1,2) = "SampNum";
%colLabels(1,3) = "PortStbd";
%colLabels(1,4) = "TWTT";
%colLabels(1,5) = "DOAPrediction";

%%
%CSV_Matrix = cat(1, colLabels, CSV_Matrix);
ColumnNames = {'PingNum', 'SampNum', 'PortStbd', 'TWTT', 'DOAPrediction'};
writecell(ColumnNames, outputFP)
writematrix(CSV_Matrix, outputFP, 'WriteMode', 'append');
msgbox('Done!');
%save(outputFP, 'AI_Predicted_DOA_Array');