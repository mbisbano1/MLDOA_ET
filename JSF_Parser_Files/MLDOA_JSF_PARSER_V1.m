clear all
close all
clc
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
CSVfile = strcat(CSVfiles{1,1}, '.xlsx')
CSVfilename = fullfile(CSVfpath, CSVfile);







%% Message List Declaration
    % Stave Data:   Message 80
    % Roll Data:    Message 2020 or 3001
    % Sound Speed:  Message 2060
    % Bathy Data:   Message 3000
    % 
%messageList = [1, 
    


%                                       readJSFv3_small(JSFfp,  messageList)                                    
%function [messageHeader,data,header] = readJSFv3_small(fileid,reqDataType,concatChannels)





%% Write Output CSV File
%A = ones(4);
%writematrix(A, CSVfilename);