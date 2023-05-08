
## File paths ##################################################################

summer_path <- "data/Dataset_SONNENLAND/Radiation/tilt_30_summer_2056.tif"
swissboundaries_path <- "data/swissboundaries3d_2023-01_2056_5728.gdb/swissBOUNDARIES3D_1_4_LV95_LN02.gpkg"
stehende_gewaesser_path <- "data/Dataset_SONNENLAND/Classification/Standing_Water/stehende_gewaesser_merged.parquet"
staumauer_path <- "data/Dataset_SONNENLAND/Classification/DAMS/OBJEKTART_Staumauer.shp"
roads_path <- "data/Dataset_SONNENLAND/Classification/ROADS/swissTLM3D_TLM_STRASSE.parquet"


## Switzerland's borders #######################################################

schweiz <- st_read(swissboundaries_path, "TLM_LANDESGEBIET") |> 
  st_zm() |> 
  filter(NAME != "Liechtenstein") |> 
  st_union() |> 
  st_as_sf()

st_geometry(schweiz) <- "geom"

st_layers(swissboundaries_path)

cantons <- st_read(swissboundaries_path, "TLM_KANTONSGEBIET") |> 
  st_zm() |> 
  group_by(NAME) |> 
  summarise()

canton_names <- read_csv("data/cantons.csv") |> arrange(canton_long)
# test
# anti_join(cantons, canton_names, by = c("NAME" = "canton_long"))
cantons <- left_join(cantons, canton_names, by = c("NAME" = "canton_long"))

## Solar potential raster ######################################################

summer_rast <- rast(summer_path)
units(summer_rast) <- "W*h/m^2"

# !time!
summer_ch <- crop(summer_rast, vect(schweiz))
summer_ch <- mask(summer_ch, vect(schweiz),filename = "data-intermediate/summer-ch.tif", overwrite = TRUE)  
units(summer_ch) <- "W*h/m^2"


# !time!
schweiz$radiation_mean <- global_with_units(summer_ch)
schweiz$area <- st_area(schweiz)
schweiz$radiation_total <- schweiz$radiation_mean*schweiz$area

save(schweiz, file = "data-intermediate/schweiz.Rda")


## Standing Water ##############################################################

stehende_gewaesser <- sfarrow::st_read_parquet(stehende_gewaesser_path) |> 
  st_zm() |> 
  st_set_crs(2056)

staumauern <- st_read("data/Dataset_SONNENLAND/Classification/DAMS/OBJEKTART_Staumauer.shp")


# I had initially thought that we would have select lakes within a distance to 
# "staumauern" and so introduce a bit of tolerance. It turns out however, that all
# "staumauern" actually intersect the "stauseen" they are closest to, so the distance is
# usually 0. They usually touch (but not always),  but they always intersect.

# !time!
stehende_gewaesser <- st_join(stehende_gewaesser, transmute(staumauern, staumauer = row_number()))


# !time!
stehende_gewaesser$radiation_mean <- extract_with_units(summer_ch, stehende_gewaesser)
stehende_gewaesser$area <- st_area(stehende_gewaesser)


stehende_gewaesser$radiation_total <- stehende_gewaesser$radiation_mean * stehende_gewaesser$area


stehende_gewaesser <- select(stehende_gewaesser, radiation_mean, area, radiation_total,staumauer)


save(stehende_gewaesser, file = "data-intermediate/stehende_gewaesser.Rda")




## Agriculture #################################################################


## Roads  ######################################################################




