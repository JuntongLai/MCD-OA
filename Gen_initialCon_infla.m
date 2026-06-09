%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------%
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------% 

function Gen_initialCon_infla()
% Set up the initial conditions for the inflammatory simulationat iteration 1

    info_path_mcodes = dir('Lib_mCodes');        % Save the information of Raw_mCodes
    path_mcodes = info_path_mcodes.folder;    % Save the path of Raw_mCodes
    if ~isfolder('Raw_initialconditions')
        mkdir('Raw_initialconditions');
    end
    info_path_initialconditions = dir('Raw_initialconditions');        % Save the information of Raw_initialcondistions
    path_initialconditions = info_path_initialconditions.folder;    % Save the path of Raw_initialcondistions
    load("PipelineArguments.mat") % Load the arguments for the simulation
    
    cd(path_mcodes)

    initial_input_PAL = input_PAL;
    initial_input_BMI_meas = input_BMI_meas;
    initial_input_intakeOfEnergy = input_intakeOfEnergy;
    initial_ars_damage = 0;
    initial_tspan = [0 100];
    initialconditions = [0 0 0 0 0];
    [initial_ars, initial_input] = Initiation(initial_input_PAL, initial_input_BMI_meas, initial_input_intakeOfEnergy, initial_ars_damage);
    [initial_t,initial_y] = ode15s(@(initial_t, initial_y) ODEsOfInflammation(initial_t, initial_y, initial_ars), initial_tspan, initialconditions);
    initialconditions = [initial_y(end,1) initial_y(end,2) initial_y(end,3) initial_y(end,4) initial_y(end,5)];
    writematrix(initialconditions, 'ic_sim_inflammation.txt');
    movefile('ic_sim_inflammation.txt',path_initialconditions);
end