
raster=data/Dataset_SONNENLAND/Radiation/tilt_30_summer_2056.tif
tempdir=data-intermediate


# working with multiple values does not seem to work
#te=$(gdalinfo $rasterdir/tilt_30_summer_2056.tif -json | jq -r '.cornerCoordinates | " " + (.upperLeft[0]|tostring) + " " + (.lowerLeft[1]|tostring) + " " + (.lowerRight[0]|tostring) + " " + (.upperRight[1]|tostring)')
#tr=$(gdalinfo $rasterdir/tilt_30_summer_2056.tif | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{printf("%1.0f %1.0f\n", $1, $2)}')
xmin=$(gdalinfo $raster -json | jq -r .cornerCoordinates | jq -r ".lowerLeft[0]")
ymin=$(gdalinfo $raster -json | jq -r .cornerCoordinates | jq -r ".lowerLeft[1]")
xmax=$(gdalinfo $raster -json | jq -r .cornerCoordinates | jq -r ".upperRight[0]")
ymax=$(gdalinfo $raster -json | jq -r .cornerCoordinates | jq -r ".upperRight[1]")

xres=$(gdalinfo $raster | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
yres=$(gdalinfo $raster | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')

## Agriculture #################################################################

lwb=data/Dataset_SONNENLAND/Classification/Agricultural/Farming_most_cantons/shapefiles/lwb_perimeter_ln_sf/perimeter_ln_sf.shp
lwb2=data/Dataset_SONNENLAND/Classification/Agricultural/farming_ar_nw_ow_vd/geopackage/lwb_perimeter_ln_sf_lv95.gpkg




# for the full datasets
temprast1=$tempdir/perimeter_ln_sf.tif
temprast2=$tempdir/summer_perimeter_ln_sf.tif
description="all values"
gdal_rasterize -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres $lwb $temprast1
gdal_rasterize -burn 1 $lwb2 $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"
echo $description", " $(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}') > $tempdir/summer_perimeter_ln_sf_mean.txt



# for the individual datasets
temprast1=$tempdir/perimeter_ln_sf2.tif
temprast2=$tempdir/summer_perimeter_ln_sf2.tif
description="Landwirtschaftliche Nutzfläche"
sql="SELECT * FROM perimeter_ln_sf WHERE "typ" = 'Landwirtschaftliche Nutzfläche'"
# the following lines are pretty identical to the above. Differenes:
# - the sql statement
# - the output is appended to the existing file
gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres $lwb $temprast1
gdal_rasterize -sql $sql -burn 1 $lwb2 $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"
echo $description", " $(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}') >> $tempdir/summer_perimeter_ln_sf_mean.txt

temprast1=$tempdir/perimeter_ln_sf3.tif
temprast2=$tempdir/summer_perimeter_ln_sf3.tif
description="Sömmerungsgebiet"
sql="SELECT * FROM perimeter_ln_sf WHERE "typ" = 'Sömmerungsgebiet'"
# the following lines are identical to the above. 
gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres $lwb $temprast1
gdal_rasterize -sql $sql -burn 1 $lwb2 $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"
echo $description", " $(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}') >> $tempdir/summer_perimeter_ln_sf_mean.txt


# this is for both datasts and subsets
ogr2ogr -dialect sqlite -sql "SELECT typ, SUM(flaeche_m2) as flaeche_m2, 'lwb1' as file FROM perimeter_ln_sf GROUP BY typ " $tempdir/lwb1_summary.csv $lwb
ogr2ogr -dialect sqlite -sql "SELECT typ, SUM(flaeche_m2) as flaeche_m2, 'lwb2' as file FROM perimeter_ln_sf GROUP BY typ " $tempdir/lwb2_summary.csv $lwb2


## Roads #######################################################################

roads=data/Dataset_SONNENLAND/Classification/ROADS/swissTLM3D_TLM_STRASSE.shp
temprast1=$tempdir/roads_bund.tif
temprast2=$tempdir/summer_roads_bund.tif3
tempgpkg=$tempdir/roads_bund.gpkg
sql="SELECT buff.geom, ST_AREA(buff.geom) as area_m2 FROM (SELECT ST_UNION(ST_BUFFER(geometry, 10)) as geom FROM swissTLM3D_TLM_STRASSE WHERE EIGENTUEME = 'Bund') buff"
description="Bundesstrassen"

ogr2ogr -dialect sqlite -sql $sql $tempgpkg $roads -nln roads_bund
gdal_rasterize -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres $tempgpkg $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

echo $description", " $(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}') > $tempdir/summer_road_mean.txt
ogr2ogr $tempgpkg.csv $tempgpkg 