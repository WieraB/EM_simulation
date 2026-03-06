# Electrostatic problem

#-------------------------------------------------------------------------
#_* MOOSEHERDER VARIABLES - START

# Loads/BCs
I_coil = 2191.9 # Input electric current [A]

# Geometric Parameters
cross_section = 7.0710678118656e-05 # Coil's cross section [m^2]

# Material Properties:
sigma_coil = 62.83185 # Coil's electric conductivity [S/m]

#** MOOSEHERDER VARIABLES - END
#-------------------------------------------------------------------------

[Functions]
  [current_density_func]
    type = ParsedFunction
    expression = 'i / area'
    symbol_names = 'i area'
    # Value = Total Current (Amps) / Area (m^2)
    symbol_values = '${I_coil} ${cross_section}'
  []
[]

[Mesh]
  type = MFEMMesh
  file = coil_box_named.msh
[]

[Problem]
  type = MFEMProblem
[]

[SubMeshes]
  [wire]
    type = MFEMDomainSubMesh
    block = 'wire'
  []
[]

[FESpaces]
  [H1FESpace]
    type = MFEMScalarFESpace
    fec_type = H1
    fec_order = FIRST
  []
  [HCurlFESpace]
    type = MFEMVectorFESpace
    fec_type = ND
    fec_order = FIRST
  []
  [SubMeshH1FESpace]
    type = MFEMScalarFESpace
    fec_type = H1
    fec_order = FIRST
    submesh = wire
  []
  [SubMeshHCurlFESpace]
    type = MFEMVectorFESpace
    fec_type = ND
    fec_order = FIRST
    submesh = wire
  []
[]

[Variables]
  [electric_potential]
    type = MFEMVariable
    fespace = H1FESpace
  []
  [submesh_potential]
    type = MFEMVariable
    fespace = SubMeshH1FESpace
  []
[]

[AuxVariables]
  [current_density]
    type = MFEMVariable
    fespace = HCurlFESpace
  []
  [submesh_current_density]
    type = MFEMVariable
    fespace = SubMeshHCurlFESpace
  []
[]

[AuxKernels]
  # Ohm's Law
  [grad]
    type = MFEMGradAux
    variable = submesh_current_density
    source = submesh_potential
    scale_factor = -${sigma_coil}
    execute_on = TIMESTEP_END
  []
[]

[BCs]
  [inlet_current]
    # Current-driven input (Neumann type)
    type = MFEMBoundaryIntegratedBC
    variable = submesh_potential
    boundary = 'CoilIn'
    coefficient = current_density_func
  []

  [outlet_ground]
    # Reference ground (Dirichlet type)
    type = MFEMScalarDirichletBC
    variable = submesh_potential
    boundary = 'CoilOut'
    coefficient = 0.0
  []
[]

[Kernels]
  # Diffusion kernel
  [diff]
    type = MFEMDiffusionKernel
    variable = submesh_potential
    coefficient = ${sigma_coil}
  []
[]

[Preconditioner]
  [boomeramg]
    type = MFEMHypreBoomerAMG
  []
[]

[Solver]
  type = MFEMHypreGMRES
  preconditioner = boomeramg
  l_tol = 1e-30
  l_max_its = 2000
[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]

[Transfers]
  [submesh_transfer]
    type = MFEMSubMeshTransfer
    from_variable = submesh_current_density
    to_variable = current_density
    execution_order_group = 2
  []
  [submesh_potential_transfer]
    type = MFEMSubMeshTransfer
    from_variable = submesh_potential
    to_variable = electric_potential
  []
[]

# [Postprocessors]
#   [coil_area]
#     type = AreaPostprocessor
#     boundary = 'CoilIn'
#   []
# []

[VectorPostprocessors]
  [point_sample_electric_potential]
    type = MFEMPointValueSampler
    variable = 'electric_potential'
    points = '0 0 0'
    execute_on = TIMESTEP_END
    execution_order_group = 3
  []
  [point_sample_current_density]
    type = MFEMPointValueSampler
    variable = 'current_density'
    points = '0 0 0'
    execute_on = TIMESTEP_END
    execution_order_group = 4
  []
[]

[Outputs]
  [VacuumParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData
    vtk_format = ASCII
  []
[]

[Outputs]
[txt_output]
    type = CSV
    file_base = OutputData/CoilMagnetostatic/gauss/gauss
    execute_on = 'FINAL'
  []
[]
