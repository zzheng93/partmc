
PartMC
======

PartMC: Particle-resolved Monte Carlo code for atmospheric aerosol simulation

[![Latest version](https://img.shields.io/github/tag/compdyn/partmc.svg?label=version)](https://github.com/compdyn/partmc/blob/master/ChangeLog.md) [![Docker build status](https://img.shields.io/docker/automated/compdyn/partmc.svg)](https://hub.docker.com/r/compdyn/partmc/builds/) [![Build Status](https://img.shields.io/travis/compdyn/partmc/master.svg)](https://travis-ci.org/compdyn/partmc) [![License](https://img.shields.io/github/license/compdyn/partmc.svg)](https://github.com/compdyn/partmc/blob/master/COPYING) [![DOI](https://zenodo.org/badge/24058992.svg)](https://zenodo.org/badge/latestdoi/24058992)

Version 2.5.0 | Released 2018-11-17


<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Information](#information)
- [Usage](#usage)
- [Running PartMC with Docker](#running-partmc-with-docker)
- [Installation (local)](#installation-local)
- [Installation (Blue Waters)](#installation-blue-waters)
- [Installation (NCAR's Cheyenne)](#installation-ncars-cheyenne)

<!-- /code_chunk_output -->


## Information

**Source:** <https://github.com/compdyn/partmc>

**Homepage:** <http://lagrange.mechse.illinois.edu/partmc/>

**Cite as:** M. West, N. Riemer, J. Curtis, M. Michelotti, and J. Tian (2018) PartMC, [![version](https://img.shields.io/github/release/compdyn/partmc.svg?label=version)](https://github.com/compdyn/partmc), [![DOI](https://zenodo.org/badge/24058992.svg)](https://zenodo.org/badge/latestdoi/24058992)

Copyright (C) 2005-2018 Nicole Riemer and Matthew West  
Portions copyright (C) Andreas Bott, Richard Easter, Jeffrey Curtis, Matthew Michelotti, and Jian Tian  
Licensed under the GNU General Public License version 2 or (at your option) any later version.  
For details see the file COPYING or <http://www.gnu.org/licenses/old-licenses/gpl-2.0.html>.

**Dependencies**

Required dependencies:

   * Fortran 2003 compiler - <https://gcc.gnu.org/fortran/> or similar
   * CMake version 2.6.4 or higher - <http://www.cmake.org/>
   * NetCDF version 4.2 or higher -
     <http://www.unidata.ucar.edu/software/netcdf/>

Optional dependencies:

   * MOSAIC chemistry code version 2012-01-25 - Available from Rahul Zaveri - <Rahul.Zaveri@pnl.gov>
   * MPI parallel support - <http://www.open-mpi.org/>
   * GSL for random number generators - <http://www.gnu.org/software/gsl/>
   * SUNDIALS ODE solver version 2.6 for condensation support - <http://www.llnl.gov/casc/sundials/>
   * gnuplot for testcase plotting - <http://www.gnuplot.info/>

**References**

   * N. Riemer, M. West, R. A. Zaveri, and R. C. Easter (2009),
     Simulating the evolution of soot mixing state with a
     particle-resolved aerosol model, _J. Geophys. Res._ 114(D09202),
     <http://dx.doi.org/10.1029/2008JD011073>.
   * N. Riemer, M. West, R. A. Zaveri, and R. C. Easter (2010),
     Estimating black carbon aging time-scales with a
     particle-resolved aerosol model, _J. Aerosol Sci._ 41(1), 143-158,
     <http://dx.doi.org/10.1016/j.jaerosci.2009.08.009>.
   * R. A. Zaveri, J. C. Barnard, R. C. Easter, N. Riemer, and M. West
     (2010), Particle-resolved simulation of aerosol size,
     composition, mixing state, and the associated optical and cloud
     condensation nuclei activation properties in an evolving urban
     plume, _J. Geophys. Res._ 115(D17210),
     <http://dx.doi.org/10.1029/2009JD013616>.
   * R. E. L. DeVille, N. Riemer, and M. West, Weighted Flow
     Algorithms (WFA) for stochastic particle coagulation,
     _J. Comp. Phys._ 230(23), 8427-8451, 2011,
     <http://dx.doi.org/10.1016/j.jcp.2011.07.027>
   * J. Ching, N. Riemer, and M. West, Impacts of black carbon mixing
     state on black carbon nucleation scavenging: Insights from a
     particle-resolved model, _J. Geophys. Res._ 117(D23209), 2012,
     <http://dx.doi.org/10.1029/2012JD018269>
   * M. D. Michelotti, M. T. Heath, and M. West, Binning for efficient
     stochastic multiscale particle simulations, _Multiscale
     Model. Simul._ 11(4), 1071-1096, 2013,
     <http://dx.doi.org/10.1137/130908038>
   * N. Riemer and M. West, Quantifying aerosol mixing state with
     entropy and diversity measures, _Atmos. Chem. Phys._ 13,
     11423-11439, 2013, <http://dx.doi.org/10.5194/acp-13-11423-2013>
   * J. Tian, N. Riemer, M. West, L. Pfaffenberger, H. Schlager, and
     A. Petzold, Modeling the evolution of aerosol particles in a ship
     plume using PartMC-MOSAIC, _Atmos. Chem. Phys._ 14, 5327-5347,
     2014, <http://dx.doi.org/10.5194/acp-14-5327-2014>
   * R. M. Healy, N. Riemer, J. C. Wenger, M. Murphy, M. West,
     L. Poulain, A. Wiedensohler, I. P. O'Connor, E. McGillicuddy,
     J. R. Sodeau, and G. J. Evans, Single
     particle diversity and mixing state measurements,
     _Atmos. Chem. and Phys._ 14, 6289-6299,
     2014, <http://dx.doi.org/10.5194/acp-14-6289-2014>
   * J. H. Curtis, M. D. Michelotti, N. Riemer, M. Heath, and M. West,
     Accelerated simulation of stochastic particle removal processes
     in particle-resolved aerosol models, _J. Comp. Phys._ 322, 21-32,
     2016, <http://dx.doi.org/10.1016/j.jcp.2016.06.029>
   * J. Ching, N. Riemer, and M. West, Black carbon mixing state
     impacts on cloud microphysical properties: Effects of aerosol
     plume and environmental conditions, _J. Geophys. Res._ 121(10),
     5990-6013, 2016 <http://dx.doi.org/10.1002/2016JD024851>
   * J. Ching, J. Fast, M. West, and N. Riemer, Metrics to quantify
     the importance of mixing state for CCN activity, _Atmos.
     Chem. and Phys._ 17, 7445-7458, 2017
     <http://dx.doi.org/10.5194/acp-17-7445-2017>
   * J. Tian, B. T. Brem, M. West, T. C. Bond, M. J. Rood, and
     N. Riemer, Simulating aerosol chamber experiments with the
     particle-resolved aerosol model PartMC, _Aerosol Sci. Technol._
     51(7), 856-867, 2017
     <http://dx.doi.org/10.1080/02786826.2017.1311988>
   * J. H. Curtis, N. Riemer, and M. West, A single-column
     particle-resolved model for simulating the vertical distribution
     of aerosol mixing state: WRF-PartMC-MOSAIC-SCM v1.0,
     _Geosci. Model Dev._ 10, 4057-4079, 2017
     <http://dx.doi.org/10.5194/gmd-10-4057-2017>
   * J. Ching, M. West, and N. Riemer, Quantifying impacts of aerosol
     mixing state on nucleation-scavenging of black carbon aerosol
     particles, _Atmosphere_ 9(1), 17, 2018
     <http://dx.doi.org/10.3390/atmos9010017>
   * M. Hughes, J. K. Kodros, J. R. Pierce, M. West, and N. Riemer,
     Machine learning to predict the global distribution of aerosol
     mixing state metrics, _Atmosphere_ 9(1), 15, 2018
     <http://dx.doi.org/10.3390/atmos9010015>

## Usage 

The main `partmc` command reads `.spec` files and does the run specified therein. Either particle-resolved runs, sectional-code runs, or exact solutions can be generated. A run produces one NetCDF file per output timestep, containing per-particle data (from particle-resolved runs) or binned data (from sectional or exact runs). The `extract_*` programs can read these per-timestep NetCDF files and output ASCII data (the `extract_sectional_*` programs are used for sectional and exact model output).

## Running PartMC with Docker 

This is the fastest way to get running.

* **_Step 1:_** Install [Docker Community Edition](https://www.docker.com/community-edition).
    
  - On Linux and MacOS this is straightforward. [Download from here](https://store.docker.com/search?type=edition&offering=community).
  - On Windows the best version is [Docker Community Edition for Windows](https://store.docker.com/editions/community/docker-ce-desktop-windows), which requires Windows 10 Pro/Edu.
    
* **_Step 2:_** (Optional) Run the PartMC test suite with:

    ```bash
    docker run -it --rm compdyn/partmc bash -c 'cd /build; make test'
    ```

* **_Step 3:_** Run a scenario like the following. This example uses `partmc/scenarios/4_chamber`. This mounts the current directory (`$PWD`, replace with `%cd%` on Windows) into `/run` inside the container, changes into that directory, and then runs PartMC.

    ```bash
    cd partmc/scenarios/4_chamber
    docker run -it --rm -v $PWD:/run compdyn/partmc bash -c 'cd /run; /build/partmc chamber.spec'
    ```

In the above `docker run` command the arguments are:

- `-it`: activates "interactive" mode so Ctrl-C works to kill the command
- `--rm`: remove temporary docker container files after running
- `-v LOCAL:REMOTE`: mount the `LOCAL` directory to the `REMOTE` directory inside the container
- `compdyn/partmc`: the docker image to run
- `bash -c 'COMMAND'`: run `COMMAND` inside the docker container

The directory structure inside the docker container is:

    /partmc           # a copy of the partmc git source code repository
    /build            # the diretory in which partmc was compiled
    /build/partmc     # the compiled partmc executable
    /run              # the default diretory to run in

## Installation (local) 

Here we show how to install PartMC (or PartMC-MOSAIC) on your local machine.

**Step 1:** Install cmake and NetCDF (see above). The NetCDF libraries are required to compile PartMC. The `netcdf.mod` Fortran 90 module file is required, and it must be produced by the same compiler being used to compile PartMC.

**Step 2:** Unpack PartMC:

```bash
 tar xzvf partmc-2.5.0.tar.gz
```

**Step 3:** Change into the main PartMC directory (where this README file is located):

```bash
 cd partmc-2.5.0
```

**Step 4:** Make a directory called `build` and change into it:

```bash
 mkdir build
 cd build
```

**Step 5:** If desired, set environment variables to indicate the install locations of supporting libraries. If running `echo $SHELL` indicates that you are running `bash`, then you can do something like:

```bash
 export NETCDF_HOME=/
 export MOSAIC_HOME=${HOME}/mosaic-2012-01-25
 export SUNDIALS_HOME=${HOME}/opt
 export GSL_HOME=${HOME}/opt
```

Of course the exact directories will depend on where the libraries are installed. You only need to set variables for libraries installed in non-default locations, and only for those libraries you want to use. Everything except NetCDF is optional.

If `echo $SHELL` instead is `tcsh` or similar, then the environment variables can be set like `setenv NETCDF_HOME /` and similarly.

**Step 6:** Run cmake with the main PartMC directory as an argument (note the double-c):

```bash
 ccmake ..
```

**Step 7:** Inside ccmake press `c` to configure, edit the values as needed, press `c` again, then `g` to generate. Optional libraries can be activated by setting the `ENABLE` variable to `ON`. For a parallel build, toggle advanced mode with `t` and set the `CMAKE_Fortran_COMPILER` to `mpif90`, then reconfigure.

**Step 8:** Optionally, enable compiler warnings by pressing `t` inside ccmake to enable advanced options and then setting `CMAKE_Fortran_FLAGS` to:

```
 -O2 -g -fimplicit-none -W -Wall -Wconversion -Wunderflow -Wimplicit-interface -Wno-compare-reals -Wno-unused -Wno-unused-parameter -Wno-unused-dummy-argument -fbounds-check
```

**Step 9:** Compile PartMC and test it as follows. Some tests may fail due to bad random initial conditions, so re-run the tests a few times to see if failures persist.

```bash
 make
 make test
```

**Step 10:** To run just a single set of tests do something like:

```bash
 ctest -R bidisperse   # argument is a regexp for test names
```

**Step 11:** To see what make is doing run it like:

```
 VERBOSE=1 make
```

**Step 12:** To run tests with visible output or to make some plots from the tests run them as:

```bash
cd test_run/emission
./test_emission_1.sh
./test_emission_2.sh
./test_emission_3.sh            # similarly for other tests
gnuplot -persist plot_species.gnuplot # etc...
```

**Step 13:** To run full scenarios, do, for example:

```bash
 cd ../scenarios/1_urban_plume
 ./1_run.sh
```

## Installation (Blue Waters) 

Here we show how to install PartMC-MOSAIC on the HPC. We use the [Blue Waters](https://bluewaters.ncsa.illinois.edu/) as an example.

**Step 1:** Configure your environment in terms of setting up compilers and NetCDF. For Blue Waters users:

```bash
module swap PrgEnv-cray PrgEnv-gnu
module load gcc/6.3.0
module load cray-netcdf/4.4.1
module load cmake
module unload darshan
```

**Step 2:** Build MOSAIC chemistry (you need to have the permission to the MOSAIC software)

```bash
cd mosaic
```

- Move "Makefile.local.gfortran" to "Makefile.local"

```bash
mv Makefile.local.gfortran Makefile.local
```

- Makefile.local must use ftn as the Fortran compiler so change `FC = gfortran` to `FC = ftn`

- Build MOSAIC

```bash
make
```

**Step 3:** Build PartMC-MOSAIC

- Create a build directory and change into it from the partmc-2.4.0, partmc-2.5.0 or cloned directory.

```bash
git clone git@github.com:compdyn/partmc.git
cd partmc
mkdir build
cd build
```

- Set the `MOSAIC_HOME` variable to the path of where you have installed MOSAIC (you have to finished step 2)

```bash
export MOSAIC_HOME=/u/sciteam/your_id/mosaic
```

- Create a file `bluewaters.cmake` within the `build` fold. The file should contain the following:

```bash
set(CMAKE_BUILD_TYPE "RELEASE" CACHE STRING "")
set(ENABLE_MOSAIC ON CACHE BOOL "")
set(CMAKE_C_COMPILER "/opt/cray/craype/2.5.8/bin/cc" CACHE STRING "") 
set(CMAKE_Fortran_COMPILER "/opt/cray/craype/2.5.8/bin/ftn" CACHE STRING "") 
set(NETCDF_C_LIB "/opt/cray/netcdf/4.4.1/GNU/51/lib/libnetcdf.a" CACHE STRING "") 
set(NETCDF_FORTRAN_LIB "/opt/cray/netcdf/4.4.1/GNU/51/lib/libnetcdff.a" CACHE STRING "") 
set(NETCDF_INCLUDE_DIR "/opt/cray/netcdf/4.4.1/GNU/51/include" CACHE STRING "")
```

- Run CMake with the above settings

```bash
ccmake .. -P bluewaters.cmake
```

- Build PartMC-MOSAIC

```bash
make
```

**Step 4:** Test the build. Make sure you have the test cases such as "test_mosaic_1" and "test_mosaic_2" passed.

```bash
make test
```

## Installation (NCAR's Cheyenne)  

**Step 1:** Configure your environment in terms of setting up compilers and NetCDF.

```bash
module load gnu/9.1.0
module load netcdf/4.7.3
module load cmake
module unload darshan
```

**Step 2:** Build MOSAIC chemistry (you need to have the permission to the MOSAIC software)

```bash
cd /glade/work/zhonghua/mosaic
mv Makefile.local.gfortran Makefile.local
make
```

**Step 3:** Build PartMC-MOSAIC

```bash
cd /glade/work/zhonghua/
git clone git@github.com:compdyn/partmc.git
cd partmc
mkdir build
cd build
export MOSAIC_HOME=/glade/work/zhonghua/mosaic
ccmake ..
```

**First, press "c". Then press "e", and type the following options**:

```
CMAKE_BUILD_TYPE: RELEASE
ENABLE_MOSAIC: ON 
NETCDF_C_LIB: /glade/u/apps/ch/opt/netcdf/4.7.3/gnu/9.1.0/lib/libnetcdf.a 
NETCDF_FORTRAN_LIB: /glade/u/apps/ch/opt/netcdf/4.7.3/gnu/9.1.0/lib/libnetcdff.a 
NETCDF_INCLUDE_DIR: /glade/u/apps/ch/opt/netcdf/4.7.3/gnu/9.1.0/include
```

**Then press "c", then "c" again, and "g".**

Then make and make test:

```bash
make
make test
```

Make sure you have the test cases such as "test_mosaic_1" and "test_mosaic_2" passed.
