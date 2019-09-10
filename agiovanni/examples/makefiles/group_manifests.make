# From parent Makefile
GROUP_TYPE = SEASON
CLASSES = DJF MAM
DATA_SLICE = AIRX3STM_006_TotCH4_A+zNA AIRX3STD_006_Temperature_A+z850
SERVICE = QuCl

# Derived in search+fetch.make
DATA_FETCH_LISTi = mfst.data_fetch+dAIRX3STM_006_TotCH4_A+t20120101000000_20141231235959.xml mfst.data_fetch+dAIRX3STD_006_Temperature_A+t20120101000000_20141231235959.xml

# Derived in time_string.make
TIME_RANGE = 20120101000000_20141231235959

# Derived in bbox.make
BBOX_STRING = 115.3000W_23.4000N_25.7000W_54.3000N

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

all:
	@echo ALGORITHM_LIST = $(ALGORITHM_LIST) | fmt -w 60
