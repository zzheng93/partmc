! Copyright (C) 2005-2008 Nicole Riemer and Matthew West
! Licensed under the GNU General Public License version 2 or (at your
! option) any later version. See the file COPYING for details.

!> \file
!> The pmc_run_mc module.

!> Monte Carlo simulation.
module pmc_run_mc

  use pmc_inout
  use pmc_process_spec
  use pmc_util
  use pmc_aero_state
  use pmc_bin_grid 
  use pmc_aero_binned
  use pmc_condensation
  use pmc_env_data
  use pmc_env_state
  use pmc_aero_data
  use pmc_gas_data
  use pmc_gas_state
  use pmc_output_state
  use pmc_mosaic
  use pmc_coagulation
  use pmc_kernel
  use pmc_output_processed
  use pmc_mpi
#ifdef PMC_USE_MPI
  use mpi
#endif

  !> Options controlling the execution of run_mc().
  type run_mc_opt_t
     !> Maximum number of particles.
    integer :: n_part_max
    !> Final time (s).
    real*8 :: t_max
    !> Output interval (0 disables) (s).
    real*8 :: t_output
    !> State output intvl (0 disables) (s).
    real*8 :: t_state
    !> Progress interval (0 disables) (s).
    real*8 :: t_progress
    !> Timestep for coagulation.
    real*8 :: del_t
    !> Prefix for output files.
    character(len=300) :: output_prefix
    !> Prefix for state files.
    character(len=300) :: state_prefix
    !> Whether to do coagulation.
    logical :: do_coagulation
    !> Allow doubling if needed.
    logical :: allow_double
    !> Whether to do condensation.
    logical :: do_condensation
    !> Whether to do MOSAIC.
    logical :: do_mosaic
    !> Whether to restart from state.
    logical :: do_restart
    !> Name of state to restart from.
    character(len=300) :: restart_name
    !> Loop number of run.
    integer :: i_loop
    !> Total number of loops.
    integer :: n_loop
    !> Cpu_time() of start.
    real*8 :: t_wall_start
    !> Mix rate for parallel states (0 to 1).
    real*8 :: mix_rate
 end type run_mc_opt_t
  
contains
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Do a particle-resolved Monte Carlo simulation.
  subroutine run_mc(kernel, bin_grid, aero_binned, env_data, env_state, &
       aero_data, aero_state, gas_data, gas_state, mc_opt, process_spec_list)
    
    !> Bin grid.
    type(bin_grid_t), intent(in) :: bin_grid
    !> Binned distributions.
    type(aero_binned_t), intent(out) :: aero_binned
    !> Environment state.
    type(env_data_t), intent(in) :: env_data
    !> Environment state.
    type(env_state_t), intent(inout) :: env_state
    !> Aerosol data.
    type(aero_data_t), intent(in) :: aero_data
    !> Aerosol state.
    type(aero_state_t), intent(inout) :: aero_state
    !> Gas data.
    type(gas_data_t), intent(in) :: gas_data
    !> Gas state.
    type(gas_state_t), intent(inout) :: gas_state
    !> Monte Carlo options.
    type(run_mc_opt_t), intent(in) :: mc_opt
    !> Processing spec.
    type(process_spec_t), intent(in) :: process_spec_list(:)

    ! FIXME: can we shift this to a module? pmc_kernel presumably
    interface
       subroutine kernel(v1, v2, env_state, k)
         use pmc_env_state
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         type(env_state_t), intent(in) :: env_state   
         real*8, intent(out) :: k
       end subroutine kernel
    end interface
    
    real*8 time, pre_time, pre_del_t
    real*8 last_output_time, last_state_time, last_progress_time
    real*8 k_max(bin_grid%n_bin, bin_grid%n_bin)
    integer n_coag, tot_n_samp, tot_n_coag, rank, pre_index, ncid, pre_i_loop
    logical do_output, do_state, do_progress, did_coag
    real*8 t_start, t_wall_now, t_wall_est, prop_done, old_height
    integer n_time, i_time, i_time_start, pre_i_time, i_state, i_summary
    character*100 filename
    type(bin_grid_t) :: restart_bin_grid
    type(aero_data_t) :: restart_aero_data
    type(gas_data_t) :: restart_gas_data

    rank = pmc_mpi_rank() ! MPI process rank (0 is root)

    i_time = 0
    i_summary = 1
    i_state = 1
    time = 0d0
    n_coag = 0
    tot_n_samp = 0
    tot_n_coag = 0
    
    if (mc_opt%do_restart) then
#ifdef PMC_USE_MPI
       if (rank == 0) then
          write(0,*) 'ERROR: restarting not currently supported with MPI'
          call pmc_mpi_abort(1)
       end if
#endif
       call inout_read_state(mc_opt%restart_name, restart_bin_grid, &
            restart_aero_data, aero_state, restart_gas_data, gas_state, &
            env_state, time, pre_index, pre_del_t, pre_i_loop)
       ! FIXME: should we check whether bin_grid == restart_bin_grid, etc?
       i_time = nint(time / mc_opt%del_t)
       if (mc_opt%allow_double) then
          do while (aero_state_total_particles(aero_state) &
               < mc_opt%n_part_max / 2)
             call aero_state_double(aero_state)
          end do
       end if
       ! write data into output file so that it will look correct
       pre_time = 0d0
       last_output_time = pre_time
       call aero_state_to_binned(bin_grid, aero_data, aero_state, aero_binned)
       do pre_i_time = 0,(i_time - 1)
          call env_data_update_state(env_data, env_state, pre_time)
          if (mc_opt%t_output > 0d0) then
             call check_event(pre_time, mc_opt%del_t, mc_opt%t_output, &
                  last_output_time, do_output)
             if (do_output) then
                call die_msg(139423908, "not implemented")
             end if
          end if
          pre_time = pre_time + mc_opt%del_t
       end do
    end if

    call aero_state_to_binned(bin_grid, aero_data, aero_state, aero_binned)
    
    call est_k_max_binned(bin_grid, kernel, env_state, k_max)

    if (mc_opt%do_mosaic) then
       call mosaic_init(bin_grid, env_state, mc_opt%del_t)
    end if

    if (mc_opt%t_output > 0d0) then
       call output_processed_open(mc_opt%output_prefix, mc_opt%i_loop, ncid)
       call output_processed(ncid, process_spec_list, &
            bin_grid, aero_data, aero_state, gas_data, gas_state, &
            env_state, i_summary, time, mc_opt%t_output, mc_opt%i_loop)
    end if

    if (mc_opt%t_state > 0d0) then
       call inout_write_state(mc_opt%state_prefix, bin_grid, &
            aero_data, aero_state, gas_data, gas_state, env_state, i_state, &
            time, mc_opt%del_t, mc_opt%i_loop)
    end if

    t_start = time
    last_progress_time = time
    last_state_time = time
    last_output_time = time
    n_time = nint(mc_opt%t_max / mc_opt%del_t)
    i_time_start = nint(time / mc_opt%del_t) + 1
    do i_time = i_time_start,n_time

       time = dble(i_time) * mc_opt%del_t

       old_height = env_state%height
       call env_data_update_state(env_data, env_state, time)
       call env_state_update_gas_state(env_state, mc_opt%del_t, &
            old_height, gas_data, gas_state)
       call env_state_update_aero_state(env_state, mc_opt%del_t, &
            old_height, bin_grid, aero_data, aero_state, aero_binned)

       if (mc_opt%do_coagulation) then
          call mc_coag(kernel, bin_grid, aero_binned, env_state, aero_data, &
               aero_state, mc_opt, k_max, tot_n_samp, n_coag)
       end if
       tot_n_coag = tot_n_coag + n_coag

       if (mc_opt%do_condensation) then
          call condense_particles(bin_grid, aero_binned, env_state, &
               aero_data, aero_state, mc_opt%del_t)
       end if

       if (mc_opt%do_mosaic) then
          call mosaic_timestep(bin_grid, env_state, aero_data, &
               aero_state, aero_binned, gas_data, gas_state, time)
       end if

       call mc_mix(aero_data, aero_state, gas_data, gas_state, &
            aero_binned, env_state, bin_grid, mc_opt%mix_rate)
       
       ! if we have less than half the maximum number of particles then
       ! double until we fill up the array, and the same for halving
       if (mc_opt%allow_double) then
          do while (aero_state_total_particles(aero_state) &
               < mc_opt%n_part_max / 2)
             call aero_state_double(aero_state)
          end do
          do while (aero_state_total_particles(aero_state) &
               > mc_opt%n_part_max * 2)
             call aero_state_halve(aero_state, aero_binned, bin_grid)
          end do
       end if
    
       ! DEBUG: enable to check array handling
       ! call aero_state_check(bin_grid, aero_binned, aero_data, aero_state)
       ! DEBUG: end
       
       if (mc_opt%t_output > 0d0) then
          call check_event(time, mc_opt%del_t, mc_opt%t_output, &
               last_output_time, do_output)
          if (do_output) then
             i_summary = i_summary + 1
             call output_processed(ncid, process_spec_list, bin_grid, &
                  aero_data, aero_state, gas_data, gas_state, env_state, &
                  i_summary, time, mc_opt%t_output, mc_opt%i_loop)
          end if
       end if

       if (mc_opt%t_state > 0d0) then
          call check_event(time, mc_opt%del_t, mc_opt%t_state, &
               last_state_time, do_state)
          if (do_state) then
             i_state = i_state + 1
             call inout_write_state(mc_opt%state_prefix, bin_grid, &
                  aero_data, aero_state, gas_data, gas_state, env_state, &
                  i_state, time, mc_opt%del_t, mc_opt%i_loop)
          end if
       end if

       if (mc_opt%t_progress > 0d0) then
          if (rank == 0) then
             ! progress only printed from root process
             call check_event(time, mc_opt%del_t, mc_opt%t_progress, &
                  last_progress_time, do_progress)
             if (do_progress) then
                call cpu_time(t_wall_now)
                prop_done = (dble(mc_opt%i_loop - 1) + (time - t_start) &
                     / (mc_opt%t_max - t_start)) / dble(mc_opt%n_loop)
                t_wall_est = (1d0 - prop_done) / prop_done &
                     * (t_wall_now - mc_opt%t_wall_start)
                write(6,'(a6,a9,a9,a11,a9,a11,a10)') 'loop', 'time', &
                     'n_part', 'tot_n_samp', 'n_coag', 'tot_n_coag', 't_est'
                write(6,'(i6,f9.1,i9,i11,i9,i11,f10.0)') mc_opt%i_loop, time, &
                     aero_state_total_particles(aero_state), tot_n_samp, &
                     n_coag, tot_n_coag, t_wall_est
             end if
          end if
       end if
       
    enddo

    if (mc_opt%t_output > 0d0) then
       call output_processed_close(ncid)
    end if

    if (mc_opt%do_mosaic) then
       call mosaic_cleanup()
    end if

  end subroutine run_mc
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Do coagulation for time del_t.
  subroutine mc_coag(kernel, bin_grid, aero_binned, env_state, aero_data, &
       aero_state, mc_opt, k_max, tot_n_samp, n_coag)

    !> Bin grid.
    type(bin_grid_t), intent(in) :: bin_grid
    !> Binned distributions.
    type(aero_binned_t), intent(out) :: aero_binned
    !> Environment state.
    type(env_state_t), intent(inout) :: env_state
    !> Aerosol data.
    type(aero_data_t), intent(in) :: aero_data
    !> Aerosol state.
    type(aero_state_t), intent(inout) :: aero_state
    !> Monte Carlo options.
    type(run_mc_opt_t), intent(in) :: mc_opt
    !> Maximum kernel.
    real*8, intent(in) :: k_max(bin_grid%n_bin,bin_grid%n_bin)
    !> Total number of samples tested.
    integer, intent(out) :: tot_n_samp
    !> Number of coagulation events.
    integer, intent(out) :: n_coag

    interface
       subroutine kernel(v1, v2, env_state, k)
         use pmc_env_state
         real*8, intent(in) :: v1
         real*8, intent(in) :: v2
         type(env_state_t), intent(in) :: env_state   
         real*8, intent(out) :: k
       end subroutine kernel
    end interface
    
    logical did_coag
    integer i, j, n_samp, i_samp, M
    real*8 n_samp_real

    tot_n_samp = 0
    n_coag = 0
    do i = 1,bin_grid%n_bin
       do j = 1,bin_grid%n_bin
          call compute_n_samp(aero_state%bin(i)%n_part, &
               aero_state%bin(j)%n_part, i == j, k_max(i,j), &
               aero_state%comp_vol, mc_opt%del_t, n_samp_real)
          ! probabalistically determine n_samp to cope with < 1 case
          n_samp = prob_round(n_samp_real)
          tot_n_samp = tot_n_samp + n_samp
          do i_samp = 1,n_samp
             M = aero_state_total_particles(aero_state)
             ! check we still have enough particles to coagulate
             if ((aero_state%bin(i)%n_part < 1) &
                  .or. (aero_state%bin(j)%n_part < 1) &
                  .or. ((i == j) .and. (aero_state%bin(i)%n_part < 2))) then
                exit
             end if
             call maybe_coag_pair(bin_grid, aero_binned, env_state, &
                  aero_data, aero_state, i, j, mc_opt%del_t, k_max(i,j), &
                  kernel, did_coag)
             if (did_coag) n_coag = n_coag + 1
          enddo
       enddo
    enddo

  end subroutine mc_coag

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Compute the number of samples required for the pair of bins.
  subroutine compute_n_samp(ni, nj, same_bin, k_max, comp_vol, &
       del_t, n_samp_real)

    !> Number particles in first bin .
    integer, intent(in) :: ni
    !> Number particles in second bin.
    integer, intent(in) :: nj
    !> Whether first bin is second bin.
    logical, intent(in) :: same_bin
    !> Maximum kernel value.
    real*8, intent(in) :: k_max
    !> Computational volume (m^3).
    real*8, intent(in) :: comp_vol
    !> Timestep (s).
    real*8, intent(in) :: del_t
    !> Number of samples per timestep.
    real*8, intent(out) :: n_samp_real
    
    real*8 r_samp
    real*8 n_possible ! use real*8 to avoid integer overflow
    ! FIXME: should use integer*8 or integer(kind = 8)
    
    if (same_bin) then
       n_possible = dble(ni) * (dble(nj) - 1d0) / 2d0
    else
       n_possible = dble(ni) * dble(nj) / 2d0
    endif
    
    r_samp = k_max / comp_vol * del_t
    n_samp_real = r_samp * n_possible
    
  end subroutine compute_n_samp
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Mix data between processes.
  subroutine mc_mix(aero_data, aero_state, gas_data, gas_state, &
       aero_binned, env_state, bin_grid, mix_rate)

    !> Aerosol data.
    type(aero_data_t), intent(in) :: aero_data
    !> Aerosol state.
    type(aero_state_t), intent(inout) :: aero_state
    !> Gas data.
    type(gas_data_t), intent(in) :: gas_data
    !> Gas state.
    type(gas_state_t), intent(inout) :: gas_state
    !> Binned aerosol data.
    type(aero_binned_t), intent(inout) :: aero_binned
    !> Environment.
    type(env_state_t), intent(inout) :: env_state
    !> Bin grid.
    type(bin_grid_t), intent(in) :: bin_grid
    !> Amount to mix (0 to 1).
    real*8, intent(in) :: mix_rate

    call assert(173605827, (mix_rate >= 0d0) .and. (mix_rate <= 1d0))
    if (mix_rate == 0d0) return

    call aero_state_mix(aero_state, mix_rate, &
         aero_binned, aero_data, bin_grid)
    call gas_state_mix(gas_state)
    call env_state_mix(env_state)
    
  end subroutine mc_mix

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Determines the number of bytes required to pack the given value.
  integer function pmc_mpi_pack_size_mc_opt(val)

    !> Value to pack.
    type(run_mc_opt_t), intent(in) :: val

    pmc_mpi_pack_size_mc_opt = &
         pmc_mpi_pack_size_integer(val%n_part_max) &
         + pmc_mpi_pack_size_real(val%t_max) &
         + pmc_mpi_pack_size_real(val%t_output) &
         + pmc_mpi_pack_size_real(val%t_state) &
         + pmc_mpi_pack_size_real(val%t_progress) &
         + pmc_mpi_pack_size_real(val%del_t) &
         + pmc_mpi_pack_size_string(val%output_prefix) &
         + pmc_mpi_pack_size_string(val%state_prefix) &
         + pmc_mpi_pack_size_logical(val%do_coagulation) &
         + pmc_mpi_pack_size_logical(val%allow_double) &
         + pmc_mpi_pack_size_logical(val%do_condensation) &
         + pmc_mpi_pack_size_logical(val%do_mosaic) &
         + pmc_mpi_pack_size_logical(val%do_restart) &
         + pmc_mpi_pack_size_string(val%restart_name) &
         + pmc_mpi_pack_size_integer(val%i_loop) &
         + pmc_mpi_pack_size_integer(val%n_loop) &
         + pmc_mpi_pack_size_real(val%t_wall_start) &
         + pmc_mpi_pack_size_real(val%mix_rate)

  end function pmc_mpi_pack_size_mc_opt

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Packs the given value into the buffer, advancing position.
  subroutine pmc_mpi_pack_mc_opt(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(run_mc_opt_t), intent(in) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_pack_integer(buffer, position, val%n_part_max)
    call pmc_mpi_pack_real(buffer, position, val%t_max)
    call pmc_mpi_pack_real(buffer, position, val%t_output)
    call pmc_mpi_pack_real(buffer, position, val%t_state)
    call pmc_mpi_pack_real(buffer, position, val%t_progress)
    call pmc_mpi_pack_real(buffer, position, val%del_t)
    call pmc_mpi_pack_string(buffer, position, val%output_prefix)
    call pmc_mpi_pack_string(buffer, position, val%state_prefix)
    call pmc_mpi_pack_logical(buffer, position, val%do_coagulation)
    call pmc_mpi_pack_logical(buffer, position, val%allow_double)
    call pmc_mpi_pack_logical(buffer, position, val%do_condensation)
    call pmc_mpi_pack_logical(buffer, position, val%do_mosaic)
    call pmc_mpi_pack_logical(buffer, position, val%do_restart)
    call pmc_mpi_pack_string(buffer, position, val%restart_name)
    call pmc_mpi_pack_integer(buffer, position, val%i_loop)
    call pmc_mpi_pack_integer(buffer, position, val%n_loop)
    call pmc_mpi_pack_real(buffer, position, val%t_wall_start)
    call pmc_mpi_pack_real(buffer, position, val%mix_rate)
    call assert(946070052, &
         position - prev_position == pmc_mpi_pack_size_mc_opt(val))
#endif

  end subroutine pmc_mpi_pack_mc_opt

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  !> Unpacks the given value from the buffer, advancing position.
  subroutine pmc_mpi_unpack_mc_opt(buffer, position, val)

    !> Memory buffer.
    character, intent(inout) :: buffer(:)
    !> Current buffer position.
    integer, intent(inout) :: position
    !> Value to pack.
    type(run_mc_opt_t), intent(out) :: val

#ifdef PMC_USE_MPI
    integer :: prev_position

    prev_position = position
    call pmc_mpi_unpack_integer(buffer, position, val%n_part_max)
    call pmc_mpi_unpack_real(buffer, position, val%t_max)
    call pmc_mpi_unpack_real(buffer, position, val%t_output)
    call pmc_mpi_unpack_real(buffer, position, val%t_state)
    call pmc_mpi_unpack_real(buffer, position, val%t_progress)
    call pmc_mpi_unpack_real(buffer, position, val%del_t)
    call pmc_mpi_unpack_string(buffer, position, val%output_prefix)
    call pmc_mpi_unpack_string(buffer, position, val%state_prefix)
    call pmc_mpi_unpack_logical(buffer, position, val%do_coagulation)
    call pmc_mpi_unpack_logical(buffer, position, val%allow_double)
    call pmc_mpi_unpack_logical(buffer, position, val%do_condensation)
    call pmc_mpi_unpack_logical(buffer, position, val%do_mosaic)
    call pmc_mpi_unpack_logical(buffer, position, val%do_restart)
    call pmc_mpi_unpack_string(buffer, position, val%restart_name)
    call pmc_mpi_unpack_integer(buffer, position, val%i_loop)
    call pmc_mpi_unpack_integer(buffer, position, val%n_loop)
    call pmc_mpi_unpack_real(buffer, position, val%t_wall_start)
    call pmc_mpi_unpack_real(buffer, position, val%mix_rate)
    call assert(480118362, &
         position - prev_position == pmc_mpi_pack_size_mc_opt(val))
#endif

  end subroutine pmc_mpi_unpack_mc_opt

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
end module pmc_run_mc