% method to pull Array w/ ping number N out of a 3D Matrix

% Recommend using ischar(ArrayN) or size(ArrayN) to determine if output is an error flag
% before trying to use the data.

% Michael Bisbano    
function ArrayN = PullPingOutOf3DMatrix(Matrix3D, N)
    firstPingNumIn3D = Matrix3D(1,1,6);
    lastPingNumIn3D = Matrix3D(end,1,3);
    firstSampNum = Matrix3D(1, 1, 4);
    finalSampNum = Matrix3D(end,end, 4);
    %disp(lastPingNumIn3D);
    try
        ArrayN = squeeze(Matrix3D(N-firstPingNumIn3D + 1, :, :));
        if firstSampNum ~= 1
            % pad nan into the first samples that are missing!
            firstFewSamplesArray = nan(firstSampNum-1, 6);
            firstFewSamplesArray(:,3) = N;
            firstFewSamplesArray(:,4) = 1:(firstSampNum-1);
            firstFewSamplesArray(:,6) = firstPingNumIn3D;
            ArrayN = cat(1, firstFewSamplesArray, ArrayN);                                    
        end
    catch EX
        %disp(EX)
        tooLowMSG = 'Index in position 1 is invalid. Array indices must be positive integers or logical values.';
        tooHighMSG = 'Index in position 1 exceeds array bounds';
        if strcmp(EX.message, tooLowMSG)
            %ArrayN = 'PingTooLow';
            ArrayN = firstPingNumIn3D;
        elseif strcmp(EX.message(1:40), tooHighMSG)            
            %ArrayN = 'PingTooHigh';
            ArrayN = lastPingNumIn3D;
        else
            ArrayN = 'UnexpectedError';
        end        
    end    
end