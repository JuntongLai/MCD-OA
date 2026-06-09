%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

function MDLAlogri(i_list_f, list_fieldoutput, path_MechanobioCoupling, path_i_sim_mdlfolder, path_MDL,i_sim, Dthreshold)

    % Format the text files of filed outputs
    fo_name = list_fieldoutput(i_list_f).name;            % The file names of field ouput reports
    elementData_FE = readmatrix(fo_name);                 % Read element lables and output variables from fieldoutput report
    mdl_name = append(num2str(i_sim),'_MDL_',fo_name);    % Name the data file

    % Calculate the mechanical damage level (MDL) based on stress/strain and past levels
    e_DL = (elementData_FE(:,2)-Dthreshold)./(Dthreshold);   % The calculation of current damage level due to stress
    e_DL(e_DL <= 0) = 0;    % Damage level is zero when the mechanical response is less than threhold

    if i_sim == 1
        elementData_MDL = [elementData_FE(:,1), e_DL];   % Save the damage level data for C22
    else
        % Define the path of texts for MDL from the last iteration
        mdl_name_last = append(num2str(i_sim-1),'_MDL_',fo_name);    % Name the data file
        fo_name_MDL_last = fullfile(path_MechanobioCoupling, mdl_name_last);
        % Read the MDL from the last iteration and caculate total MDL
        e_DL_last = readmatrix(fo_name_MDL_last);
        ToT_e_DL = e_DL_last(:,2) + e_DL;    % Calculate total (accumulative) damage level for C22 based on stress/strain and past levels
        elementData_MDL = [elementData_FE(:,1), ToT_e_DL];   % Save the damage level data for C22
    end

    % Write MDL into text files
    writematrix(elementData_MDL, mdl_name);     % Output data file as text file
    copyfile(mdl_name, path_i_sim_mdlfolder);   % Move data of accumulative MDL for the next iteration to Raw_MDL
    movefile(mdl_name, path_MDL);               % Move data file of mechanical damage level to 2_MDL

end
