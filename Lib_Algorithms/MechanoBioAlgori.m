%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------

function MechanoBioAlgori(i_list_f, list_IDL,path_MDL,path_IDL,i_sim, path_i_sim_mpfolder, fnfs_baseline, omega_e, F_max, omega_k,permeability_AC, E_AC)

% Read the data of inflammatory damage (based on mechanical damage parameter) of each element
cd(path_IDL); % Back to 3_IDL
fidl_name = list_IDL(i_list_f).name; % The file names of inflammatory damage (based on mechanical damage parameter) of each element
elementData_IDL = readmatrix(fidl_name);

% Create the suffix for mp_name
split_fidl_name = strsplit(fidl_name, 'ICon_');
mp_name_suffix = split_fidl_name{2};

% Compatible the file name of inflammatory damage with the file name of mechanical damage
% ------------------Notes------------------
%       ·This function can ensure the inflammed element will not be degraded if the mechanical damage is zero
fmdl_name = append(num2str(i_sim),"_MDL_",mp_name_suffix);
cd(path_MDL);
elementData_MDL = readmatrix(fmdl_name); % Read element lables and mechanical damage level from the text file
cd(path_IDL); % Back to 3_IDL

% Calculate the material property of each element for the tissue turnover
% ------------------Notes------------------
%       ·omega_E is the constant to determine E_min that is the boundary of the lowest elastic modulus of the tissue during turnover, 
%           behyond the assumption, the tissue is removed. E_min = (1 - omega_e)*E_AC
%       ·F_max is the boundary of the highest Fn-fs level from the tissue degradation, 
%           the underlying assumption is that the amount of Fn-fs is constant from the degradation of ECM elements.
%       ·Here we use the same degradation approach for both E and permeability so omega_k is the constant to determine permeability_AC_max that 
%           is the highest value for permeability. permeability_AC_max = permeability_AC*(1+ omega_k)
elementMP = [elementData_IDL(:,1), elementData_IDL(:,1), elementData_IDL(:,6)];    % [elementID, Updated E, Updated permeability]
% When the Fn-fs level is higher than the maximum level, the young's modulus is set to the minimum value and permeability is set to the maximum value
idxFulldegen = elementData_IDL(:,6) > F_max;
idxNotFulldegen = ~idxFulldegen;
idxMechanicalDamaged = elementData_MDL(:,2) ~= 0;           % The index for elements with mechanical damage
idxBeingDegen = idxMechanicalDamaged & idxNotFulldegen;     % The index for elements that are being degenerated
idxhealth = ~idxMechanicalDamaged;                          % The index for elements that are not being degenerated

% The elements that are fully degenerated
elementMP(idxFulldegen,2) = E_AC.*(1-omega_e);              % E_min = (1 - omega_e)*E_AC
elementMP(idxFulldegen,3) = permeability_AC.*(1+omega_k);   % permeability_AC_max = permeability_AC*(1+ omega_k)
% The elements that are being degenerated
delta_F = (F_max-elementData_IDL(idxBeingDegen,6))./(F_max);            % The percentage of Fn-fs level change due to degeneration
elementMP(idxBeingDegen,2) = E_AC.*(1-omega_e.*(1-delta_F));                        % Updated E
elementMP(idxBeingDegen,3) = permeability_AC.*(1+omega_k.*(1-delta_F));             % Updated permeability
% The elements that are not degenerated
elementMP(idxhealth,2) = E_AC;              % E_min = (1 - omega_e)*E_AC
elementMP(idxhealth,3) = permeability_AC;   % permeability_AC_max = permeability_AC*(1+ omega_k)

% 5.3.5 Write the material property into text files
mp_name = append(num2str(i_sim), '_MP_', mp_name_suffix);    % Name the data file of material property
writematrix(elementMP, mp_name);   % Output data file as text file
movefile(mp_name, path_i_sim_mpfolder) % Move data of material property for the next iteration to Raw_MP

end
