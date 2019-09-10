# Copy the documentation stuff into PREFIX/www/doc.
# Author: C. Smit

##
# Setup a variables for the destination directories
##

HTML_DIR=$(PREFIX)/www/doc
IMAGE_DIR=$(HTML_DIR)/images

##
# Actual help document
##
MANUAL=UsersManualworkingdocument.docx.html
DESTINATION_MANUAL=$(HTML_DIR)/$(MANUAL)


##
# Figure out which images we are copying over
##

# get a list of the image files:
# image00.png image01.png ...
IMAGE_FILES=$(shell ls images/)


# create a list with the destination
# /home/csmit/public_html/giovanni4/www/doc/images/image00.png /home/csmit/public_html/giovanni4/www/doc/images/image01.png ...
DESTINATION_IMAGE_LIST=$(IMAGE_FILES:%=$(HTML_DIR)/images/%)



##
# Actual rules for making targets
##

# Rule to make the HTML directory if it doesn't exist
$(HTML_DIR): Makefile
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi

# Rule to make the images directory if it doesn't exist
$(IMAGE_DIR): Makefile $(HTML_DIR)
	if [ ! -d $@ ]; then install -d $@; fi
	if [ -O $@ ]; then chmod 775 $@; fi
	
		

# Rule to copy over the help document
$(DESTINATION_MANUAL): $(MANUAL) $(HTML_DIR)
	install $< $@

# Rule to copy over the images.
$(HTML_DIR)/images/%:images/% $(IMAGE_DIR)
	install $< $@

# Main target
install: $(DESTINATION_IMAGE_LIST) $(DESTINATION_MANUAL)

# Clean up files. Leaves directories.
clean: 
	rm $(DESTINATION_IMAGE_LIST)
	rm $(DESTINATION_MANUAL)

debug:
	@echo HTML_DIR: $(HTML_DIR)
	@echo IMAGE_DIR: $(IMAGE_DIR)
	@echo DESTINATION_IMAGE_LIST: $(DESTINATION_IMAGE_LIST)
	@echo IMAGE_FILES: $(IMAGE_FILES)
	@echo DESTINATION_MANUAL: $(DESTINATION_MANUAL)