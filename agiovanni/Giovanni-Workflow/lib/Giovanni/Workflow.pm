#$Id: Workflow.pm,v 1.50 2015/04/02 20:19:00 mhegde Exp $
#-@@@ aGiovanni, Version $Name:  $

package Giovanni::Workflow;

use 5.008008;
use strict;
use warnings;
use File::Basename;
use XML::LibXML;
use Giovanni::Util;
use Cwd;
use Date::Parse;
use vars '$AUTOLOAD';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

sub new() {
    my ( $class, %input ) = @_;
    my $self = {};

    if ( defined $input{WORKFLOW} ) {

        # Get the list of workflows
        my @workflowFileList
            = ( ref $input{WORKFLOW} eq 'ARRAY' )
            ? @{ $input{WORKFLOW} }
            : ( $input{WORKFLOW} );
        foreach my $workflowFile (@workflowFileList) {
            unless ( -f "$input{WORKFLOW_DIR}/$workflowFile" ) {
                return bless( $self, $class );
            }
        }
        $self->{_WORKFLOW}{TYPE} = 'MAKE';
        $self->{_WORKFLOW}{FILE} = $input{WORKFLOW_DIR} . "/Makefile";
        createMakefile( $input{WORKFLOW_DIR}, @workflowFileList );
    }
    elsif ( -d $input{WORKFLOW_DIR} ) {
        if ( -f $input{WORKFLOW_DIR} . "/Makefile" ) {
            $self->{_WORKFLOW}{FILE} = $input{WORKFLOW_DIR} . "/Makefile";
            $self->{_WORKFLOW}{TYPE} = "MAKE";
        }
    }

    return bless( $self, $class );
}

sub createMakefile {
    my ( $workflowDir, @workflowFileList ) = @_;
    my $inputXmlFile = $workflowDir . '/input.xml';
    my $makeFile     = $workflowDir . '/Makefile';
    my $inputDoc     = Giovanni::Util::parseXMLDocument($inputXmlFile);
    my $bbox         = $inputDoc->findvalue('//bbox/text()');
    my $startTime    = $inputDoc->findvalue('//starttime/text()');
    my $endTime      = $inputDoc->findvalue('//endtime/text()');
    my $service      = $inputDoc->findvalue('//service/text()');
    my $sessionDir   = $inputDoc->findvalue('//dir/text()');
    my $portal       = $inputDoc->findvalue('//portal/text()');
    my $verbose      = $inputDoc->findvalue('//verbose/text()');
    my $seasons      = $inputDoc->findvalue('//seasons/text()');
    my $months       = $inputDoc->findvalue('//months/text()');
    my $shape        = $inputDoc->findvalue('//shape/text()');
    my $user         = $inputDoc->findvalue('//user/text()');
    my $groupType
        = ( $seasons ne '' ? 'SEASON' : ( $months ne '' ? 'MONTH' : '' ) );
    my $groupValue
        = ( $seasons ne '' ? $seasons : ( $months ne '' ? $months : '' ) );

    my @dataList = ();
    my @zvals    = ();

    # Read units configuration file if one is defined
    my $unitsDoc
        = defined $GIOVANNI::UNITS_CFG
        ? Giovanni::Util::parseXMLDocument($GIOVANNI::UNITS_CFG)
        : undef;

    # Set the verbose value to zero if not defined
    $verbose = 0 if ( ( not defined $verbose ) || ( $verbose !~ /\d+/ ) );
    foreach my $node ( $inputDoc->findnodes('//data') ) {
        my $data = $node->textContent();

        # Escape ':'; make doesn't like it in target/dependency names
        $data =~ s/:/\\:/g;
        push( @dataList, $data );
        my $zv   = $node->getAttribute('zValue');
        my $unit = $node->getAttribute('units');
        $unit = 'NA' unless defined $unit;
        if ( defined $unitsDoc && $unit ne 'NA' ) {
            my ($node)
                = $unitsDoc->findnodes(
                      '/units/fileFriendlyStrings/destinationUnit[@original="'
                    . $unit
                    . '"]' );
            $unit = $node->getAttribute('file') if defined $node;
        }
        $zv = 'NA' unless ( defined $zv );
        $zv =~ s/[\.\+]/_/g;
        push( @zvals, $data . '+z' . $zv . '+u' . $unit );
    }
    my $makeFileContent = <<END_OF_MAKE;
VERBOSE = $verbose
PORTAL = $portal
BBOX = $bbox
STARTTIME = $startTime
ENDTIME = $endTime
SERVICE = $service
AESIR = $GIOVANNI::DATA_CATALOG
SESSION_DIR = $sessionDir
CACHE_DIR = $GIOVANNI::CACHE_DIR
MISSING_URL_FILE = $GIOVANNI::MISSING_URL_FILE
UNITS_CFG = $GIOVANNI::UNITS_CFG
SHAPEFILE = $shape
USER = $user
USER_DIR = $GIOVANNI::USER_DATA_DIR
END_OF_MAKE
    $makeFileContent .= 'DATA = ' . join( " ", @dataList ) . "\n";
    $makeFileContent .= 'DATA_SLICE = ' . join( " ", @zvals ) . "\n";
    $makeFileContent .= 'GROUP_TYPE = ' . $groupType . "\n"
        if ( $groupType ne '' );
    $makeFileContent .= 'GROUP_VALUE = ' . $groupValue . "\n"
        if ( $groupValue ne '' );
    foreach my $workflow (@workflowFileList) {
        $makeFileContent .= "include " . basename($workflow) . "\n";
    }
    my $status = Giovanni::Util::writeFile( $makeFile, $makeFileContent );
    return $status;
}

sub findExistingTargets {
    my ($self) = @_;

    my $workflow    = $self->getWorkflow();
    my $workflowDir = dirname($workflow);
    my $cwd         = getcwd();
    chdir($workflowDir);

    # Look for manifest files that are regular files
    my @mfstList = `find ../../ -type f -name 'mfst.*.xml' -print`;
    chomp @mfstList;
    my @newTargetList = $self->getTargets('ALL');
    my %newTargetHash = map { basename($_) => 1 } @newTargetList;

# Cull targets so that we have only manifest files needed for the current result
    my @oldTargetList = ();
    foreach my $item (@mfstList) {
        push( @oldTargetList, $item )
            if ( $newTargetHash{ basename($item) } );
    }

# Sort the list based on modification time; this is done to preserve the dependency order for backward chaining
    @oldTargetList = sort { -M $b <=> -M $a } @oldTargetList;
    my $i = 0;
    foreach my $item (@oldTargetList) {
        my $provItem = $item;
        $provItem =~ s/mfst\./prov\./;
        my $logItem = $item;
        $logItem =~ s/\.xml$/.log/;
        next unless ( $newTargetHash{ basename($item) } );
        my %symLinkHash = ();
        foreach my $target ( $item, $provItem, $logItem ) {
            my $file = basename($target);
            next if ( $symLinkHash{$file} );
            symlink( $target, $file ) if -e $target;
            $symLinkHash{$file} = 1;
        }
    }
    chdir($cwd);
}

sub getTargets {
    my ( $self, $flag ) = @_;

    $flag = 'ALL' unless defined $flag;
    my $type        = $self->getType();
    my $workflow    = $self->getWorkflow();
    my $workflowDir = dirname($workflow);
    my $cwd         = getcwd();
    chdir($workflowDir);
    my @targetList = ();
    if ( $type eq 'MAKE' ) {
        my $targetFile = $workflowDir . "/targets.txt";
        if ( -f $targetFile ) {
            @targetList = Giovanni::Util::readFile($targetFile);
            chomp @targetList;
        }
        else {
            my @allList
                = `make -qp all | grep -v '^#.' | grep ':' | grep -v '=' | grep '^mfst' | grep -v '%'`;
            chomp @allList;
            if ($?) {
                @targetList = ();
            }
            else {

 # Remove 'init' targets from the target list as they don't need to be tracked
                my @initList = split( /\s+/,
                    `make -qp | grep '^init:' | cut -f2 -d ':'` );
                my %initTarRef = map { $_ => 1 } @initList;
                foreach my $item (@allList) {
                    my ( $target, ) = split( /:/, $item, 2 );

                    next if exists $initTarRef{$target};
                    push( @targetList, $target );
                }
            }

            # Save target list if possible
            Giovanni::Util::writeFile( $targetFile,
                join( "\n", @targetList ) );

            my $str = `make -s printsteps`;
            my @targetGroupList = $? ? () : split( /\s+/, $str );
            chomp @targetGroupList;
            my $targetGroupFile = $workflowDir . "/provenance_group.txt";
            Giovanni::Util::writeFile( $targetGroupFile,
                join( "\n", @targetGroupList ) );
        }

        # Filter the target list based on the flag
        @targetList
            = ( $flag eq 'ALL' )
            ? map { my $s = $_; $s =~ s/^#//; $s } @targetList
            : grep( !/^#/, @targetList );
    }

    # Restore working dir
    chdir($cwd);

    # Return target list
    return @targetList;
}

sub init {
    my ($self) = @_;

    my $workflow    = $self->getWorkflow();
    my $workflowDir = dirname($workflow);
    my $cwd         = getcwd();
    chdir($workflowDir);
    my $flag = 1;
    my $cmd  = "make -L init 2>&1";
    my $status = system($cmd);
    if ($status) {
        print STDERR "Failed to initialize workflow.\n";
        $self->{_STATUS}{MESSAGE} = "Failed to initialize.\nPlease refer to workflow.log for details.\n";
        $flag = 0;
    }
    chdir($cwd);
    return $flag;
}

sub launch {
    my ( $self, %input ) = @_;
    my $type        = $self->getType();
    my $workflow    = $self->getWorkflow();
    my $workflowDir = dirname($workflow);
    my $cwd         = getcwd();
    my $maxJobCount
        = exists $input{MAX_JOB_COUNT} ? $input{MAX_JOB_COUNT} : 1;
    $maxJobCount = 1 if ( $maxJobCount < 1 );

    # Create initial targets
    $self->init();

    # Link to any existing targets; this must happen after init()
    $self->findExistingTargets();
    chdir($workflowDir);
    my $flag    = 1;
    my $cmd = "make -L all -j $maxJobCount 2>&1";
    my $status = system($cmd);
    if ($status) {
        print STDERR "Failed to run workflow.\n";
        $self->{_STATUS}{MESSAGE} = "Failed to run workflow.\nPlease refer to workflow.log for details.\n";
        $flag = 0;
    }
    chdir($cwd);
    return $flag;
}

sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::getWorkflow/ ) {
        return (
            defined $self->{_WORKFLOW}
            ? ( defined $self->{_WORKFLOW}{FILE}
                ? $self->{_WORKFLOW}{FILE}
                : undef
                )
            : undef
        );
    }
    elsif ( $AUTOLOAD =~ /.*::getType/ ) {
        return (
            defined $self->{_WORKFLOW}
            ? ( defined $self->{_WORKFLOW}{TYPE}
                ? $self->{_WORKFLOW}{TYPE}
                : undef
                )
            : undef
        );
    }
    elsif ( $AUTOLOAD =~ /.*::getStatusMessage/ ) {
        return $self->{_STATUS}{MESSAGE};
    }
}

# Gets the most recent status messages for every step and percent done. Takes
# the directory and target names as hash keys.
sub getStatus {
    my (%input) = @_;
    if ( !exists( $input{DIRECTORY} ) ) {
        die("Function requires DIRECTORY key");
    }
    if ( !exists( $input{TARGETS} ) ) {
        die("Function requires TARGETS key");
    }
    my $dir          = $input{DIRECTORY};
    my $targets_ref  = $input{TARGETS};
    my @statuses     = ();
    my @percentDones = ();
    my @times        = ();

    # loop through the targets
    for my $target (@$targets_ref) {
        my ( $status, $percentDone, $time )
            = getStatusOneTarget( $dir, $target );
        push( @statuses,     $status );
        push( @percentDones, $percentDone );
        push( @times,        $time );
    }

    return ( \@statuses, \@percentDones, \@times );
}

# Gets the status for one target
sub getStatusOneTarget {
    my ( $dir, $target ) = @_;

    # figure out the log file name
    my $ret = ( $target =~ m/^(.*)[.]xml$/ );
    my $logFile = "$dir/$1.log";
    if ( !$ret ) {
        die("Unable to parse target $target");
    }

    # if the log file isn't there, return an empty status and 0 percent done
    if ( !( -e $logFile ) ) {
        return ( "", "0", 0 );
    }

    # read through the file (Clearly this is non ideal. We should really be
    # starting at the end of the file.)
    my $percentDone = "0";
    my $status      = "";
    my $time        = 0;
    my $timeRegEx   = '\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d';
    open( FILE, "<", $logFile );
    my @lines = <FILE>;
    chomp(@lines);
    my $i = 0;

    while ( $i < scalar(@lines) ) {

        # get the next entry
        my $entry = $lines[$i];
        $i++;
        while ( $i < scalar(@lines) && !( $lines[$i] =~ m/^($timeRegEx)/ ) ) {
            $entry = $entry . "\n" . $lines[$i];
            $i++;
        }

        # get out the time stamp for this entry
        my $timeStamp;
        $entry =~ m/^($timeRegEx),(\d\d\d)/
            or die "Unable to parse time stamp in $entry";
        $timeStamp = str2time($1);
        my $timeMilliseconds = $2;
        $timeStamp = $timeStamp + ( $timeMilliseconds / 1000.0 );

        # Note: '.' does not match a new line. I want to match everything
        # including new lines. Hence the weird regex. I'm sure there's a
        # more elegant way of doing this.
        if ( $entry =~ m/^.* - \[[A-Z]*\s*] - \S*? - PERCENT_DONE ([\s\S]*)/ ) {
            $percentDone = $1;
        }
        elsif ( $entry =~ m/^.* - \[[A-Z]*\s*] - \S*? - USER_MSG ([\s\S]*)/ ) {
          
            #  message for the users  
            $status = $1;
            $time   = $timeStamp;
        }
        elsif ( $entry =~ m/^.* - \[[A-Z]*\s*] - \S*? - ERROR ([\s\S]*)/ ) {

            # not a message we want users to see
            $status = "";
        }
        elsif ( $entry =~ m/^.* - \[[A-Z]*\s*] - \S*? - USER_ERROR ([\s\S]*)/ ) {

            # error message for users
            # Use hash signs to distinguish error messages from regular messages
            # Consumers of the status should remove this marker when printing to screen
            $status = '##'.$1;
            $time   = $timeStamp;
        }
    }
    close(FILE);
    return ( $status, $percentDone, $time );
}

# Concatenates all the lineage files together. Takes
# the directory and target names as hash keys.
sub getProvenance {
    my (%input) = @_;
    if ( !exists( $input{DIRECTORY} ) ) {
        die("Function requires DIRECTORY key");
    }
    if ( !exists( $input{TARGETS} ) ) {
        die("Function requires TARGETS key");
    }
    my $dir         = $input{DIRECTORY};
    my $targets_ref = $input{TARGETS};

    # create a new XML document
    my $doc = XML::LibXML::Document->new( '1.0', 'utf-8' );
    my $root = $doc->createElement('provenance');
    $doc->setDocumentElement($root);

    # read through the individual provenance steps
    for my $target (@$targets_ref) {

        # figure out the provenance file name
        my $provFile = $target;
        $provFile =~ s/^mfst/prov/;
        $provFile = "$dir/$provFile";
        if ( !( -e $provFile ) ) {
            die(      "Unable to find provenance file for target '$target'."
                    . " Expected file to be '$provFile'." );
        }

        # append it to our current lineage
        my $provXml = Giovanni::Util::parseXMLDocument($provFile);
        $root->appendChild($provXml);
    }

    return $doc;
}
1;

__END__

=head1 NAME

Giovanni::Workflow - Giovanni Perl package to handle launching and monitoring of workflows

=head1 SYNOPSIS

  use Giovanni::Workflow;
  my $workflow = Giovanni::Workflow->new();
  $workflow->launch();
  $workflow->getStatus();
  $workflow->getProvenance();
  $workflow->findExistingTargets()

=head1 DESCRIPTION



=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Mahabaleshwara S. Hegde, E<lt>Mahabaleshwa.S.Hegde@nasa.govE<gt>

=cut

