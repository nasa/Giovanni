#!/usr/bin/perl
use strict;
use XML::LibXML;
use Getopt::Long;
use File::Temp;
use File::Path;
use Giovanni::Agent;
use Giovanni::Util;
use Giovanni::Data::NcFile;
use Safe;

my $rootPath;

BEGIN {
    $rootPath = ( $0 =~ /(.+\/)bin\/.+/ ? $1 : undef );
    push( @INC, $rootPath . 'share/perl5/' )
        if defined $rootPath;
}

my ( $planFile, $outDir, $opt_h, $opt_v );

# Get command line options
Getopt::Long::GetOptions(
    "h"   => \$opt_h,
    "f=s" => \$planFile,
    "o=s" => \$outDir,
    "v"   => \$opt_v
);
if ( defined $opt_h ) {
    print STDERR
        "$0 -f 'test cases file' -o 'output directory' 'URL for Giovanni #1' 'URL for Giovanni #2'\n";
    print "Specify -v for verbose option\n";
    exit(0);
}

# Make sure two Giovanni instances are specified
die "Specify the URLs for two Giovanni instances" unless ( @ARGV == 2 );

# Check existence of output dir if one is supplied
die "Specify output directory (-o) for storing downloaded files\n"
    unless defined $outDir;
die "$outDir doesn't exist"  unless -d $outDir;
die "$outDir isn't writable" unless -w $outDir;

# Based on the root path, read the Giovanni confiuration file which
# contains session location and URL mappings
my $cfgFile = $rootPath . "/cfg/giovanni.cfg";
my $cpt     = Safe->new('GIOVANNI');
die "Failed to read $cfgFile" unless ( $cpt->rdo($cfgFile) );

# Parse the test plan and get a document element
my $dom;
eval { $dom = XML::LibXML->load_xml( location => $planFile ); }
    or die "Failed to parse $planFile ($@)";
my $doc = $dom->documentElement();

# Parse all tests and create a list of tests (hash refs)
my @testList = ();
foreach my $testNode ( $doc->findnodes('./test') ) {
    my $name = $testNode->getAttribute('name');
    my $imgTest
        = ( lc( $testNode->getAttribute('image') ) eq 'true' ) ? 1 : 0;
    my $query = $testNode->findvalue('./query');
    my $desc  = $testNode->findvalue('./description');
    push(
        @testList,
        {   name        => $name,
            imgTest     => $imgTest,
            query       => $query,
            description => $desc,
            urlList     => [ "$ARGV[0]#$query", "$ARGV[1]#$query" ],
            outDir      => defined $outDir ? $outDir : undef
        }
    );
}

# Run tests one by one
my $exitStatus = 0;
foreach my $test (@testList) {
    print STDERR
        "Name: $test->{name}\nDescription: $test->{description}\nQuery: $test->{query}\n";
    my ( $flag, $message ) = runTest( $test, $opt_v );
    print STDERR "Status: "
        . ( $flag ? "Success" : "Fail" ) . "\n"
        . $message . "\n";
    $exitStatus = 1 unless $flag;
}
exit $exitStatus;

# Method that runs a test and returns a flag (1/0) and a message
sub runTest {
    my ( $test, $verbose ) = @_;

    # Create a temporary output directory if one doesn't exist
    my $outDir
        = defined $test->{outDir}
        ? $test->{outDir}
        : File::Temp::tempdir( CLEANUP => 1 );

    my $i        = 0;
    my $filesRef = {};
    my $imgsRef  = {};
    my @timeList = ();
URL_LOOP: for my $url ( @{ $test->{urlList} } ) {
        my $agent = Giovanni::Agent->new( URL => $url );

        # Make sure that the agent doesn't throw an error
        if ( $agent->onError() ) {
            print STDERR $agent->errorMessage(), "\n";
            $filesRef->{$i} = [];
            next URL_LOOP;
        }

        # Time stamps are for log messages only
        my $t1      = time();
        my $timeStr = `date`;
        chomp $timeStr;
        print STDERR "Time: $timeStr\nSubmitting request: $url\n";
        my $response = $agent->submit_request();
        my $t2       = time();
        if ( $response->is_success() ) {
            my $replace = '/';

# Get the session IDs from the response. For example: _SESSION_ID=D629BA9A-841C-11E5-97D1-028EC2763517 _RESULTSET_ID=D62BCCCC-841C-11E5-97D1-028EC2763517 _RESULT_ID=D62BE8A6-841C-11E5-97D1-028EC2763517
            my $sessionId   = $response->getSessionId();
            my $resultId    = $response->getResultId();
            my $resultSetId = $response->getResultSetId();
            print STDERR "Session is: /var/giovanni/session/"
                . $sessionId . "/"
                . $resultSetId . "/"
                . $resultId . "/\n";
            my $subDir = $test->{name};
            $subDir =~ s/\W/_/g;
            my $testOutDir = "$outDir/" . $subDir . "/$i";
            File::Path::make_path($testOutDir);
            die "Failed to create $testOutDir" unless ( -d "$testOutDir" );
            my $response
                = $response->download_data_files( DIR => $testOutDir );

            # Download image files only if data download succeeds
            # and image comparison is needed
            $response = $response->download_image_files( DIR => $testOutDir )
                if $response->is_success && $test->{imgTest};

            if ( $response->is_success ) {

                # On successful submission, download files
                my @files = $response->getDownloadedDataFileNames();
                print STDERR "Downloaded data files: ", join( "\n", @files ),
                    "\n";

                # Download images
                my @imgs
                    = $test->{imgTest}
                    ? $response->getDownloadedImageFileNames()
                    : ();
                print STDERR "Downloaded image files: ", join( "\n", @imgs ),
                    "\n"
                    if $test->{imgTest};

                # Save downloaded files
                $filesRef->{$i} = \@files;
                $imgsRef->{$i}  = \@imgs;
            }
            else {
                print STDERR "No files were downloaded: ",
                    $response->message(), "\n";
                $filesRef->{$i} = [];
                $imgsRef->{$i}  = [];
            }
        }
        else {
            $filesRef->{$i} = [];
            $imgsRef->{$i}  = [];
            return ( 0, "Failed to get $url" );
        }
        push( @timeList, ( $t2 - $t1 ) );

        $i++;
    }

    # Get list of files for each instance
    my @fileList1 = @{ $filesRef->{0} };
    my @fileList2 = @{ $filesRef->{1} };

    # Check for presence of image files if testing images
    return ( 0, "Did not find any images\n" )
        if ( $test->{imgTest}
        && ( @{ $imgsRef->{0} } == @{ $imgsRef->{0} } )
        && ( @{ $imgsRef->{0} } == 0 ) );
    push( @fileList1, @{ $imgsRef->{0} } );
    push( @fileList2, @{ $imgsRef->{1} } );

    my $flag    = 1;
    my $message = "Took $timeList[0] and $timeList[1] seconds\n";
    return ( 0, $message . "Number of files differ\n" )
        unless @fileList1 == @fileList2;

    # Compare each file
FILE_LOOP: for ( my $i = 0; $i < @fileList1; $i++ ) {
        my ( $fname, $dir, $suffix )
            = File::Basename::fileparse( $fileList1[$i], qr/\.[^.]*$/ );
        $suffix = lc($suffix);
        if ( $suffix eq '.csv' ) {

            # Case of csv files
            my @diffOut = `diff -q "$fileList1[$i]" "$fileList2[$i]"`;
            if (@diffOut) {
                $flag = 0;
                $message .= "$fileList1[$i] & $fileList2[$i] differ\n";
            }
        }
        elsif ( $suffix eq '.nc' ) {
            my ($stat) = findStat( $fileList1[$i], $fileList2[$i], $verbose );
            if ( defined $stat ) {
                if (exists $stat->{varlist} ) {
                        $flag = 0;
                        $message
                            .= "$fileList1[$i] & $fileList2[$i] variables differ:$stat->{varlist} )\n";
                        next FILE_LOOP;
                }
                foreach my $var ( keys %$stat ) {
                    if (    $stat->{$var}{min} == $stat->{$var}{max}
                        and $stat->{$var}{max} == 0 )
                    {
                    }
                    else {
                        $flag = 0;
                        $message
                            .= "$fileList1[$i] & $fileList2[$i] differ for $var: difference=($stat->{$var}{min}, $stat->{$var}{max})\n";
                        next FILE_LOOP;
                    }
                }
            }
            else {
                $flag = 0;
                $message
                    .= "$fileList1[$i] & $fileList2[$i] differ: contains NaN\n";
                next FILE_LOOP;
            }
        }
        elsif (( $suffix eq '.png' )
            or ( $suffix eq '.gif' )
            or ( $suffix eq '.jpg' ) )
        {

            # Case of img files
            my ($imgCompareStr)
                = `compare "$fileList1[$i]" "$fileList2[$i]" -metric AE NULL: 2>&1`;
            if ( $? or ( $imgCompareStr != 0 ) ) {
                $flag = 0;
                $message
                    .= "Failed to compare $fileList1[$i] & $fileList2[$i] ($imgCompareStr)\n";
            }
            elsif ( $imgCompareStr != 0 ) {
                $flag = 0;
                $message
                    .= "$fileList1[$i] & $fileList2[$i] differ in $imgCompareStr pixels\n";
            }
        }
        else {
            $flag = 0;
            $message
                .= "$fileList1[$i] & $fileList2[$i] differ: unknown file format ($suffix)\n";
        }
    }
    return ( $flag, $message );
}

# Finds the statistics (currently on min & max) of difference of two files
# Returned hash ref contains variable names as primary key and statistical
# measures (min, max) as secondary keys
sub findStat {
    my ( $file1, $file2, $verbose ) = @_;

    $verbose = 0 unless defined $verbose;

    my $difFile = File::Temp::tmpnam();
    my $stat    = {};


    # capture any dimensions have the quantity_type attribute:
    # dimensions (bins) were given this attribute in Histogram workflow)
    # Other solutions are:
    # 1. Fix Histogram so it doesn't add quantity_type to bins
    # 2. Create a real Giovanni::Util::getNetcdfDataVariables() that really
    # does only return DATA variables.
    # This solution:
    # cp them to another variable name (in the same file)
    # store that new variable name in the varList so that it's
    # difference will be examined and not the original coordinate variable
    my ($dummy, $varListString1)   = copy_quantity_type_variables($file1);
    my ($varList, $varListString2) = copy_quantity_type_variables($file2);
    # ncdiff succeeds silently if variables are different
    if ($varListString1 ne $varListString2) {
        $stat->{varlist} = qq($varListString1 ne $varListString2);
        return $stat; 
        # variables in each downloaded file that contain quantity_type are different 
    }


    # now diff:
    my $diffOut = `ncdiff "$file1" "$file2" $difFile`;
    print STDERR "$file1 and $file2 differ:\n", $diffOut if $verbose;
    if ($?) {
        print STDERR "Failed to difference $file1 and $file2\n";
        return undef;
    }

    # Loop through every variable in the difference
    my ( $inMin, $inMax, $outMin, $outMax ) = ( {}, {}, {}, {} );
    foreach my $var ( keys %$varList ) {
        foreach my $file ( $file1, $file2 ) {
            my ( $min, $max )
                = Giovanni::Util::getNetcdfDataRange( $file, $var );
            return undef if ( $min =~ /NaN/ or $max =~ /NaN/ );
            $inMin->{$var}
                = exists $inMin->{$var}
                ? ( $inMin->{$var} < $min ? $inMin->{$var} : $min )
                : $min;
            $inMax->{$var}
                = exists $inMax->{$var}
                ? ( $inMax->{$var} > $max ? $inMax->{$var} : $max )
                : $max;
        }
        my ( $min, $max )
            = Giovanni::Util::getNetcdfDataRange( $difFile, $var );
        return undef if ( $min =~ /NaN/ or $max =~ /NaN/ );
        $outMin->{$var}
            = exists $outMin->{$var}
            ? ( $outMin->{$var} < $min ? $outMin->{$var} : $min )
            : $min;
        $outMax->{$var}
            = exists $outMax->{$var}
            ? ( $outMax->{$var} > $max ? $outMax->{$var} : $max )
            : $max;
    }

    foreach my $var ( keys %$varList ) {
        $stat->{$var}{min} = $outMin->{$var};
        $stat->{$var}{max} = $outMax->{$var};
    }
    return $stat;
}

# This will copy the dimension variables that have
# the quantity_type attribute to another variable so that
# ncdiff will diff them:
sub copy_quantity_type_variables {
  my $file = shift;
  my %varList = Giovanni::Util::getNetcdfDataVariables($file);
  my $ncfile = Giovanni::Data::NcFile->new(
           NCFILE      => $file, 
           verbose     => 0);
    $ncfile->get_dimension_names();
    foreach my $var ( keys %varList ) {
          if (exists($ncfile->{topdim}{names}{$var})) {
             my $newvar = 'new_' . $var;
             my $status = $ncfile->copy_dimension_to_another_variable_name($var, $newvar);
             if ($status == 1 ) {
                $varList{$newvar} = $varList{$var};
                delete $varList{$var};
             }
             # otherwise keep the old var
             # Will behave same as before
          }
    }
  my @arrList = sort keys %varList;
  return (\%varList, join("", @arrList));
}

__END__

=head1 NAME

compareGiovannis.pl - Script to compare two Giovanni instances

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

compareGiovannis.pl
[B<-f> Giovanni test cases file]
[B<-o> Directory to download files]
[B<-h> Prints command synopsis] 
[B<-v> Verbose option] 
Giovanni Instance #1 URL
Giovanni Instance #1 URL
Giovanni Instance #2 URL

=head1 DESCRIPTION

Given a file with test cases for Giovanni (Giovanni query with a name) and 
Giovanni instance URLs (ex: http://giovanni.gsfc.nasa.gov/giovanni/), the 
script executes Giovanni service specified in the test case, downloads data 
files, compares downloaded files and determines the outcome of success 
(Success/Fail). The test is considered successful if data files (netCDF) from 
two Giovanni instances for the query being tested have variables with same 
values. When it finds differences in the output files, a message is printed out 
indicating the min and max. If data files are in a textual format, the diff 
command is used to determine the difference. 

Sample test cases file looks like:

    <tests>
        <test name="ArAvTs 002">
            <description>ArAvTs: out of range units conversion</description>
            <query>service=ArAvTs;starttime=2010-01-01T00%3A00%3A00Z;endtime=2010-01-11T23%3A59%3A59Z;bbox=-82.2656%2C-66.6797%2C-50.625%2C-44.1797;data=TRMM_3B42_daily_precipitation_V6%2CTRMM_3B42RT_daily_7_precipitation%28units%3Dinch%2Fday%29;dataKeyword=daily;portal=GIOVANNI</query>
        </test>
    </tests>

=head1 OPTIONS

=over 4

=item B<h>

Prints command synposis

=item B<v>

Prints detailed messages.

=item B<f>

Giovanni test cases file

=item B<o>

Directory to store downloaded files. Data related to test cases will be stored in <test case name>/0 and <test case name>/1 for the first and second Giovanni instances respectively.

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

None

=head1 EXAMPLES

perl compareGiovannis.pl -f testPlan.xml -o /var/scratch/mhegde/test/ "http://giovanni.gsfc.nasa.gov/giovanni/" "http://giovanni-test.gesdisc.eosdis.nasa.gov/giovanni/"

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut

