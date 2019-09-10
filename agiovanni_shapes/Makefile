SHAPE_DIR = $(PREFIX)
SHAPE_FILES = \
	state_dept_countries.dbf \
	state_dept_countries.json \
	state_dept_countries.shp \
	state_dept_countries.shx \
	tl_2014_us_state.dbf \
	tl_2014_us_state.json \
	tl_2014_us_state.shp \
	tl_2014_us_state.shx \
	watersheds.dbf \
	watersheds.json \
	watersheds.shp \
	watersheds.shx \
	gpmSeaMask.nc \
	gpmSeaMask.json \
	gpmLandMask.nc \
	gpmLandMask.json

$(SHAPE_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi 

$(SHAPE_DIR)/%: % $(SHAPE_DIR) Makefile
	install $< $@
	if [ -O $@ ]; then chmod 755 $@; fi

install: ${SHAPE_FILES:%=${SHAPE_DIR}/%}
	if [ ! -d $(PREFIX)/geojson ]; then mkdir $(PREFIX)/geojson; fi
	cp geojson/*.geojson $(PREFIX)/geojson
