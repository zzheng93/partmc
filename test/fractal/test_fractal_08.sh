#!/bin/bash

# exit on error
set -e
# turn on command echoing
set -v
# make sure that the current directory is the one where this script is
cd ${0%/*}
# make the output directory if it doesn't exist
mkdir -p out

../../partmc run_part_vemury_cont_df_1_8.spec

../../test_fractal_self_preserve --num --dimless_vol_min 1e-3 --dimless_vol_max 10 --nbin 100 out/part_vemury_cont_df_1_8_0001

../../numeric_diff --by col --rel-tol 0.1 ref_cont_df_1_8_self_preserve_regrid.txt out/part_vemury_cont_df_1_8_0001_self_preserve.txt