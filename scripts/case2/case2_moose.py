import time
from pathlib import Path
from typing import Any
import dataclasses
import shutil
import numpy as np
from scipy.spatial import KDTree
import pyvista as pv

#pyvale imports
import pyvale.dataset as dataset
import pyvale.sensorsim as sens
from pyvale.mooseherder import (MooseConfig,
                                MooseRunner,
                                ExodusReader)

#%%
# Set file locations
case_name = "case2"
mesh_name = "coil_box_named.msh"

mesh_path = "../../meshes/"
output_path = f"../../output/{case_name}/{case_name}_moose.vtu"
output_path2 = f"../../output/{case_name}/gauss/{case_name}_moose.npy"
input_file_path = f"../../input_moose/{case_name}/{case_name}.i"
input_file_path_copy = f"../../input_moose/{case_name}/{case_name}_copy.i"
input_path = f"../../input_moose/{case_name}/"

gauss_coords = np.load(f"../../output/{case_name}/gauss/{case_name}_ngsolve.npy")[:, 0:3]
gauss_coords_vec = np.zeros((gauss_coords.shape[0]*3))

for i in range(gauss_coords.shape[0]):
    gauss_coords_vec[i*3 + 0] = gauss_coords[i, 0]
    gauss_coords_vec[i*3 + 1] = gauss_coords[i, 1]
    gauss_coords_vec[i*3 + 2] = gauss_coords[i, 2]

np.savetxt(f'{input_path}/gauss_points.txt', gauss_coords_vec, delimiter=' ', newline=' ')

# gauss_coords_vec = gauss_coords_vec[:300]

gauss_coords_string = ' '.join(map(str, gauss_coords_vec))

# new_value = "    points = '0 0 0 0.01 0 0'\n"
new_value = f"    points = '{gauss_coords_string}'\n"
with open(input_file_path, 'r') as file:
    lines = file.readlines()

for i, line in enumerate(lines):
    if "points =" in line:
        lines[i] = new_value
        # break
    
with open(input_file_path_copy, 'w') as file:
    file.writelines(lines)


mesh_file_path = mesh_path + mesh_name
mesh_file_path_moose = input_path + mesh_name
shutil.copyfile(mesh_file_path, mesh_file_path_moose)

config = {'main_path': Path.home()/ 'moose',
          'app_path': Path.home() / 'proteus',
          'app_name': 'proteus-opt'}
moose_config = MooseConfig(config)

moose_runner = MooseRunner(moose_config)

moose_runner.set_run_opts(n_tasks = 1,
                          n_threads = 1,
                          redirect_out = False)

moose_input = Path(input_file_path_copy) # It actually works now :)

moose_runner.set_input_file(moose_input)

print(moose_runner.get_arg_list())
print()

#%%
# Run the simulation

start_time = time.perf_counter()
moose_runner.run()
run_time = time.perf_counter() - start_time

print()
print("-"*80)
print(f'MOOSE run time = {run_time:.3f} seconds')
print("-"*80)
print()

#%%
# Save the results
# WARNING!!! If there is an error, it is likely because the version of .msh file is above 2 for pyvista.

sim_data = pv.read(input_path + "OutputData/CoilMagnetostatic/Run0/Cycle000001/proc000000.vtu")

sim_data.rename_array('a_field', 'magnetic_vector_potential_nd')
sim_data.rename_array('b_field', 'magnetic_flux_density_nd')
sim_data.rename_array('a_field_h1', 'magnetic_vector_potential')
sim_data.rename_array('b_field_h1', 'magnetic_flux_density')

sim_data.save(output_path)

sim_data_a_field = np.genfromtxt(input_path + "OutputData/CoilMagnetostatic/gauss/gauss_point_sample_a_0001.csv", delimiter = ",", skip_header=1)
sim_data_b_field = np.genfromtxt(input_path + "OutputData/CoilMagnetostatic/gauss/gauss_point_sample_b_0001.csv", delimiter = ",", skip_header=1)

print(sim_data_a_field.shape)
print(sim_data_b_field.shape)

sim_data_coords = sim_data_a_field[:, 3:]
print(sim_data_coords.shape)

sim_data_convert = np.zeros((sim_data_coords.shape[0], 9))
sim_data_convert[:, 0:3] = sim_data_coords
sim_data_convert[:, 3:6] = sim_data_a_field[:, 0:3]
sim_data_convert[:, 6:9] = sim_data_b_field[:, 0:3]

np.save(output_path2, sim_data_convert)



#%%

# Delete copy of MOOSE input file
if moose_input.exists():
    moose_input.unlink()
    print("Copy of MOOSE input file deleted successfully.")
else:
    print("Copy of MOOSE input file does not exist.")
