# This workflow is for editing the attributes of the cached files.

# Manifest file with local data file paths
RESULT_LIST = $(DATA:%=mfst.result+d%.xml)

# Edits all of the cached files of a particular variable.
result: $(RESULT_LIST)

#
mfst.result+d%.xml: mfst.data_field_info+d%.xml
	updateScrubbedDataFile.pl  --data-url-file $(SESSION_DIR)/$< 

all: $(RESULT_LIST)
