#!/usr/bin/env python
import sys
sys.path.append('../../tool/')
import subprocess
import os
import math
import numpy as np
import mpl_helper
import matplotlib.pyplot as plt

shape_opt = raw_input("Enter s for spherical, f for fractal:")

partmc_num = np.loadtxt("out/case_0161_wc_0001_aero_size_num.txt")
barrel_num = np.loadtxt("ref_aero_size_num_regrid.txt")
partmc_mass = np.loadtxt("out/case_0161_wc_0001_aero_size_mass.txt")
barrel_mass = np.loadtxt("ref_aero_size_mass_regrid.txt")

t = 0
if not os.path.exists("plots_aero_num_size"):
   os.mkdir("plots_aero_num_size")
for col in range(1,partmc_num.shape[1]):
    (figure, axes) = mpl_helper.make_fig(colorbar=False)
    axes.semilogx(barrel_num[:,0], barrel_num[:,col], color='r')
    axes.semilogx(partmc_num[:,0], partmc_num[:,col]*math.log(10), color='k')
    t = t + 1
    axes.set_title(r"time %02d" % (t))
    axes.set_xlabel("Diameter (m)")
    axes.set_ylabel(r"Number concentration ($\mathrm{m}^{-3}$)")
    axes.grid()
    axes.set_ylim(0, 1.05*max(partmc_num[:,1]*math.log(10)))
    axes.legend(('Barrel', 'PartMC'))
    filename_out = "plots_aero_num_size/aero_num_size_time%02d.pdf" %(t)
    figure.savefig(filename_out)

if not os.path.exists("plots_aero_mass_size"):
   os.mkdir("plots_aero_mass_size")

if shape_opt == 's':
   t = 0
   for col in range(1,partmc_mass.shape[1]):
       (figure, axes) = mpl_helper.make_fig(colorbar=False)
       axes.semilogx(barrel_mass[:,0], barrel_mass[:,col], color='r')
       axes.semilogx(partmc_mass[:,0], partmc_mass[:,col]*math.log(10), color='k')
       t = t + 1
       axes.set_title(r"time %02d" % (t))
       axes.set_xlabel("Diameter (m)")
       axes.set_ylabel(r"Mass concentration (kg $\mathrm{m}^{-3}$)")
       axes.grid()
       axes.set_ylim(0, 1.05*max(partmc_mass[:,1]*math.log(10)))
       axes.legend(('Barrel', 'PartMC'), loc='upper left')
       filename_out = "plots_aero_mass_size/aero_mass_size_time%02d.pdf" %(t)
       figure.savefig(filename_out)
if shape_opt == 'f':
   t = 0
   rho = 1760 # density in kgm-3
   for col in range(1,partmc_num.shape[1]):
       (figure, axes) = mpl_helper.make_fig(colorbar=False)
       axes.semilogx(barrel_num[:,0], barrel_num[:,col] * math.pi / 6. * rho * barrel_num[:,0]**3, color='r')
       axes.semilogx(partmc_num[:,0], partmc_num[:,col] * math.pi / 6. * rho * partmc_num[:,0]**3 * math.log(10), color='k')
       t = t + 1
       axes.set_title(r"time %02d" % (t))
       axes.set_xlabel("Diameter (m)")
       axes.set_ylabel(r"Mass concentration (kg $\mathrm{m}^{-3}$)")
       axes.grid()
       axes.set_ylim(0, 1.05*max(partmc_num[:,1] * math.pi / 6. * rho * partmc_num[:,0]**3 * math.log(10)))
       axes.legend(('Barrel', 'PartMC'), loc='upper left')
       filename_out = "plots_aero_mass_size/aero_mass_size_time%02d.pdf" %(t)
       figure.savefig(filename_out)