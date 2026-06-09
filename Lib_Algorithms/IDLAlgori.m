%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

function IDLAlgori(i_list_f, list_MDL, path_MDL, path_IDL, path_i_sim_icfolder, path_MechanobioCoupling, i_sim, input_PAL, input_BMI_meas, input_intakeOfEnergy, tspan, n_cores,r_localDamage)

    % Format the text files of mechanical damage level (MDL)
    cd(path_MDL);                                                   % Change the working directory back to 2_MDL
    fmdl_name = list_MDL(i_list_f).name;                            % The file name of mechanical damage level of the current component
    elementData_MDL = readmatrix(fmdl_name);                        % Read element lables and mechanical damage level from the text file
    % Create the suffix for icon_name
    split_fmdl_name = strsplit(fmdl_name, 'MDL_');
    icon_name_suffix = split_fmdl_name{2};
    % Define C22 as the arguments of mechanical damage level for the ODE model
    ars_damage = CalculateArsDamage(elementData_MDL,r_localDamage);
    % Pre-allocate matrix space for running ODEs and concentration of mediators during inflammatory process
    elementData_concentration = zeros(size(elementData_MDL,1), 6);      % Define the dimension of the matrix for mediator concentration of all of elements
    elementData_concentration(:,1) = elementData_MDL(:,1);              % Save element lable to the first column of elementData_concentration
    t = zeros(length(tspan),size(elementData_MDL,1));                           % Pre-allocate matrix of time steps for ODEs simulation of each element
    y = zeros(length(tspan),5,size(elementData_MDL,1));                         % Pre-allocate matrix of mediator concentration at each time step for ODEs simulation of each element
    % Go to the working directory to running ODEs of inflammation
    cd(path_MechanobioCoupling);
    % Setup parallel computing once needed (Avoided starting or deleting the MATLAB parpool multiple times.)
    if isempty(gcp('nocreate'))
        parpool(n_cores);
    end

    if i_sim == 1
        initialconditions = readmatrix('ic_sim_inflammation.txt');
        parfor i_ele = 1:length(ars_damage)
            % Setup inflammation model (Input BMI, PAL, C22 (Update the inflammation model) when calculating
            % Simulation of inflammatory activities
            [t(:,i_ele), y(:,:,i_ele)] = ode15s(...
                @(t, y) ODEsOfInflammation(t, y, ...
                Initiation(input_PAL, input_BMI_meas, input_intakeOfEnergy, ars_damage(i_ele))), ...
                tspan, initialconditions);
        end
        y_shape = y(end, :, :);
        elementData_concentration_raw = reshape(permute(y_shape,[2 1 3]), 5, [])';
    else
        initialconditions = readmatrix(append(num2str(i_sim-1), '_ICon_', icon_name_suffix));
        initialconditions = initialconditions(:,2:end);
        % Setup inflammation model (Input BMI, PAL, C22 (Update the inflammation model) when calculating
        % Simulation of inflammatory activities
        parfor i_ele = 1:length(ars_damage)
            [t(:,i_ele), y(:,:,i_ele)] = ode15s(...
            @(t, y) ODEsOfInflammation(t, y, ...
            Initiation(input_PAL, input_BMI_meas, input_intakeOfEnergy, ars_damage(i_ele))), ...
            tspan, initialconditions(i_ele,:));
        end
        y_shape = y(end, :, :);
        elementData_concentration_raw = reshape(permute(y_shape,[2 1 3]), 5, [])';
    end

    elementData_concentration(:,2:end) = elementData_concentration_raw;
    icon_name = append(num2str(i_sim), '_ICon_', icon_name_suffix);    % Name the data file of initial concitions
    writematrix(elementData_concentration, icon_name);                 % Output data file as text file
    copyfile(icon_name, path_i_sim_icfolder)                           % Move data of initial conditions for the next iteration to Raw_initialcondistions
    movefile(icon_name, path_IDL)                                      % Move data file of inflammation damage level to 3_IDL
    cd(path_MDL);

end
