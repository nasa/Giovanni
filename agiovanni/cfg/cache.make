# This workflow is for caching. It continues downloading and scrubbing data
# even when some data URLs fail.

# Make sure we do expansion and keep all the manifest files around

.SECONDEXPANSION:

.SECONDARY:


# Manifest file with local data file paths
RESULT_LIST = $(DATA:%=mfst.result+d%+t$(TIME_RANGE).xml)
RESULT_CLEAN_LIST = $(DATA_FETCH_LIST) \
	$(RESULT_LIST:mfst.%=prov.%) \
	$(RESULT_LIST:%.xml=%.log)



# Downloads and caches data not already in the cache. Keeps going in the event that some URLs are unreachable.
result: $(RESULT_LIST)

mfst.result+d%+t$(TIME_RANGE).xml: mfst.data_search+d%+t$(TIME_RANGE).xml mfst.data_field_info+d%.xml
	stageGiovanniData.pl --datafield-info-file $(SESSION_DIR)/$(word 2,$^) --data-url-file $(SESSION_DIR)/$<  --output $(SESSION_DIR)/$@ --time-out 60 --max-retry-count 3 --retry-interval 3 --chunk-size 20 --cache-root-path $(CACHE_DIR) --keep-going

all: $(RESULT_LIST)
