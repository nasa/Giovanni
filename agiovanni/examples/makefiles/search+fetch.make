# From parent Makefile
DATA = AIRX3STM_006_TotCH4_A AIRX3STD_006_Temperature_A
DATA_SLICE = AIRX3STM_006_TotCH4_A+zNA AIRX3STD_006_Temperature_A+z850

# Derived in time_string.make
TIME_RANGE = 20120101000000_20141231235959

# Derived manifest filenames
#
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
#
all:
	@echo Data Fields: $(DATA)
	@echo Search Manifests: $(DATA_SEARCH_LIST)
	@echo Fetch Manifests: $(DATA_FETCH_LIST)
