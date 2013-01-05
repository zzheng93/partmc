#!/usr/bin/env python

import sys, os
sys.path.append("../../../tool")
import mpl_helper
import partmc
import scipy.io, numpy

for (filename, index) in partmc.get_filename_list('out/', r'urban_plume_([0-9]+)_process\.nc'):
    (figure, axes) = mpl_helper.make_fig(right_margin=0.8)

    ncf = scipy.io.netcdf_file(filename)
    entropy = ncf.variables["entropy"].data
    entropy_dist = ncf.variables["entropy_dist"].data
    entropy_err = ncf.variables["entropy_dist_ci_offset"].data


    axes.plot(entropy, entropy_dist/entropy_dist.max())
    axes.set_xlabel(r"entropy")
    axes.set_ylabel(r"norm. num. conc.")
    axes.set_xlim(0,2)
#   axes.set_ylim(0, 1)
    axes.grid(True)

    out_filename = "out/urban_plume_entropy_dist_%s.pdf" % index
    figure.savefig(out_filename)
    print out_filename