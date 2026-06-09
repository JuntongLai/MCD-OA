#------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
#                                                             Ver 1.0.0
#                                                   Copyright (c) 2026 Juntong Lai
#                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
#-------------------------------------------------------------------------------------------------------------------------------

import re
import glob

# This script updates an Abaqus input file (.inp) by replacing material properties
txtfile_names = glob.glob('*.txt')
inpfile_name = glob.glob('*.inp')

for txtfile_name in txtfile_names:
    # Load mapping file: label, elastic, permeability
    material_values = {}
    with open(txtfile_name) as f:
        for line in f:
            parts = line.strip().split(",")     # Split by comma
            if len(parts) == 3:                 # Ensure there are exactly three parts  
                label = parts[0].strip()        # First part is the label
                elastic = float(parts[1])       # Second part is the modulus value
                permeability = float(parts[2])  # Third part is the permeability value
                material_values[label] = (elastic, permeability)    # Store in dictionary
            else:
                print("Warning: Invalid line in {}: {}".format(txtfile_name, line.strip()))

    # Extract MP set name from the file name
    if 'PT_' in txtfile_name and 'Ele' in txtfile_name:
        MPsetname = txtfile_name.split('PT_')[1].split('_Ele')[0]
    else:
        MPsetname = ""
        print("Warning: Could not extract MPsetname from {}".format(txtfile_name))
    
    # Read the input file
    if len(inpfile_name) != 1:
        raise ValueError("Expected exactly one .inp file, but found {}: {}".format(len(inpfile_name), inpfile_name))
    
    with open(inpfile_name[0]) as f:
        lines = f.readlines()
        # Prepare output lines
        updated_lines = []
        i = 0
        while i < len(lines):
            line = lines[i]
            updated_lines.append(line)
            if line.startswith("*Material, name=PT_"+MPsetname+"_"):
                name = line.strip().split(MPsetname+"_")[-1]
                if name in material_values:
                    elastic, permeability = material_values[name]
                    # Move to "*Elastic"
                    while i < len(lines) and not lines[i].strip().startswith("*Elastic"):
                        i += 1
                        updated_lines.append(lines[i])
                    # Overwrite Elastic value line
                    i += 1
                    updated_lines.append(" {:.5f}, 0.15\n".format(elastic)) # (stiffness, Poisson's ratio)

                    # Move to "*Permeability"
                    while i < len(lines) and not lines[i].strip().startswith("*Permeability"):
                        i += 1
                        updated_lines.append(lines[i])
                    # Overwrite Permeability value line
                    i += 1
                    updated_lines.append(" {:.5e},4.\n".format(permeability))   # (permeability, void ratio)
                    
                    # Move to next material definition
                    # print("Processed line {} for {}_{} in {}".format(i, MPsetname, name, inpfile_name[0]))
                else:
                    print("Warning: No data found for {}".format(name))
            i += 1

    # Save updated template
    with open(inpfile_name[0], "w+") as f:
        f.writelines(updated_lines)