use strict;
use Test::More tests => 26;
use Giovanni::Testing;
use Giovanni::Data::NcFile;
use File::Temp;

my $dir = $ENV{SAVEDIR} || File::Temp::tempdir( DIR => '.', CLEANUP => 1 );

# Find path for $program
my $program = 'getUnitsArg.pl';
my ($script_path) = Giovanni::Testing::find_script_paths($program);
ok( ( -e $script_path ), "Find script path for $program" );

my $mfst1 = "$dir/mfst.1.xml";
my $mfst2 = "$dir/mfst.2.xml";

# Null cases
write_file( $mfst1,
    '<manifest><data units="NA" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,ALGORITHM units.cfg`,
    '', "No conversion requested" );

write_file( $mfst1,
    '<manifest><data zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 POST,POST units.cfg`,
    '', "No conversion requested" );

write_file( $mfst1,
    '<manifest><data units="mm/day" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,POST units.cfg`, '', "Not this step" );
is( `$script_path -v $mfst1 POST,POST`,                '', "No config file" );

# Non-null cases
# Single variable
is( `$script_path -v $mfst1 ALGORITHM,ALGORITHM units.cfg`,
    '--units "mm/day,units.cfg",ALGORITHM',
    "One field"
);

# Comparison: convert only one
write_file( $mfst2,
    '<manifest><data units="NA" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,ALGORITHM units.cfg`,
    '--units "mm/day,,units.cfg",ALGORITHM',
    "Comparison"
);

# Comparison: convert both
write_file( $mfst2,
    '<manifest><data units="mm/day" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,ALGORITHM units.cfg`,
    '--units "mm/day,mm/day,units.cfg",ALGORITHM',
    "Comparison"
);

# Time dependent cases
my ( $data_mfst, @data_files ) = write_data($dir);
my $config = "$dir/units.cfg";
write_config($config);

# Non-time-dependent case
is( `$script_path -v $mfst1 ALGORITHM,ALGORITHM,WRAPPER $config $data_mfst`,
    "--units \"mm/day,$config\",ALGORITHM",
    "Non-Time dependent in algorithm"
);

# Time dependent cases
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,ALGORITHM,WRAPPER $config $data_mfst`,
    "--units \"mm/month,$config\",WRAPPER",
    "Time dependent in wrapper"
);

# Single Variable POST, WRAPPER:
# HiGm, InTs, QuCl, TmAvMp, VtPf
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,POST,WRAPPER $config $data_mfst`,
    "--units \"mm/month,$config\",WRAPPER",
    "Time dependent in wrapper: yes, here"
);
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 POST,POST,WRAPPER $config $data_mfst`,
    "", "Time dependent: not here" );

# Comparison (POST, WRAPPER)
# TmAvSc
# This step (time dependent)
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
write_file( $mfst2,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,POST,WRAPPER $config $data_mfst`,
    "--units \"mm/month,mm/month,$config\",WRAPPER",
    "Comparison (time dependent): yes, here"
);

# Not this step (time dependent)
is( `$script_path -v $mfst1,$mfst2 POST,POST,WRAPPER $config $data_mfst`,
    "", "Comparison (time dependent), not here" );

# not time dependent
write_file( $mfst1,
    '<manifest><data units="mm/day" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
write_file( $mfst2,
    '<manifest><data units="mm/day" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,POST,WRAPPER $config $data_mfst`,
    "",
    "POST,WRAPPER Comparison (non-time0dependent): not here"
);
is( `$script_path -v $mfst1,$mfst2 POST,POST,WRAPPER $config $data_mfst`,
    "--units \"mm/day,mm/day,$config\"",
    "POST,WRAPPER Comparison (non-time-dependent): yes, here"
);

# Comparison (POST, POST)
# Time dependent same as non-dependent
# Comparison (ALGORITHM, WRAPPER)
# DiTmAvMp
# This step (time dependent)
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
write_file( $mfst2,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,ALGORITHM,WRAPPER $config $data_mfst`,
    "--units \"mm/month,mm/month,$config\",WRAPPER",
    "Comparison (time dependent)"
);

# Not this step (time dependent)
is( `$script_path -v $mfst1,$mfst2 POST,ALGORITHM,WRAPPER $config $data_mfst`,
    "",
    "Comparison (time dependent), not this step"
);

# Comparison (POST, POST)
# Time dependent same as non-dependent
# ArAvSc, IaSc, StSc
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
write_file( $mfst2,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,POST,POST $config $data_mfst`,
    "", "POST,POST not here" );
is( `$script_path -v $mfst1,$mfst2 POST,POST,POST $config $data_mfst`,
    "--units \"mm/month,mm/month,$config\"",
    "POST,POST yes, here"
);

# Single Variable (POST, POST)
# Time dependent same as non-dependent
# ArAvTs, HvLt, HvLn, MpAn
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,POST,POST $config $data_mfst`,
    "", "POST,POST not here" );
is( `$script_path -v $mfst1 POST,POST,POST $config $data_mfst`,
    "--units \"mm/month,$config\"",
    "POST,POST yes, here"
);

# Comparison (ALGORITHM, ALGORITHM)
# Time dependent same as non-dependent
# DiArAvTs
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
write_file( $mfst2,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V6</data></manifest>'
);
is( `$script_path -v $mfst1,$mfst2 ALGORITHM,ALGORITHM,ALGORITHM $config $data_mfst`,
    "--units \"mm/month,mm/month,$config\",ALGORITHM",
    "ALGORITHM,ALGORITHM yes here"
);
is( `$script_path -v $mfst1,$mfst2 POST,ALGORITHM,ALGORITHM $config $data_mfst`,
    "",
    "ALGORITHM,ALGORITHM not here"
);

# SingleVariable (WRAPPER,WRAPPER)
# Time dependent same as non-dependent
# AcMp
write_file( $mfst1,
    '<manifest><data units="mm/month" zValue="NA">TRMM_3B42_precipitation_V7</data></manifest>'
);
is( `$script_path -v $mfst1 ALGORITHM,WRAPPER,WRAPPER $config $data_mfst`,
    "--units \"mm/month,$config\",WRAPPER",
    "WRAPPER,WRAPPER yes here"
);
is( `$script_path -v $mfst1 POST,WRAPPER,WRAPPER $config $data_mfst`,
    "", "WRAPPER,WRAPPER not here" );

# Cleanup
unlink( $mfst1, $mfst2 ) unless $ENV{SAVEDIR};
unlink( $data_mfst, $config, @data_files ) unless $ENV{SAVEDIR};

sub write_data {
    my $dir    = shift;
    my $mfst   = "$dir/mfst.foo.xml";
    my $ra_cdl = Giovanni::Data::NcFile::read_cdl_data_block();
    my @files = map { "$dir/TRMM_3B42_precipitation_V" . $_ . ".20090101.nc" }
        ( 6, 7 );
    Giovanni::Data::NcFile::write_netcdf_file( $files[0], $ra_cdl->[0] );
    Giovanni::Data::NcFile::write_netcdf_file( $files[1], $ra_cdl->[1] );
    open MFST, '>', $mfst;
    print MFST << "EOF";
<?xml version="1.0"?>
<manifest>
<fileList id="TRMM_3B42_precipitation_V6">
<file>$files[0]</file>
</fileList>
<fileList id="TRMM_3B42_precipitation_V7"><file>$files[1]</file></fileList>
</manifest>
EOF
    close MFST;
    return ( $mfst, @files );
}

sub write_file {
    my ( $file, $string ) = @_;
    open OUT, ">$file" or die "Cannot write to $file: $!\n";
    print OUT $string;
    close OUT;
}

sub write_config {
    my $file = shift;
    open( CFG, '>', $file ) or die "Cannot write to $file: $!";
    print CFG << 'EOF';
<units>
    <linearConversions>
        <linearUnit source="mm/hr" destination="mm/day"
            scale_factor="24" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/hr"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="mm/hr" destination="inch/day"
            scale_factor="24.0/25.4" add_offset="0" />
        <linearUnit source="mm/day" destination="mm/hr"
            scale_factor="1.0/24.0" add_offset="0" />
        <linearUnit source="mm/day" destination="inch/day"
            scale_factor="1.0/25.4" add_offset="0" />
        <linearUnit source="kg/m^2" destination="mm" scale_factor="1"
            add_offset="0" />
        <linearUnit source="K" destination="C" scale_factor="1"
            add_offset="-273.15" />
        <linearUnit source="kg/m^2/s" destination="mm/s"
            scale_factor="1" add_offset="0" />
        <linearUnit source="molecules/cm^2" destination="DU"
            scale_factor="1.0/2.6868755e+16" add_offset="0" />
    </linearConversions>
    <nonLinearConversions>
        <timeDependentUnit source="mm/hr" destination="mm/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0" />
        <timeDependentUnit source="mm/hr" destination="inch/month"
            class="Giovanni::UnitsConversion::MonthlyAccumulation"
            to_days_scale_factor="24.0/25.4" />
        <timeDependentUnit source="mm/hr" destination="inch/month"
         class="Giovanni::UnitsConversion::MonthlyAccumulation"
         to_days_scale_factor="86400.0" />
    </nonLinearConversions>
</units>
EOF
    close CFG;
}
__DATA__
netcdf a {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 1 ;
variables:
    float TRMM_3B42_precipitation_V6(time, lat, lon) ;
        TRMM_3B42_precipitation_V6:_FillValue = -9999.9f ;
        TRMM_3B42_precipitation_V6:coordinates = "time lat lon" ;
        TRMM_3B42_precipitation_V6:units = "mm/hr" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
data:

 TRMM_3B42_precipitation_V6 =
  0 ;

 lat = 29.875 ;

 lon = 99.875 ;

 time = 1230762601 ;
}
netcdf b {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 1 ;
    lon = 1 ;
variables:
    float TRMM_3B42_precipitation_V7(time, lat, lon) ;
        TRMM_3B42_precipitation_V7:_FillValue = -9999.9f ;
        TRMM_3B42_precipitation_V7:coordinates = "time lat lon" ;
        TRMM_3B42_precipitation_V7:units = "mm/hr" ;
    double lat(lat) ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
data:

 TRMM_3B42_precipitation_V7 =
  0 ;

 lat = 29.875 ;

 lon = 99.875 ;

 time = 1230762601 ;
}

