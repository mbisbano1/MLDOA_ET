% splits 2D Matrix into a 3D Matrix based on matching third column values..
% Adds column into matrix to hold "starting Ping # value
function output3DMatrix = splitArrayIntoMatrixOnThirdColumnValues(inputArray)
    %sp = shape(inputArray)
    %disp(['shape inputArray = ', num2str(sp)])
    numPings = max(inputArray(:,3))-min(inputArray(:,3)) + 1;
    numSamplesPerPing = max(inputArray(:,4))-min(inputArray(:,4))+1;
    % Determine Number of Columns in Output Array
            %       port  stbd    ping# sample# TWTT  InitialPingNumber
    numColumns =    1 +   1 +     1 +   1 +     1 +   1    ;

    % Preallocate output Array
    output3DMatrix = nan(numPings, numSamplesPerPing, numColumns);

    % Find first/last Ping # 
    firstPingNum = min(inputArray(:,3));
    lastPingNum = max(inputArray(:,3));

    for pingCtr = 1:numPings
        tempMat = inputArray(find(inputArray(:, 3)== firstPingNum + pingCtr - 1), :);
        addMat = firstPingNum.*ones(numSamplesPerPing,1);
        tempMat = cat(2, tempMat, addMat);
        output3DMatrix(pingCtr, :, :) = tempMat;


    end
end
    %save('output3DMatrix.mat', 'output3DMatrix')
    %view1 = squeeze(output3DMatrix(1,:,:));
    %view2 = squeeze(output3DMatrix(2,:,:));

    %% method to pull Array w/ ping number N out of 3DMatrix
    % This works, just uncomment.
    %N = 16;

    %firstPingNumIn3D = output3DMatrix(1,1,6);

    %ArrayN = squeeze(output3DMatrix(N-firstPingNumIn3D + 1, :, :));


