# Electrostatic problem

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
    scale_factor = -62.83185 # = -conductivity
    execute_on = TIMESTEP_END
  []
[]

[BCs]
  [high_terminal]
    type = MFEMScalarDirichletBC
    variable = submesh_potential
    boundary = 'CoilIn'
    coefficient = 0.5
  []
  [low_terminal]
    type = MFEMScalarDirichletBC
    variable = submesh_potential
    boundary = 'CoilOut'
    coefficient = -0.5
  []
[]

[Kernels]
  # Diffusion kernel
  [diff]
    type = MFEMDiffusionKernel
    variable = submesh_potential
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

[Outputs]
  [VacuumParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData
    vtk_format = ASCII
  []
[]
