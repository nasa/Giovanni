# $Id: comparison.make,v 1.22 2015/04/30 21:25:19 dedasilv Exp $
# To Use, create another makefile with the following macros in
# them: ALGORITHM_CMD is the actual executable (basename only),
# SERVICE_LABEL is what shows up in the plot title, and
# OUTPUT_FILE_ROOT is the first part of the output netCDF filename
# Example:
# ALGORITHM_CMD = g4_ex_area_avg_diff_time.pl
# SERVICE_LABEL = "Time Series of Area Averaged Differences"
# OUTPUT_FILE_ROOT = areaAvgDiffTimeSer

DATA_SLICE_TAR_STRING = $(shell echo $(DATA_SLICE) | sed 's/ /+d/g')
DATA_SLICE_ARG_STRING = $(shell echo $(DATA_FIELD_SLICE_LIST) | sed 's/ /,/g')
DATA_INFO_ARG_STRING = $(shell echo $(DATA_FIELD_INFO_LIST) | sed 's/ /,/g')
DATA_FETCH_ARG_STRING = $(shell echo $(DATA_FETCH_LIST) | sed 's/ /,/g')

REGRID_LIST = mfst.regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
ifdef SKIP_REGRID
  REGRID_LIST = mfst.merge+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
endif
REGRID_CLEAN_LIST = $(REGRID_LIST) \
	prov.regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).log

RESULT_LIST = mfst.postprocess+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
RESULT_CLEAN_LIST = $(RESULT_LIST)\
	prov.postprocess+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	postprocess+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).log

VERBOSE_ARG = $(if $(VERBOSE),--debug $(VERBOSE))
DATELINE_ARG = $(if $(DATELINE_METHOD),--dateline $(DATELINE_METHOD))
STEPS += result+s$(SERVICE)
STEPS += postprocess+s$(SERVICE)
COMPARISON_ARG = $(if $(COMPARISON),--comparison $(COMPARISON),--comparison vs.)
# See if the PLOT_TYPE starts with TIME_SERIES (also gets TIME_SERIES_GNU)
ifneq ($(filter TIME_SERIES%,$(PLOT_TYPE)), )
  TIME_AXIS_ARG = --time-axis
endif

BBOX_INTERSECTION = $(shell $(BBOX_INTERSECTION_CMD))

##############################################
test: 

.SECONDEXPANSION:

# Regrid step
# We can skip this, letting the algorithm defer regridding to the end in some cases, 
# but we still need to combine the two variables into a single manifest
ifdef SKIP_REGRID
  #NOTE: Chris says this will not work for grouping. Look at singlefield.make. And don't panic.
  mfst.merge+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: \
	$(DATA_FETCH_LIST) \
	$(DATA_INFO_LIST) \
	$(BBOX_FILE)

	sed 's#</manifest>##' < $(word 1,$^) > $@.tmp
	tail -n +2 $(word 2,$^) | sed 's#<manifest>##' >> $@.tmp
	mv $@.tmp $@
else
  mfst.regrid+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: \
	$(DATA_FETCH_LIST) \
	$(DATA_INFO_LIST) \
	$(BBOX_FILE)

	giovanni_regrid.pl \
		--inputfilelist       '$(DATA_FETCH_ARG_STRING)' \
		--bbox                '$(BBOX_INTERSECTION)' \
		--outfile             '$(SESSION_DIR)/$@' \
		--zfile               '$(DATA_SLICE_ARG_STRING)' \
		--datafield-info-file '$(DATA_INFO_ARG_STRING)' \
		-s                    '$(STARTTIME)' \
		-e                    '$(ENDTIME)'
endif

# Comparison step
mfst.result+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: \
	$(REGRID_LIST) \
	$(DATA_INFO_LIST) \
	$(BBOX_FILE)

	giovanni_wrapper.pl \
		--output-file-root $(OUTPUT_FILE_ROOT) \
		--program          '$(ALGORITHM_CMD)' \
		--inputfiles       $< \
		--bbox             '$(BBOX)' \
		--outfile          '$(SESSION_DIR)/$@' \
		--zfiles           '$(DATA_SLICE_ARG_STRING)' \
		--varfiles         '$(DATA_INFO_ARG_STRING)' \
		--starttime        "$(STARTTIME)" \
		--endtime          "$(ENDTIME)" \
		--variables        $(DATA_FIELDS) \
		--name             '$(SERVICE_LABEL)' \
                --jobs             $(JOBS) \
                $(if $(UNITS_CFG), $(shell getUnitsArg.pl -v $(DATA_SLICE_ARG_STRING) ALGORITHM,$(CONVERT_UNITS_STEP) $(UNITS_CFG) $(word 1, $^) )) \
		$(COMPARISON_ARG) \
		$(MINIMUM_TIME_STEPS_ARG) \
		$(DATELINE_ARG) \
		$(VERBOSE_ARG) \
		$(TIME_AXIS_ARG)


all: $(RESULT_LIST) 

clean:
	/bin/rm -f mfst.*.xml *.log prov.*.xml *.nc

# Post-Process step
mfst.postprocess+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: \
	mfst.result+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	$(DATA_INFO_LIST)

	giovanni_postprocess.pl \
		$(BBOX_ARG) \
		--endtime     $(ENDTIME) \
		--infile      $< \
		--name        '$(SERVICE_LABEL)' \
		--outfile     $(SESSION_DIR)/$@ \
		--service     $(SERVICE) \
		--session-dir $(SESSION_DIR) \
		--starttime   $(STARTTIME) \
		--variables   $(DATA_FIELDS) \
		--varfiles    $(DATA_INFO_ARG_STRING) \
		--zfiles      $(DATA_SLICE_ARG_STRING) \
                $(if $(UNITS_CFG), $(shell getUnitsArg.pl -v $(DATA_SLICE_ARG_STRING) POST,$(CONVERT_UNITS_STEP) $(UNITS_CFG) $<) ) \
		$(SHAPEFILE_ARG) \
		$(TIME_AXIS_ARG) \
		$(COMPARISON_ARG)

# Ensures that intermediate targets are not deleted
.SECONDARY: 

