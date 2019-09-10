#$Id: Scrubber.pm,v 1.50 2015/09/03 14:08:37 rstrub Exp $

package Giovanni::Scrubber;

@ISA    = qw(Exporter);
@EXPORT = qw(quit runNCOCommand  EvenOutLatitudes
    dump2XML move_file getRootNode
    createAttribute deleteAttribute
    getVariablesForKeeping getChildrenNodeList
    getAttributeValue deleteSelectedVariables
    runVirtualGenerator do_padding get_padding
    reverseCoords add_offset dateobj2attribute
    insist_on_lastsecondoftheday isaLatitude isaLongitude
    update_type createSortedListingFile  make_record_dimension
    getVariableValues  getVariableNamesString
    getTimeVariableDimName2  changeAttributeName
    changeVariableName  updateAttributeValue
    existsAttribute  createXMLDocument  handleUnitsUpdate
    padding_sequence  getDateMidpoint  update_time_value
    handling_already_unpacked_data  ApplyValidMinAndValidMax
    applyCellMethodPointForInstantaneous
    addTimeBnds  addLatLonBnds  apply_timeIntvRepPos
    rename_dimensionVariables getIndexVariable
);

our $VERSION = '2.21';

use Safe;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use DB_File;
use File::Copy;
use CGI;
use Fcntl ':flock';
use Time::Local;
use XML::LibXML;
use POSIX;

use strict;

our ( $verbose, $total );

sub new {
    my ( $pkg, %params ) = @_;
    my $self = bless \%params, $pkg;
    $self->{OK} = 1;
    return $self;
}

# Untainting here is no longer needed.
#
sub handleInput {

    my $self = shift;

    my $input = shift;

    foreach my $parm ( keys %$input ) {
        print STDERR qq(handleInput: $parm $input->{$parm}\n);

            if ( not exists $SCRUBBER::ATTR_NAMES->{$parm} ) {
                print STDERR qq($parm is not one listed in rescrubber.cf \n);
            }
            else {
                $self->{$parm} = $input->{$parm};
            }

          # Now we have to see if it is one of the ones we are actually doing:
            if ( not exists $SCRUBBER::PROCESSING->{$parm} ) {
                delete $self->{$parm};    # so it doesn't bother us later
                  # If it isn't in our list at all then we have already exited
            }
    }

    return 0;
}

sub CheckToSeeIfWeHaveAnyLeft {
    my $self   = shift;
    my $status = 1;
    foreach my $key ( keys %{$SCRUBBER::ATTR_NAMES} ) {
        print STDERR "checking against $key\n";
        if ( exists $self->{$key} ) {
            return 0;
        }
    }
    $self->{message} = "No valid attributes survived validation";
    return $status;
}

sub sendmail {
    my $person  = shift;
    my $message = shift;
    my $SUBJECT = shift;

    open( MAIL, "| /usr/sbin/sendmail -t" );

    print MAIL "To: $person\n";
    print MAIL "From: ReScrubber\@Giovanni.gov\n";
    print MAIL "Subject: $SUBJECT\n\n";
## Mail Body
    print MAIL qq($message\n);

    close(MAIL);
}

sub getFilenames {
    my $self   = shift;
    my $dir    = $self->{cache_dir};
    my $dbFile = $self->{data_field} . ".db";
    print STDERR "getFilenames $dir $dbFile\n";
    if ( !-e $self->{cache_dir} . "/" . $dbFile ) {
        $self->{message} = qq(no db_file yet so nothing to do);
        return [];
    }
    elsif ( $dbFile !~ /\.db/ ) {
        $self->{message}
            = qq(the db_file parm should be a .db file in the giovanni cache dir!);
        return [];
    }

    my $filename = makeTempDBFile($self,$dir, $dbFile, $GIOVANNI::SESSION_LOCATION );
    if ( !$filename ) {
        $self->{message} = qq{$! ($dbFile)};
        return [];
    }
    print STDERR "Reading Cache File $filename\n";
    my $files = readCacheFile($self,$filename);
    return $files;
}

sub makeTempDBFile {
    my $self       = shift;
    my $cache_dir  = shift;
    my $dbFile     = shift;
    my $sessionDir = shift;

    my ( $tmpFH1, $tmpFile ) = File::Temp::tempfile(
        "giovanni_XXXX",
        DIR    => $sessionDir,
        SUFFIX => ".db",
        UNLINK => 1
    );

    #if ($temppath =~ /([\w\d_]+)/) {
    #    $temppath = $1;
    #}
    my $path = "$cache_dir/$dbFile";
    $tmpFile = $tmpFile;

    my $status = copy( $path, $tmpFile );
    chmod 0666, $tmpFile;
    if ($!) {
        return undef;
    }

    return ($tmpFile);

}

sub readCacheFile {
    my $self = shift;
    my $dbFile = shift;
    my %dbHash = ();
    my $result = {};
    my @files;

    local (*FH);
    my $lockFile = $dbFile . '.lck';
    if ( open( FH, ">$lockFile" ) ) {
        flock( FH, LOCK_EX );
    }
    else {
        $self->{message} = "Failed to get a lock on $dbFile";
        return;
    }

    if ( tie %dbHash, "DB_File", $dbFile, O_RDWR | O_CREAT, 0666, $DB_HASH ) {
        foreach my $key ( keys %dbHash ) {

           if ( $dbHash{$key} =~ /(^.+scrubbed.+\.nc)/ ) {
                push @files, $1;
            }

        }
        untie %dbHash;
    }
    else {
        $self->{message} = "Failed to open  $dbFile";
        print STDERR "Failed to open $dbFile ($!)\n";
    }
    flock( FH, LOCK_UN );

    $total = $#files;
    return \@files;
}

# This subroutine might delete our entire cache so be careful!
# This subroutine is left here for use on dev. It is not needed
# on giovanni cluster, Beta or OPS. It is commented out.
sub copyOutAndReplace {
    my $self = shift;
    my $orgCacheFile = shift;
    my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );
    my ( $tmpFH1, $tmpFile ) = File::Temp::tempfile(
        "giovanni_editcache_XXXXXXXX",
        DIR    => $tmpdir,
        SUFFIX => ".nc",
        UNLINK => 1
    );
    # copy the file out to TMP 
    my $status = copy( "$orgCacheFile", "$tmpFile" );
    if (!$status) {
        $self->{message} = "copy of $orgCacheFile to $tmpFile failed";
        return 0;
    }
    if ( !myChMod( $self, $tmpFile, "write" ) ) {
        $self->{message} = "chmod of temp file also failed";
        return 0;
    }
    unlink($orgCacheFile);
    # copy the file back into cache
    my $status = copy( $tmpFile, $orgCacheFile);
    if (!$status) {
        $self->{message} = "copy back into cachoe of $tmpFile to $orgCacheFile failed";
        return 0;
    }
    # delete the tmpFile
    unlink($tmpFile);
    return 1;
}    

    

sub updateFile {
    my $self       = shift;
    my $thisfile   = shift;
    my $data_field = $self->{data_field};
    my $file       = $self->{cache_dir} . "/" . $thisfile;
    my $found      = undef;
    
    if ( !myChMod( $self, $file, "write" ) ) {
        # If testing on dev uncomment:
        my $status = -1; # copyOutAndReplace($self,$file); 
        return 1 if !$status; 
    }

    if ($self->{vector}) {
        $found = vector_updateFile($self,$thisfile); 
    }
    else {
        $found = single_var_updateFile($self,$thisfile); 
    }

    if ( !myChMod( $self, $file, "readonly" ) )
    {    # using retuurn val of chmod.
        $self->{message} = "chmod back to read failed";
        return 1;
    }
    if ( !$found ) {
        $self->{message}
            .= "ncatted not run because attribute given was not in our SCRUBBER::PROCESSING hash"
            . " or hash doesn't exist in .cfg file";
        return 1;
    }
    return 0;
}

sub single_var_updateFile {
    my $self       = shift;
    my $thisfile   = shift;
    my $data_field = $self->{data_field};
    my $file       = $self->{cache_dir} . "/" . $thisfile;
    my $found      = undef;
    
    foreach my $attr ( keys %$SCRUBBER::PROCESSING ) {
        if ( exists $self->{$attr} ) {
            $found = 1;

            # This is the translation from AG name to ncfile name
            my $attr_name  = $SCRUBBER::PROCESSING->{$attr};
            my $attr_value = $self->{$attr};
            my $cmd
                = qq(ncatted -h -a $attr_name,$data_field,o,c,"$attr_value" $file );
            my $status = runNCOCommand( $cmd, "rescrubbing" );
            if ( $status != 0 ) {
                $self->{message} = "the command:<$cmd> failed with $status";
                return 1;
            }
        }
    }
    return $found;
}

sub vector_updateFile {
    my $self       = shift;
    my $thisfile   = shift;
    my $data_field = $self->{data_field};
    my $file       = $self->{cache_dir} . "/" . $thisfile;
    my $found      = undef;
    my @vectors = ("_u","_v");
    
    foreach my $vector (@vectors) {
    foreach my $attr ( keys %$SCRUBBER::PROCESSING ) {
        if ( exists $self->{$attr} ) {
            $found = 1;

            # This is the translation from AG name to ncfile name
            my $attr_name  = $SCRUBBER::PROCESSING->{$attr};
            my $attr_value = $self->{$attr};
            my $arrow = $data_field . $vector;
            my $cmd
                = qq(ncatted -h -a $attr_name,$arrow,o,c,"$attr_value" $file );
            my $status = runNCOCommand( $cmd, "rescrubbing" );
            if ( $status != 0 ) {
                $self->{message} = "the command:<$cmd> failed with $status";
                return 1;
            }
        }
    }
    }
    return $found;
}

sub myChMod {
    my $self  = shift;
    my $file  = shift;
    my $state = shift;
    if ( $state eq "write" ) {
        my $mode = 0664;
        return chmod $mode, $file;
    }
    elsif ( $state eq "readonly" ) {
        my $mode = 0444;
        return chmod $mode, $file;
    }
    else {
        $self->{message}
            = "the state:<$state> was not recognized. Expecting 'write' or 'readonly'";
        return undef;
    }
    return undef;
}

sub reviewFile {
    my $self     = shift;
    my $state    = shift;
    my $thisfile = shift;
    # This subroutine can check to see if it is already been done
    return if ( $state eq "after" and !$SCRUBBER::PLEASEREVIEW );
    my $val;
    my $found = undef;
    $self->{set} = "false";

    # This one is the .nc file
    my $file = $self->{cache_dir} . "/" . $thisfile;

    foreach my $attr ( keys %$SCRUBBER::PROCESSING ) {
        if ( exists $self->{$attr} ) {
            $found = 1;

            # This is the translation from AG name to ncfile name
            my $attr_name = $SCRUBBER::PROCESSING->{$attr};
            my $cmd = qq(ncdump -h $file);
            if ( $state eq "before" ) {
                $val = $self->{data_field} . " | grep " . $attr_name;
                $cmd .= qq( | grep $val | grep -v history);
            }
            else {
                $val = $self->{$attr}; 
                $cmd .= qq( | grep "$val" | grep -v history);
            }

            # This one is data_field:attr_name
            my $notice = `$cmd`;

            # Now let's see if we even have to perform a rescrub:
            if ( $notice =~ /$val\s+=\s+"(.*)"\s*;/ ) {
                my $current_long_name = $1;
                if ( $state eq "before"
                    and $current_long_name eq $self->{$attr} )
                {
                    $self->{message}
                        = "The $attr is already set to new value";
                    $self->{set} = "true";
                    return -1;
                }
            }
            if ( length($notice) < 30 ) {
                $self->{message} = "ncdump failed with $notice ($cmd)";
                return 1;
            }
            else {
                if ($SCRUBBER::PLEASEREVIEW ) {
                    $self->{message} .= "$notice";
                }
            }
        }
    }
    if ( !$found ) {
        $self->{message}
            = "ncdump was not even run because attribute given was not in our SCRUBBER::PROCESSING hash";
        return 1;
    }
    return 0;
}

sub deleteNotice {
    my $self = shift;
    $self->{notice} = "";
}

# No longer referenced as updateScrubbedFile.pl is now run from /bin
sub untaint {
    my $self = shift;
    my $var  = shift;
    my $val  = shift;
    my $line = shift;
    my $out;
    if ( $var =~ /$val/ ) {
        $out = $1;
    }
    else {
        $self->{message} = "$var is tainted";
        return 1;
    }
    return $out;
}

sub swallowCGI {
    my $self  = shift;
    my $cgi   = shift;
    my $input = $cgi->Vars();

    # later I need to add here a test for arrays
    foreach my $param (%$input) {

        #if (ref $input->{$param} eq 'ARRAY') {
        $self->{$param} = $input->{$param};
    }
}

sub printError {
    my $self = shift;
    return $self->{error};
}

######################################################
## Name: runNCOCommand() -- to execute a nco command
## Arguments:
##      $cmd -- a nco command string
##      $step -- a step name at which the command is executed
## Return: exit(1) if failure; empty if success
#######################################################
sub runNCOCommand {
    my ( $cmd, $step ) = @_;

    my $time = '';
    my $profile;
    if ( defined( $ENV{PROFILE} ) ) {
        $time    = 'time -p ';
        $profile = 1;
    }
    print STDERR "INFO Executing command: $cmd\n" if ( $verbose || $time );
    printf STDERR ( "INFO Time Before=%lf\n", Time::HiRes::time() )
        if ($profile);
    my $status = system("$time$cmd 2> /dev/null");

    if ( $status != 0 ) {
        $status = $status >> 8;
        quit( 1, "Failed to execute $cmd : $status" );
        quit( 2, "ERROR: [$?]: $cmd -- $status" );
    }
    else {
        print STDERR "INFO: $step -- successful\n" if ($verbose);
        printf STDERR ( "INFO Time After =%lf\n", Time::HiRes::time() )
            if ($profile);
    }
    return $status;
}

sub quit {
    my ( $error_code, $log_msg, $file ) = @_;
    my $msg = "USER_ERROR Failed to preprocess ";
    $msg .= $file ? "file " . basename($file) : "data";
    warn "$msg\n";
    warn "$log_msg\n";
    exit($error_code);
}

sub EvenOutLatitudes {
    my $outfile  = shift;
    my $lat_name = shift;

    # Finding number of elements of latitude (wish lat[-1] works here)
    my @lat_values = `ncks -H -v $lat_name $outfile`;
    pop(@lat_values) until $lat_values[-1];
    my @lat_values_reverse = reverse(@lat_values);
    my $cnt_empty          = 0;
    foreach my $lat (@lat_values_reverse) {
        $lat =~ s/^\s+|\s+$//g;
        if ( $lat eq "" ) {
            $cnt_empty++;
            next;
        }
        last;
    }
    printf STDERR ( "INFO Processing GoCart %s variable \n", $lat_name )
        if ($verbose);
    my $ilat_last = scalar(@lat_values) - $cnt_empty - 1;
    my $cmd
        = qq(ncap2 -O -s "if(($lat_name(0)-$lat_name(1))!=($lat_name(1)-$lat_name(2)) && $lat_name(0)==-89.5)$lat_name(0)=-90;if(($lat_name($ilat_last)-$lat_name($ilat_last-1))!=($lat_name($ilat_last-1)-$lat_name($ilat_last-2)) && $lat_name($ilat_last)==89.5)$lat_name($ilat_last)=90" $outfile $outfile.eol 2> /dev/null);
    my $status = system($cmd);
    if ($status) {
        die
            "ERROR Failed in processing GoCart $lat_name variable with this message: $status\n\n";
    }
    move_file( "$outfile.eol", $outfile, "$outfile.eol" );
}

sub dump2XML {
    my $workingfile = shift;
    my $workingdir  = shift;
    my $filename    = basename($workingfile);
    my $xmlfile     = "$workingdir/$filename.xml";
    my $dumpCommand = "ncdump -x $workingfile > $xmlfile";
    runNCOCommand( $dumpCommand, "Generate ncml file" );

    if ( !-e $xmlfile ) {
        quit( 1, "ERROR Failed to find xml file: $xmlfile" );
    }
    return $xmlfile;
}

sub move_file {
    my ( $f1, $f2, $fname ) = @_;
    if ( rename( $f1, $f2 ) ) {
        return 1;
    }
    else {
        quit( 2, "Failed to move file $f1 to $f2: $!", $fname );
    }
}

######################################################
## Name: getRootNode
## Arguments:
##          $xmlfile -- an ncml file dumped from a netcdf file
## Return: a root node
######################################################
sub getRootNode {
    my ($xmlfile) = shift;
    my $root = undef;
    eval {
        my @variables = ();

        my $parser = XML::LibXML->new();
        my $doc    = $parser->parse_file($xmlfile);
        my $xpc    = XML::LibXML::XPathContext->new($doc);
        $xpc->registerNs( ncml =>
                'http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2' );
        my @rootNodes = $xpc->findnodes('/ncml:netcdf');
        $root = $rootNodes[0];
        print "DEBUG Root Node name = " . $root->getName . "\n" if ($verbose);
    };

    if ($@) {
        print STDERR "USR_ERROR XML failure\n";
        print STDERR "ERROR Failed to retrieve the xml root element: $@\n";
        exit(1);
    }
    return $root;
}

#######################################################
## Name: createAttribute() -- to create a new attribute with float data type
## Argument:
##   $ncfile -- a netcdf file being worked on
##   $attrname -- attribute name to be created
##   $varname -- variable name
##   $attrval -- attribute value
########################################################
sub createAttribute {
    my ( $ncfile, $attrname, $varname, $type, $attrval ) = @_;
    my $attrCreateCommand
        = "ncatted -O -a \"$attrname,$varname,o,$type,$attrval\" $ncfile";
    print STDERR "INFO create attribute command: $attrCreateCommand\n"
        if ($verbose);
    my $status = `$attrCreateCommand`;
    if ( $status ne "" ) {
        quit( 1,
            "ERROR failed to create attribute $varname:$attrname: $status",
            $ncfile );
    }
}
#######################################################
## Name: deleteAttribute() -- to delete an attribute
## Arguments:
##      $ncfile -- a netcdf file you are working on
##      $attrname -- the attribute name to be deleted
##      $varname -- the variable in which $attrname is in
#######################################################
sub deleteAttribute {
    my ( $ncfile, $attrname, $varname ) = @_;
    print STDERR "DEBUG going to delete $varname:$attrname\n" if ($verbose);
    my $attrDeleteCommand
        = "ncatted -O -a \"$attrname,$varname,d,,\" $ncfile";
    print STDERR
        "INFO to execute the delete attribute command: $attrDeleteCommand \n"
        if ($verbose);
    my $status = `$attrDeleteCommand`;

    if ( $status ne "" ) {
        quit( 1, "ERROR failed to delete $attrname of $varname: $status" );
    }
}

########################################################
## getVariablesForKeeping() -- to find the variables for lat, lon, time
## Arguments:
##      $inputfile -- a valid netcdf file
## Return: an array of variable names
########################################################
sub getVariablesForKeeping {
    my ( $infile, $aesirId, $type, $zdim, $boundsDims, $docRoot,
        $indexVariable )
        = @_;
    my @keepVars   = ();
    my @deleteVars = ();

    my @varListNodes = getChildrenNodeList( $docRoot, 'variable' );
    my @dimListNodes = getChildrenNodeList( $docRoot, 'dimension' );
    my @tmp;
    my %revBounds;    # keep bounds variables
    my $mainVar;      # where we are to look for cell methods
    foreach (@dimListNodes) {

        if ( !exists $boundsDims->{ $_->getAttribute("name") } )
        {             # to get the ndim count on unknown var name correct
            push @tmp, $_;
        }
        else {
            $revBounds{ $boundsDims->{ $_->getAttribute("name") } } = 1;
        }
    }
    @dimListNodes = @tmp;

    print STDERR "INFO z dim: $zdim\n" if ( $verbose && defined($zdim) );

    foreach my $varNode (@varListNodes) {
        my $shape = getAttributeValue( $varNode, 'shape' );
        my @varDimArray = split( ' ', $shape );
        my $varName = getAttributeValue( $varNode, 'name' );
        chomp($varName);

        ## to find the index variable for AIRS
        ## $zdim is the zDim_Name defined in EDDA (varinfo)
        #  $indexVariable is the dimension containing index values that
        #  is the dimension of the zdim (scrubber removes the indexVariable)
        if ( defined($zdim)
            && ( $varName eq $zdim
                or $varName eq $indexVariable )
            )
        {
            push( @keepVars, $varName );
            print STDERR "INFO Keep variable: $varName\n" if ($verbose);
        }
        elsif ( exists $revBounds{$varName} ) {
            push( @keepVars, $varName );
            print STDERR "INFO Keep bounds variable: $varName\n"
                if ($verbose);
        }
        elsif ( scalar(@dimListNodes) == scalar(@varDimArray) )
        {    ## data variables to keep
            if ( $type eq "virtual" ) {
                if ( $varName eq $aesirId ) {

                    # Only keep the $aesirId in the virtual variable case
                    # in the virtual case $mainVar (dataFieldId) has already
                    # been created and we in fact do know what it's name is: $aesirId.
                    # Nominally we still  don't know what the name of the
                    # measured parameter is yet -
                    # which is why we go through this convoluted procedure
                    $mainVar = $varName;
                    push( @keepVars, $varName );
                    print STDERR "INFO Keep variable: $varName\n"
                        if ($verbose);
                }
                else {
                    push( @deleteVars, $varName );
                    print STDERR "INFO variable for deleting1: $varName\n";
                }
            }
            else {
                push( @keepVars, $varName );
                $mainVar = $varName;
                print STDERR "INFO Keep variable: $varName\n" if ($verbose);
            }
        }
        else {    ## lat, lon, and time variables to keep
            my @attrListNodes = getChildrenNodeList( $varNode, 'attribute' );
            if ( existsAttribute( 'units', @attrListNodes ) ) {
                my $found = 0;
                foreach my $attrNode (@attrListNodes)
                {    ## to find the variables for time, lat, lon
                    my $attrvalue = getAttributeValue( $attrNode, 'value' );
                    if ( isaLatitude( $attrvalue, $varName, $infile )
                        || isaLongitude($attrvalue)
                        || $attrvalue =~ /\ssince\s/ )
                    {
                        push( @keepVars, $varName );
                        $found = 1;
                        print STDERR "INFO Keep variable: $varName\n"
                            if ($verbose);
                        last;
                    }
                }
                if ( !$found ) {
                    push( @deleteVars, $varName );
                    print STDERR "INFO variable for deleting2: $varName\n"
                        if ($verbose);
                }
            }
            else {
                if ( $varName !~ /bnds/ ) {
                    push( @deleteVars, $varName );
                }
                print STDERR "INFO variable for deleting3: $varName\n"
                    if ($verbose);
            }
        }
    }

    return \@keepVars, \@deleteVars, $mainVar;
}

## ###################################################
## Name: getChildrenNodeList() -- to get a list of children nodes specified by the node name
## Arguments:
##      $parentnode -- a node which contains child nodes
##      $childname -- the child node name you want to retrieve
## Return: a node list
######################################################
sub getChildrenNodeList {
    my ( $parentnode, $childname ) = @_;
    print STDERR "DEBUG Child node name: $childname\n" if ($verbose);
    unless ( defined $parentnode || defined $childname ) {
        print STDERR
            "ERROR either parentnode not defined, or child node name '$childname' not defined\n";
        exit(1);
    }
    my @nodeList = $parentnode->getChildrenByTagName($childname);
    return @nodeList;
}

######################################################
## Name: getAttributeValue() -- to get a value from an attribute by an attribute name
## Arguments:
##      $node -- an node element
##      $attrname -- an attribute name
## Return: a string value
#######################################################
sub getAttributeValue {
    my ( $node, $attrname ) = @_;
    if ( !defined $node ) {
        print STDERR "WARN undefined node\n";
        return undef;
    }
    if ( !defined $attrname || $attrname eq "" ) {
        print STDERR "WARN undefined attribute name\n";
        return undef;
    }
    my $val = $node->getAttribute($attrname);
    return $val;
}

##################################################
## Name: existsAttribute() -- to check if an attribute exists
## Argument:
##      $attrname -- the searched attribute name you want to find
##      @attrNodeList -- a node list
## Return 0 or 1
## ###############################################
sub existsAttribute {
    my ( $attrname, @attrNodeList ) = @_;
    my $found = 0;

    foreach my $attrnode (@attrNodeList) {
        my $name = getAttributeValue( $attrnode, 'name' );
        if ( $name eq $attrname ) {
            $found = 1;
            last;
        }
    }

    return $found;
}

sub runVirtualGenerator {
    my ( $workingfile, $virtualGenerator, $file ) = @_;
    my $virtualfile         = "$workingfile.virtual";
    my $virtualGeneratorCmd = "$virtualGenerator $workingfile $virtualfile";
    runNCOCommand( $virtualGeneratorCmd, "Generate virtual variable" );
    move_file( $virtualfile, $workingfile, $file );
}

sub deleteSelectedVariables {
    my ( $virtualFlag, $excludedVariables, $workingfile, $includedVariables )
        = @_;

    if ($virtualFlag) {    ## to delete data variables
        my $delIndexVarCmd
            = "ncks -h -x -v $excludedVariables $workingfile $workingfile.index";
        runNCOCommand( $delIndexVarCmd,
            "Delete the unwanted variable: $excludedVariables" );
        move_file( "$workingfile.index", $workingfile );
    }
    else {                 ## to delete dimensional variables
        my $updateVDcommand
            = "ncwa -C -h -v $includedVariables -a $excludedVariables $workingfile $workingfile.new";
        runNCOCommand( $updateVDcommand, "Wiping out extra dimensions" );
        move_file( "$workingfile.new", $workingfile );
    }
}

# do_padding() - Perform padding/shifting
# Inputs:
#   $in      - Input nc file to be examined
#   $latname - Variable name of latitude dimension
#   $lonname - Variable name of longitude dimension
#   $vname   - Variable name
#   $nco     - NCO script file for padding/shifting
# Return:
#   ncfile  - New nc file with padding/shifting
#   1  - fail
sub do_padding {
    my ( $in, $latname, $lonname, $vname, $nco, $padded_file ) = @_;

    # padding/shifting
    runNCOCommand( "ncap2 -S $nco -O -h $in $padded_file ",
        'Padding/shifting' );

}

sub add_offset {
    my $inputDate = shift;
    my $inputTime = shift;
    my $offset    = shift;

    my @dateparts = split( /-/, $inputDate, 3 );
    my @timeparts = split( /:/, $inputTime, 3 );
    $timeparts[2] = int $timeparts[2];    # don't want millisecs

    my $Date = DateTime->new(
        year       => $dateparts[0],
        month      => $dateparts[1],
        day        => $dateparts[2],
        hour       => $timeparts[0],
        minute     => $timeparts[1],
        second     => $timeparts[2],
        nanosecond => 0,
        time_zone  => 'UTC'
    );
    $Date->add( seconds => $offset );

    return $Date;
}

sub dateobj2attribute {
    my $Date       = shift;
    my $attrYear   = $Date->year();
    my $attrMonth  = sprintf( "%02d", $Date->month() );
    my $attrDay    = sprintf( "%02d", $Date->day() );
    my $attrHour   = sprintf( "%02d", $Date->hour() );
    my $attrMinute = sprintf( "%02d", $Date->minute() );
    my $attrSecond = sprintf( "%02d", $Date->second() );
    my $out        = "$attrYear-$attrMonth-$attrDay" . "T";
    $out .= "$attrHour:$attrMinute:$attrSecond" . "Z";
    return $out;
}

# Only for daily granules
sub insist_on_lastsecondoftheday {
    my $startobj = shift;
    my $endobj   = shift;

    return if ( $startobj->hour() != 0 or
        $startobj->min() != 0 or
        $startobj->second() != 0 );

    # If the above test passes through, then the provider wants a canonical date.
    # In this case it is best in Giovanni that the end date is not
    # on the first second of the next day but rather on the last second
    # of the same day
    my $sanity = 0;
    while ( $endobj->day() ne $startobj->day() and $sanity < 86400 ) {
        $endobj->add( seconds => -1 );
        ++$sanity;
    }
}

# get_padding() - Get padding/shifting info
# Description:
#     This function examines an nc file and determines whether
#     padding/shifting is needed.
# Inputs:
#   $in      - Input nc file to be examined
#   $latname - Variable name of latitude dimension
#   $lonname - Variable name of longitude dimension
#   $vname   - Variable name
# Return:
#   ncofile  - when padding/shifting is needed
#   undef    - No padding/shifting needed
# This new version of the subroutine
# Only does padding if it is only needed in the lat direction
# If lat is -90 to 90 and lon is -180 to 180      then don't pad (global)
# If lat is -90 to 90 and lon is NOT -180 to 180  then don't pad (no cases yet)
# If lat is NOT -90 to 90 and lon is NOT -180 to 180 then  don't pad (NLDAS)
# If lat is NOT -90 to 90 and lon is  -180 to 180 then  pad  (TRMM)
sub get_padding {
    my ( $in, $shape, $vname ) = @_;

    my @dims = split( /\s+/, $shape );

    # Temp file for padding nco script
    my $nco_file  = "$in.padding.nco";
    my $lonname   = 'lon';               # lat lon ordered differently
    my $latname   = 'lat';
    my $timename  = $dims[0];
    my $layername = undef;

    # THE ORDER of these is CRITICAL (3B43 lat,lon...3hour and 3A12 lon,lat)
    #my $getmiss_str = "[\$time,\$Lat,\$Lon]=";
    my $getmiss_str = "[";
    my $offset_str;
    foreach my $dim (@dims) {
        $getmiss_str .= "\$" . $dim . ",";
        $offset_str  .= ":,";
    }
    chop $getmiss_str;    #remove last comma
    $offset_str
        = substr( $offset_str, 0, -5 );    #remove lat and lon place holders
    $getmiss_str .= "]=";

    # always new lat name:
    $getmiss_str =~ s/lat/Lat/;

    my $flag_padding_lat    = 0;
    my $flag_padding_lon    = 0;
    my $flag_longitudeshift = 0;

    #
    # Determine need for longitude shifting
    #
    my $lon_str = `ncks -s "%f " -H -C -v $lonname $in`;
    chomp $lon_str;
    $lon_str =~ s/^\s|\s$//g;
    my @lon     = split( ' ', $lon_str );
    my $res_lon = $lon[1] - $lon[0];
    my $nlon    = scalar(@lon);

    # Shifting done only when end longitudes greater than 180
    my $offset = 0;    ## End index of eastern part (0-180)
    if ( $lon[-1] > 180 ) {

        # Longitudes must be global (start/end longitudes at 0/360
        # or half step from it)
        my $x0 = $res_lon / 2.;
        my $x1 = 360. - $x0;      ## x0 used as a half step

        if ( ( $lon[0] == 0 || $lon[0] == $x0 )
            and ( $lon[-1] == 360 || $lon[-1] == $x1 ) )
        {

            # We need shift
            $flag_longitudeshift = 1;
            $offset              = int( $nlon / 2 );
            $offset              = $offset - 1 if $nlon % 2 == 0;
        }
    }
    if ( $flag_longitudeshift == 1 ) {
        print STDERR "INFO Longitude shifts at $offset $lon[$offset]\n";
    }

    #
    # Determine need for latitude/longitude padding
    #
    my $lat_str = `ncks -s "%f " -H -C -v $latname $in`;
    chomp $lat_str;
    $lat_str =~ s/^\s|\s$//g;
    my @lat     = split( ' ', $lat_str );
    my $res_lat = $lat[1] - $lat[0];
    my $nlat    = scalar(@lat);

    if ( $res_lat == 0 ) {
        print STDERR "ERROR: resolution of latitude in file is 0:\n";
        print STDERR `ncdump $latname $in`;
        return;
    }
    if ( $res_lon == 0 ) {
        print STDERR "ERROR: resolution of longitude in file is 0:\n";
        print STDERR `ncdump $lonname $in`;
        return;
    }

    # Number of latitude elements to be added
    my $n_north = int( ( 90 - $lat[-1] ) / $res_lat );
    my $n_south = int( ( $lat[0] + 90 ) / $res_lat );
    my $nlat_new = $nlat + $n_north + $n_south;

    # Adding 2 for the cases of :
    #    -90 to 89
    $flag_padding_lat = 1 if $nlat_new > $nlat + 2;

    # Number of longitude elements to be added
    # TBD: We are working on a [-180,180] system and not
    #      considering [0,360] for now, because we don't
    #      have such cases so far.
    my $n_east = int( ( 180 - $lon[-1] ) / $res_lon );
    my $n_west = int( ( $lon[0] + 180 ) / $res_lon );
    my $nlon_new = $nlon + $n_east + $n_west;

    # Adding 2 for the cases of :
    #     -180 to 177.5 gives an $n_east of 1
    $flag_padding_lon = 1 if $nlon_new > $nlon + 2;
    if ( $n_east < 0 ) {
        print STDERR "WARN Skipping lon padding for [0,360]\n";
        $flag_padding_lon = 0;

        # Make sure nlon_new remains the same as nlon because
        # above algorithm is not accurate when east is not exactly 180
        $nlon_new = $nlon;
    }

    # Padding values added to extend the latitudes
    # Used in cases like TRMM in padding polar belts
    # These are not needed in a generic padding algorithm
    my $padding_north = $lat[-1] - $lat[0] + $res_lat;
    my $padding_south = int( $lat[0] + 90 );

    #
    #  Create padding nco
    #

    my $vname_tmp = $vname . "_tmp";

    # THIS CODE MAY NEED ORDERING TOO IF YOU SEE STRIPING:
    if ( $flag_longitudeshift and $flag_padding_lat ) {
        $getmiss_str =~ s/lon/Lon/;
        print STDERR
            "INFO Creating NCO script for latitude padding and longitude shifting\n"
            if ($verbose);
        my $nlat_m1       = $nlat - 1;
        my $n_north_m1    = $n_north - 1;
        my $i_right_start = $offset + 1;
        my $j_bot_end     = $n_south - 1;
        my $j_mid_start   = $n_south;
        my $j_mid_end     = $nlat + $n_south - 1;
        my $j_top_start   = $nlat + $n_south;
        my $nlon_new_m1   = $nlon_new - 1;
        my $nlat_new_m1   = $nlat_new - 1;
        open( NCO, ">$nco_file" ) || die;
        print NCO "defdim(\"Lat\", $nlat_new);\n";
        print NCO "defdim(\"Lon\", $nlon);\n";
        print NCO "$vname_tmp" . $getmiss_str . $vname . '.get_miss();', "\n";
        print NCO "$vname_tmp.set_miss($vname.get_miss());\n";
        print NCO "*z = $vname;\n";
        print NCO
            "$vname_tmp(:,$j_mid_start:$j_mid_end:1,$i_right_start:$nlon_new_m1) = z(:,:,0:$offset:1);\n";
        print NCO
            "$vname_tmp(:,$j_mid_start:$j_mid_end:1,0:$offset:1) = z(:,:,$i_right_start:$nlon_new_m1:1);\n";
        print NCO 'Lat[$Lat] = 0.;', "\n";
        print NCO 'Lon[$Lon] = 0.;', "\n";
        print NCO
            "Lon(0:$offset:1) = $lonname($i_right_start:$nlon_new_m1:1);\n";
        print NCO
            "Lon($i_right_start:$nlon_new_m1:1) = $lonname(0:$offset:1);\n";
        print NCO 'Lon -= (360. * (Lon > 180.));', "\n";
        print NCO
            "Lat(0:$j_bot_end:1) = $latname(0:$j_bot_end:1) - $padding_south.;\n";
        print NCO
            "Lat($j_mid_start:$j_mid_end:1) = ${latname}(0:$nlat_m1:1);\n";
        print NCO
            "Lat(${j_top_start}:$nlat_new_m1:1) = ${latname}(0:$n_north_m1:1) + $padding_north;\n";
        print NCO 'Lat@units="degrees_north";',     "\n";
        print NCO 'Lat@standard_name="latitude";',  "\n";
        print NCO 'Lon@units="degrees_east";',      "\n";
        print NCO 'Lon@standard_name="longitude";', "\n";
        print NCO "$vname = $vname_tmp;\n";
        close(NCO);
        return ( $nco_file, "shift" );
    }
    elsif ($flag_longitudeshift) {
        print STDERR
            "ERROR Shifting only not implemented here but in WorldLongitude\n";
        return ( undef, "shifting only" );
    }
    elsif ( $flag_padding_lat and !$flag_padding_lon ) {

        # Generic algorithm to compute lat/lon in padded area
        $getmiss_str =~ s/Lon/lon/;
        print STDERR
            "INFO Creating NCO script for latitude/longitude padding (generic)\n"
            if ($verbose);

        # since we are not doing longitude in this section:
        #my $i1       = $n_west;
        #my $i2       = $nlon + $n_west - 1;
        my $i1       = 0;
        my $i2       = $nlon - 1;
        my $j1       = $n_south;
        my $j2       = $nlat + $n_south - 1;
        my $n_west1  = $n_west - 1;
        my $n_south1 = $n_south - 1;
        my $i2p1     = $i2 + 1;
        my $j2p1     = $j2 + 1;
        open( NCO, ">$nco_file" ) || die;
        print NCO "defdim(\"Lat\", $nlat_new);\n";

        #print NCO "defdim(\"Lon\", $nlon_new);\n";
        print NCO "$vname_tmp" . $getmiss_str . $vname . '.get_miss();', "\n";
        print NCO "$vname_tmp.set_miss($vname.get_miss());\n";
        print NCO "*z = $vname;\n";
        print NCO "*res_lat = $res_lat;\n";
        print NCO "*res_lon = $res_lon;\n";
        if ( $shape =~ /lat lon/ ) {
            print NCO "$vname_tmp("
                . $offset_str
                . ",$j1:$j2:1,$i1:$i2:1) = z("
                . $offset_str
                . ",:,:);\n";
        }
        else {    # lon lat instead of lat lon
            print NCO "$vname_tmp("
                . $offset_str
                . ",$i1:$i2:1,$j1:$j2:1) = z("
                . $offset_str
                . ",:,:);\n";
        }
        print NCO 'Lat[$Lat] = 0.;', "\n";

        #print NCO 'lon[$lon] = 0.;', "\n";
        #print NCO "lon($i1:$i2) = $lonname(:);\n";
        print NCO "Lat($j1:$j2:) = $latname(:);\n";
        print NCO "for (*j=$n_south1; j>=0; j--)\n";
        print NCO "    Lat(j) = Lat(j+1) - res_lat;\n";
        print NCO "for (*j=0; j<$n_north; j++)\n";
        print NCO "    Lat(j+$j2p1) = Lat(j+$j2) + res_lat;\n";

        # Not needed if you are not padding lon:
        #print NCO "for (*i=$n_west1; i>=0; i--)\n";
        #print NCO "    lon(i) = lon(i+1) - res_lon;\n";
        #print NCO "for (*i=0; i<$n_east; i++)\n";
        #print NCO "    lon(i+$i2p1) = lon(i+$i2) + res_lon;\n";
        print NCO 'Lat@units="degrees_north";',     "\n";
        print NCO 'Lat@standard_name="latitude";',  "\n";
        print NCO 'lon@units="degrees_east";',      "\n";
        print NCO 'lon@standard_name="longitude";', "\n";
        print NCO "$vname = $vname_tmp;\n";
        close(NCO);
        return ( $nco_file, "onlylat" );
    }
    else {
        return undef;
    }
}

######################################################
## Name: reverseCoords() -- reverse coordinate direction if negative
## Arguments:
##       $infile -- input netCDF file
##       $outfile -- (optional) output netCDF file (default = infile)
##       $ncpdq_args -- (optional) arguments for ncpdq command. If not
##                      specified, run ncap2 to find reversed coordinates
##
sub reverseCoords {
    my ( $infile, $profile, $outfile, $ncpdq_args ) = @_;
    my $pdq_args;
    $outfile ||= $infile;

    unless ($ncpdq_args) {

        # Determine which coordinates need reversing
        # N.B.:  do not reverse coordinates that are only one element long
        my $tmpfile = "$outfile.tmp";

        # Form NCO script
        my $nco
            = 'if ($lat.size > 1) if(lat(1)<lat(0)) print ("-lat "); if ($lon.size > 1) if(lon(1)<lon(0)) print ("-lon ");';
        my $cmd = "ncap2 -O -h -o $tmpfile -v -s '$nco' $infile";

        # Run ncap2 command to find out which coordinates should be reversed
        printf STDERR ( "INFO Time Before =%lf\n", Time::HiRes::time() )
            if ($profile);
        $pdq_args = `$cmd 2> /dev/null`;
        if ($?) {
            quit(
                23,
                sprintf(
                    "ERROR Determining coordinate direction with %s: %d %s",
                    $cmd, $? >> 8, $pdq_args
                ),
                $infile
            );
        }
        printf STDERR ( "INFO Time After =%lf\n", Time::HiRes::time() )
            if ($profile);
        unlink($tmpfile);
        $pdq_args =~ s/\s*$//;

        # Replace space delimiter with comma
        my @pdq_args = split( '\s+', $pdq_args );
        $pdq_args = join( ',', @pdq_args );
    }

    # IF and ONLY IF there are coordinates to be reversed, call ncpdq
    if ($pdq_args) {

        # Step 2:  Reverse coordinates
        my $cmd    = "ncpdq -O -h -o $outfile -a $pdq_args $infile";
        my $output = `$cmd 2> /dev/null`;
        if ($?) {
            quit(
                24,
                sprintf(
                    "ERROR Reversing coordinate direction with %s: %d %s\n",
                    $cmd, $? >> 8, $output
                ),
                $infile
            );
        }
        warn "INFO Reversed coordinates $pdq_args in $infile to $outfile\n"
            if ($profile);
    }

    # No dimension reversing, but want to make sure outfile is populated
    elsif ( $infile ne $outfile ) {
        if ( !copy( $infile, $outfile ) ) {
            quit( 25, "ERROR Copying input $infile to output $outfile: $!",
                $infile );
        }
        else {
            warn "INFO: Copied $infile to $outfile\n" if ($profile);
        }
    }

    # Return $pdq_args so it can be used in subsequent calls
    return $pdq_args;
}

# netCDF acceptable standard for latitude:
sub isaLatitude {
    my $attr = shift;
    if ( $attr eq "degrees_north" ) {
        return 2;    # Giovanni STD
    }
    if ( $attr eq "degree_north"
        || $attr eq "degrees_N"
        || $attr eq "degree_N" )
    {
        return 1;
    }
    else {
        return undef;
    }
}

# netCDF acceptable standard for longitude:
sub isaLongitude {
    my $attr = shift;
    if ( $attr eq "degrees_east" ) {
        return 2;
    }

    if ( $attr eq "degree_east"
        || $attr eq "degrees_E"
        || $attr eq "degree_E" )
    {
        return 1;
    }
    else {
        return undef;
    }

}

# updates the type of a variable.
# We did this because
# ncap2 -O -h -s 'time(:)=9494400' puts the
# result in SCI when type is a float.
# we want to keep it in int
# (which nco does if double or int)
sub update_type {
    my $variable    = shift;
    my $in_type     = shift;
    my $out_type    = shift;
    my $workingfile = shift;
    my $orgfilename = shift;

    my $type_update_cmd
        = qq(ncap2 -s '$variable=$out_type($variable)' $workingfile $workingfile.update_type);
    runNCOCommand( $type_update_cmd,
        "update $variable type from $in_type to $out_type" );
    move_file( "$workingfile.update_type", $workingfile, $orgfilename );
}

# We should probably get rid of this:
# Don't confuse this with the one scrubber uses in Giovanni::Data::NcFile
sub createRecordDim {
    my $workingfile = shift;
    my $file        = shift;
    my $tempfile    = "$workingfile.rec";
    my $catCommand  = "ncecat -h -O $workingfile $tempfile";
    runNCOCommand( $catCommand, "Copy source file" );
    if ( !( -e $tempfile ) ) {
        quit( 1, "ERROR failed to find the file -- $tempfile" );
    }
    move_file( $tempfile, $workingfile, $file );
}

sub createSortedListingFile {
    my $doc = shift;

    my @sorted = sort {
        $a->getAttribute("granuleDate") cmp $b->getAttribute("granuleDate")
    } $doc->findnodes("//dataFile");

    my $topNode = $doc->getElementsByTagName('dataFileList')->[0];

    # This leaves too many empty lines:
    #my $nodesToDelete = $topNode->getElementsByTagName('dataFile');
    #foreach (@$nodesToDelete) {
    #  $_->unbindNode;
    #}

    # create new xml doc to avoid empty space in resulting doc from
    # removal of nodes above
    my $new    = createXMLDocument('data');
    my $newtop = XML::LibXML::Element->new('dataFileList');
    $newtop->setAttribute( "id", $topNode->getAttribute('id') );
    $new->addChild($newtop);

    foreach (@sorted) {
        $newtop->addChild($_);
    }

    return $new;

}

#########################################################################
## Name: getVariableValues -- to retrieve the multiple time values for MERRA
## Arguments:
##		@varName -- variable name
##		@inputFile -- a netcdf file
## Return: an array of values
########################################################################
sub getVariableValues {
    my ( $varName, $inputFile, $type ) = @_;
    my $ret = "";
    my $cmd = "";
    eval {
        if ( $type eq "float" || $type eq "double" )
        {
            $cmd = "ncks -s \"%f\n\" -H -C -v $varName $inputFile";
        }
        elsif ( $type eq "int" ) {
            $cmd = "ncks -s \"%d\n\" -H -C -v $varName $inputFile";
        }
        else {
            $cmd = "ncks -H -C -v $varName $inputFile";
        }
        print STDERR "INFO $cmd \n" if ($verbose);
        $ret = `$cmd`;
    };
    if ($?) {
        quit( 1, "ERROR: Failed to extract values from $varName because $ret",
            $inputFile );
    }
    my @rets = ();
    chomp($ret);
    if ( $ret =~ /=/ ) {
        ($ret) = ( $ret =~ /=(.+)$/ );
    }

    if ( $ret =~ /\n/g ) {
        @rets = split( /\n/, $ret );
    }
    else {
        push( @rets, $ret );
    }

    return @rets;
}

########################################################################
sub getVariableNamesString {
    my (@varList) = @_;
    my $vnames = "";
    foreach my $var (@varList) {
        my $name = getAttributeValue( $var, 'name' );
        next if ( $name eq "record" );
        $vnames .= "," if ( $vnames ne "" );
        $vnames .= $name;
    }
    return $vnames;
}
######################################################
## Name: getTimeVariableName2 () -- to find the 'time' variable name by searching for 'units=""'
## Arguments:
##         $boundsDims -- array reference - so that we can rule these out in our search
##         @vars -- variable array
##         if a variable is not one of the bounds dims but has units containg  'since YYYY...'
##         then we can be dead certain that this is the the time variable.
## Return: the time dimension name either a 'time' dimension itself, or a variable name with standard_name='time'
#####################################################
sub getTimeVariableDimName2 {
    my $boundsDims = shift;
    my (@varList) = @_;

    my $timeDmnName = undef;

    ## to find the 'time' dimension from variables
    foreach my $vnode (@varList) {
        my $vname = getAttributeValue( $vnode, 'name' );
        my @have = grep { $boundsDims->{$_} eq $vname } keys %$boundsDims;
        next if $#have >= 0;

        my @attributeList = getChildrenNodeList( $vnode, 'attribute' );

        foreach my $attrNode (@attributeList) {
            my $attrName = getAttributeValue( $attrNode, 'name' );
            next if ( $attrName ne "units" );

            my $attrValue = getAttributeValue( $attrNode, 'value' );
            print STDERR "DEBUG attr name = 'units' and value = $attrValue\n"
                if ($verbose);
            if ( $attrValue =~ m/\ssince\s/g ) {
                $timeDmnName = $vname;

            }
        }
        last if $timeDmnName;
    }

    return $timeDmnName;
}

######################################################
## Name: changeAttributeName() -- to rename an attribute name
## Arguments:
##		$ncfile -- a netcdf file you are working on
##		$fromattr -- the attribute name to be changed
##      $toattr -- the attribute name you want to change to
######################################################
sub changeAttributeName {
    my ( $ncfile, $fromattr, $toattr ) = @_;
    my $attributeCommand = "ncrename -a $fromattr,$toattr $ncfile";
    print STDERR "INFO Rename Attribute command: $attributeCommand \n"
        if ($verbose);
    my $status = system($attributeCommand);
    if ( $status ne 0 ) {
        quit(
            1,
            "ERROR Failed to rename the attribute from $fromattr to $toattr because $status",
            $ncfile
        );
    }
}

######################################################
## Name: changeVariableName() -- to rename a variable by stripping off the prefix 'h5_HDFEOS_GRIDS'
## Arguments:
##		$ncfile -- a netcdf file you are working on
##		$fromvar -- the attribute name to be changed
##      $tovar -- the attribute name you want to change to
######################################################
sub changeVariableName {
    my ( $ncfile, $fromvar, $tovar ) = @_;

    if ( $fromvar ne $tovar ) {
        my $variableCommand = "ncrename -v $fromvar,$tovar $ncfile";
        print STDERR "INFO Rename variable command: $variableCommand \n"
            if ($verbose);
        my $status = system($variableCommand);
        if ( $status ne 0 ) {
            quit(
                1,
                "ERROR Failed to rename the variable from $fromvar to $tovar because $status",
                $ncfile
            );
        }
    }
    else {
        print STDERR "INFO no change in variable name: $fromvar\n"
            if ($verbose);
    }
}

# This doesn't work with NetCDF-4 so I'll have to do it while the file is still NetCDF3:
# http://www.unidata.ucar.edu/mailing_lists/archives/netcdfgroup/2014/msg00315.html
# http://nco.sourceforge.net/nco.html#ncrename-netCDF-Renamer
sub rename_dimensionVariables {
    my $dataFieldVarInfo = shift;
    my $workingfile      = shift;
    my $NcFile           = shift;
    my $dataVariableName = shift;
    my $indexVariable    = shift;

    my $newVarDim = $dataFieldVarInfo->get_zDimName;

    if ( defined $newVarDim && $newVarDim ne "" ) {

        if ($indexVariable) {

            my $addZDim
                = "ncrename -d $indexVariable,"
                . $newVarDim
                . " $workingfile";
            runNCOCommand( $addZDim,
                "Change the index dimension to the real dimension (the one with values)"
            );

            my $delIndexVarCmd
                = "ncks -x -v $indexVariable $workingfile $workingfile.index";
            runNCOCommand( $delIndexVarCmd,
                "Delete the new variable: $newVarDim in case it exists" );
            move_file( "$workingfile.index", $workingfile );

            updateAttributeValue( $workingfile, 'coordinates',
                $dataVariableName, 'c', "time " . $newVarDim . " lat lon" );
        }
    }
    return $indexVariable;
}

# This is needed because I need to discover the indexVariable and rename it while the file is
# still netCDF3: FEDGIANNI-2254
#      if (   $vname eq "StdPressureLev"
#            || $vname eq "StdPressureLev_1"
#            || $vname eq "H2OPressureLev"
#            || $vname eq "H2OPressureLev_1" )
#            This subroutine replaces that list by identifying the indexVariable by:
# 1. The indexVariable is the dimension of the 3D Variable
# 2. The 3D variable is supposed to either (CF):
#     a) have the standard_name of 'pressure'
#     b) have an attribute called 'positive':
#
sub getIndexVariable {
    my $NcFile        = shift;
    my $workingfile   = shift;
    my $valueVariable = shift;
    my $variable;
    my $layerCFattribute     = 'positive';
    my $layerCFstandard_name = 'pressure';

    my @variableNodeList
        = getChildrenNodeList( $NcFile->{rootNode}, 'variable' );

    foreach my $vnode (@variableNodeList) {
        my $vname = getAttributeValue( $vnode, 'name' );

        # Note: this subroutine is case insensitive:
        my $standard_name
            = Giovanni::Data::NcFile::get_value_of_attribute( $workingfile,
            $vname, "standard_name" );
        my $positive_value
            = Giovanni::Data::NcFile::get_value_of_attribute( $workingfile,
            $vname, "positive" );

        if ( $standard_name =~ /^$layerCFstandard_name$/i
            or length($positive_value) > 1 )
        {

            # The dimension of the 3D layer variable that we eventially keep is the one we want to get rid of
            if ( $valueVariable ne $vname ) {
                warn( "The  EDDA zDimName: "
                        . $valueVariable
                        . " is not the same as the one we identified: "
                        . $vname
                        . " This needs to be changed in EDDA or it is a 'fake' 3D variable "
                );
            }
            my $indexVariable
                = getAttributeValue( $vnode, 'shape' );   ## get variable name
            $indexVariable =~ s/\s.*//
                ; # in case for some strange reason there is more than one dimension
             # Sometimes, the ValueVariable unfortunately already is the indexVariable and we want
             # to keep at least one. So if all (not mentioning names) MERRA is willing to give us is
             # the index variable in the first place, then we don't want to remove it. Identifying
             # will cause rename_dimensionVariables() to delete it later

            if ( $indexVariable ne $valueVariable ) {
                return $indexVariable;
            }
        }
    }

}

#######################################################
## Name: updateAttributeValue() -- to update an attribute value
## Arguments:
##              $ncfile -- a netcdf file you are working on
##              $attrname -- the attribute name to be deleted
##              $varname -- the variable in which $attrname is in
##              $type -- data type
##              $newval -- new value to replace the existing one
#######################################################
sub updateAttributeValue {
    my ( $ncfile, $attrname, $varname, $type, $newval ) = @_;
    my $attrValueCommand
        = "ncatted -O -a \"$attrname,$varname,o,$type,$newval\" $ncfile";
    print STDERR "INFO Update attribute value command: $attrValueCommand\n"
        if ($verbose);
    my $status = `$attrValueCommand`;
    if ( $status ne "" ) {
        quit(
            1,
            "ERROR Failed to update the attribute value for $attrname of $varname -- $status",
            $ncfile
        );
    }
}

sub createXMLDocument {
    my ($rootElemName) = @_;
    return undef unless defined $rootElemName;
    my $dom = undef;
    eval {
        my $xmlParser = XML::LibXML->new();
        $xmlParser->keep_blanks(0);
        $dom = $xmlParser->parse_string( '<' . $rootElemName . '/>' );
    };
    if ($@) {
        print STDERR "USR_ERROR Failed to create XML root\n";
        print STDERR "ERROR Failed to create $rootElemName node: $$@\n";
        exit(1);
    }

    return $dom->documentElement();
}

sub handleUnitsUpdate {
    my $dataId           = shift;
    my $dataFieldVarInfo = shift;
    my $NcFile           = shift;
    my $status           = 1;

    if ( $dataFieldVarInfo->get_dataFieldUnitsValue ) {
        $status = $NcFile->update_attribute( "units", $dataId,
            $dataFieldVarInfo->get_dataFieldUnitsValue );
    }
    else {

        # this subroutine is not a method yet:
        if ( $NcFile->does_variable_attribute_exist( $dataId, 'units' ) ) {

            # skip if units exists in file
            $status = 0;
        }
        else {
            $status = 1;

            # error if it does not.
            warn
                "units attribute for <$dataId> does not exist in the file and dataFieldUnitsValue also does not exist in the varInfo input file";
        }
    }
    return $status;
}

# get_padding now (Sep 2014 w/ TRMM RT) only pads if it is only needed in the lat direction
sub padding_sequence {
    my $dataId        = shift;
    my $workingfile   = shift;
    my $workingdir    = shift;
    my $fillvalue_ref = shift;

    # not sure yet why this is done:
    my $newVarName = $dataId;
    print STDERR "DEBUG virtualFlag == 1; variable = $dataId\n" if ($verbose);
    my $shape
        = Giovanni::Data::NcFile::get_variable_dimensions( $workingfile, "",
        $dataId );

    my ( $nco, $type ) = get_padding( $workingfile, $shape, $newVarName );
    if ( $type eq 'shifting only' ) {
        my $normalizedfile = $workingfile;
        $normalizedfile =~ s/\.nc$/_lonshift.nc/;
        my $normalized = Giovanni::WorldLongitude::normalizeIfNeeded(
            sessionDir => $workingdir,
            in         => [$workingfile],
            out        => [$normalizedfile]
        );
        if ($normalized) {
            $workingfile = $normalizedfile;
        }
    }
    elsif ( !( defined $nco ) ) {
        print STDERR "INFO no padding performed on this data: $workingfile\n"
            if ($verbose);
    }
    else {
        my $filedir     = dirname($workingfile);
        my $filename    = basename($workingfile);
        my $padded_file = "$filedir/padded_noclean_$filename";
        do_padding( $workingfile, 'lat', 'lon', $newVarName, $nco,
            $padded_file );

        # Now doing cleanup here because of two kinds 10/2014
        if ( -e $padded_file ) {
            my $in_tmp1   = "$filedir/padded_$filename";
            my $vname_tmp = $newVarName . "_tmp";
            if ( $type eq "shift" ) {
                runNCOCommand(
                    "ncks -C -O -h -x -v $vname_tmp,lat,lon $padded_file $in_tmp1",
                    'After padding, cleanup old lat/lon names'
                );
                unlink($padded_file)
                    or warn "WARN failed to delete file $padded_file: $!";
                runNCOCommand(
                    "ncrename -O -h -v Lat,lat -v Lon,lon $in_tmp1",
                    'After padding, Rename new lat/lon to old names'
                );
            }
            else {
                runNCOCommand(
                    "ncks -C -O -h -x -v $vname_tmp,lat $padded_file $in_tmp1",
                    'After padding, cleanup old lat and new unwanted Lon  names'
                );
                unlink($padded_file)
                    or warn "WARN failed to delete file $padded_file: $!";

                # Rename
                runNCOCommand(
                    "ncrename -O -h  -v Lat,lat  $in_tmp1",
                    'After padding, Rename new lat to old names'
                );
            }
            move_file( $in_tmp1, $workingfile );

            # if we do padding, NCO may have given us a fillvalue
            $$fillvalue_ref = Giovanni::Data::NcFile::get_value_of_attribute(
                $workingfile, $dataId, "_FillValue" );
            chomp $$fillvalue_ref;
        }
        else {
            print STDERR "WARN padded file does not exist: $padded_file \n";
        }
    }
    return $workingfile;
}

sub getDateMidpoint {
    my $startobj = shift;
    my $endobj   = shift;

    my @mids = ( 14, 15, 16 );
    my $midmonths = {
        '01'        => $mids[2],
        '1'         => $mids[2],
        'January'   => $mids[2],
        'Jan'       => $mids[2],
        '02'        => $mids[0],
        '2'         => $mids[0],
        'February'  => $mids[0],
        'Feb'       => $mids[0],
        '03'        => $mids[2],
        '3'         => $mids[2],
        'March'     => $mids[2],
        'Mar'       => $mids[2],
        '04'        => $mids[1],
        '4'         => $mids[1],
        'April'     => $mids[1],
        'Apr'       => $mids[1],
        '05'        => $mids[2],
        '5'         => $mids[2],
        'May'       => $mids[2],
        '06'        => $mids[1],
        '6'         => $mids[1],
        'June'      => $mids[1],
        'Jun'       => $mids[1],
        '07'        => $mids[2],
        '7'         => $mids[2],
        'July'      => $mids[2],
        'Jul'       => $mids[2],
        '08'        => $mids[2],
        '8'         => $mids[2],
        'August'    => $mids[2],
        'Aug'       => $mids[2],
        '09'        => $mids[1],
        '9'         => $mids[1],
        'September' => $mids[1],
        'Sep'       => $mids[1],
        '10'        => $mids[2],
        'October'   => $mids[2],
        'Oct'       => $mids[2],
        '11'        => $mids[1],
        'November'  => $mids[1],
        'Nov'       => $mids[1],
        '12'        => $mids[2],
        'December'  => $mids[2],
        'Dec'       => $mids[2],
    };
    my $datepart = sprintf( "%04d-%02d-%02d",
        int( ( $startobj->year + $endobj->year ) / 2 ),
        $startobj->month, $midmonths->{ $startobj->month } );

    # return a DateTime obj instead of hand crafted date.
    my $midpointTimeAttribute = add_offset( $datepart,
        "00:00:00", 0 );

    return $midpointTimeAttribute;
}

sub update_time_value {
    my $startTimeAttribute = shift;
    my $seconds            = shift;
    my $workingfile        = shift;
    my $epoch_secs
        = Giovanni::Data::NcFile::string2epoch($startTimeAttribute);

    if ( $epoch_secs != $seconds ) {
        print STDERR
            "WARN startTimeAttribute ($epoch_secs) != startobj ($seconds) \n";
        if ( $seconds == 0 ) {
            print STDERR
                "WARN using startTimeAttribute ($epoch_secs) for :start_time \n";
            $seconds = $epoch_secs;
            if ( $epoch_secs == 0 ) {
                print STDERR
                    "WARN not updating time because both startTimeAttribute and startobj are 0\n";
                return;
            }
        }
    }

    # In order not to rearrange the format for all of the unit tests I need to not do
    # this if I don't have to:
    # second time is data:
    my @data = `ncdump -v time $workingfile`;
    while ( $data[0] !~ /data:/ and $#data > 1 ) {
        shift @data;
    }
    while ( $data[0] !~ /time =/ and $#data >= 0 ) {
        shift @data;
    }
    my $string;
    foreach (@data) {
        $string .= $_;
    }
    $string =~ s/time =//;
    $string =~ s/;//;
    $string =~ s/}//;
    @data = split( /,/, $string );

    if ( $data[0] == $seconds ) {

        # nothing to do.
        return;
    }
    my $timeUpdateCommand
        = "ncap2 -O -h -s 'time(:)={$seconds}' $workingfile $workingfile.alwaysupdatetime";
    runNCOCommand( $timeUpdateCommand,
        "Always update the time variable value" );
    print STDERR "INFO update time command: $timeUpdateCommand\n"
        if ($verbose);
    move_file( "$workingfile.alwaysupdatetime",
        $workingfile, "$workingfile.alwaysupdatetime" );
}

# GLDAS_020_monthly swe difficulties with fillvalue:
# The packing of the input data causes the problem.
# The scale_factor and add_offset indicate the input data are to be upacked into type NC_FLOAT, though the variable itself is already unpacked and stored as type NC_DOUBLE. Basically, this confuses ncap2/NCO internally, and you get the garbled results.
#Here are three options to consider for the input data:
#Delete the packing metadata (since it is degenerate, redundant, and mis-typed)
#ncatted -a add_offset,,d,, -a scale_factor,,d,, pad_bug_in.nc
#This is what I recommend. Saving data with scale_factor=1 and add_offset=0 is a poor practice that can unnecessarily slow down data analysis. Your input data are unpacked. Either pack it correctly or delete the packing information.
sub handling_already_unpacked_data {
    my $self      = shift;
    my $datafield = shift;

    my ( $atthash, $attlist )
        = Giovanni::Data::NcFile::get_variable_attributes( $self->{file}, 0,
        $datafield );

    if ($atthash) {
        if ( $atthash->{scale_factor} and $atthash->{add_offset} ) {
            if ( $atthash->{scale_factor} == 1
                and $atthash->{add_offset} == 0 )
            {

                $self->delete_attribute( "scale_factor", $datafield );
                $self->delete_attribute( "add_offset",   $datafield );

                print STDERR
                    "Removing packing info scale_factor and add_offset"
                    if $verbose;
            }
            else {
                print STDERR "Not removing packing info" if $verbose;
            }
        }

    }
    else {
        warn( "No attributes for our main variable! <" . $datafield . ">" );
    }

}

# apply the EDDA/AESIR Minimum Valid Value and or Maximum Valid Value:
sub ApplyValidMinAndValidMax {
    my $workingfile      = shift;
    my $finalVarName     = shift;
    my $dataFieldVarInfo = shift;
    my $fillval          = shift;
    my $orgFV            = shift;

    # Because we may be creating fill values where there were none before we need to make sure there
    # is one and it is set to the given fillvalue (default in scrubber is -9999
    # At this point the fill value name is always _FillValue (either originally or has been changed to this

    ## to create the 'validMin' and validMax' attributes if defined
    # If there is no valid min or valid max we don't want to both:
    # 1. run the Filter
    # 2. Change the fillvalue.

    my $doit = 0;
    if ( Giovanni::Data::NcFile::StringBoolean(
            $dataFieldVarInfo->get_validMin, $fillval
        )
        )
    {
        createAttribute( $workingfile, 'valid_min', $finalVarName, 'f',
            $dataFieldVarInfo->get_validMin );
        ++$doit;
    }
    if ( Giovanni::Data::NcFile::StringBoolean(
            $dataFieldVarInfo->get_validMax, $fillval
        )
        )
    {
        createAttribute( $workingfile, 'valid_max', $finalVarName, 'f',
            $dataFieldVarInfo->get_validMax );
        ++$doit;
    }
    return 0 if $doit == 0;

    # We only want to update this if it doesn't already exist as there are some crazy values for fillvalue which
    # if we try to update will be slightly different 9.99u2852279e+20 instead of 9.999e+20
    # This will only be different if the fillvalue is the default -9999., assigned by scrubber:
    # This might be true if somehow we missed picking up the fillvalue so I think I want to employ my new checker...
    # If we do have a fillvalue, we do want to put it in, if needed, before we run the filter
    my $current_fillvalue
        = Giovanni::Data::NcFile::get_value_of_attribute( $workingfile,
        $finalVarName, "_FillValue" );
    if ( $fillval == $orgFV and !$current_fillvalue ) {
        my $fvCommand
            = "ncatted -a _FillValue,$finalVarName,o,f,$fillval $workingfile";
        runNCOCommand( $fvCommand,
            'Making sure there is a fillvalue attribute as we are about to use the Filter'
        );
    }

    my $status = Giovanni::Data::NcFile::Filter(
        $workingfile, $finalVarName, $fillval,
        $dataFieldVarInfo->get_validMin,
        $dataFieldVarInfo->get_validMax
    );
    return $status;
}

# If necessary add cell method to main var
sub applyCellMethodPointForInstantaneous {
    my $dataId      = shift;
    my $startobj    = shift;
    my $endobj      = shift;
    my $workingfile = shift;

    my $filetime = $endobj->epoch - $startobj->epoch;

    if ( $filetime < 10 ) {    # 10 seconds...really testing for 1 second
        if ( $filetime < 0 ) {
            die "time of the file is < 0: end:"
                . $endobj->epoch
                . " start:"
                . $startobj->epoch;
        }
        if ( $filetime > 0 ) {
            warn "Interesting time length for file:" . $filetime . " seconds";
        }

        # This attribute is one case where we may just want to append to it, not replace
        my ( $atthash, $attarr )
            = Giovanni::Data::NcFile::get_variable_attributes( $workingfile,
            0, $dataId );
        my $cellMethodsCurrentValue = $atthash->{'cell_methods'}
            if exists $atthash->{'cell_methods'};

        if ( $cellMethodsCurrentValue =~ /point/
            and $cellMethodsCurrentValue !~ /time: point/ )
        {
            warn
                "This file may already have a misformatted cell_methods attribute for $dataId";
        }
        my $newCellMethodsValue;
        if ( $cellMethodsCurrentValue
            and $cellMethodsCurrentValue !~ /time: point/ )
        {
            $newCellMethodsValue = $cellMethodsCurrentValue . " time: point";
        }
        else {
            $newCellMethodsValue = " time: point";
        }
        updateAttributeValue( $workingfile, "cell_methods", $dataId, 'c',
            $newCellMethodsValue );
    }
}

# If necessary add time_bnds variable and artifacts
sub addTimeBnds {
    my $NcFile      = shift;
    my $startobj    = shift;
    my $endobj      = shift;
    my $workingfile = shift;

    if ( !$NcFile->get_time_bnds_name('time') ) {

        # create time bounds from $startobj, $endobj
        my $first  = $startobj->epoch;
        my $second = $endobj->epoch;

        my $ncapstring
            = qq('defdim("nv",2); time_bnds[\$time,\$nv]={$first,$second}');
        my $timeUpdateCommand
            = qq(ncap2 -O -h -s $ncapstring $workingfile $workingfile.time_bnds);
        print STDERR $timeUpdateCommand, "\n" if $verbose;
        runNCOCommand( $timeUpdateCommand, "Adding time_bnds variable" );
        move_file( "$workingfile.time_bnds", $workingfile,
            "$workingfile.time_bnds" );
        updateAttributeValue( $workingfile, "units", "time_bnds", 'c',
            'seconds since 1970-01-01 00:00:00' );
        updateAttributeValue( $workingfile, 'bounds', 'time', 'c',
            'time_bnds' );
    }
    else {
        print STDERR"This file already has time_bnds\n" if $verbose;
    }
}

# Here we are adding a two dimensional bnds variable for lat and for lon.
# This involves selecting a pair of numbers that defines the bounds of each of the
# points in the lat and lon.  Since our grids are even we decided that the half-way
# point would be our bounds
#
# We also try and do a check on whether or not one pair of bounds overlap with the next
# Essentially the upperbound of one coordinate should = the lowerbound of the next:

sub addLatLonBnds {
    my $workingfile        = shift;
    my $workingdir         = shift;
    my $recordedTheProblem = undef;

    my ( $lat_res, $lon_res )
        = Giovanni::Data::NcFile::spatial_resolution( $workingfile, 'lat',
        'lon' );

    # LATITUDE:
    my @lat_values
        = Giovanni::Data::NcFile::get_variable_values( $workingfile, 'lat',
        'lat' );

    if ( $#lat_values < 1 ) {
        die "Man! this file doesn't even have lat lons!!!\n";
    }

    my $latstring = "";

    # LIMITS:
    my $minlat
        = $lat_values[0] - $lat_res / 2.0 < -90
        ? -90
        : $lat_values[0] - $lat_res / 2.0;
    my $maxlat
        = $lat_values[-1] + $lat_res / 2.0 > 90
        ? 90
        : $lat_values[-1] + $lat_res / 2.0;

    my $previouslat = $minlat
        ;    # checking to make sure bounds values don't overlap for than ==
    for ( my $i = 0; $i <= $#lat_values; ++$i ) {

        my $lower_bound = $lat_values[$i] - $lat_res / 2.0;
        my $upper_bound = $lat_values[$i] + $lat_res / 2.0;

        if ( $i == 0 ) {
            $latstring .= sprintf( "%8.4f,%8.4f,", $minlat, $upper_bound );
        }
        elsif ( $i == $#lat_values ) {
            $latstring .= sprintf( "%8.4f,%8.4f,", $lower_bound, $maxlat );
        }
        else {
            if ( abs( $previouslat - $lower_bound ) > .0001
                and $previouslat > $lower_bound )
            {
                if ( !$recordedTheProblem ) {

                    # review the problem
                    print STDERR "latitude separation\n";
                    for ( my $j = $i - 3; $j < $i + 3; ++$j ) {
                        if ( $j >= 0 and ( $j + 1 ) < $#lat_values ) {
                            print STDERR $lat_values[$j]
                                - $lat_values[ $j + 1 ], "\n";
                        }
                    }
                    warn( 'WARN',
                        'lat_bnds are overlapping. The previous upper bound was: '
                            . $previouslat
                            . ' It should be <= '
                            . $lower_bound
                            . " ( the lower bound of this lat:"
                            . $lat_values[$i] );

                    $recordedTheProblem = 1;
                }

                # just going to set the lower_bound = previous upper bound...
                $lower_bound = $previouslat;
            }
            $latstring
                .= sprintf( "%8.4f,%8.4f,", $lower_bound, $upper_bound );
        }
        $previouslat = $upper_bound;
    }

    chop($latstring);    # last comma

    # create the 2 dimensions
    my $ncapstring
        = qq('defdim("latv",2); lat_bnds\@units="degrees_north"; lat_bnds[\$lat,\$latv]={$latstring}');

    my $latUpdateCommand;

    if ( length($ncapstring) > 32000 ) {
        $ncapstring =~ s/^'//;
        $ncapstring =~ s/'$/;/;

        eval {
            open( FH, ">$workingdir/lat.nco" );
            print FH $ncapstring;
            close(FH);
        };
        if ($?) {
            quit( 1,
                "ERROR failed to create the lat ncap2 script file: $? -- $@"
            );
        }
        $latUpdateCommand
            = qq(ncap2 -O -h -S $workingdir/lat.nco  $workingfile $workingfile.lat_bnds);
    }
    else {
        $latUpdateCommand
            = qq(ncap2 -O -h -s $ncapstring $workingfile $workingfile.lat_bnds);
    }

    print STDERR $latUpdateCommand, "\n" if $verbose;
    runNCOCommand( $latUpdateCommand, "Adding lat_bnds variable" );
    move_file( "$workingfile.lat_bnds", $workingfile,
        "$workingfile.lat_bnds" );
    updateAttributeValue( $workingfile, 'bounds', 'lat', 'c', 'lat_bnds' );

    # LONGITUDE
    $recordedTheProblem = undef;
    my @lon_values
        = Giovanni::Data::NcFile::get_variable_values( $workingfile, 'lon',
        'lon' );

    my $lonstring = "";
    my $minlon
        = $lon_values[0] - $lon_res / 2.0 < -180
        ? -180
        : $lon_values[0] - $lon_res / 2.0;
    my $maxlon
        = $lon_values[-1] + $lon_res / 2.0 > 180
        ? 180
        : $lon_values[-1] + $lon_res / 2.0;
    my $previouslon = $minlon
        ;    # checking to make sure bounds values don't overlap for than ==

    for ( my $i = 0; $i <= $#lon_values; ++$i ) {

        my $lower_bound = $lon_values[$i] - $lon_res / 2.0;
        my $upper_bound = $lon_values[$i] + $lon_res / 2.0;

        if ( $i == 0 ) {
            $lonstring .= sprintf( "%8.4f,%8.4f,", $minlon, $upper_bound );
        }
        elsif ( $i == $#lon_values ) {
            $lonstring .= sprintf( "%8.4f,%8.4f,", $lower_bound, $maxlon );
        }
        else {

            if ( abs( $previouslon - $lower_bound ) > .0001
                and $previouslon > $lower_bound )
            {

                # review the problem
                if ( !$recordedTheProblem ) {
                    print STDERR "longitude separation\n";
                    for ( my $j = $i - 3; $j < $i + 3; ++$j ) {
                        if ( $j >= 0 and ( $j + 1 ) < $#lon_values ) {
                            print STDERR $lon_values[$j]
                                - $lon_values[ $j + 1 ], "\n";
                        }
                    }

                    warn(
                        'WARN lon_bnds are overlapping. The previous upper bound was: '
                            . $previouslon
                            . ' It should be <= '
                            . $lower_bound
                            . " ( the lower bound of this lon:"
                            . $lon_values[$i] );
                    $recordedTheProblem = 1;
                }

                # just going to set the lower_bound = previous upper bound...
                $lower_bound = $previouslon;
            }
            $lonstring
                .= sprintf( "%8.4f,%8.4f,", $lower_bound, $upper_bound );
        }
        $previouslon = $upper_bound;
    }
    chop($lonstring);

    # create the 2 dimensions
    $ncapstring
        = qq('defdim("lonv",2); lon_bnds\@units="degrees_east"; lon_bnds[\$lon,\$lonv]={$lonstring}');

    my $lonUpdateCommand;

    # command lines can only be so long. I think limit is between 132000 and 260000
    if ( length($ncapstring) > 32000 ) {
        $ncapstring =~ s/^'//;
        $ncapstring =~ s/'$/;/;

        eval {
            open( FH, ">$workingdir/lon.nco" );
            print FH $ncapstring;
            close(FH);
        };
        if ($?) {
            quit( 1,
                "ERROR failed to create the lon ncap2 script file: $? -- $@"
            );
        }
        $lonUpdateCommand
            = qq(ncap2 -O -h -S $workingdir/lon.nco  $workingfile $workingfile.lon_bnds);
    }
    else {
        $lonUpdateCommand
            = qq(ncap2 -O -h -s $ncapstring $workingfile $workingfile.lon_bnds);
    }

    print STDERR $lonUpdateCommand, "\n" if $verbose;
    runNCOCommand( $lonUpdateCommand, "Adding lon_bnds variable" );
    move_file( "$workingfile.lon_bnds", $workingfile,
        "$workingfile.lon_bnds" );

    updateAttributeValue( $workingfile, 'bounds', 'lon', 'c', 'lon_bnds' );
}

sub apply_timeIntvRepPos {
    my $dataFieldVarInfo = shift;
    my $startobj         = shift;
    my $endobj           = shift;
    my $workingfile      = shift;

    if ( defined $dataFieldVarInfo->get_timeIntvRepPos )
    {
        my $newTime = $startobj->epoch;
        if ( $dataFieldVarInfo->get_timeIntvRepPos eq 'start' ) {

            # already set to start
        }
        elsif ( $dataFieldVarInfo->get_timeIntvRepPos eq 'middle' ) {
            $newTime = ceil( ( $startobj->epoch + $endobj->epoch ) / 2 );
        }
        elsif ( $dataFieldVarInfo->get_timeIntvRepPos eq 'end' ) {
            $newTime = $endobj->epoch;
        }
        my $timeUpdateCommand
            = "ncap2 -O -h -s 'time(:)={$newTime}' $workingfile $workingfile.alwaysupdatetime";
        runNCOCommand( $timeUpdateCommand,
            "Always update the time variable value" );
        print STDERR "INFO update time command: $timeUpdateCommand\n"
            if ($verbose);
        move_file( "$workingfile.alwaysupdatetime",
            $workingfile, "$workingfile.alwaysupdatetime" );

        return $newTime;
    }
}

1;
__END__

=head1 NAME

Giovanni::Scrubber - Perl module for EDDA re-naming of data field attributes in scrubbed files

=head1 ABSTRACT

Giovanni::Scrubber - Perl module for EDDA re-naming of data field attributes in scrubbed files

=head1 SYNOPSIS

  use Giovanni::Scrubber;
  
  1. Find the giovanni.cfg so that ncatted is in the path and you can find the right cache dir
  2. Find the rescrubber.cfg so that you can do some logging and get the AESIR-AG vaiable mapping hash
  3. Find the .db file for the data_field being processed.
  4. Get a list of the file locations from the db file.
  5. For each file:
       review it beforehand
       make the change: chmod 664 , ncatted, chmod 444
       review it afterwords
       publish results of review.
  6. Log 


   
=head1 CLIENTS

  updateScrubbedDataFile.pl
  deprecated:
  http://s4ptu-ts2.ecs.nasa.gov/~rstrub/daac-bin/giovanni/updateScrubbedDataFile.pl?data_field=AIRX3STD_006_RelHumid_A&attr_name=dataFieldUnit&attr_value=percent
  new:
  http://s4ptu-ts2.ecs.nasa.gov/~rstrub/daac-bin/giovanni/updateScrubbedDataFile.pl?data_field=AIRX3STD_006_RelHumid_A&dataFieldUnits=percent&dataFieldLongName=A very long name
  
