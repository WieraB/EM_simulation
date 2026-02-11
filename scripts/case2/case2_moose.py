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
input_file_path = f"../../input_moose/{case_name}/{case_name}.i"
input_path = f"../../input_moose/{case_name}/"

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

moose_input = Path(input_file_path) # It actually works now :)

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

sim_data.rename_array('a_field', 'magnetic_vector_potential')
sim_data.rename_array('b_field', 'magnetic_flux_density')

sim_data.save(output_path)

# # Extarct data for the cells corresponding to the coil.
# sim_data = sim_data.extract_values(values=[2, 1], scalars="attribute", preference="cell")

# # elec_pot_unordered = sim_data["electric_potential"]
# curr_dens_unordered = sim_data["current_density"]
# attribute = sim_data["attribute"]

# # sol1_unordered = elec_pot_unordered
# sol2_unordered = curr_dens_unordered
# sol3_unordered = sim_data["a_field"]
# sol4_unordered = sim_data["b_field"]
# # print(sol1_unordered.shape)
# # print(sol2_unordered.shape)
# # print(attribute.shape)

# points_unordered = sim_data.points
# res = pv.read(mesh_file_path)
# points = res.points
# tree2 = KDTree(points_unordered)

# # sol1 = np.zeros(len(points))
# sol2 = np.zeros((len(points), 3))
# sol3 = np.zeros((len(points), 3))
# sol4 = np.zeros((len(points), 3))

# for i in range(len(points)):
#     _, index = tree2.query(points[i, :], distance_upper_bound=1e-9)
#     if index == tree2.n:
#         continue
#     else:
#         # sol1[i] = sol1_unordered[index]
#         sol2[i, :] = sol2_unordered[index]
#         sol3[i, :] = sol3_unordered[index]
#         sol4[i, :] = sol4_unordered[index]

# # res["electric_potential"] = sol1
# res["current_density"] = sol2
# res["magnetic_vector_potential"] = sol3
# res["magnetic_flux_density"] = sol4

# res.save(output_path)
