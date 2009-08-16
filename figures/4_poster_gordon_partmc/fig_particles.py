#!/usr/bin/env python
# Copyright (C) 2007-2009 Matthew West
# Licensed under the GNU General Public License version 2 or (at your
# option) any later version. See the file COPYING for details.

import os, sys, math, re
import copy as module_copy
from Scientific.IO.NetCDF import *
from pyx import *
sys.path.append("../../tool")
from pmc_data_nc import *
from pmc_pyx import *
import numpy
sys.path.append(".")
from fig_helper import *

out_prefix = "figs/particles"
data_prefix = "data/particles"

aero_species = [
    {"label": "", "species": ["BC"],
     "style": style.linestyle.dashed, "thickness": style.linewidth.thick,
     "color": color_list[0]},
    {"label": "", "species": ["OC"],
     "style": style.linestyle.dashed, "thickness": style.linewidth.THick,
     "color": color_list[1]},
    {"label": "", "species": ["NO3"],
     "style": style.linestyle.solid, "thickness": style.linewidth.THick,
     "color": color_list[2]},
    {"label": "", "species": ["NH4"],
     "style": style.linestyle.dotted, "thickness": style.linewidth.THick,
     "color": color_list[3]},
    {"label": "", "species": ["SO4"],
     "style": style.linestyle.dotted, "thickness": style.linewidth.thick,
     "color": color_list[4]},
    {"label": "SOA", "species": ["ARO1", "ARO2", "ALK1", "OLE1"],
     "style": style.linestyle.dashdotted, "thickness": style.linewidth.thick,
     "color": color_list[5]},
    {"label": "", "species": ["H2O"],
     "style": style.linestyle.solid, "thickness": style.linewidth.thick,
     "color": color.gray.black},
    ]

aero_data = read_any(aero_data_t, netcdf_dir_wc, netcdf_pattern_wc)

particle_ids = [p["id"] for p in show_particles]

plot_data_list = {}
for id in particle_ids:
    filename = "%s_%d.txt" % (data_prefix, id)
    data = loadtxt(filename)
    times = data[:,0] / 60.0
    comp_vols = data[:,1]
    masses = data[:,2:]
    pd = []
    for line in aero_species:
        mass = zeros(size(masses,0))
        for s in line["species"]:
            mass += masses[:, aero_data.name.index(s)]
        mass *= 1e21
        pd.append(zip(times, mass))
    plot_data_list[id] = pd

env_state = read_any(env_state_t, netcdf_dir_wc, netcdf_pattern_wc)
start_time_of_day_min = env_state.start_time_of_day / 60
max_time_min = max([max([max([time for (time, vaue) in line])
                          for line in pd])
                    for (id, pd) in plot_data_list.iteritems()])

for use_color in [True, False]:
    c = canvas.canvas()

    graphs = {}

    graphs[0] = c.insert(graph.graphxy(
        width = 6.4,
        x = graph.axis.linear(min = 0,
                              max = max_time_min,
                              title = r'local standard time (LST) (hours:minutes)',
                              parter = graph.axis.parter.linear(tickdists
                                                                = [6 * 60,
                                                                   3 * 60]),
                              texter = time_of_day(base_time
                                                   = start_time_of_day_min),
                              painter = grid_painter),
        y = graph.axis.log(min = 1e-2,
                           max = 1e4,
                           title = r"mass ($\rm ag$)",
                           painter = grid_painter)))

    for i in range(1, len(show_particles)):
        if i == len(show_particles) / 2:
            key = graph.key.key(pos = "tc", vinside = 0,
                                columns = len(aero_species))
            #symbolwidth = unit.v_cm)
        else:
            key = None
        graphs[i] = c.insert(graph.graphxy(
            width = 6.4,
            xpos = graphs[i-1].xpos + graphs[i-1].width + 1.0,
            x = graph.axis.linear(min = 0,
                                  max = max_time_min,
                                  title = r'local standard time (LST) (hours:minutes)',
                                  parter = graph.axis.parter.linear(tickdists
                                                                    = [6 * 60,
                                                                       3 * 60]),
                                  texter = time_of_day(base_time
                                                       = start_time_of_day_min),
                                  painter = grid_painter),
            y = graph.axis.linkedaxis(graphs[i-1].axes["y"],
                                      painter = linked_grid_painter),
            key = key))

    for i in range(len(show_particles)):
        #g = graphs[len(show_particles) - i - 1]
        g = graphs[i]

        plot_data = plot_data_list[show_particles[i]["id"]]
        for s in range(len(aero_species)):
            plot_data[s] = [[time, value] for [time, value] in plot_data[s]
                            if value > 0.0]
            if aero_species[s]["label"] == "":
                label = tex_species(aero_species[s]["species"][0])
            else:
                label = aero_species[s]["label"]
            if len(plot_data[s]) > 0:
                if use_color:
                    attrs = [aero_species[s]["color"],
                             style.linewidth.thick]
                else:
                    attrs = [aero_species[s]["style"],
                             aero_species[s]["thickness"]]
                g.plot(graph.data.points(plot_data[s], x = 1, y = 2, title = label),
                       styles = [graph.style.line(lineattrs = attrs)])

        min_time_min = min([plot_data[s][0][0] for s in range(len(aero_species))])
        if not use_color:
            print "%s emitted at %s LST" \
                  % (show_particles[i]["label"],
                     time_of_day_string(min_time_min * 60
                                        + env_state.start_time_of_day))

        g.doaxes()
        g.dodata()

        write_text_inside(g, show_particles[i]["box label"])

    if use_color:
        out_filename = "%s_color.pdf" % out_prefix
    else:
        out_filename = "%s_bw.pdf" % out_prefix
    c.writePDFfile(out_filename)
    if not use_color:
        print "figure height = %.1f cm" % unit.tocm(c.bbox().height())
        print "figure width = %.1f cm" % unit.tocm(c.bbox().width())
