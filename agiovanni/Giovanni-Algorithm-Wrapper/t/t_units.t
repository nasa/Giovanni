# Use modules

use strict;
use Test::More tests => 3;
use File::Temp;
use Giovanni::Data::NcFile;
BEGIN { use_ok('Giovanni::Algorithm::Wrapper'); }

my $cleanup = ( not exists $ENV{SAVEDIR} );
my $parent_dir = $ENV{'SAVEDIR'} || $ENV{'TMPDIR'} || '.';
my $dir      = File::Temp::tempdir( DIR => $parent_dir, CLEANUP => $cleanup );
my $cfg_file = write_config_file($dir);
my ( $infile, $ref_file ) = write_data_file($dir);
my @cvt = Giovanni::Algorithm::Wrapper::setup_units_converters(
    "inch/hr,$cfg_file", 'val', [$infile] );

ok( @cvt, "Create converter" );
my $cvt     = $cvt[0];
my $outfile = "$infile.cvt";
ok( $cvt->ncConvert( sourceFile => $infile, destinationFile => $outfile ),
    "Run converter to make $outfile" );

#==============================================================
sub write_data_file {
    my $dir     = shift;
    my $infile  = "$dir/units_input.nc";
    my $outfile = "$dir/units_output.nc";
    my $cdl     = << 'EOF';
netcdf input {
dimensions:
	time = UNLIMITED ; // (3 currently)
variables:
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float val(time) ;
		val:units = "mm/hr" ;

// global attributes:
		:temporal_resolution = "daily" ;
data:

 time = 1232150400, 1232236800, 1232323200 ;

 val = -0.9884639, -0.8631611, -0.1213655 ;
}
EOF
    Giovanni::Data::NcFile::write_netcdf_file( $infile, $cdl );

    $cdl = << 'EOF';
netcdf output {
dimensions:
	time = UNLIMITED ; // (3 currently)
variables:
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float val(time) ;
		val:units = "inch/hr" ;

// global attributes:
		:temporal_resolution = "daily" ;
data:

 time = 1232150400, 1232236800, 1232323200 ;

 val = -0.0389159, -0.0339827, -0.0047782 ;
}
EOF
    Giovanni::Data::NcFile::write_netcdf_file( $outfile, $cdl );

    return ( $infile, $outfile );
}

sub write_config_file {
    my $dir     = shift;
    my $outfile = "$dir/units-cfg.xml";
    open OUT, ">$outfile";
    print OUT << 'EOF';
<units>
        <linearConversions>
                <linearUnit source="mm/hr" destination="mm/day" scale_factor="24"
                        add_offset="0" />
                <linearUnit source="mm/hr" destination="inch/hr"
                        scale_factor="1.0/25.4" add_offset="0" />
                <linearUnit source="mm/hr" destination="inch/day"
                        scale_factor="24.0/25.4" add_offset="0" />
                <linearUnit source="mm/day" destination="mm/hr" scale_factor="1.0/24.0"
                        add_offset="0" />
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
                <nonLinearUnit source="mm/hr" destination="mm/month"
                        function="monthlyRate" />
                <nonLinearUnit source="mm/hr" destination="inch/month"
                        function="monthlyRate" />
        </nonLinearConversions>
</units>
EOF
    close(OUT);
    return $outfile;
}
