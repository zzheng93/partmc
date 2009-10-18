# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set xlabel "time (s)"
set ylabel "relative humidity (1)"
set y2label "aerosol water mass concentration (kg/m^3)"

set key bottom right

set ytics nomirror
set y2tics

plot "true_env.txt" using 1:3 axes x1y1 with lines title "true relative humidity", \
     "out/condense_env.txt" using 1:3 axes x1y1 with points title "relative humidity", \
     "true_aero_species.txt" using 1:21 axes x1y2 with lines title "true aerosol water", \
     "out/condense_aero_species.txt" using 1:21 axes x1y2 with points title "aerosol water"
