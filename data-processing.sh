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
echo "dataset, mean_value, perc_valid, pixelsize_x, pixelsize_y, rastersize_x, rastersize_y" > $tempdir/mean_values.txt


## Agriculture #################################################################


###### Regular Farmland ########################################################

lwb=data/Dataset_SONNENLAND/Classification/Agricultural/Farming_most_cantons/shapefiles/lwb_perimeter_ln_sf/perimeter_ln_sf.shp
lwb2=data/Dataset_SONNENLAND/Classification/Agricultural/farming_ar_nw_ow_vd/geopackage/lwb_perimeter_ln_sf_lv95.gpkg
lwb3=data/TI_153-1_Nutzungsfla/TI_153-1_Nutzungsfla.gpkg

tlm_wald=data/swisstlm3d_2023-03_2056_5728/SWISSTLM3D_2023_LV95_LN02.gpkg
sql_tlm_wald="SELECT * FROM tlm_bb_bodenbedeckung WHERE \"objektart\" = 'Wald' OR \"objektart\" = 'Wald offen'"

# for the individual datasets
temprast1=$tempdir/perimeter_ln_sf2.tif
temprast2=$tempdir/summer_perimeter_ln_sf2.tif
description="Regular Farmland"
sql="SELECT * FROM perimeter_ln_sf WHERE \"typ\" = 'Landwirtschaftliche Nutzfläche'"
sql_ti="SELECT * FROM TI_153_1_Nutzungsfla WHERE \"COLTURA\" != 'Pascoli d''estivazione'"


gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $lwb $temprast1
gdal_rasterize -sql $sql -burn 1 $lwb2 $temprast1
gdal_rasterize -sql $sql_ti -burn 1 $lwb3 $temprast1
# burn AR will go here
gdal_rasterize -sql $sql_tlm_wald -burn 255 $tlm_wald $temprast1

gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

pkinfo -stats -i $temprast2 
meanval=$(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}')
perc_valid=$(gdalinfo -stats $temprast2 | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
pixelsize_x=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
pixelsize_y=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
rastersize_x=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
rastersize_y=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')

echo $description", " $meanval", " $perc_valid", " $pixelsize_x", " $pixelsize_x", " $rastersize_x", " $rastersize_y >> $tempdir/mean_values.txt


###### Summer Grazing Land #####################################################

temprast1=$tempdir/perimeter_ln_sf3.tif
temprast2=$tempdir/summer_perimeter_ln_sf3.tif
description="Summer Grazing Land"
sql="SELECT * FROM perimeter_ln_sf WHERE \"typ\" = 'Sömmerungsgebiet'"
sql_ti="SELECT * FROM TI_153_1_Nutzungsfla WHERE \"COLTURA\" = 'Pascoli d''estivazione'"

# the following lines are identical to the above. 
gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $lwb $temprast1
gdal_rasterize -sql $sql -burn 1 $lwb2 $temprast1
gdal_rasterize -sql $sql_ti -burn 1 $lwb3 $temprast1
# burn AR will go here
gdal_rasterize -sql $sql_tlm_wald -burn 255 $tlm_wald $temprast1

gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

pkinfo -stats -i $temprast2 
meanval=$(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}')
perc_valid=$(gdalinfo -stats $temprast2 | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
pixelsize_x=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
pixelsize_y=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
rastersize_x=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
rastersize_y=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')

echo $description", " $meanval", " $perc_valid", " $pixelsize_x", " $pixelsize_x", " $rastersize_x", " $rastersize_y >> $tempdir/mean_values.txt


## this is for both datasts and subsets
#ogr2ogr -dialect sqlite -sql "SELECT typ, SUM(flaeche_m2) as flaeche_m2, 'lwb1' as file FROM perimeter_ln_sf GROUP BY typ " $tempdir/lwb1_summary.csv $lwb
#ogr2ogr -dialect sqlite -sql "SELECT typ, SUM(flaeche_m2) as flaeche_m2, 'lwb2' as file FROM perimeter_ln_sf GROUP BY typ " $tempdir/lwb2_summary.csv $lwb2


## Roads #######################################################################

roads=data/Dataset_SONNENLAND/Classification/ROADS/swissTLM3D_TLM_STRASSE.shp
temprast1=$tempdir/roads_bund.tif
temprast2=$tempdir/summer_roads_bund.tif
tempgpkg=$tempdir/roads_bund.gpkg
sql="SELECT buff.geom, ST_AREA(buff.geom) as area_m2 FROM (SELECT ST_UNION(ST_BUFFER(geometry, 10)) as geom FROM swissTLM3D_TLM_STRASSE WHERE EIGENTUEME = 'Bund') buff"
description="National Roads"

ogr2ogr -dialect sqlite -sql $sql $tempgpkg $roads -nln roads_bund
gdal_rasterize -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

pkinfo -stats -i $temprast2 
meanval=$(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}')
perc_valid=$(gdalinfo -stats $temprast2 | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
pixelsize_x=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
pixelsize_y=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
rastersize_x=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
rastersize_y=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')


echo $description", " $meanval", " $perc_valid", " $pixelsize_x", " $pixelsize_x", " $rastersize_x", " $rastersize_y >> $tempdir/mean_values.txt

#ogr2ogr $tempgpkg.csv $tempgpkg 



## Standing Water ##############################################################

standingwater=data/Dataset_SONNENLAND/Classification/Standing_Water/stehende_gewaesser_merged.gpkg
dams=data/Dataset_SONNENLAND/Classification/DAMS/OBJEKTART_Staumauer.shp
swissboundaries=data/swissBOUNDARIES3D_1_4_LV95_LN02.gpkg
temprast1=$tempdir/water_artificial.tif
temprast2=$tempdir/summer_water_artificial.tif
tempgpkg=$tempdir/water_merged.gpkg

###### Reservoirs ##############################################################

description="Standing Water (Reservoirs)"
sql="SELECT standingwater.* FROM standingwater2, dams WHERE st_intersects(standingwater.geom, dams.geom)"

ogr2ogr -sql "SELECT * FROM stehende_gewaesser WHERE St_area(geom) > 10000" -nln standingwater $tempgpkg $standingwater
ogr2ogr -nln dams -update $tempgpkg $dams
ogr2ogr -sql "SELECT St_union(Shape) as geom FROM TLM_LANDESGEBIET WHERE \"NAME\" != 'Liechtenstein'" -nln switzerland -update $tempgpkg $swissboundaries
# the following takes a long time!
ogr2ogr -sql "SELECT St_intersection(standingwater.geom, switzerland.geom) FROM standingwater, switzerland WHERE St_intersects(standingwater.geom, switzerland.geom)" -nln standingwater2 -nlt MULTIPOLYGON -update $tempgpkg $tempgpkg



gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

pkinfo -stats -i $temprast2 
meanval=$(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}')
perc_valid=$(gdalinfo -stats $temprast2 | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
pixelsize_x=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
pixelsize_y=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
rastersize_x=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
rastersize_y=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')

echo $description", " $meanval", " $perc_valid", " $pixelsize_x", " $pixelsize_x", " $rastersize_x", " $rastersize_y >> $tempdir/mean_values.txt



###### Natural #################################################################


description="Standing Water (Natural)"
sql="SELECT standingwater.* FROM standingwater2, dams WHERE NOT st_intersects(standingwater.geom, dams.geom)"

gdal_rasterize -sql $sql -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1
gdal_calc.py -A $raster -B $temprast1 --outfile=$temprast2 --calc="A*B"

pkinfo -stats -i $temprast2 
meanval=$(gdalinfo -stats $temprast2 | grep STATISTICS_MEAN | awk -F= '{print $2}')
perc_valid=$(gdalinfo -stats $temprast2 | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
pixelsize_x=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
pixelsize_y=$(gdalinfo $temprast2 | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
rastersize_x=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
rastersize_y=$(gdalinfo $temprast2 | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')

echo $description", " $meanval", " $perc_valid", " $pixelsize_x", " $pixelsize_x", " $rastersize_x", " $rastersize_y >> $tempdir/mean_values.txt


