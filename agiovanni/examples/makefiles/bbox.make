# Convert bbox from something like -180,-90,180,90 to 180.0000W_90.0000S_180.0000E_90.0000N
# 4 Decimal places need to support NLDAS

# Setting a Makefile variable
BBOX = -115.3,23.4,-25.7,54.3

# Substitute the variable into what will be a perl script
BBOX_CMD = '@bb=split(",","$(BBOX)"); printf("%.4f%s_%.4f%s_%.4f%s_%.4f%s",abs($$bb[0]),($$bb[0]<0.)?"W":"E",abs($$bb[1]),($$bb[1]< 0.)?"S":"N",abs($$bb[2]),($$bb[2] < 0.)?"W":"E",abs($$bb[3]),($$bb[3]< 0.)?"S":"N");'

# Run the Perl script to convert to filename-safe string
BBOX_STRING = $(shell perl -e $(BBOX_CMD))

# And substitute in the perl script output in the manifest file
BBOX_FILE = mfst.bbox.b$(BBOX_STRING).xml

all:
	@echo BBOX $(BBOX) becomes manifest file $(BBOX_FILE)
