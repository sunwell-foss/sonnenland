# Reporject rasterdata to EPSG 2056
DIR=data/Dataset_SONNENLAND/Radiation
gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite $DIR/tilt_30_summer.tif $DIR/tilt_30_summer_2056.tif
gdalwarp -t_srs EPSG:2056 -tr 25 25 -overwrite $DIR/tilt_30_winter.tif $DIR/tilt_30_winter_2056.tif

# Merge the two vector datasets into one single geopackage
DIR2=data/Dataset_SONNENLAND/Classification/Standing_Water
ogr2ogr $DIR2/stehende_gewaesser_merged.gpkg $DIR2/"OST/OBJEKTART_Stehende Gewaesser.shp" -nln stehende_gewaesser
ogr2ogr $DIR2/stehende_gewaesser_merged.gpkg $DIR2/"WEST/OBJEKTART_Stehende Gewaesser.shp" -nln stehende_gewaesser -append
ogr2ogr $DIR2/stehende_gewaesser_merged.parquet $DIR2/stehende_gewaesser_merged.gpkg

# convert swissboundaries into a geopackage
DIR3=data/swissboundaries3d_2023-01_2056_5728.gdb
ogr2ogr data/swissBOUNDARIES3D_1_4_LV95_LN02.gpkg \
  $DIR3/swissBOUNDARIES3D_1_4_LV95_LN02.gdb
  
# convert the Ticino Dataset into a geopackage
DIR_ticino=data/TI_153-1_Nutzungsfla
ogr2ogr $DIR_ticino/TI_153-1_Nutzungsfla.gpkg -nln TI_153_1_Nutzungsfla \
  $DIR_ticino/TI_153-1_Nutzungsfla.shp


# DIR4=data/Dataset_SONNENLAND/Classification/Agricultural/Farming_most_cantons/shapefiles/lwb_perimeter_ln_sf
# ogr2ogr $DIR4/perimeter_ln_sf.parquet $DIR4/perimeter_ln_sf.shp
# 
# DIR5=data/Dataset_SONNENLAND/Classification/Agricultural/farming_ar_nw_ow_vd/geopackage
# ogr2ogr $DIR5/lwb_perimeter_ln_sf_lv95.parquet $DIR5/lwb_perimeter_ln_sf_lv95.gpkg

dir_roads=data/Dataset_SONNENLAND/Classification/ROADS
ogr2ogr $dir_roads/swissTLM3D_TLM_STRASSE.parquet $dir_roads/swissTLM3D_TLM_STRASSE.shp