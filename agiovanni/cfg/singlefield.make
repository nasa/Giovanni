# $Id: singlefield.make,v 1.31 2015/04/30 21:25:19 dedasilv Exp $
DATA_INFO_ARG_STRING = $(shell echo $(DATA_FIELD_INFO_LIST) | sed 's/ /,/g')
DATA_FETCH_ARG_STRING = $(shell echo $(DATA_FETCH_LIST) | sed 's/ /,/g')

SHAPE_LIST = $(subst result,shape_mask,$(RESULT_LIST))
SHAPE_CLEAN_LIST = $(SHAPE_LIST) \
        $(SHAPE_LIST:mfst.%=prov.%) \
        $(SHAPE_LIST:%.xml=%.log)

POSTPROCESS_LIST = $(subst result,postprocess,$(RESULT_LIST))
ifdef GROUP_TYPE
  COMBINED_START  = $(DATA_SLICE:%=mfst.combine+s$(SERVICE)+d%+t$(TIME_RANGE)+b$(BBOX_STRING))
  COMBINED_CLASSES = $(foreach V,$(CLASSES),_$(V))
  # the COMBINED_CLASSES are white space separated, so remove that white space.
  # # e.g. - '_01 _02' --> '_01_02'
  COMBINED_RESULT_LIST = $(COMBINED_START)$(GROUP)$(shell echo $(COMBINED_CLASSES) | sed 's/\s//g').xml
  COMBINED_RESULT_CLEAN_LIST = $(COMBINED_LIST)\
         $(COMBINED_RESULT_LIST:mfst.%=prov.%) \
                 $(COMBINED_RESULT_LIST:%.xml=%.log)
endif


VERBOSE_ARG = $(if $(VERBOSE),--debug $(VERBOSE))
DATELINE_ARG = $(if $(DATELINE_METHOD), --dateline $(DATELINE_METHOD))
OUTPUT_TYPE_ARG = $(if $(OUTPUT_TYPE),--output-type $(OUTPUT_TYPE))
STEPS += result+s$(SERVICE)
STEPS += postprocess+s$(SERVICE)
# See if the PLOT_TYPE contains TIME_SERIES (also gets TIME_SERIES_GNU)
ifneq ($(findstring TIME_SERIES,$(PLOT_TYPE)), )
  TIME_AXIS_ARG = --time-axis
endif

##############################################
test: 

.SECONDEXPANSION:

# Shapefile masking step
$(SHAPE_LIST): $$(call target2prereq,$$@,shape_mask,$$(ALGORITHM_PREREQ),sbzu)

	giovanni_shape_mask.py \
		--bbox '$(BBOX)' \
		--in-file  $< \
		--out-file $@ \
		--service  $(SERVICE) \
		$(MASK_ARG) \
		$(SHAPEFILE_ARG)

# Algorithm step
$(RESULT_LIST):  $$(subst result,shape_mask,$$@) \
	$$(call target2prereq,$$@,result,data_field_slice,sbgt) \
	$$(call target2prereq,$$@,result,data_field_info,sbzugt) \
	$(BBOX_FILE)

	giovanni_wrapper.pl \
		--inputfiles       $(word 1, $^) \
		--bbox             '$(BBOX)' \
		--outfile          $(SESSION_DIR)/$@ \
		--zfiles           $(word 2, $^) \
		--varfiles         $(word 3, $^) \
		--starttime        "$(STARTTIME)" \
		--endtime          "$(ENDTIME)" \
		--program          '$(ALGORITHM_CMD)' \
		--output-file-root $(OUTPUT_FILE_ROOT) \
		--name             '$(SERVICE_LABEL)' \
		--jobs              $(JOBS)  \
		--variables        `echo $@ | sed -e 's/.*+d//' -e 's/+z.*//'` \
		$(if $(UNITS_CFG), $(shell getUnitsArg.pl -v $(word 2, $^) ALGORITHM,$(CONVERT_UNITS_STEP) $(UNITS_CFG) $<)) \
		$(MINIMUM_TIME_STEPS_ARG) \
		$(call mfstname2grouparg,$@) \
		$(DATELINE_ARG) \
		$(VERBOSE_ARG) \
		$(SHAPEFILE_ARG) \
		$(OUTPUT_TYPE_ARG) \
		$(TIME_AXIS_ARG)

# Post-Process step
$(POSTPROCESS_LIST): $$(subst postprocess,result,$$@) \
	$$(call target2prereq,$$@,postprocess,data_field_info,sbzugt) \
	$$(call target2prereq,$$@,postprocess,data_field_slice,sbgt)

	giovanni_postprocess.pl \
		$(BBOX_ARG) \
                --endtime     $(ENDTIME) \
		--infile      $(word 1, $^) \
		--name        '$(SERVICE_LABEL)' \
		--outfile     $(SESSION_DIR)/$@ \
		--service     $(SERVICE) \
		--session-dir $(SESSION_DIR) \
		--starttime   $(STARTTIME) \
		--variables   `echo $@ | sed -e 's/.*+d//' -e 's/+z.*//'` \
		--varfiles    $(word 2, $^) \
		--zfiles      $(word 3, $^) \
		$(if $(UNITS_CFG), $(shell getUnitsArg.pl -v $(word 3, $^) POST,$(CONVERT_UNITS_STEP) $(UNITS_CFG) $< )) \
		$(SHAPEFILE_ARG) \
		$(TIME_AXIS_ARG) \
		$(call mfstname2grouparg,$@)

ifdef GROUP_TYPE
  $(COMBINED_RESULT_LIST): $(POSTPROCESS_LIST)
	combineFileManifests.pl $@ $^
endif

all: $(RESULT_LIST) $(POSTPROCESS_LIST) $(COMBINED_RESULT_LIST)

clean:
	/bin/rm -f mfst.*.xml *.log prov.*.xml *.nc

# Ensures that intermediate targets are not deleted
.SECONDARY: 

