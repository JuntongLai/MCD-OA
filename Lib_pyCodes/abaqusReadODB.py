#------------------The Integrative Multiscale Framework: Mechanical Loading and Inflammation in Osteoarthritis------------------
#                                                             Ver 1.0.0
#                                                   Copyright (c) 2026 Juntong Lai
#                                   Insigneo Institute for in silico Medicine, University of Sheffield, UK
#-------------------------------------------------------------------------------------------------------------------------------

from abaqusConstants import *																						
												
from odbAccess import *												
from odbMaterial import *												
from odbSection import *												
												
import os												

# The function is used to export the fieldoutputs based on defined variables/regions from a ODB file in Abaqus												
def ElementFieldoutput(odbpath, fieldoutput_path, setnames, output_step, output_frame, outputVariable_root, outputVariable_subroot):												
    o1 = openOdb(path = odbpath,readOnly=False)			# Open ODB file																					
	# Input arguments	(By doing this, only open the odb once with viewports)
    for setname in setnames:
        region_arg = o1.rootAssembly.instances['PART-1-1'].elementSets[setname]		# Define the region where we are extracting data (By only having the main big sets including all of elements to save time instead of looping all of sets)										
        setname = 'PART-1-1.' + setname		                                        # Reset the setname										
        fieldoutput_filename = setname + '_Ele_' + outputVariable_root + outputVariable_subroot + '.txt'	# Name the output text file											
        filenamePath = os.path.join(fieldoutput_path, fieldoutput_filename)			# Set the full path of output text
        # Extracting particular mechanical outputs
        stressField = o1.steps[output_step].frames[output_frame].fieldOutputs[outputVariable_root] # Decide the loading step and frames										
        field = stressField.getSubset(region=region_arg, position=CENTROID)
        fieldValues = field.values
        # Write field outputs into the text file (filenamePath)
        with open(filenamePath, 'w') as f:
            #-----------------------Stress field output-----------------------#
            if outputVariable_root == 'S':
                # Minimum principal stress
                if outputVariable_subroot == 'minprincipal':   # 'mises' for von Mises stress
                    for v in fieldValues: 
                        f.write(str(v.elementLabel))
                        f.write('\t')
                        f.write(str(v.minPrincipal))
                        f.write('\n')
                # Maximum principal stress
                if outputVariable_subroot == 'maxprincipal':
                    for v in fieldValues: 
                        f.write(str(v.elementLabel))
                        f.write('\t')
                        f.write(str(v.maxPrincipal))
                        f.write('\n')
                # Hydrostatic Pressure (solid consitituents)
                if outputVariable_subroot == 'HP':
                    for v in fieldValues: 
                        f.write(str(v.elementLabel))
                        f.write('\t')
                        f.write(str(v.press))
                        f.write('\n')
            #-----------------------Strain field output-----------------------#            
            elif outputVariable_root == 'LE':
                # Minimum principal strain
                if outputVariable_subroot == 'minprincipal':
                    for v in fieldValues: 
                        f.write(str(v.elementLabel))
                        f.write('\t')
                        f.write(str(v.minPrincipal))
                        f.write('\n')
                # Maximum principal strain
                if outputVariable_subroot == 'maxprincipal':
                    for v in fieldValues: 
                        f.write(str(v.elementLabel))
                        f.write('\t')
                        f.write(str(v.maxPrincipal))
                        f.write('\n')
            #-----------------------Pore pressure field output-----------------------#
            elif outputVariable_root == 'POR':  # Pore pressure field output
                for region_ele in region_arg.elements:
                    eleLabel = region_ele.label
                    nodeLabels = region_ele.connectivity
                    region_node_arg = o1.rootAssembly.instances['PART-1-1'].NodeSetFromNodeLabels(name=str(eleLabel), nodeLabels=nodeLabels)
                    field = stressField.getSubset(region=region_node_arg)
                    v = sum([val.data for val in field.values]) / len(field.values)   # Average pore pressure from nodes for the element
                    f.write(str(eleLabel))
                    f.write('\t')
                    f.write(str(v))
                    f.write('\n')
            #-----------------------Contact pressure field output-----------------------#
            elif outputVariable_root == 'CPRESS':  # Conctact pressure field output
                field = stressField.getSubset(region=region_arg, position=NODAL)     # Overwrite the field to get nodal data
                fieldValues = field.values
                for v in stressField.values:       # Should be 'stressField.values' to include nodal data
                    f.write(str(v.nodeLabel))
                    f.write('\t')
                    f.write(str(v.data))
                    f.write('\n')
        # Close writting text file
        f.close()
    # Close odb once postprocessing is finished	       									                        											
    o1.close()
												
# This function is built to loop all of text files in a folder and return their paths (NOT USING HERE)												
def DefineTxtPath(txtpath):												
    txtfile_names = list()      # Create the list for txt file names and paths												
    # Loop the directory path and directory names and file names under the path of txtpath												
    for dirpath, dirname, filenames in os.walk(txtpath):												
        # Loop the file names in the txtpath												
        for filename in filenames:												
            file_path = os.path.join(dirpath, filename)     # Save the entire file path with suffix												
            # Determine whether the file is a text file with .txt, if yes then save its full path (name) into the list, txtfile_names												
            if file_path.endswith('.txt'):												
                txtfile_names.append(file_path)												
    return txtfile_names     												
                    												
### START												
## Define the current path and argument path												
currentpath = os.path.dirname(os.path.abspath('__file__'))												
fieldoutput_path = os.path.join(currentpath, '1_Fieldoutputs')												
												
### START												
## Define the list of arguments input for postprocessing of odb data												
odbpath = 'USER-DEFINED'				
setnames = ['USER-DEFINED']			
outputVariable_root = 'USER-DEFINED'		
outputVariable_subroot = 'USER-DEFINED'
output_step = 'Load1'   # USER-DEFINED
output_frame = -1        # USER-DEFINED	
												
# Call the built function to generate fieldoutput by sorting element labels												 
ElementFieldoutput(odbpath, fieldoutput_path, setnames, output_step, output_frame, outputVariable_root, outputVariable_subroot)										