%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------%
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------% 

function [] = GenArgumentMat(ps_mechanicalvar,psname, ps_argument, subject_argument)
    % Define the input parameters for the mechanical simulation
    cartSets = ["PT_FCART", "PT_TCART_LAT", "PT_TCART_MED"];         % The set names of cartilage to be exported with field outputs
    outputVariable_root = ps_mechanicalvar{1};                       % The variable for field outputs
    outputVariable_subroot = ps_mechanicalvar{2};                    % The specific variable for field outputs

    % Define the input parameters for the inflammatory simulation
    input_PAL = 1;
    input_BMI_meas = subject_argument;
    input_intakeOfEnergy = 2500;
    tspan = 0:0.01:1;                    % 1 month NOTE: The time step shall not be too small to avoid out of memory

    % Define the arguments for algorithms
    Dthreshold = 0.1;                    % The threshold (MPa) for mechanical damage level
    r_localDamage = 2/3;                 % The parameter for calculating the mechanical damage level as the parameter in inflammation
    permeability_AC = 0.00000001;        % Permeability of the AC tissue
    E_AC = 10;                           % Young's modulus of the AC tissue
    omega_e = 0.99;                      % The constant to determine the minimum Young's modulus of the AC tissue during turnover: E_min = (1 - omega_e)*E_AC
    F_max = 50;                          % The maximum Fn-fs level from the tissue degradation
    omega_k = 3;                         % The constant to determine the maximum permeability of the AC tissue during turnover: permeability_AC_max = permeability_AC*(1+ omega_k)

    % Update the arguments in the pipeline files
    if strcmp(psname, 'Dthreshold')
        Dthreshold = ps_argument; % Update the damage threshold
    end
    if strcmp(psname, 'r_localDamage')
        r_localDamage = ps_argument; % Update the root parameter
    end
    if strcmp(psname, 'F_max')
        F_max = ps_argument; % Update the maximum Fn-fs level from the tissue degradation
    end


    % Save the arguments in a .mat file
    save('PipelineArguments.mat', 'cartSets', 'outputVariable_root', 'outputVariable_subroot', ...
        'input_PAL', 'input_BMI_meas', 'input_intakeOfEnergy', 'tspan', ...
        'Dthreshold', 'r_localDamage', 'permeability_AC', ...
        'E_AC', 'omega_e', 'F_max', 'omega_k');
end

