# Find start and stop dates for given combinations of season
# If doing SEASON DJF, adjust start year back one and adjust end date if leap year

# From parent Makefile...
STARTTIME = 2012-01-01T00:00:00Z
ENDTIME = 2014-12-31T23:59:59Z
GROUP_TYPE = SEASON
GROUP_VALUE = 

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
