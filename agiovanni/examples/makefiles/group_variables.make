# From parent Makefile
GROUP_TYPE = SEASON
GROUP_VALUE = DJF,MAM
STARTTIME = 2012-01-01T00:00:00Z
ENDTIME = 2014-12-31T23:59:59Z
MFST_FILE = mfst.data_group+dAIRX3STM_006_TotCH4_A+t20111201000000_20140531235959+gSEASON_DJF.xml

ifdef GROUP_TYPE
  CLASSES = $(shell echo $(GROUP_VALUE) | sed 's/,/ /g')
  # Special targets to get around restrictions on comma and space in make functions
  # From the GNU make manual
  comma:= ,
  empty:=
  # Put space between two empty's
  space:= $(empty) $(empty)
  # Hmmm...seems like we're just repeating group
  GROUP_VALUES = $(subst $(space),$(comma),$(CLASSES))
endif

# Define a user-defined makefile function:
#    mfstfile2grouparg (use for wrapper algorithms):
#    Convert a target filename to the necessary group arguments, iff grouping has been specified.
mfstname2grouparg = $(shell perl -e 'if (qw($(1)) =~ /\+g$(GROUP_TYPE)_([^+\.]+)/) {print "--group $(GROUP_TYPE)=$$1"}')

#############################################################################
# Find start and stop dates for given combinations of season
# If doing SEASON DJF, adjust start year back one and adjust end date if leap year

ifeq ($(GROUP_TYPE),SEASON)
  STARTYR=$(shell echo $(STARTTIME) | cut -c 1-4)
  GOT_DJF = $(findstring DJF, $(CLASSES))
  STARTYEAR=$(if $(GOT_DJF),$(shell echo '$(STARTYR) - 1'|bc),$(STARTYR))
  # How we do table lookup in Make syntax: filter then basename to get value
  SEASONSTART = 12.DJF 03.MAM 06.JJA 09.SON
  STARTMONTH = $(basename $(filter %.$(firstword $(CLASSES)), $(SEASONSTART)))
  WF_STARTTIME = $(STARTYEAR)-$(STARTMONTH)-01T$(shell echo $(STARTTIME)|sed 's/.*T//')

  ENDYEAR = $(shell echo $(ENDTIME) | cut -c 1-4)
  SEASONEND = 02.DJF 05.MAM 08.JJA 11.SON
  ENDMONTH = $(basename $(filter %.$(lastword $(CLASSES)), $(SEASONEND)))
  SEASONDAY = 28.DJF 31.MAM 31.JJA 30.SON
  ENDDAY_0 = $(basename $(filter %.$(lastword $(CLASSES)), $(SEASONDAY)))
  # Correct for leap year: add 1 if DJF and divisible by 4 but not by 100 unless it's by 400
  ENDDAY = $(shell echo $(ENDYEAR) $(ENDMONTH) $(ENDDAY_0) |awk '{y=$$1; if (($$2 == 02) && !(y%4) && ((y%100) || !(y%400))){$$3++} print $$3}')
  WF_ENDTIME = $(ENDYEAR)-$(ENDMONTH)-$(ENDDAY)T$(shell echo $(ENDTIME)|sed 's/.*T//')
else
  WF_STARTTIME = $(STARTTIME)
  WF_ENDTIME = $(ENDTIME)
endif

#############################################################################

all:
	@echo group type: $(GROUP_TYPE)
	@echo classes: $(CLASSES)
	@echo group values: $(GROUP_VALUES)
	@echo Initial  date/time range: $(STARTTIME) to $(ENDTIME)
	@echo Adjusted date/time range: $(WF_STARTTIME) to $(WF_ENDTIME)
	@echo group argument: $(call mfstname2grouparg,$(MFST_FILE))
#  Most common mistakes in calling a user-defined function:  
#  omitting "call", forgetting ","
