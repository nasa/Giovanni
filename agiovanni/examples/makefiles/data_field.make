# From parent Makefile
DATA = AIRX3STM_006_TotCH4_A AIRX3STD_006_Temperature_A
DATA_SLICE = AIRX3STM_006_TotCH4_A+zNA AIRX3STD_006_Temperature_A+z850

# Derived manifest filenames
#
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

all:
	@echo Data Fields: $(DATA)
	@echo Data Field Manifests: $(DATA_FIELD_LIST)
	@echo Data Slices: $(DATA_SLICE)
	@echo Data Slice Manifests: $(DATA_FIELD_SLICE_LIST)
