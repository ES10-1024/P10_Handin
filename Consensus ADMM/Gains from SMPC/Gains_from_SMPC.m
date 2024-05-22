%% Doing a bit of spring cleaning 
clear 
clf 
close all 
clc 
%% Adding a few paths and loading in scaled standard constants and data
addpath('../../')
c=scaled_standard_constants; 
load('benfits_gained_smpc.mat')


%% Picking out values, for the shares: 
    %Picking out the first ten which is a bit complicated due to xbar being
    %determinted in between: 
index=1; 
for i=1:20
    if mod(i,2)==1
        ownShare(index,1) = ADMM_2.Own_shares(1,i); 
        index=index+1; 
    end 
end 

%picking out the remaining, 90 samples: 
ownShare=[ownShare;ADMM_2.Own_shares(1,21:110)'];


%%
plot(ownShare,'*')