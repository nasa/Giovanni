WF_STARTTIME = 2012-01-01T00:00:00Z
WF_ENDTIME = 2014-12-31T23:59:59Z

# Take out colons, T, Z, and dashes for file names
START_STRING = $(shell echo $(WF_STARTTIME) | sed 's/[TZ:-]//g')
END_STRING = $(shell echo $(WF_ENDTIME) | sed 's/[TZ:-]//g')

# Create TIME_RANGE convenience variable for brevity
TIME_RANGE = $(START_STRING)_$(END_STRING)

all:
	@echo Start string: $(START_STRING)
	@echo End string: $(END_STRING)
	@echo Time range: $(TIME_RANGE)
