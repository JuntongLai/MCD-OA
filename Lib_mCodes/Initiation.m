%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

% This is the function for initiating the parameters for the inflammatory simulations based on model parameterisation in the paper:
% J. Lai and D. Lacroix, "A computational study of adiposity-associated factors in the inflammatory process of osteoarthritis", Journal of Theoretical Biology, vol. 625, p. 112429, May 2026, doi: 10.1016/j.jtbi.2026.112429.
function [ars, input] = Initiation(input_PAL, input_BMI_meas, input_intakeOfEnergy, ars_damage)

% Input of Physical acitivity/BMI Measured/IntakeNutrition
input.PAL = input_PAL;
input.BMI_meas = input_BMI_meas;
input.intakeOfEnergy = input_intakeOfEnergy;

% Function of BMI
BMI_standard = 25;
fBMI = input.BMI_meas/BMI_standard;
% Function of nutrition
baselineOfBMR = 2500*input.PAL;       % Need to think about its setting
paranutrition = input.intakeOfEnergy/baselineOfBMR;
    
%% Setup the main parameters and transfer the parameter values of BMI and nutrition to the parameter structure
% Parameters in the production of pro-inflammatory cytokine
ars.C_0 = 0.05;    % Natural pro-inflammatory production rate
ars.C_1 = 50;      % Pro-inflammatory cytokine production rate driven by pro-inflammatory cytokine
ars.C_2 = 5;       % Pro-inflammatory cytokine concentration whose capability of driving pro-inflammatory cytokine is half of maximum
ars.C_3 = 50;      % Pro-inflammatory cytokine production rate driven by adipokine
ars.C_4 = 5;       % Adipokine concentration whose capability of driving pro-inflammatory cytokine is half of maximum
ars.C_5 = 50;      % Pro-inflammatory cytokine production rate driven by Fibronectin-fragments
ars.C_6 = 5;       % Fn-fs concentration whose capability of driving pro-inflammatory cytokine is half of maximum
ars.C_7 = 5;       % Anti-inflammatory cytokine concentration whose capability of inhibiting pro-inflammatory cytokine is half of maximum
ars.D_1 = 5.2;     % Clearance rate of pro-inflammatory cytokine (Representative value is taken from IL-6 of which half-life is 4 days, 
                % D_1=ln2/(4/30) = 5.2 month-1)

% Parameters in the production of anti-inflammatory cytokine
ars.C_8 = 15000;   % Anti-inflammatory cytokine production rate driven by pro-inflammatory cytokine
ars.C_9 = 1500;    % Pro-inflammatory cytokine concentration whose capability of driving anti-inflammatory cytokine is half of maximum
ars.C_10 = 15000;  % Anti-inflammatory cytokine production rate driven by Fibronectin-fragments
ars.C_11 = 1500;   % Fibronectin-fragments concentration whose capability of driving anti-inflammatory cytokine is half of maximum
ars.D_2 = 1500;    % Clearance rate of anti-inflammatory cytokine (Take the half-life of IL-4, which is 20 mins
                % (D_2=ln2/(20/60/24/30 = 1500 month-1), we should estimate it as 1500 but may take an average to 1000?)

% Parameters in the production of MMPs
ars.C_12 = 0.05;   % Natural MMPs production rate
ars.C_13 = 50;     % MMPs production rate driven by pro-inflammatory cytokine
ars.C_14 = 5;      % Pro-inflammatory cytokine concentration whose capability of driving MMPs is half of maximum
ars.C_15 = 50;     % MMPs production rate driven by adipokines
ars.C_16 = 5;      % Adipokine concentration whose capability of driving MMPs is half of maximum
ars.C_17 = 5;      % Anti-inflammatory cytokine concentration whose capability of inhibiting MMPs is half of maximum
ars.D_3 = 4.2;     % Clearance rate of MMPs (D_3=ln2/(120/24/30 = 4.2 month-1)Take the half-life of MMP to be 120 hours as an average)

% Parameters in the production of adipokine
ars.C_18 = 500;    % Natural adipokine production rate
ars.C_19 = 500;    % Production rate of adipokine driven by BMI
ars.D_4 = 1200;    % Clearance rate of adipokine (Take the half-life of leptin (25 mins), D_4=ln2/(25/60/24/30) = 1200 month-1)
                % The half-life of adiponectin is 30-90 mins, so we may take an average of 1 h for it, D_4=ln2/(1/24/30) = 500 month-1
ars.paranutrition = paranutrition; % Nutrition term
ars.fBMI = fBMI;   % BMI level

% Parameters in the production of Fibronectin-fragments
ars.C_21 = 3;      % Activated production rate of Fn-fs by MMPs
ars.C_22 = ars_damage;      % Damage level
ars.D_5 = 3;       % Clearance rate of Fibronectin-fragments (Half-life is 7 days, D_5=ln2/(7/30) = 3 month-1)

% Hill coefficient
ars.n = 2; 

% Exercise coefficient  
if input.BMI_meas < 18.5
    ars.nex = 10 - input.BMI_meas*(2/18.5);
elseif input.BMI_meas >= 18.5 && input.BMI_meas <= 24.9
    ars.nex = 8 - (input.BMI_meas-18.5)*(4/(24.9-18.5));
elseif input.BMI_meas > 24.9 && input.BMI_meas <= 29.9
    ars.nex = 4 - (input.BMI_meas-24.9)*(2/(29.9-24.9));
elseif input.BMI_meas > 29.9 && input.BMI_meas < 40
    ars.nex = 2 - (input.BMI_meas-29.9)*(1/(40-29.9));
elseif input.BMI_meas >= 40
    ars.nex = 40/input.BMI_meas;
end

scalingPAL = 50;

% Adipokine concentration whose capability of driving adipokine is half of maximum, which depends on exercise level
if input.PAL >= 1 && input.PAL <= 1.39
    ars.C_20 = (1 - (input.PAL-1)*(0.5/(1.39-1))).*scalingPAL;
elseif input.PAL > 1.39 && input.PAL <= 1.59
    ars.C_20 = (0.5 - (input.PAL-1.39)*(0.25/(1.59-1.39))).*scalingPAL;
elseif input.PAL > 1.59 && input.PAL <= 1.89
    ars.C_20 = (0.25 - (input.PAL-1.59)*(0.15/(1.89-1.59))).*scalingPAL;
elseif input.PAL > 1.89
    ars.C_20 = (0.1 - (input.PAL-1.89)*(0.1/(2.5-1.89)))*scalingPAL;
end


end

