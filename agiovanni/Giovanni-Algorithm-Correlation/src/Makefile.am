bin_PROGRAMS = nccorrelate

nccorrelate_SOURCES = nccorrelate.c \
		accumulate.c array_regression.c find_bounds.c \
		parse_varstring.c read_nc_var.c read_att.c write_netcdf_output.c

man_MANS = nccorrelate.1

check_PROGRAMS = t_accumulate t_array_regression t_parse_varstring t_read_nc_var t_write_netcdf_output t_nccorrelate t_find_bounds
t_array_regression_SOURCES = t_array_regression.c array_regression.c check.c
t_read_nc_var_SOURCES = t_read_nc_var.c read_nc_var.c read_att.c cdl2nc.c
t_accumulate_SOURCES = t_accumulate.c accumulate.c read_nc_var.c read_att.c cdl2nc.c
t_write_netcdf_output_SOURCES = t_write_netcdf_output.c cdl2nc.c write_netcdf_output.c
t_nccorrelate_SOURCES = t_nccorrelate.c cdl2nc.c cdldiff.c run_nccorrelate_test.c system_call.c
t_parse_varstring_SOURCES = t_parse_varstring.c parse_varstring.c
t_find_bounds_SOURCES = t_find_bounds.c find_bounds.c parse_varstring.c read_nc_var.c read_att.c

NETCDF_PREFIX = @NETCDF_PREFIX@
AM_CPPFLAGS = -I$(NETCDF_PREFIX)/include
AM_CFLAGS = -g -O0

LDADDS = -L$(NETCDF_PREFIX)/lib -lnetcdf -lhdf5_hl -lhdf5 -lz -lm -lcurl
nccorrelate_LDADD = $(LDADDS)
t_array_regression_LDADD = $(LDADDS)
t_read_nc_var_LDADD = $(LDADDS)
t_accumulate_LDADD = $(LDADDS)
t_write_netcdf_output_LDADD = $(LDADDS)
t_find_bounds_LDADD = $(LDADDS)

TESTS = $(check_PROGRAMS)
