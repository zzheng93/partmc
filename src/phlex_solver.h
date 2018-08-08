/* Copyright (C) 2015-2017 Matthew Dawson
 * Licensed under the GNU General Public License version 2 or (at your
 * option) any later version. See the file COPYING for details.
 *
 * Header file for solver functions
 *
*/
/** \file
 * \brief Header file for solver functions
*/
#ifndef PHLEX_SOLVER_H_
#define PHLEX_SOLVER_H_
#include <stdio.h>
#include <stdlib.h>

/* Header files with a description of contents used */
#ifdef PMC_USE_SUNDIALS
#include <cvodes/cvodes.h>               /* Protoypes for CVODE fcts., consts.  */
#include <cvodes/cvodes_direct.h>        /* CVDls interface                     */
#include <nvector/nvector_serial.h>      /* Serial N_Vector types, fcts, macros */
#include <sundials/sundials_math.h>      /* SUNDIALS math function macros       */
#include <sundials/sundials_types.h>     /* definition of types                 */
#include <sunlinsol/sunlinsol_klu.h>     /* KLU SUNLinearSolver                 */
#include <sunmatrix/sunmatrix_sparse.h>  /* sparse SUNMatrix                    */
#endif

/* Math constants */
#define ZERO 0.0
#define ONE 1.0
#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif

/* boolean definition */
typedef enum {false, true} bool;

/* Model data structure */
typedef struct {
  int n_state_var;	// number of state variables (>=NV_LENGTH_S(y))
  double *abs_tol;      // pointer to array of state variable absolute
                        // integration tolerances
  int *var_type;	// pointer to array of state variable types (solver,
                        // constant, PSSA)
#ifdef PMC_USE_SUNDIALS
  SUNMatrix J_init;	// sparse Jacobian matrix with used elements
                        // initialized to 1.0
#endif
  double *state;	// Pointer to the state array
  double *env;		// Pointer to the environmental state array
  void *rxn_data;	// Pointer to reaction parameters
  void *nxt_rxn;	// Pointer to element of rxn_data in which to store next
 			// set of reaction data
  void *aero_phase_data;// Pointer to aerosol phase parameters
  void *nxt_aero_phase; // Pointer to element of aero_phase_data in which to store
                        // the next set of aerosol phase data
  void *aero_rep_data;	// Pointer to aerosol representation parameters
  void *nxt_aero_rep;	// Pointer to element of aero_rep_data in which to store
  			// the next set of aerosol representation data
  void *sub_model_data; // Pointer to the sub model parameters
  void *nxt_sub_model;  // Pointer to the element of sub_model_data in which to
                        // store the next set of sub model data
} ModelData;

/* Solver data structure */
typedef struct {
#ifdef PMC_USE_SUNDIALS
  N_Vector abs_tol_nv;  // abosolute tolerance vector
  N_Vector y;		// vector of solver variables
  SUNLinearSolver ls;   // linear solver
  SUNMatrix J;          // Jacobian matrix
#endif
  void *cvode_mem;	// CVodeMem object
  ModelData model_data; // Model data (used during initialization and solving)
  bool no_solve;        // Flag to indicate whether to run the solver needs to be
                        // run. Set to true when no reactions are present.
} SolverData;

/* Functions called by phlex-chem */
void * solver_new(int n_state_var, int *var_type, int n_rxn,
          int n_rxn_int_param, int n_rxn_float_param, int n_aero_phase,
          int n_aero_phase_int_param, int n_aero_phase_float_param,
          int n_aero_rep, int n_aero_rep_int_param, int n_aero_rep_float_param,
          int n_sub_model, int n_sub_model_int_param,
          int n_sub_model_float_param);
void solver_initialize(void *solver_data, double *abs_tol, double rel_tol,
          int max_steps, int max_conv_fails); 
int solver_run(void *solver_data, double *state, double *env, double t_initial,
	  double t_final);
void sub_model_add_condensed_data(int sub_model_type, int n_int_param,
	  int n_float_param, int *int_param, double *float_param,
          void *solver_data);
void sub_model_update_data(int update_sub_model_type, void *update_data,
          void *solver_data);
int sub_model_get_parameter_id_sd(void *solver_data, int sub_model_type,
          void *identifiers);
double sub_model_get_parameter_value_sd(void *solver_data, int parameter_id);
void rxn_add_condensed_data(int rxn_type, int n_int_param, 
	  int n_float_param, int *int_param, double *float_param,
          void *solver_data);
void rxn_update_data(int update_rxn_type, void *update_data, void *solver_data);
void aero_phase_add_condensed_data(int n_int_param, int n_float_param,
          int *int_param, double *float_param, void *solver_data);
void aero_rep_add_condensed_data(int aero_rep_type, int n_int_param,
	  int n_float_param, int *int_param, double *float_param,
          void *solver_data);
void aero_rep_update_data(int update_aero_rep_type, void *update_data,
          void *solver_data);
void solver_free(void *solver_data);
void model_free(ModelData model_data);

/* Update functions */
void rxn_free_update_data(void *update_data); 
void * rxn_photolysis_create_rate_update_data();
void rxn_photolysis_set_rate_update_data(void *update_data, int photo_id,
          double base_rate);

void aero_rep_free_update_data(void *update_data); 
void * aero_rep_single_particle_create_radius_update_data();
void aero_rep_single_particle_set_radius_update_data(void *update_data,
          int aero_rep_id, double radius);
void * aero_rep_single_particle_create_number_update_data();
void aero_rep_single_particle_set_number_update_data(void *update_data,
          int aero_rep_id, double number_conc);
void * aero_rep_modal_binned_mass_create_gmd_update_data();
void aero_rep_modal_binned_mass_set_gmd_update_data(void *update_data,
          int aero_rep_id, int section_id, double gmd);
void * aero_rep_modal_binned_mass_create_gsd_update_data();
void aero_rep_modal_binned_mass_set_gsd_update_data(void *update_data,
          int aero_rep_id, int section_id, double gsd);

#ifdef PMC_USE_SUNDIALS
/* Functions called by the solver */
int f(realtype t, N_Vector y, N_Vector deriv, void *model_data);
int Jac(realtype t, N_Vector y, N_Vector deriv, SUNMatrix J, void *model_data,
		N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);

/* SUNDIALS support functions */
SUNMatrix get_jac_init(SolverData *solver_data);
int check_flag(void *flag_value, char *func_name, int opt);
void check_flag_fail(void *flag_value, char *func_name, int opt);
static void solver_print_stats(void *cvode_mem);
#endif

/* Reaction solver functions */
void * rxn_get_used_jac_elem(ModelData *model_data, bool **jac_struct);
void rxn_update_ids(ModelData *model_data, int *deriv_ids, int **jac_ids); 
void rxn_update_env_state(ModelData *model_data, double *env);
void rxn_pre_calc(ModelData *model_data);
void rxn_print_data(void *solver_data);
#ifdef PMC_USE_SUNDIALS
void rxn_calc_deriv(ModelData *model_data, N_Vector deriv, double time_step);
void rxn_calc_jac(ModelData *model_data, SUNMatrix J, double time_step);
#endif

/* Aerosol phase solver functions */
void * aero_phase_get_mass(ModelData *model_data, int aero_phase_idx,
          double *state_var, double *mass, double *MW);
void * aero_phase_get_volume(ModelData *model_data, int aero_phase_idx,
          double *state_var, double *volume);
void * aero_phase_find(ModelData *model_data, int int_aero_phase_idx);
void * aero_phase_skip(void *aero_phase_data);
void aero_phase_print_data(void *solver_data);

/* Aerosol representation solver functions */
void * aero_rep_get_dependencies(ModelData *model_data, bool *state_flags);
void aero_rep_update_env_state(ModelData *model_data, double *env);
void aero_rep_update_state(ModelData *model_data);
void * aero_rep_get_effective_radius(ModelData *model_data, int aero_rep_idx,
          int aero_phase_idx, double *radius);
void * aero_rep_get_number_conc(ModelData *model_data, int aero_rep_idx,
          int aero_phase_idx, double *number_conc);
int aero_rep_get_aero_conc_type(ModelData *model_data, int aero_rep_idx,
          int aero_phase_idx);
void * aero_rep_get_aero_phase_mass(ModelData *model_data, int aero_rep_idx,
          int aero_phase_idx, double *aero_phase_mass,
          double *aero_phase_avg_MW);
void aero_rep_print_data(void *solver_data);

/* Sub model solver functions */
void sub_model_update_env_state(ModelData *model_data, double *env);
int sub_model_get_parameter_id(ModelData *model_data, int type,
          void *identifiers);
double sub_model_get_parameter_value(ModelData *model_data, int parameter_id);
void sub_model_calculate(ModelData *model_data);
void sub_model_print_data(void *solver_data);

#endif