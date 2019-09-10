#
# $Id: Makefile,v 1.27 2015/12/05 01:45:57 eseiler Exp $
#

# Expect values to be set for:
# PREFIX: directory prefix for installation
# PREFIX_INSTALL: directory prefix for installation without additional prefix
#                 e.g. build prefix used for creating RPM
# PREFIX_CATALOG directory prefix for data catalog directories

PERM_CFG = 664
PERM_DIR = 775

BASELINE=NO_BASELINE
GROUP_DIR=wwwuser
ifeq ($(patsubst %/tools/gdaac/TS2,/tools/gdaac/TS2,$(PREFIX)),/tools/gdaac/TS2)
	BASELINE=TS2
	GROUP=testanddev
endif
ifeq ($(patsubst %/opt/edda_dev,/opt/edda_dev,$(PREFIX)),/opt/edda_dev)
	BASELINE=TS2
	GROUP=wwwuser
endif
ifeq ($(patsubst %/tools/gdaac/TS1,/tools/gdaac/TS1,$(PREFIX)),/tools/gdaac/TS1)
	BASELINE=TS1
	GROUP=cfts1
endif
ifeq ($(patsubst %/opt/edda,/opt/edda,$(PREFIX)),/opt/edda)
	BASELINE=TS1
	GROUP=wwwuser
endif
ifeq ($(PREFIX_INSTALL),)
	PREFIX_INSTALL=$(PREFIX)
endif

TMPSAV	= /var/tmp
CFG_DIR = $(PREFIX)/cfg/EDDA
CFG_FILES = \
	edda.cfg \
	dataFieldAccessFormatValids.xml \
	dataFieldAccessFormatVersionValids.xml \
	dataFieldAccessMethodValids.xml \
	dataFieldDisciplineValids.xml \
	dataFieldFillValueFieldNameValids.xml \
	dataFieldMeasurementValids.xml \
	dataFieldSldValids.xml \
	dataFieldValuesDistributionValids.xml \
	dataFieldTagsValids.xml \
	dataProductDataCenterValids.xml \
	dataProductPlatformInstrumentValids.xml \
	dataProductProcessingLevelValids.xml \
	dataProductResponseFormatValids.xml \
	dataProductSpatialResolutionUnitsValids.xml \
	dataProductSpecialFeaturesValids.xml \
	dataProductTimeFrequencyValids.xml \
	dataProductTimeIntervalValids.xml \
	dataFieldTimeIntvRepPosValids.xml \
	dataField.xsl \
	dataProduct.xsl \
	exportToAddDoc.xsl \
	edda_df_basic_to_full.xsl \
	edda_df_full_to_basic.xsl \
	edda_dp_basic_to_full.xsl \
	edda_dp_full_to_basic.xsl

$(CFG_DIR)/%.cfg: %.cfg
	if [ ! -d $(CFG_DIR) ]; then install -m $(PERM_DIR) -g $(GROUP) -d $(CFG_DIR); fi
	sed -e 's#INSERT_BASELINE_HERE#$(BASELINE)#g;s#INSERT_PREFIX_HERE#$(PREFIX_INSTALL)#g' < $< > $(TMPSAV)/$<
	install $(TMPSAV)/$< $@
	if [ -f $(TMPSAV)/$< ]; then rm -f $(TMPSAV)/$<; fi
	if [ -O $@ ]; then chmod $(PERM_CFG) $@; fi
	if [ -O $@ ]; then chgrp $(GROUP) $@; fi

$(CFG_DIR)/%.xml: %.xml
	if [ ! -d $(CFG_DIR) ]; then install -m $(PERM_DIR) -g $(GROUP) -d $(CFG_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod $(PERM_CFG) $@; fi
	if [ -O $@ ]; then chgrp $(GROUP) $@; fi

$(CFG_DIR)/%.xsl: %.xsl
	if [ ! -d $(CFG_DIR) ]; then install -m $(PERM_DIR) -g $(GROUP) -d $(CFG_DIR); fi
	install $< $@
	if [ -O $@ ]; then chmod $(PERM_CFG) $@; fi
	if [ -O $@ ]; then chgrp $(GROUP) $@; fi

install: ${CFG_FILES:%=${CFG_DIR}/%}

test: ${CFG_FILES:%=${CFG_DIR}/%}
