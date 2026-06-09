function exit_code = MasterRun(n_cores)
%------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------%
%                                                             Ver 1.0.0
%                                                   Copyright (c) 2026 Juntong Lai
%                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
%-------------------------------------------------------------------------------------------------------------------------------%                                          

% clc
% clear

%------------------Folder preparation for raw data from simulations------------------%

mkdir Raw_materialproperty;
mkdir Raw_MDL;
mkdir Raw_ODBfile;
mkdir Raw_fieldoutputs;
addpath('Lib_Algorithms');

%------------------Define root path and paths of folders at root through the entire pipeline------------------%

path_main = pwd;                                                % Save the initial working path

info_path_pycodes = dir('Lib_pyCodes');                         % Save the information of Lib_pyCodes
info_path_mcodes = dir('Lib_mCodes');                           % Save the information of Lib_mCodes
info_path_initialconditions = dir('Raw_initialconditions');     % Save the information of Raw_initialcondistions
info_path_rawMDL = dir('Raw_MDL');                              % Save the information of Raw_MDL
info_path_materialproperty = dir('Raw_materialproperty');       % Save the information of Raw_initialcondistions
info_path_inpfile = dir('Raw_inpfile');                         % Save the information of Raw_inpfile
info_path_ODBfile = dir('Raw_ODBfile');                         % Save the information of Raw_ODBfile
info_path_fieldoutputfile = dir('Raw_fieldoutputs');            % Save the information of Raw_fieldoutputs

path_pycodes = info_path_pycodes.folder;                        % Save the path of Lib_pyCodes
path_mcodes = info_path_mcodes.folder;                          % Save the path of Lib_mCodes
path_initialconditions = info_path_initialconditions.folder;    % Save the path of Raw_initialcondistions
path_rawMDL = info_path_rawMDL.folder;                          % Save the path of Raw_MDL
path_materialproperty = info_path_materialproperty.folder;      % Save the path of Raw_initialcondistions
path_inpfile = info_path_inpfile.folder;                        % Save the path of Raw_inpfile
path_ODBfile = info_path_ODBfile.folder;                        % Save the path of Raw_ODBfile
path_fieldoutputfile = info_path_fieldoutputfile.folder;        % Save the path of Raw_fieldoutputs

%------------------Simulation running------------------%
for i_sim = 1:1:60          % 12months*5
T_sim = tic;
fprintf(['------------------------------------------------', 'Start iteration ',num2str(i_sim), '------------------------------------------------\n']);
fprintf('Preprossing...\n\nInput arguments:\n');

%% (1) Pre-process
% 1.1 Create a folder for the current iteration (i_sim is the number of current iteration)
i_sim_folder = append(num2str(i_sim), '_iteration');
mkdir(i_sim_folder);
cd(i_sim_folder);

% 1.2 Prepare subfolders in iteration i_sim
% 1.2.1 Create subfolders
mkdir 1_FEsim;
mkdir '2_MechanobioCoupling';
% 1.2.2 Save subfolder information
info_path_FEsim = dir('1_FEsim');
info_path_MechanobioCoupling = dir('2_MechanobioCoupling');
% 1.2.3 Save the paths of subfolders
path_FEsim = info_path_FEsim.folder;
path_MechanobioCoupling = info_path_MechanobioCoupling.folder;

% 1.3 Prepare working functions (python codes) from Lib_pyCodes to specified subfolders
cd(path_pycodes);
copyfile('UpdateINP.py', path_FEsim);               % The script for updating FE model (material property) 
copyfile('abaqusReadODB.py', path_MechanobioCoupling);      % The script for postprocessing odb data

% 1.4 Prepare working functions (matlab codes) from Lib_mCodes to specified folders
cd(path_mcodes);
copyfile('Initiation.m', path_MechanobioCoupling);
copyfile('ODEsOfInflammation.m', path_MechanobioCoupling);

% 1.5 Copy the initial inp file to FEsim/ at the first iteration
if i_sim == 1   
% When i_sim is 1 then it can be directly used in path_FEsim;
% If it is not 1 then inp will be refered to the path without number (Because there was ERROR in abaqus when using number for dir) 
% and will be updated with material properties (written into .inp file at working directory FEsim/) before running simulations
    cd(path_inpfile);
    copyfile('iter_1.inp', path_FEsim);
end 

% 1.6 Prepare iterative data folders
%       -Initial conditions: ic_{i_sim}/
%       -Accumulative mechanical damage level: mdl_{i_sim}/
%       -Material properties: mp_{i_sim}/
i_sim_icfolder = append('ic_', num2str(i_sim));          % The name of folder containing mediator concentrations by the end of this iteration
i_sim_mpfolder = append('mp_', num2str(i_sim));          % The name of folder containing changed material properties by the end of this iteration that will be used for the model in next iteration
i_sim_mdlfolder = append('mdl_', num2str(i_sim));        % The name of folder containing accumulated mechanical damage level by the end of this iteration

% 1.7 Prepare input data from the last iteration
% 1.7.1 Preparation for FE simulations
cd(path_materialproperty);
mkdir(i_sim_mpfolder);         % Create a folder for the material properties updated as inputs of the next iteration from the current iteration
if i_sim ~= 1
    input_sim_mpfolder = append('mp_', num2str(i_sim-1));    % The name of folder containing material properties that should be updated at this iteration
    copyfile(input_sim_mpfolder, path_FEsim);                % Copy the text of material properties to 1_FEsim
end
% 1.7.2 Preparation for MechanobioCoupling-calculation of mechanical damage level
cd(path_rawMDL);
mkdir(i_sim_mdlfolder);        % Create a folder for the initialconditions as input of the next iteration
if i_sim ~= 1
    last_sim_mdlfolder = append('mdl_', num2str(i_sim-1));      % The name of folder containing mechanical damage accumulated from the last iteration
    copyfile(last_sim_mdlfolder, path_MechanobioCoupling);      % Copy the text of MDL to 2_MechanobioCoupling
end
% 1.7.3 Preparation for MechanobioCoupling-inflammatory simulations
cd(path_initialconditions);
mkdir(i_sim_icfolder);              % Create a folder for the initialconditions as inputs of the next iteration from the current iteration
ic_baseline = readmatrix('ic_sim_inflammation.txt');    % Read the baseline of initial conditions
fnfs_baseline = ic_baseline(1, 5);  % The baseline of Fn-fs
if i_sim == 1
    copyfile('ic_sim_inflammation.txt', path_MechanobioCoupling);   % Copy the 1st text of initialconditions to 2_MechanobioCoupling
else
    input_sim_icfolder = append('ic_', num2str(i_sim-1));           % The name of folder containing concentations from the last iteration as the initial conditions at this iteration
    copyfile(input_sim_icfolder, path_MechanobioCoupling);          % Copy the texts of initialconditions to 2_MechanobioCoupling
end

% 1.8 Save path information of material property (FE model) for each iteration/accumulative mehcanical damage level (Output from FE model and Input to ODE model)/initial conditions (ODE model)
cd(path_materialproperty);
info_path_i_sim_mpfolder = dir(i_sim_mpfolder);             % Save the information of i_sim_mpfolder
path_i_sim_mpfolder = info_path_i_sim_mpfolder.folder;      % Save the path of i_sim_mpfolder
cd(path_rawMDL);
info_path_i_sim_mdlfolder = dir(i_sim_mdlfolder);           % Save the information of i_sim_mdlfolder
path_i_sim_mdlfolder = info_path_i_sim_mdlfolder.folder;    % Save the path of i_sim_mdlfolder
cd(path_initialconditions);
info_path_i_sim_icfolder = dir(i_sim_icfolder);             % Save the information of i_sim_icfolder
path_i_sim_icfolder = info_path_i_sim_icfolder.folder;      % Save the path of i_sim_icfolder 

% 1.9 Define the input parameters for the mechanical simulation
cd(path_main);
PipelineArs = load("PipelineArguments.mat"); % Load the arguments for the simulation
cartSets = PipelineArs.cartSets;
outputVariable_root = PipelineArs.outputVariable_root;
outputVariable_subroot = PipelineArs.outputVariable_subroot;
input_PAL = PipelineArs.input_PAL;
input_BMI_meas = PipelineArs.input_BMI_meas;
input_intakeOfEnergy = PipelineArs.input_intakeOfEnergy;
tspan = PipelineArs.tspan;
Dthreshold = PipelineArs.Dthreshold;
r_localDamage = PipelineArs.r_localDamage;
permeability_AC = PipelineArs.permeability_AC;
E_AC = PipelineArs.E_AC;
omega_e = PipelineArs.omega_e;
F_max = PipelineArs.F_max;
omega_k = PipelineArs.omega_k;
% The set names of cartilage to be exported with field outputs
fprintf('cartSets = ');
for i = 1:length(cartSets)
    fprintf('%s ', cartSets(i));
end
fprintf('\n');
% The variable for field outputs
fprintf('outputVariable_root = %s\n',outputVariable_root);
% The specific variable for field outputs
fprintf('outputVariable_subroot = %s\n', outputVariable_subroot);

% 1.10 Define the input parameters for the inflammatory simulation
fprintf('input_PAL = %s\n', num2str(input_PAL));
fprintf('input_BMI = %s\n', num2str(input_BMI_meas));
fprintf('input_intakeOfenergy = %s\n', num2str(input_intakeOfEnergy));
fprintf('tspan = %s:%s:%s\n', num2str(tspan(1)), num2str(tspan(2)-tspan(1)), num2str(tspan(end)));      % NOTE: The time step shall not be too small to avoid out of memory
fprintf('n_cores = %s\n', num2str(n_cores));  % The number of cores for parallel computing of inflammation model

% 1.11 Define the arguments for algorithms
fprintf('Dthreshold = %s\n', num2str(Dthreshold));             % The threshold (MPa) for mechanical damage level
fprintf('r_localDamage = %s\n', num2str(r_localDamage));       % The parameter for calculating the mechanical damage level as the parameter in inflammation
fprintf('permeability_AC = %s\n', num2str(permeability_AC));   % Permeability of the AC tissue
fprintf('E_AC = %s\n', num2str(E_AC));                         % Young's modulus of the AC tissue
fprintf('omega_e = %s\n', num2str(omega_e));                   % The constant to determine the minimum Young's modulus of the AC tissue during turnover: E_min = (1 - omega_e)*E_AC
fprintf('F_max = %s\n', num2str(F_max));                       % The maximum Fn-fs level from the tissue degradation
fprintf('omega_k = %s\n', num2str(omega_k));                   % The constant to determine the maximum permeability of the AC tissue during turnover: permeability_AC_max = permeability_AC*(1+ omega_k)

fprintf('\nPreprossing is completed.\n\n');

%% (2) Launch FE simulation
cd(path_FEsim);
% 2.1 Prepare input file for the FE simulation in the current iteration
if i_sim ~= 1
    % 2.1.1 Define the raw .inp file path and .inp file name
    inppath = fullfile(path_inpfile, 'iter_1.inp');         % Define the inppath
    inpname = append('iter_', num2str(i_sim));              % Define the inpname
    copyfile(inppath, fullfile(path_FEsim,append(inpname, '.inp')));  % Rename the inp file to iter_i_sim.inp and copy it to path_FEsim
    % 2.1.2 Call .py to update the inp model
    tic
    fprintf('\n------------------------------------------------\nStart to update FE model...\n');
    system('abaqus python UpdateINP.py');
    fprintf(['FE model update is completed.\n\n','1.Time for FE model update: ', num2str(toc/60), ' mins\n\n']);
else
    % When the iteration is 1, there is no need update of the FE model so the python script (UpdateINP.py) will not be used.
    % Therefore, there is no need to define the inppath and copy file to path_FEsim.
    inpname = 'iter_1';  % Define the inpname
end

% 2.2 Submit the FE simulation (.inp file) to Abaqus
% tic
fprintf('------------------------------------------------\nStart to run FE simulation...\n');

%------------------Submission of FE simulation via abaqus cae noGUI------------------%
cd(path_FEsim);
tic
% Submit an FE job to Abaqus via calling solver directly
FEruncommand = sprintf('abaqus job=%s input=%s cpus=%d', inpname, append(inpname,'.inp'), n_cores);
system(FEruncommand);
fprintf('FE simulation has been submitted.\nFE simulation is running...\n');

% Wait for the log file to be generated
logID = append(inpname, '.log');
while (exist(logID, 'file') == 0)
end
% Wait till simulation is completed (Need to deactivate the commond "mdb.jobs[jobname].waitForCompletion()")
SimCompletion = 0;
SimCompletion = waitForFEsimCompletion(SimCompletion, logID);
%------------------End of FE simulation via abaqus cae noGUI------------------%

fprintf(['FE simulation is completed.\n\n','2.Time for FE simulation: ', num2str(toc/60), ' mins\n\n']);

% 2.4 After FE simulation completed
% 2.4.1 Check if the simulation is convergent
[isConvergent] = checkConvergence(inpname);
if isConvergent == 0
    fprintf(['------------------------------------------------\nThe simulation is not completed at iteration ', num2str(i_sim),'. Please check the .sta file for more information.\n']);
    break;
end

% 2.4.2 Copy the current .odb file to the raw data folder (Raw_ODBfile/)
odbname = append(inpname, '.odb');
movefile(odbname, path_ODBfile);

%------------------Folder preparation for output data------------------%
cd(path_MechanobioCoupling);
mkdir 1_Fieldoutputs;             % The field outputs from the current iteration
mkdir 2_MDL;                      % The damage level (for articular cartilage (AC)) due to mechanics, calculated by field outputs of FE model
mkdir 3_IDL;                      % The damage level (for articular cartilage (AC)) due to inflammation, calculated by ODEs of inflammation
info_path_MDL = dir('2_MDL');     % Save the information of MDL
path_MDL = info_path_MDL.folder;  % Save the path of folder 2_MDL/
info_path_IDL = dir('3_IDL');     % Save the information of IDL
path_IDL = info_path_IDL.folder;  % Save the path of folder 3_IDL/

%% (3) Data-processing of odb files and extracting element data
% 3.1 User-defined arguments for data-postprocessing
%------------------cartSets: The set names of cartilage to be exported with field outputs---------
%------------------outputVariable_root: The variable for field outputs----------------------------
%------------------outputVariable_subroot: The specific variable for field outputs----------------
odbpath = fullfile(path_ODBfile, odbname);      % The path to read .odb files

% 3.2 Input arguments to abaqusReadODB.py
editAbaqusReadODB(odbpath, cartSets, outputVariable_root, outputVariable_subroot);

% 3.3 Extract field outputs from .odb results
tic
fprintf('------------------------------------------------\nStart to extract field outputs from ODB...\nData extraction is running...\n');

system('abaqus python abaqusReadODB.py');

fprintf(['Data extraction is completed.\n\n','3.Time for data extraction from ODB: ', num2str(toc/60), ' mins\n\n']);

%% (4) Data-processing of calculation of mechanical damage level
tic
% 4.1 Change the working directory
cd 1_Fieldoutputs;                 % Go to the directory of saving data of field output
path_fieldoutput = pwd;             % Save the path of fieldoutputs
list_fieldoutput = dir('*.txt');    % Get all of text files in the directory saving reports of field output

% 4.2 Loop the text files and edit them by only saving element lables and variable values
for i_list_f = 1:1:length(list_fieldoutput)
    % 4.2.1 copy the field output text files to the folder of Raw_fieldoutputs
    iterfoname = append(num2str(i_sim),"_",list_fieldoutput(i_list_f).name);
    copyfile(list_fieldoutput(i_list_f).name, iterfoname);
    movefile(iterfoname,path_fieldoutputfile);
    % 4.2.2 Algothrithm for calculating the mechanical damage of each AC element
    % -----------------Brief Description of the algothrithm-----------------
    % Calculate mechanical damage level according to the report of filed output from abaqus to a text file 
    % with only element lables and defined variable values
    MDLAlogri(i_list_f, list_fieldoutput, path_MechanobioCoupling, path_i_sim_mdlfolder, path_MDL,i_sim, Dthreshold);
end

fprintf(['------------------------------------------------\nMechanical damage level is being calculated...\nCalculation is completed.\n\n3.Time for the calculation of damage level: ', num2str(toc/60), ' mins\n\n']);

%% (5) Coupling algothrithm (MECHANO-BIOLOGICAL REGULATION ALGORITHM) 
% (Try to describ it: machanical damage level -> inflammation model -> output of Fn-fs -> material changes)
fprintf('------------------------------------------------\nStart to simulate inflammatory process...\n');
tic
% User-defined arguments for inflammatory simulations
% ------------------input_PAL: Physical activity level (PAL)---------------------
% ------------------input_BMI_meas: Body mass index (BMI) measured---------------
% ------------------input_intakeOfEnergy: Intake of energy-----------------------
% ------------------tspan: Time span for the simulation--------------------------
% ------------------n_cores: The number of cores for parallel computing----------

% 5.1 Get information of mechanical damage level for each component of CART in path_MDL
cd(path_MDL);               % Change the working directory to 2_MDL
list_MDL = dir('*.txt');    % Get all of text files in the directory

% 5.2 Loop the components of CART to calculate the concentration of mediators for each element
for i_list_f = 1:1:length(list_MDL)
% 5.3 Algothrithm for calculating the concentration of inflammatory mediators (inflammatory damage) of each AC element
    % -----------------Brief Description of the algothrithm-----------------
    %                              To be filled in
    IDLAlgori(i_list_f, list_MDL, path_MDL, path_IDL, path_i_sim_icfolder, path_MechanobioCoupling, i_sim, input_PAL, input_BMI_meas, input_intakeOfEnergy, tspan, n_cores,r_localDamage);
end

fprintf(['\nInflammatory process has been simulated.\n\n','4.Time for simulation of inflammatory process: ', num2str(toc/60), ' mins\n\n']);

% Output of Fn-fs and calculate stiffness
% User-defined arguments for inflammatory simulations
cd(path_IDL); % Back to 3_IDL
list_IDL = dir('*.txt'); % Get all of text files in the directory

for i_list_f = 1:1:length(list_IDL)
    MechanoBioAlgori(i_list_f, list_IDL,path_MDL,path_IDL,i_sim, path_i_sim_mpfolder, fnfs_baseline, omega_e, F_max, omega_k,permeability_AC, E_AC);
end

%%------------------Simulation end------------------%

%() Clean-up, record the iteration number
cd(path_main);

fprintf(['------------------------------------------------', 'End of iteration ',num2str(i_sim), '------------------------------------------------\n']);
fprintf(['-----------------------------------', 'Totoal time for iteration ',num2str(i_sim), ' is: ', num2str(toc(T_sim)/60), 'mins ------------------------------------\n\n\n']);
fprintf('\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tLOADING\n\n\n');

end

%------------------End of the simulation------------------%

%------------------Post-processing------------------%
cd(path_main);
% Submit a batch job to run script for post-processing
!sbatch MasterRunPostprocess.slurm

%% BUILT-IN FUNCTIONS
% Function 1 to replace a particular line of a file
function [] = updatefile(filename, new_filename, number_updateline, updatecontents)
    fid = fopen(filename, 'r+');
    i_UL = 0; % Index for UpdatedLines
    while ~feof(fid)
        tline = fgetl(fid);
        i_UL = i_UL + 1;
        UpdatedLines{i_UL} = tline;
        if i_UL == number_updateline
            UpdatedLines{i_UL} = updatecontents;
        end
    end
    fclose(fid);
    
    % Copy a new file
    fid = fopen(new_filename, 'w+');
    for ii_UL = 1:i_UL
        fprintf(fid, '%s\t\n', UpdatedLines{ii_UL});
    end
    fclose(fid);
end

% Function 2 to edit the post-processing script (editAbaqusReadODB.py)
function [] = editAbaqusReadODB(odbpath, cartSets, outputVariable_root, outputVariable_subroot)
    % Argument 1_Define the odb directory for .py
    updatecontents_odb = append("odbpath = '", odbpath, "'");
    updatefile('abaqusReadODB.py', 'abaqusReadODB.py', 115, updatecontents_odb);
    
    % Argument 2_Define the sets of different cartilage components (a list) for .py
    updatecontents_carsets = "setnames = ['";
    for i_cartSets = 1:1:length(cartSets)
        if i_cartSets < length(cartSets)
            updatecontents_carsets = append(updatecontents_carsets, cartSets(i_cartSets), "', '");
        else 
            updatecontents_carsets = append(updatecontents_carsets, cartSets(i_cartSets), "']");
        end
    end
    updatefile('abaqusReadODB.py', 'abaqusReadODB.py', 116, updatecontents_carsets);
    
    % Argument 3_Define the root outputVariable for .py
    updatecontents_rootvar = append("outputVariable_root = '", outputVariable_root, "'");
    updatefile('abaqusReadODB.py', 'abaqusReadODB.py', 117, updatecontents_rootvar);
    
    % Argument 4_Define the subroot outputVariable for .py
    updatecontents_subrootvar = append("outputVariable_subroot = '", outputVariable_subroot, "'");
    updatefile('abaqusReadODB.py', 'abaqusReadODB.py', 118, updatecontents_subrootvar);
end

% Function 3 to wait for the FE simulation to be completed
function SimCompletion = waitForFEsimCompletion(SimCompletion, logID)
    while SimCompletion == 0
        fid = fopen(logID, 'r');
        while ~feof(fid)
            tline = fgetl(fid);
            if (ischar(tline) || isstring(tline))
                if contains(tline, 'Begin SIM Wrap-up')
                    SimCompletion = 1;
                    pause(5);  % Pause for 1 second to ensure the log file is updated
                    break;
                end
            end
        end
        % Close the file
        fclose(fid);
    end
end

% Function 4 to determine if the simulation is convergent or successfully completed
function [isConvergent] = checkConvergence(inpname)
    stafilename = append(inpname, '.sta');
    if exist(stafilename,'file') == 2   % 2 represents the file with extention exists
        fid = fopen(stafilename, 'r');
        while ~feof(fid)
            tline = fgetl(fid);
            if contains(tline, 'THE ANALYSIS HAS COMPLETED')
                isConvergent = 1;
                break;
            else
                isConvergent = 0;
            end
        end
        % Close the file
        fclose(fid);
    else
        isConvergent = 0;   % When the .sta file does not exist, it means the simulation is not completed
    end
end