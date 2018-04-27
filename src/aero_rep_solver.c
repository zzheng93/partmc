/* Copyright (C) 2015-2018 Matthew Dawson
 * Licensed under the GNU General Public License version 1 or (at your
 * option) any later version. See the file COPYING for details.
 *
 * Aerosol representation-specific functions for use by the solver
 *
 */
/** \file
 * \brief Aerosol representation functions
 */
#include "phlex_solver.h"
#include "aero_rep_solver.h"

// Aerosol representations (Must match parameters defined in pmc_aero_rep_factory
#define AERO_REP_SINGLE_PARTICLE 1
#define AERO_REP_MODAL_MASS      2

#ifdef PMC_USE_SUNDIALS

/** \brief Get the state array elements used by the aerosol representation functions
 *
 * \param model_data A pointer to the model data
 * \param state_flags An array of flags the length of the state array indicating species used
 * \return The aero_rep_data pointer advanced by the size of the aerosol representation data
 */
void * aero_rep_get_dependencies(ModelData *model_data, bool *state_flags)
{

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to determine the Jacobian elements used
  // advancing the aero_rep_data pointer each time
  for (int i_aero_rep=0; i_aero_rep<n_aero_rep; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Call the appropriate function
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_get_dependencies((void*) aero_rep_data, state_flags);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_get_dependencies((void*) aero_rep_data, state_flags);
        break;
    }
  }
  return aero_rep_data;
}

/** \brief Update the aerosol representations for new environmental conditions
 *
 * \param model_data Pointer to the model data
 * \param env Pointer to the environmental state array
 */
void aero_rep_update_env_state(ModelData *model_data, double *env)
{

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to update the environmental conditions
  // advancing the aero_rep_data pointer each time
  for (int i_aero_rep=0; i_aero_rep<n_aero_rep; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Call the appropriate function
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_update_env_state(env, (void*) aero_rep_data);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_update_env_state(env, (void*) aero_rep_data);
        break;
    }
  }
}

/** \brief Update the aerosol representations for a new state
 *
 * \param model_data Pointer to the model data
 */
void aero_rep_update_state(ModelData *model_data)
{

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to update the state
  // advancing the aero_rep_data pointer each time
  for (int i_aero_rep=0; i_aero_rep<n_aero_rep; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Call the appropriate function
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_update_state(model_data, 
                  (void*) aero_rep_data);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_update_state(model_data, 
                  (void*) aero_rep_data);
        break;
    }
  }
}

/** \brief Get the effective particle radius
 *
 * Calculates particle radius r (m), as well as the set of dr/dy where y are 
 * variables on the solver state array.
 *
 * \param model_data Pointer to the model data (state, env, aero_rep)
 * \param aero_rep_idx Index of aerosol representation to use for calculation
 * \param aero_phase_idx Index of the aerosol phase within the aerosol representation
 * \param radius Pointer to hold effective particle radius (m)
 * \return A pointer to a set of partial derivatives dr/dy, or a NULL pointer if no
 *         partial derivatives exist
 */
void * aero_rep_get_effective_radius(ModelData *model_data, int aero_rep_idx, int aero_phase_idx,
		double *radius)
{

  // Set up a pointer for the partial derivatives
  void *partial_deriv = NULL;

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to find the one requested
  for (int i_aero_rep=0; i_aero_rep<aero_rep_idx; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Advance the pointer to the next aerosol representation
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_skip((void*) aero_rep_data);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_skip((void*) aero_rep_data);
        break;
    }
  }

  // Get the aerosol representation type
  int aero_rep_type = *(aero_rep_data++);

  // Get the particle radius and set of partial derivatives
  switch (aero_rep_type) {
    case AERO_REP_MODAL_MASS :
      aero_rep_data = (int*) aero_rep_modal_mass_get_effective_radius(
		      aero_phase_idx, radius, partial_deriv, (void*) aero_rep_data);
      break;
    case AERO_REP_SINGLE_PARTICLE :
      aero_rep_data = (int*) aero_rep_single_particle_get_effective_radius(
		      aero_phase_idx, radius, partial_deriv, (void*) aero_rep_data);
      break;
  }
  return partial_deriv;
}

/** \brief Get the particle number concentration
 *
 * Calculates particle number concentration, n (#/cm^3), as well as the set of dn/dy where y are 
 * variables on the solver state array.
 *
 * \param model_data Pointer to the model data (state, env, aero_rep)
 * \param aero_rep_idx Index of aerosol representation to use for calculation
 * \param aero_phase_ids Index of the aerosol phase within the aerosol representation
 * \param number_conc Pointer to hold calculated number concentration, n (#/cm^3)
 * \return A pointer to a set of partial derivatives dr/dy, or a NULL pointer if no
 *         partial derivatives exist
 */
void * aero_rep_get_number_conc(ModelData *model_data, int aero_rep_idx, int aero_phase_idx,
		double *number_conc)
{

  // Set up a pointer for the partial derivatives
  void *partial_deriv = NULL;

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to find the one requested
  for (int i_aero_rep=0; i_aero_rep<aero_rep_idx; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Advance the pointer to the next aerosol representation
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_skip((void*) aero_rep_data);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_skip((void*) aero_rep_data);
        break;
    }
  }

  // Get the aerosol representation type
  int aero_rep_type = *(aero_rep_data++);

  // Get the particle number concentration
  switch (aero_rep_type) {
    case AERO_REP_MODAL_MASS :
      aero_rep_data = (int*) aero_rep_modal_mass_get_number_conc( 
		      aero_phase_idx, number_conc, partial_deriv, (void*) aero_rep_data);
      break;
    case AERO_REP_SINGLE_PARTICLE :
      aero_rep_data = (int*) aero_rep_single_particle_get_number_conc( 
		      aero_phase_idx, number_conc, partial_deriv, (void*) aero_rep_data);
      break;
  }
  return partial_deriv;
}

/** \brief Check whether aerosol concentrations are per-particle or total for each phase
 *
 * \param model_data Pointer to the model data (state, env, aero_rep)
 * \param aero_rep_idx Index of aerosol representation to use for calculation
 * \param aero_phase_ids Index of the aerosol phase within the aerosol representation
 * \return 0 for per-particle; 1 for total for each phase
 */
int aero_rep_get_aero_conc_type(ModelData *model_data, int aero_rep_idx, int aero_phase_idx)
{

  // Initialize the aerosol concentration type
  int aero_conc_type = 0;

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to find the one requested
  for (int i_aero_rep=0; i_aero_rep<aero_rep_idx; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Advance the pointer to the next aerosol representation
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_skip((void*) aero_rep_data);
        break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_skip((void*) aero_rep_data);
        break;
    }
  }

  // Get the aerosol representation type
  int aero_rep_type = *(aero_rep_data++);

  // Get the type of aerosol concentration
  switch (aero_rep_type) {
    case AERO_REP_MODAL_MASS :
      aero_rep_data = (int*) aero_rep_modal_mass_get_aero_conc_type( 
		      aero_phase_idx, &aero_conc_type, (void*) aero_rep_data);
      break;
    case AERO_REP_SINGLE_PARTICLE :
      aero_rep_data = (int*) aero_rep_single_particle_get_aero_conc_type( 
		      aero_phase_idx, &aero_conc_type, (void*) aero_rep_data);
      break;
  }
  return aero_conc_type;
}
#endif

/** \brief Add condensed data to the condensed data block for aerosol representations
 *
 * \param aero_rep_type Aerosol representation type
 * \param n_int_param Number of integer parameters
 * \param n_float_param Number of floating-point parameters
 * \param int_param Pointer to integer parameter array
 * \param float_param Pointer to floating-point parameter array
 * \param solver_data Pointer to solver data
 */
void aero_rep_add_condensed_data(int aero_rep_type, int n_int_param,
		int n_float_param, int *int_param, double *float_param, void *solver_data)
{
  ModelData *model_data = (ModelData*) &(((SolverData*)solver_data)->model_data);
  int *aero_rep_data = (int*) (model_data->nxt_aero_rep);

#ifdef PMC_USE_SUNDIALS

  // Add the aerosol representation type
  *(aero_rep_data++) = aero_rep_type;

  // Add integer parameters
  for (; n_int_param>0; n_int_param--) *(aero_rep_data++) = *(int_param++);

  // Add floating-point parameters
  realtype *flt_ptr = (realtype*) aero_rep_data;
  for (; n_float_param>0; n_float_param--) *(flt_ptr++) = (realtype) *(float_param++);

  // Set the pointer for the next free space in aero_rep_data
  model_data->nxt_aero_rep = (void*) flt_ptr;

#endif
}

/** \brief Update aerosol representation data
 *
 * \param aero_rep_id ID of aerosol representation to update
 * \param update_type Aerosol representation-specific update type
 * \param update_data Pointer to data needed for update
 * \param solver_data Pointer to solver data
 */
void aero_rep_update_data(int aero_rep_id, int update_type, void *update_data,
		void *solver_data)
{
  ModelData *model_data = (ModelData*) &(((SolverData*)solver_data)->model_data);

#ifdef PMC_USE_SUNDIALS

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

  // Loop through the aerosol representations to find the requested representation
  // data, advancing the aero_rep_data pointer each time
  int i_aero_rep = 0;
  for (; i_aero_rep<n_aero_rep && i_aero_rep<aero_rep_id; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Skip reaction
    switch (aero_rep_type) {
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_skip((void*)aero_rep_data);
    }
  }

  if (i_aero_rep==n_aero_rep) {
    printf("\nERROR: invalid aerosol representation index: %d out of %d\n", aero_rep_id, n_aero_rep);
    exit(1);
  }

  // Get the aerosol representation type
  int aero_rep_type = *(aero_rep_data++);

  // Update the data of specified representation
  switch (aero_rep_type) {
    case AERO_REP_MODAL_MASS :
      aero_rep_data = (int*) aero_rep_modal_mass_update_data(update_type, 
			  update_data, (void*)aero_rep_data);
      break;
    case AERO_REP_SINGLE_PARTICLE :
      aero_rep_data = (int*) aero_rep_single_particle_update_data(update_type, 
			  update_data, (void*)aero_rep_data);
      break;
  }
#endif
}

/** \brief Print the aerosol representation data
 *
 * \param solver_data Pointer to the solver data
 */
void aero_rep_print_data(void *solver_data)
{
  ModelData *model_data = (ModelData*) &(((SolverData*)solver_data)->model_data);

  // Get the number of aerosol representations
  int *aero_rep_data = (int*) (model_data->aero_rep_data);
  int n_aero_rep = *(aero_rep_data++);

#ifdef PMC_USE_SUNDIALS

  printf("\n\nAerosol representation data\n\nnumber of aerosol representations: %d\n\n", n_aero_rep);

  // Loop through the aerosol representations advancing the pointer each time
  for (int i_aero_rep=0; i_aero_rep<n_aero_rep; i_aero_rep++) {

    // Get the aerosol representation type
    int aero_rep_type = *(aero_rep_data++);

    // Call the appropriate printing function
    switch (aero_rep_type) {
      case AERO_REP_MODAL_MASS :
	aero_rep_data = (int*) aero_rep_modal_mass_print((void*)aero_rep_data);
	break;
      case AERO_REP_SINGLE_PARTICLE :
	aero_rep_data = (int*) aero_rep_single_particle_print((void*)aero_rep_data);
	break;
    }
  }
#endif
}
