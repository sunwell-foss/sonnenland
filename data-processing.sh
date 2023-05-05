
# Calculated outside R for speed

# This process takes approx 1 - 2h
# The code was not run as it's written here, I've cleaned it up a little
rasterdir=data/Dataset_SONNENLAND/Radiation
lwbdir=data/Dataset_SONNENLAND/Classification/Agricultural/Farming_most_cantons/shapefiles/lwb_perimeter_ln_sf
intermediatedir=data-intermediate
pkextractogr -i $rasterdir/tilt_30_summer_2056.tif -s $lwbdir/perimeter_ln_sf.shp -r mean -f CSV -o $intermediatedir/lwb_summer_mean.csv


# The above computation caused many warnings (maxed out at 1'000):
# TopologyException: side location conflict at 2634055.9960000003 1201497.003. This can occur if the input geometry is invalid.
# More than 1000 errors or warnings have been reported. No more will be reported from now.
# it might be wise to transform to geopackage and makevalid?
