%% Doing a bit of spring cleaning 
clear 
clf 
clear 
clc 
%% Loading in the needed data
addpath("C:\Users\is123\Documents\GitHub\P10_Handin\Consensus ADMM\Saved workspaces V4")
load("stopping_criteria_boyd.mat");
%% 

% Initialize vector to store last non-zero values
lastNonZeroValuesDual = zeros(1, size(epsilonDual, 2)); % Assuming columns are fixed

% Loop through each column
for col = 1:size(epsilonDual, 2)
    % Find indices of non-zero elements in the column
    nonZeroIndices = find(epsilonDual(:, col) ~= 0);
    
    % If there are non-zero elements in the column
    if ~isempty(nonZeroIndices)
        % Pick out the last non-zero value
        lastNonZeroValuesDual(col) = epsilonDual(nonZeroIndices(end), col);
    end
end


epsilonDualMean=mean(lastNonZeroValuesDual);
epsilonDualStd=std(lastNonZeroValuesDual);


% Initialize vector to stre last non-zero values
lastNonZeroValuesPri = zeros(1, size(epsilonPri, 2)); % Assuming columns are fixed

% Loop through each column
for col = 1:size(epsilonPri, 2)
    % Find indices of non-zero elements in the column
    nonZeroIndices = find(epsilonPri(:, col) ~= 0);
    
    % If there are non-zero elements in the column
    if ~isempty(nonZeroIndices)
        % Pick out the last non-zero value
        lastNonZeroValuesPri(col) = epsilonPri(nonZeroIndices(end), col);
    end
end

epsilonPriMean=mean(lastNonZeroValuesPri);
epsilonPriStd=std(lastNonZeroValuesPri);
%% 
clc
disp("Epsilon Pri is:")
disp(epsilonPriMean)
disp("Where the standard deviation is: ") 
disp(epsilonPriStd)
disp("_________________________________________")
disp("Epsilon Dual is:")
disp(epsilonDualMean)
disp("Where the standard deviation is: ")
disp(epsilonDualStd)






