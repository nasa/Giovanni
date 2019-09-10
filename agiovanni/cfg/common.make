# Common targets for make based workflows

#$Id: common.make,v 1.22 2015/04/16 22:11:08 clynnes Exp $ 
#-@@@ Giovanni, Version $Name:  $

# AUTHORS:  M Hegde, C Smit, C Lynnes
# SEE ALSO:
#    Filename conventions on which this is based are at:
# http://discette.gsfc.nasa.gov/mwiki/index.php/AGiovanni_Filename_Conventions
# Derived variants of input
MAKE_STARTUP_CMD = makeStartup.pl


# This appears if indeed the user is using a shapefile
SHAPEFILE_ARG = $(if $(SHAPEFILE), -S '$(SHAPEFILE)')

# This appears if indeed the user is using a bounding box
BBOX_ARG = $(if $(BBOX), --bbox $(BBOX))

# Convert bbox from something like -180,-90,180,90 to 180.0000W90.0000S180.0000E90.0000N
# Add a representation of the shapefile argument, if present
# 4 Decimal places need to support NLDAS
BBOX_CMD = format_region.py -N=4 -S=$(SHAPEFILE) -C=3 -b=$(BBOX)
BBOX_STRING = $(shell $(BBOX_CMD))
BBOX_FILE = mfst.bbox.b$(BBOX_STRING).xml

# Relict?  Convert whitespace separated data fields to comma-separated list
DATA_FIELDS = $(shell echo $(DATA) | sed 's/  */,/g')

ifdef GROUP_TYPE
  CLASSES = $(shell echo $(GROUP_VALUE) | sed 's/,/ /g')
  # Special targets to get around restrictions on comma and space in make functions
  # From the GNU make manual
  comma:= ,
  empty:=
  # Put space between two empty's
  space:= $(empty) $(empty)
  GROUP_VALUES = $(subst $(space),$(comma),$(CLASSES))
endif
#=======================================================
# Reusable Functions

# filename2grouparg (deprecated):  
# Convert a target filename to the necessary group arguments, iff grouping has been specified.
filename2grouparg = $(shell perl -e 'if (qw($(1)) =~ /\+g$(GROUP_TYPE)_([^+\.]+)/) {print "--group-type $(GROUP_TYPE) --group-value $$1"}')

# mfstfile2grouparg (use for wrapper algorithms):  
# Convert a target filename to the necessary group arguments, iff grouping has been specified.
mfstname2grouparg = $(shell perl -e 'if (qw($(1)) =~ /\+g$(GROUP_TYPE)_([^+\.]+)/) {print "--group $(GROUP_TYPE)=$$1"}')

# target2prereq: Convert a target to a prerequisite. Arguments are as follows:
#   1 - Target filename
#   2 - Target step name
#   3 - Prerequisite step name
#   4 - Filename components to be removed
# e.g., $$(call target2prereq,$$@,result,data_field_info,sbtzg) converts
#    mfst.result+sQUASI_CLIMATOLOGY+dGSSTFM_3_SET1_INT_E+zNA+t20051201000000_20080229235959+b180.000W_90.000S_180.000E_90.000N+gSEASON_DJF.xml
#    to mfst.data_field_info+dGSSTFM_3_SET1_INT_E.xml
# result is replaced by data_field_info, and the service, bounding box, time zslice and group
# parts are removed.
# N.B.: this is done on the basename to simplify the regex, and .xml is added back on at the end
# (The presence of the '.' in the bbox part can cause the .xml to be slurped up if [^+.] is used)

target2prereq = $(shell echo $(basename $(1)) | sed 's/$(2)/$(3)/' | perl -pe 's/\+[$(4)][^+]*//g').xml


#======================================================
# Create the command string for calculating the intersection between all the data field bounding boxes and the user's bounding box
# The string will look something like
#
#     intersectBboxes.pl --justOneResult --bbox -122.9297,23.2383,-56.1328,72.457 --bbox -180.0,-50.0,180.0,50.0 --bbox -180.0,-50.0,180.0,50.0
#
# For reasons that I do not understand, quotes around the bounding boxes seem to hinder rather than help.
#
BBOX_INTERSECTION_CMD = intersectBboxes.pl --justOneResult --bbox '$(BBOX)' $(foreach file,$(DATA_FIELD_INFO_LIST),--bbox $(shell getBboxOutOfDatafieldInfo.pl --file $(file)))






#=======================================================
# Find start and stop dates for given combinations of season
# If doing SEASON DJF, adjust start year back one and adjust end date if leap year

ifeq ($(GROUP_TYPE),SEASON)
  STARTYR=$(shell echo $(STARTTIME) | cut -c 1-4)
  GOT_DJF = $(findstring DJF, $(CLASSES))
  STARTYEAR=$(if $(GOT_DJF),$(shell echo '$(STARTYR) - 1'|bc),$(STARTYR))
  # How we do table lookup in Make syntax: filter then basename to get value
  SEASONSTART = 12.DJF 03.MAM 06.JJA 09.SON
  STARTMONTH = $(basename $(filter %.$(firstword $(CLASSES)), $(SEASONSTART)))
  WF_STARTTIME = $(STARTYEAR)-$(STARTMONTH)-01T$(shell echo $(STARTTIME)|sed 's/.*T//')

  ENDYEAR = $(shell echo $(ENDTIME) | cut -c 1-4)
  SEASONEND = 02.DJF 05.MAM 08.JJA 11.SON
  ENDMONTH = $(basename $(filter %.$(lastword $(CLASSES)), $(SEASONEND)))
  SEASONDAY = 28.DJF 31.MAM 31.JJA 30.SON
  ENDDAY_0 = $(basename $(filter %.$(lastword $(CLASSES)), $(SEASONDAY)))
  # Correct for leap year: add 1 if DJF and divisible by 4 but not by 100 unless it's by 400
  ENDDAY = $(shell echo $(ENDYEAR) $(ENDMONTH) $(ENDDAY_0) |awk '{y=$$1; if (($$2 == 02) && !(y%4) && ((y%100) || !(y%400))){$$3++} print $$3}')
  WF_ENDTIME = $(ENDYEAR)-$(ENDMONTH)-$(ENDDAY)T$(shell echo $(ENDTIME)|sed 's/.*T//')
else
  WF_STARTTIME = $(STARTTIME)
  WF_ENDTIME = $(ENDTIME)
endif

# Take out colons, T, Z, and dashes for file names 
START_STRING = $(shell echo $(WF_STARTTIME) | sed 's/[TZ:-]//g')
END_STRING = $(shell echo $(WF_ENDTIME) | sed 's/[TZ:-]//g')

# Create TIME_RANGE convenience variable for brevity
TIME_RANGE = $(START_STRING)_$(END_STRING)

# Manifest file with data field IDs
DATA_FIELD_LIST = $(DATA:%=mfst.data_field+d%.xml)
DATA_FIELD_CLEAN_LIST = $(DATA_FIELD_LIST) \
	$(DATA_FIELD_LIST:%.xml=%.log)

# Manifest file with data file IDs and user selected higher dimension slices
DATA_FIELD_SLICE_LIST = $(DATA_SLICE:%=mfst.data_field_slice+d%.xml)
DATA_FIELD_SLICE_CLEAN_LIST = $(DATA_FIELD_SLICE_LIST) \
	$(DATA_FIELD_SLICE_LIST:%.xml=%.log)

# Manifest file with data field metadata from AESIR catalog
DATA_FIELD_INFO_LIST = $(DATA:%=mfst.data_field_info+d%.xml)
DATA_FIELD_INFO_CLEAN_LIST = $(DATA_FIELD_INFO_LIST) \
	$(DATA_FIELD_INFO_LIST:mfst.%=prov.%) \
	$(DATA_FIELD_INFO_LIST:%.xml=%.log)

# Manifest file with data URLs
DATA_SEARCH_LIST = $(DATA:%=mfst.data_search+d%+t$(TIME_RANGE).xml)
DATA_SEARCH_CLEAN_LIST = $(DATA_SEARCH_LIST) \
	$(DATA_SEARCH_LIST:mfst.%=prov.%) \
	$(DATA_SEARCH_LIST:%.xml=%.log)

# Manifest file with local data file paths
DATA_FETCH_LIST = $(DATA:%=mfst.data_fetch+d%+t$(TIME_RANGE).xml)
DATA_FETCH_CLEAN_LIST = $(DATA_FETCH_LIST) \
	$(DATA_FETCH_LIST:mfst.%=prov.%) \
	$(DATA_FETCH_LIST:%.xml=%.log)

# Add +g to GROUP_TYPE to get the pathname segment
GROUP = $(foreach G, $(GROUP_TYPE),+g$(G))
# Expand out all the GROUP CLASSES
# Actually, this only works with one GROUP but is done to leave 
# GROUP_CLASSES blank when there is no grouping
# Not sure if this is still necessary...
GROUP_CLASSES = $(foreach G, $(GROUP), $(foreach V,$(CLASSES),$(G)_$(V)))

# DATA_CLASS_LIST targets:  same structure as DATA_FETCH_LIST
DATA_CLASS_LIST = $(DATA_FETCH_LIST:mfst.data_fetch%.xml=mfst.data_class%$(GROUP).xml)
DATA_CLASS_CLEAN_LIST = $(DATA_CLASS_LIST) \
        $(DATA_CLASS_LIST:mfst.%=prov.%) \
        $(DATA_CLASS_LIST:mfst.%.xml=%.log)

# DATA_GROUP_LIST targets:  expand DATA_CLASS_LIST to cover all the class values
data_group:	$(DATA_GROUP_LIST)

DATA_GROUP_LIST = $(subst class,group, $(foreach A,$(CLASSES),$(foreach D,$(DATA_CLASS_LIST),$(basename $D)_$A.xml)))
DATA_GROUP_CLEAN_LIST = $(DATA_GROUP_LIST) \
        $(DATA_GROUP_LIST:mfst.%=prov.%) \
        $(DATA_GROUP_LIST:mfst.%.xml=%.log)

# CRITICAL FORK IN THE ROAD:  branches depend on whether we are grouping or not
ifdef GROUP_TYPE
    SLICE_ALGORITHM_LIST = $(DATA_SLICE:%=mfst.algorithm+s$(SERVICE)+d%+t$(TIME_RANGE)+b$(BBOX_STRING))
    ALGORITHM_LIST = $(foreach A,$(GROUP_CLASSES),$(foreach D,$(SLICE_ALGORITHM_LIST),$D$A.xml))
    ALGORITHM_PREREQ = data_group
else
    ALGORITHM_LIST = $(DATA_SLICE:%=mfst.algorithm+s$(SERVICE)+d%+t$(TIME_RANGE)+b$(BBOX_STRING).xml)
    ALGORITHM_PREREQ = data_fetch
endif

ALGORITHM_CLEAN_LIST = $(ALGORITHM_LIST) \
        $(ALGORITHM_LIST:mfst.%=prov.%) \
        $(ALGORITHM_LIST:%.xml=%.log)

# RESULT_LIST is same structure as ALGORITHM_LIST
# Alternate form: RESULT_LIST = $(subst algorithm,result,$(ALGORITHM_LIST))
RESULT_LIST = $(ALGORITHM_LIST:mfst.algorithm%=mfst.result%)
RESULT_CLEAN_LIST = $(RESULT_LIST) \
        $(RESULT_LIST:mfst.%=prov.%) \
        $(RESULT_LIST:%.xml=%.log)

# If we need to expand the longitude, this happens after the algorithm step
WORLD_LONGITUDE_LIST = $(ALGORITHM_LIST:mfst.algorithm%=mfst.world%)
WORLD_CLEAN_LIST = $(WORLD_LIST) \
        $(WORLD_LIST:mfst.%=prov.%) \
        $(WORLD_LIST:%.xml=%.log)

# And then we have result targets derived from the world longitude files
RESULT_AFTER_WORLD_LIST = $(WORLD_LONGITUDE_LIST:mfst.world%=mfst.result%)
RESULT_AFTER_WORLD_CLEAN_LIST = $(RESULT_AFTER_WORLD_LIST) \
        $(RESULT_AFTER_WORLD_LIST:mfst.%=prov.%) \
        $(RESULT_AFTER_WORLD_LIST:%.xml=%.log)

# This is needed to determine which kind of Lat-Averaging is done in giovanni_shape_mask.py
# We are doing this here so that this parm doesn't have to be in every .svc file (optparse)
MASK_ARG = $(if $(LATITUDE_WEIGHTING_FUNCTION), --mask-type $(LATITUDE_WEIGHTING_FUNCTION))

# Manifet file for Workflow Queue Info
WF_QUEUE_INFO = $(DATA:%=mfst.workflow_queue_info+d%.xml)
WF_QUEUE_INFO_CLEAN = $(WF_QUEUE_INFO) \
        $(WF_QUEUE_INFO:%.xml=%.log)

STEPS =  workflow_queue_info expand_BBox expand_time data_field_info data_search data_fetch shape_mask+s$(SERVICE) data_class data_group regrid algorithm+s$(SERVICE) world+s$(SERVICE) getData biasCorrection as3_grid 

# Files generated at startup
$(BBOX_FILE): input.xml
	makeStartup.pl --type bbox --in-file $< --out-file $@

mfst.data_field+d%.xml: input.xml
	makeStartup.pl --type data --in-file $< --out-file $@

mfst.data_field_slice+d%.xml: input.xml
	makeStartup.pl --type zval --in-file $< --out-file $@

# Workflow wait step (time in workflow queue)
workflow_queue_info: $(WF_QUEUE_INFO)

# Data field info step: gets the data field information from AESIR catalog
data_field_info: $(DATA_FIELD_INFO_LIST)

mfst.data_field_info+d%.xml: mfst.data_field+d%.xml
	getDataFieldInfo.pl -user $(USER) --user-dir $(USER_DIR) --in-xml-file $< --aesir $(AESIR) --datafield-info-file $@

# Data search step: gets the URL for scientific data
data_search: $(DATA_SEARCH_LIST)

mfst.data_search+d%+t$(TIME_RANGE).xml: mfst.data_field_info+d%.xml
	search.pl --outfile $@ --catalog $< --missingUrl $(MISSING_URL_FILE) --stime $(WF_STARTTIME) --etime $(WF_ENDTIME)

# Data fetch step: downloads and stages data for use in the workflow
data_fetch: $(DATA_FETCH_LIST)

mfst.data_fetch+d%+t$(TIME_RANGE).xml: mfst.data_search+d%+t$(TIME_RANGE).xml mfst.data_field_info+d%.xml
	stageGiovanniData.pl --datafield-info-file $(SESSION_DIR)/$(word 2,$^) --data-url-file $(SESSION_DIR)/$<  --output $(SESSION_DIR)/$@ --time-out 60 --max-retry-count 3 --retry-interval 3 --chunk-size 20 --cache-root-path $(CACHE_DIR)

# Going to need to expand prerequisite rules twice to use fancy prerequisite specs
.SECONDEXPANSION:
# Targets used for classify/group
# mfst.data_class.* has same structure as mfst.data_fetch.*
mfst.data_class+d%+t$(TIME_RANGE)$(GROUP).xml: $$(shell echo $$@ | sed -e 's/class/fetch/' -e 's/$(GROUP)//')
	classify_seasonmonth.pl --in-file $< --out-file $@ --group-type $(GROUP_TYPE)

# There may be several group manifests corresponding to one class manifest
# The rule prerequisite is the target file, with the +gGROUP=VALUES section excised
# o  The --group_type argument comes from the Makefile directly
# o  The --group_value argument comes from extracting the 'XX' (or 'XXX', or...)
#      from the target filename after +gGROUP_XX in a target like
#      mfst.data_group+dGSSTFM_3_SET1_INT_E+t20081201000000_20101130235959+gMONTH_07.xml
# o  The --id argument uses a similar mechanism to extract the +dXXXX portion of the target
$(DATA_GROUP_LIST):     $$(shell echo $$@ | sed -e 's/group/class/' -e 's/$(GROUP)_[^+.]*/$(GROUP)/')
	group_data.pl --in-file $< --out-file $@ --group-type $(GROUP_TYPE) \
                      --group-value $(shell echo $@ | sed 's/.*$(GROUP)_\([^+.]*\).*/\1/')

# Targets made at startup
ifeq ($(PORTAL),GIOVANNI)
    init: $(DATA_FIELD_LIST) $(BBOX_FILE) $(DATA_FIELD_SLICE_LIST)
else
    init:
endif

printsteps:
	echo $(STEPS)

debug:
	@echo BBOX_CMD $(BBOX_CMD)
	@echo BBOX_STRING $(BBOX_STRING)
	@echo WF_QUEUE_INFO $(WF_QUEUE_INFO)
	@echo START $(STARTTIME) became $(WF_STARTTIME)
	@echo END $(ENDTIME) became $(WF_ENDTIME)
	@echo GROUP/GROUP_CLASSES $(GROUP_TYPE) $(GROUP_CLASSES)
	@echo DATA_FIELD_LIST $(DATA_FIELD_LIST)|fmt -w 20
	@echo DATA_FETCH_LIST $(DATA_FETCH_LIST)|fmt -w 20
	@echo DATA_CLASS_LIST $(DATA_CLASS_LIST)|fmt -w 20
	@echo DATA_GROUP_LIST $(DATA_GROUP_LIST)|fmt -w 20
	@echo ALGORITHM $(ALGORITHM_LIST)|fmt -w 20
	@echo RESULT_LIST $(RESULT_LIST)|fmt -w 20
	@echo WORLD_LONGITUDE_LIST $(WORLD_LONGITUDE_LIST)|fmt -w 20
	@echo RESULT_AFTER_WORLD_LIST $(RESULT_AFTER_WORLD_LIST)|fmt -w 20
	@echo POSTPROCESS_LIST $(POSTPROCESS_LIST)
	@echo COMBINED_RESULT_LIST $(COMBINED_RESULT_LIST)
	@echo GROUP $(GROUP)|fmt -w 20
	@echo GROUP_CLASSES $(GROUP_CLASSES)|fmt -w 20
	@echo TIME_AXIS_ARG $(TIME_AXIS_ARG)
	@echo SHAPEFILE_ARG $(SHAPEFILE_ARG)
	@echo MASK_ARG $(MASK_ARG)
	@echo DATELINE_ARG $(DATELINE_ARG)
	@echo DATA_FIELD_INFO_LIST $(DATA_FIELD_INFO_LIST)
	@echo BBOX_INTERSECTION_CMD $(BBOX_INTERSECTION_CMD)
