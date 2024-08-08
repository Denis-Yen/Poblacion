# 1. PAQUETES

libs <- c(
  "sf", "R.utils",
  "scales", "deckgl"
)

installed_libraries <- libs  %in% rownames(
  installed.packages()
)

if(any(installed_libraries==F)){
  install.packages(
    libs[!installed_libraries]
  )
}

invisible(
  lapply(
    libs,
    library,
    character.only = TRUE
  )
)

# 2. KONTUR POPULATION DATA

options(timeout = 300)
url <- "https://geodata-eu-central-1-kontur-public.s3.amazonaws.com/kontur_datasets/kontur_population_PE_20231101.gpkg.gz"
filename <- basename(path = url)

download.file(
    url = url,
    destfile = filename,
    mode = "wb"
)


R.utils::gunzip(
  filename,
  remove = FALSE
)

# 3. CARAGAR LOS DATOS

pop_df <- sf::st_read(
  dsn = gsub(
    pattern = ".gz",
    replacement = "",
    x = filename
  )
) |> 
  sf::st_transform(
    crs = "EPSG:4326"
  )

# 4. PALETTA DE COLORES
pal <- scales::col_quantile(
  "Blues",
  pop_df$population,
  n = 6
)

pop_df$color = pal(
  pop_df$population
)

# 5. MAPA INTERACTIVO

properties <- list(
  stroked = T,
  filled = T,
  extruded = T,
  wireframe = F,
  elevationScale = 1,
  getFillColor = ~color,
  getLineColor = ~color,
  getElevation = ~population,
  getPolygon = deckgl::JS(
    "d => d.geom.coordinates"
  ),
  tooltip = "population: {{population}}",
  opacity = .25
)

#  -12.043180, -77.028240

map <- deckgl::deckgl(
  latitude = -12.043180,
  longitude = -77.028240,
  zoom = 6, pitch = 45
) |> 
  deckgl::add_polygon_layer(
    data = pop_df, 
    properties = properties
  ) |> 
  deckgl::add_basemap(
    deckgl::use_carto_style()
  )

# 6. EXPORTAR COMO HTML

htmlwidgets::saveWidget(
  map, file = "map.html",
  selfcontained = F
)



