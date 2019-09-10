# target2prereq: Convert a target to a prerequisite. Arguments are as follows:
#   1 - Target filename
#   2 - Target step name
#   3 - Prerequisite step name
#   4 - Filename components to be removed
# e.g., $(call target2prereq,$$@,result,data_field_info,sbtzg) converts
#    mfst.result+sQUASI_CLIMATOLOGY+dGSSTFM_3_SET1_INT_E+zNA+t20051201000000_20080229235959+b180.000W_90.000S_180.000E_90.000N+gSEASON_DJF.xml
#    to mfst.data_field_info+dGSSTFM_3_SET1_INT_E.xml
# result is replaced by data_field_info, and the service, bounding box, time zslice and group
# parts are removed.
# N.B.: this is done on the basename to simplify the regex, and .xml is added back on at the end
# (The presence of the '.' in the bbox part can cause the .xml to be slurped up if [^+.] is used)

RESULT = mfst.result+sQUASI_CLIMATOLOGY+dGSSTFM_3_SET1_INT_E+zNA+t20051201000000_20080229235959+b180.000W_90.000S_180.000E_90.000N+gSEASON_DJF.xml

target2prereq = $(shell echo $(basename $(1)) | sed 's/$(2)/$(3)/' | perl -pe 's/\+[$(4)][^+]+//g').xml

all: $(RESULT)

.SECONDEXPANSION:

# Use $$(call... after .SECONDEXPANSION
$(RESULT):	$$(call target2prereq,$$@,result,data_field_info,sbtzg)
	@echo target: $@
	@echo dependency: $^

mfst.data_field_info+dGSSTFM_3_SET1_INT_E.xml:
	touch $@
