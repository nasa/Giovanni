DATA_SLICE_TAR_STRING = $(shell echo $(DATA_SLICE) | sed 's/ /+d/g')
DATA_SLICE_ARG_STRING = $(shell echo $(DATA_FIELD_SLICE_LIST) | sed 's/ /,/g')
DATA_INFO_ARG_STRING = $(shell echo $(DATA_FIELD_INFO_LIST) | sed 's/ /,/g')
DATA_FETCH_ARG_STRING = $(shell echo $(DATA_FETCH_LIST) | sed 's/ /,/g')

REGRID_LIST = mfst.regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
REGRID_CLEAN_LIST = $(REGRID_LIST) \
	prov.regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	regrid+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).log

ALGORITHM_LIST = mfst.algorithm+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
ALGORITHM_CLEAN_LIST = $(ALGORITHM_LIST)\
	prov.algorithm+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	algorithm+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).log

RESULT_LIST = mfst.result+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
RESULT_CLEAN_LIST = $(RESULT_LIST)\
	prov.result+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml \
	result+s$(SERVICE)+d$(DATA_SLICE_TAR_STRING)+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).log

VERBOSE_ARG = $(if $(VERBOSE),--debug $(VERBOSE))

BBOX_INTERSECTION = $(shell $(BBOX_INTERSECTION_CMD))

##############################################
test: 

.SECONDEXPANSION:

# Regrid step
mfst.regrid+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: $(DATA_FETCH_LIST) $(DATA_INFO_LIST) $(BBOX_FILE)
	giovanni_regrid.pl --inputfilelist '$(DATA_FETCH_ARG_STRING)' --bbox '$(BBOX_INTERSECTION)' --outfile '$(SESSION_DIR)/$@' --zfile '$(DATA_SLICE_ARG_STRING)' --datafield-info-file '$(DATA_INFO_ARG_STRING)' -s "$(STARTTIME)" -e "$(ENDTIME)"
## tried using giovanni_wrapper.pl to call the regrid script directly. But turned out to be more difficult than changing the existing regrid wrapper giovanni_regrid.pl
## the regrid script requires xml metadata for input files that is not carried over while calling science algorithms (converted into a list of inputs in a flat text file)
#	giovanni_wrapper.pl --program 'regrid_lats4d.pl' --inputfiles '$(DATA_FETCH_ARG_STRING)' --bbox '$(BBOX)' --outfile '$(SESSION_DIR)/$@' 
# --output-file-root 'outlist' --zfiles '$(DATA_SLICE_ARG_STRING)' --varfiles '$(DATA_INFO_ARG_STRING)' --starttime "$(STARTTIME)" 
# --endtime "$(ENDTIME)" --output-type filelist --variables '$(DATA_FIELDS)' --name '$(SERVICE_LABEL)' --comparison 'regrid to'

# Correlation step
mfst.algorithm+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: $(REGRID_LIST) $(DATA_INFO_LIST) $(BBOX_FILE)
	giovanni_correlation.pl --inputfilelist $< --bbox '$(BBOX_INTERSECTION)' --outfile '$(SESSION_DIR)/$@' --zfile '$(DATA_SLICE_ARG_STRING)' --datafield-info-file '$(DATA_INFO_ARG_STRING)' -M 3 -s "$(STARTTIME)" -e "$(ENDTIME)" $(VERBOSE_ARG)

# World longitude
mfst.world+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: mfst.algorithm+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml
	extendLongitude.pl --in-file $(SESSION_DIR)/$< --out-file $(SESSION_DIR)/$@ --clean-up 1


# Plot hints step
mfst.result+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml: mfst.world+s$(SERVICE)+d%+t$(START_STRING)_$(END_STRING)+b$(BBOX_STRING).xml $(DATA_INFO_LIST)
	input=($^); plotHintsWrapper.pl --mfst $(SESSION_DIR)/$< --varinfo '$(DATA_INFO_ARG_STRING)' --service correlation --bbox '$(BBOX)' --stime "$(STARTTIME)" --etime "$(ENDTIME)" --outfile $(SESSION_DIR)/$@

all: $(RESULT_LIST) 

clean:
	/bin/rm -f mfst.*.xml *.log prov.*.xml *.nc

# Ensures that intermediate targets are not deleted
.SECONDARY: 


