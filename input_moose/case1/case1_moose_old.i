[Mesh]
  type = FileMesh
  file = coil_box_named.msh
[]

[FESpaces]
  [HCurlFESpace]
    type = MFEMFESpace
    fec_type = ND
    fec_order = FIRST
  []
  [HDivFESpace]
    type = MFEMFESpace
    fec_type = RT
    fec_order = CONSTANT
  []
[]

[Variables]
  [magnetic_vector_potential]
    type = MFEMVariable
    fespace = HCurlFESpace
  []
[]

[AuxVariables]
  # This will now receive the normalized current density J from the subapp
  [source_electric_field] 
    type = MFEMVariable
    fespace = HCurlFESpace
  []
  [magnetic_flux_density]
    type = MFEMVariable
    fespace = HDivFESpace
  []
[]

[Kernels]
  [curlcarlA]
    type = MFEMCurlCurlKernel
    variable = magnetic_vector_potential
    coefficient = permeability
  []
  [source_current]
    # We couple the pre-calculated current density J here
    type = MFEMVectorBonaluLFCoupledAuxKernel
    trial_variable = source_electric_field
    variable = magnetic_vector_potential
    # Coefficient is 1.0 because 'source_electric_field' will be transferred 
    # as the full current density J (A/m^2)
    coefficient = 1.0 
  []
[]

[AuxKernels]
  [curlA]
    type = MFEMCurlAux
    variable = magnetic_flux_density
    source = magnetic_vector_potential
    execute_on = 'TIMESTEP_END'
  []
[]

[BCs]
  [tangential_A_bdr]
    type = MFEMVectorTangentialDirichletBC
    variable = magnetic_vector_potential
    boundary = 'Vacuum' # Adjust if your outer boundary name is different
    values = '0.0 0.0 0.0'
  []
[]

[Materials]
  [Permeability]
    type = MFEMGenericConstantMaterial
    prop_names = permeability
    prop_values = 1.0 # Relative permeability (adjust for Core if needed)
    block = 'Vacuum Coil'
  []
[]

[MultiApps]
  [subapp]
    type = FullSolveMultiApp
    input_files = source_current.i
    execute_on = INITIAL
    # We pass the scalar current value to the sub-app here
    cli_args = 'Postprocessors/I_input/value=100.0' 
  []
[]

[Transfers]
  [from_sub]
    type = MultiAppMFEMCopyTransfer
    source_variable = current_density # Variable name inside source_current.i
    variable = source_electric_field
    from_multi_app = subapp
    execute_on = INITIAL
  []
[]

[Preconditioner]
  [ams]
    type = MFEMHypreAMS
    fespace = HCurlFESpace
    singular = true
  []
[]

[Executioner]
  type = MFEMSteady
[]

[Solver]
  type = MFEMHypreGMRES
  preconditioner = ams
[]

[Outputs]
  exodus = true
[]