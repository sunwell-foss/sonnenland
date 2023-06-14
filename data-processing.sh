
# function to extract raster information and append it to a csv file. Usage:
# get_raster_info <raster> <csv> <dataset>
# <raster>: path to the raster file
# <csv>: path to the csv file (must exist)
# <dataset>: The dataset used
# <subset>: The subset used
get_raster_info() {
    inrast=$1
    outcsv=$2
    vector_dataset=$3
    subset=$4

    # without this line, the succeeding commands to produce wrong results
    pkinfo -stats -i $inrast 
    meanval=$(gdalinfo -stats $inrast | grep STATISTICS_MEAN | awk -F= '{print $2}')
    perc_valid=$(gdalinfo -stats $inrast | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
    pixelsize_x=$(gdalinfo $inrast | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
    pixelsize_y=$(gdalinfo $inrast | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
    rastersize_x=$(gdalinfo $inrast | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
    rastersize_y=$(gdalinfo $inrast | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')

    # get absolute value
    pixelsize_x=${pixelsize_x#-} 
    pixelsize_y=${pixelsize_y#-}

    inrast_basename=$(basename "$inrast")

    echo "${inrast_basename}, ${vector_dataset}, ${subset}, ${meanval}, ${perc_valid}, ${pixelsize_x}, ${pixelsize_x}, ${rastersize_x}, ${rastersize_y}" \
        >> $outcsv
}

# Get the area in m2 of all valid pixels in a raster file. Usage:
# get_raster_area <raster>
get_raster_area() {
    inrast=$1

    perc_valid=$(gdalinfo -stats $inrast | grep STATISTICS_VALID_PERCENT | awk -F= '{print $2}')
    pixelsize_x=$(gdalinfo $inrast | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
    pixelsize_y=$(gdalinfo $inrast | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
    rastersize_x=$(gdalinfo $inrast | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $1}')
    rastersize_y=$(gdalinfo $inrast | grep "Size is" | awk '{sub("Size is ", "")} 1' | awk -F',' '{print $2}')
    
    pixelsize_x=${pixelsize_x#-} 
    pixelsize_y=${pixelsize_y#-}

    area_raster=$(($rastersize_x * $rastersize_y * perc_valid / 100 * $pixelsize_x * $pixelsize_y))

    echo $area_raster
}

# Get the total area of a vector dataset usage:
# get_vector_area <vector> <layer> <geomfield>
get_vector_area(){
    invect=$1
    layer=$2
    geomfield=$3

    sql="SELECT Sum(area_m2) as area_m2 from (SELECT St_area(${geomfield}) as area_m2 from ${layer}) tmp"
    
    area_vector=$(ogrinfo $invect -sql $sql | grep "area_m2 (Real) =" | awk '{sub("area_m2 \\(Real\\) = ", "")} 1')

    echo $area_vector
}


basename_noext(){
    filename=$1

    basename=$(basename "$filename")
    basename_without_extension="${basename%.*}"

    echo $basename_without_extension
}


################################################################################
## Global Variables ############################################################
################################################################################

tempdir=data-intermediate

mkdir $tempdir

swissboundaries=$tempdir/swissBOUNDARIES3D_1_4_LV95_LN02.gpkg

csv_out=$tempdir/mean_values.csv

################################################################################
# Data Preprocessing ###########################################################
################################################################################

## Reproject solar potential rasterdata to EPSG 2056
max_annual_summer=$tempdir/max_annual_summer.tif
max_annual_winter=$tempdir/max_annual_winter.tif
max_winter_summer=$tempdir/max_winter_summer.tif
max_winter_winter=$tempdir/max_winter_winter.tif

files=($max_annual_summer $max_annual_winter $max_winter_summer $max_winter_winter)

gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite "data/Dataset_SONNENLAND/radiation_maps_for_paper/maximizing_annual/result_summer.tif" $max_annual_summer
gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite "data/Dataset_SONNENLAND/radiation_maps_for_paper/maximizing_annual/result_winter.tif" $max_annual_winter 
gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite "data/Dataset_SONNENLAND/radiation_maps_for_paper/maximizing_winter/result_summer.tif" $max_winter_summer 
gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite "data/Dataset_SONNENLAND/radiation_maps_for_paper/maximizing_winter/result_winter.tif" $max_winter_winter 


## convert swissboundaries dataset into a geopackage
ogr2ogr $swissboundaries data/swissboundaries3d_2023-01_2056_5728.gdb/swissBOUNDARIES3D_1_4_LV95_LN02.gdb

################################################################################
# Data Processing ##############################################################
################################################################################

#### Set global variables ######################################################

### extent
for file in "${files[@]}"
do
#   echo $file
  xmin=$(gdalinfo $file -json | jq -r .cornerCoordinates | jq -r ".lowerLeft[0]")
  ymin=$(gdalinfo $file -json | jq -r .cornerCoordinates | jq -r ".lowerLeft[1]")
  xmax=$(gdalinfo $file -json | jq -r .cornerCoordinates | jq -r ".upperRight[0]")
  ymax=$(gdalinfo $file -json | jq -r .cornerCoordinates | jq -r ".upperRight[1]")

  ### resolution
  xres=$(gdalinfo $file | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $1}')
  yres=$(gdalinfo $file | grep "Pixel Size" | cut -d'(' -f2 | cut -d')' -f1 | awk -F',' '{print $2}')
  # get absolute value
  xres=${xres#-}
  yres=${yres#-}

  echo $xmin $ymin $xmax $ymax $xres $yres

done


### csv header
echo "raster_dataset, vector_dataset, subset, mean_value, perc_valid, pixelsize_x, pixelsize_y, rastersize_x, rastersize_y" > $csv_out


## Agriculture #################################################################

# 1: Most cantons
# 2: TI, AI
# 3: OW, NW, AR, VD
lwb=data/Dataset_SONNENLAND/Classification/Agricultural/Farming_most_cantons/shapefiles/lwb_perimeter_ln_sf/perimeter_ln_sf.shp
lwb2=data/Dataset_SONNENLAND/Classification/Agricultural/farming_ar_nw_ow_vd/geopackage/lwb_perimeter_ln_sf_lv95.gpkg
lwb3=data/lwb_nutzungsflaechen_lv95_AR_TI/geopackage/lwb_nutzungsflaechen_lv95.gpkg

swiss_tlm3d=data/swisstlm3d_2023-03_2056_5728/SWISSTLM3D_2023_LV95_LN02.gpkg

tempgpkg=$tempdir/agriculture.gpkg
vector_dataset="Agriculture"
###### Regular Farmland ########################################################
temprast=$tempdir/agriculture_regular
temprast1=$temprast.tif
subset="Regular Farmland"

# merge all datasets into one
# not using append on the first dataset, because this overwrites the old geopackage
ogr2ogr -nln regular -nlt MULTIPOLYGON -dialect sqlite -sql "SELECT Geometry as geom, 1 as src  FROM perimeter_ln_sf WHERE \"typ\" = 'Landwirtschaftliche Nutzfläche'" $tempgpkg $lwb
ogr2ogr -nln regular -nlt MULTIPOLYGON -dialect sqlite -update -append -sql "SELECT wkb_geometry as geom, 2 as src FROM perimeter_ln_sf WHERE \"typ\" = 'Landwirtschaftliche Nutzfläche'" $tempgpkg $lwb2
ogr2ogr -nln regular -nlt MULTIPOLYGON -dialect sqlite -update -append -sql "SELECT wkb_geometry as geom, 3 as src FROM nutzungsflaechen WHERE \"nutzung\" NOT IN ('Wald','Waldweiden (ohne bewaldete Fläche)','Sömmerungsweiden')" $tempgpkg $lwb3

# add forest to the dataset
ogr2ogr -nln forest -update -nlt MULTIPOLYGON -sql "SELECT * FROM tlm_bb_bodenbedeckung WHERE \"objektart\" = 'Wald' OR \"objektart\" = 'Wald offen'" $tempgpkg $swiss_tlm3d

gdal_rasterize -l regular -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1


# What is the difference in area between the vector and the raster?
area_vector=$(get_vector_area $tempgpkg regular geom)
area_raster=$(get_raster_area $temprast1)
area_frac=$(($area_raster / $area_vector))
echo $area_frac

# Remove forest
gdal_rasterize -l forest -burn 255 $tempgpkg $temprast1
echo $(get_raster_area $temprast1) #seems like no forest was removed?

# Calculate solar potential

for file in "${files[@]}"
do
    basename=$(basename_noext $file)
    outfile="${temprast}_${basename}.tif"
    gdal_calc.py -A $file -B $temprast1 --outfile=$outfile --calc="A*B"
    get_raster_info $outfile $csv_out $vector_dataset $subset
done


###### Summer Grazing Land #####################################################

tempgpkg=$tempdir/agriculture.gpkg # same as above
temprast=$tempdir/agriculture_grazing
temprast1=$temprast.tif
subset="Summer Grazing Land"

ogr2ogr -nln grazing -nlt MULTIPOLYGON -dialect sqlite -update -sql "SELECT Geometry as geom, 1 as src FROM perimeter_ln_sf WHERE \"typ\" = 'Sömmerungsgebiet'" $tempgpkg $lwb
ogr2ogr -nln grazing -nlt MULTIPOLYGON -dialect sqlite -update -append -sql "SELECT wkb_geometry as geom, 2 as src FROM perimeter_ln_sf WHERE \"typ\" = 'Sömmerungsgebiet'" $tempgpkg $lwb2
ogr2ogr -nln grazing -nlt MULTIPOLYGON -dialect sqlite -update -append -sql "SELECT wkb_geometry as geom, 3 as src FROM nutzungsflaechen WHERE \"nutzung\" = 'Sömmerungsweiden'" $tempgpkg $lwb3

gdal_rasterize -l grazing -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1

# Remove forest (todo: how much forest was removed?)
gdal_rasterize -l forest -burn 255 $tempgpkg $temprast1


for file in "${files[@]}"
do
    basename=$(basename_noext $file)
    outfile="${temprast}_${basename}.tif"
    gdal_calc.py -A $file -B $temprast1 --outfile=$outfile --calc="A*B"
    get_raster_info $outfile $csv_out $vector_dataset $subset
done


## Roads #######################################################################

roads=data/Dataset_SONNENLAND/Classification/ROADS/swissTLM3D_TLM_STRASSE.shp
temprast=$tempdir/roads_bund
temprast1=$temprast.tif
tempgpkg=$tempdir/roads_bund.gpkg
sql="SELECT buff.geom, ST_AREA(buff.geom) as area_m2 FROM (SELECT ST_UNION(ST_BUFFER(geometry, 10)) as geom FROM swissTLM3D_TLM_STRASSE WHERE EIGENTUEME = 'Bund') buff"
vector_dataset="Roads"
subset="National Roads"

ogr2ogr -dialect sqlite -sql $sql $tempgpkg $roads -nln roads_bund

gdal_rasterize -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1

for file in "${files[@]}"
do
    basename=$(basename_noext $file)
    outfile="${temprast}_${basename}.tif"
    gdal_calc.py -A $file -B $temprast1 --outfile=$outfile --calc="A*B"
    get_raster_info $outfile $csv_out $vector_dataset $subset
done



# What is the difference in area between the vector and the raster?
area_vector=$(get_vector_area $tempgpkg roads_bund geom)
area_raster=$(get_raster_area $temprast1)
area_frac=$(($area_raster / $area_vector))
echo $area_frac



## Standing Water ##############################################################

## Setting global variables
dir_standingwater=data/Dataset_SONNENLAND/Classification/Standing_Water
east_shp=$dir_standingwater/"OST/OBJEKTART_Stehende Gewaesser.shp"
west_shp=$dir_standingwater/"WEST/OBJEKTART_Stehende Gewaesser.shp"
dams=data/Dataset_SONNENLAND/Classification/DAMS/OBJEKTART_Staumauer.shp
vector_dataset="Standing Water"

tempgpkg=$tempdir/water_merged.gpkg



###### Preprocessing ###########################################################
## Merge the two  water datasets (east and west) into one
ogr2ogr $tempgpkg $east_shp -nln waterbodies
ogr2ogr $tempgpkg $west_shp -nln waterbodies -append

# select only water bodies > 1ha (100a)
ogr2ogr -sql "SELECT * FROM waterbodies WHERE St_area(geom) > 10000" -update -nln waterbodies_large $tempgpkg $tempgpkg

# add the dams to the waterbodies geopackage
ogr2ogr -nln dams -update $tempgpkg $dams

# add the boundary of switzerland to the geopackage (to exclude France and Italy from the great lakes)
ogr2ogr -sql "SELECT St_union(Shape) as geom FROM TLM_LANDESGEBIET WHERE \"NAME\" != 'Liechtenstein'" -nln switzerland -update $tempgpkg $swissboundaries

# sql="SELECT DISTINCT waterbodies_large.geom AS geom, CASE WHEN ST_Intersects(waterbodies_large.geom, dams.geom) THEN true ELSE false END AS reservoir FROM waterbodies_large, dams"
sql="
SELECT waterbodies_large.geom, 
       CASE WHEN dams.geom IS NULL THEN false ELSE true END AS reservoir
FROM waterbodies_large
LEFT JOIN dams
ON ST_Intersects(waterbodies_large.geom, dams.geom);
"
ogr2ogr -sql $sql -overwrite -update -nln waterbodies_dams $tempgpkg $tempgpkg




###### Reservoirs ##############################################################

temprast=$tempdir/waterbodies_reservoirs.tif
temprast1=$temprast.tif
subset="Reservoirs"

# create a new layer with only the reservoirs
ogr2ogr -where reservoir -overwrite -update -nln reservoirs $tempgpkg $tempgpkg waterbodies_dams

# rasterize the reservoirs
gdal_rasterize -l reservoirs -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1


# What is the difference in area between the vector and the raster?
area_vector=$(get_vector_area $tempgpkg reservoirs geom)
area_raster=$(get_raster_area $temprast1)
area_frac=$(($area_raster / $area_vector))
echo $area_frac

# Mask the areas outside switzerland (strictly speaking, this step is not necessary for reservoirs)
gdal_rasterize -i -l switzerland -burn 255 $tempgpkg $temprast1


for file in "${files[@]}"
do
    basename=$(basename_noext $file)
    outfile="${temprast}_${basename}.tif"
    gdal_calc.py -A $file -B $temprast1 --outfile=$outfile --calc="A*B"
    get_raster_info $outfile $csv_out $vector_dataset $subset
done
###### Natural #################################################################

temprast=$tempdir/waterbodies_natural
temprast1=$temprast.tif
subset="Natural"

# create a new layer without the reservoirs
ogr2ogr -where "NOT reservoir" -overwrite -update -nln natural $tempgpkg $tempgpkg waterbodies_dams

gdal_rasterize -l natural -burn 1 -ot Byte -co COMPRESS=DEFLATE -te $xmin $ymin $xmax $ymax -tr $xres $xres -init 255 -a_nodata 255 $tempgpkg $temprast1

# What is the difference in area between the vector and the raster?
area_vector=$(get_vector_area $tempgpkg natural geom)
area_raster=$(get_raster_area $temprast1)
area_frac=$(($area_raster / $area_vector))
echo $area_frac

# Remove the areas outside switzerland from the dataset
gdal_rasterize -i -l switzerland -burn 255 $tempgpkg $temprast1


for file in "${files[@]}"
do
    basename=$(basename_noext $file)
    outfile="${temprast}_${basename}.tif"
    gdal_calc.py -A $file -B $temprast1 --outfile=$outfile --calc="A*B"
    get_raster_info $outfile $csv_out $vector_dataset $subset
done


## Sonnendach ##################################################################

sonnendach=data/sonnendach/SOLKAT_DACH.gpkg
vector_dataset="Sonnendach"
subset="Rooftops"

ogrinfo -sql "SELECT SUM(STROMERTRAG_SOMMERHALBJAHR) AS summer, SUM(STROMERTRAG_WINTERHALBJAHR) as winter, SUM(FLAECHE) as area FROM SOLKAT_CH_DACH" $sonnendach | grep = > $tempdir/mean_values_sonnendach.csv


