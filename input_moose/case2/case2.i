# Definite Maxwell problem solved with Nedelec elements of the first kind
# based on MFEM Example 3.

# Magnetostatic problem

[Functions]
  [mu0_inv]
    # Inverse of vacuum  permeability with the units [N/A^2]
    type = ParsedFunction
    expression = '1/(4*pi*1e-7)'
  []
[]


[Problem]
  type = MFEMProblem
[]

[Mesh]
  type = MFEMMesh
  file = coil_box_named.msh
[]

[FESpaces]
  [HCurlFESpace]
    type = MFEMVectorFESpace
    fec_type = ND
    fec_order = FIRST
  []
  [HDivFESpace]
    type = MFEMVectorFESpace
    fec_type = RT
    fec_order = CONSTANT
  []
  [H1FESpace]
    type = MFEMVectorFESpace
    fec_type = H1
    fec_order = FIRST
  []
[]

[Variables]
  [a_field]
    type = MFEMVariable
    fespace = HCurlFESpace
  []
  [current_density]
    type = MFEMVariable
    fespace = HCurlFESpace
  []
[]

[AuxVariables]
  [b_field]
    type = MFEMVariable
    fespace = HDivFESpace
  []
  [a_field_h1]
    type = MFEMVariable
    fespace = H1FESpace
  []
[]

[AuxKernels]
  [curl]
    type = MFEMCurlAux
    variable = b_field
    source = a_field
    scale_factor = 1.0
    execute_on = TIMESTEP_END
  []
  [a_field_h1]
    type = MFEMVectorProjectionAux
    variable = a_field_h1
    vector_coefficient = a_field
  []
[]

[BCs]
  [tangential_a_bdr]
    type = MFEMVectorTangentialDirichletBC
    variable = a_field
    # boundary = 'Side1 Side2 Side3 Side4 Side5 Side6'
    boundary = '1 2 3 4 5 12'
    # boundary = ''
  []
[]

[Kernels]
  [mass]
    type = MFEMVectorFEMassKernel
    variable = a_field
    coefficient = 1e-7
  []
  [curlcurl]
    type = MFEMCurlCurlKernel
    variable = a_field
    coefficient = mu0_inv
  []
  [source]
    type = MFEMVectorFEDomainLFKernel
    variable = a_field
    vector_coefficient = current_density
    block = 'wire'
  []
[]

[Preconditioner]
  [ams]
    type = MFEMHypreAMS
    fespace = HCurlFESpace
    singular = true
  []
  [boomeramg]
    type = MFEMHypreBoomerAMG
    fespace = HCurlFESpace
  []
[]

[Solver]
  type = MFEMHypreFGMRES
  # preconditioner = ams
  # preconditioner = boomeramg
  l_tol = 1e-6
  l_max_its = 100
[]

[Executioner]
  type = MFEMSteady
  device = cpu
[]

[MultiApps]
  [subapp]
    type = FullSolveMultiApp
    input_files = case2_coil_source.i
    execute_on = INITIAL
  []
[]

[Transfers]
  [from_sub]
    type = MultiAppMFEMCopyTransfer
    source_variable = current_density
    variable = current_density
    from_multi_app = subapp
  []
[]

[Outputs]
  [ParaViewDataCollection]
    type = MFEMParaViewDataCollection
    file_base = OutputData/CoilMagnetostatic
    vtk_format = ASCII
  []
[]