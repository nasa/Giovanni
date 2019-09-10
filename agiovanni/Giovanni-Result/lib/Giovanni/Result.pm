package Giovanni::Result;

# $Id: Result.pm,v 1.201 2015/05/13 14:34:21 mhegde Exp $
# aGiovanni, Version $Name:  $

use 5.008008;
use strict;
use warnings;
use Data::UUID;
use Safe;
use vars '$AUTOLOAD';
use XML::LibXML;
use XML::Hash::LX;
use URI;
use URI::Escape;
use File::Basename;
use File::Copy;
use POSIX qw(setsid);
use Giovanni::Util;
use Giovanni::Visualizer;
use Giovanni::Serializer;
use Giovanni::Status;
use Giovanni::Workflow;
use Log::Log4perl;
use List::MoreUtils qw/ uniq any /;
use Proc::Killfam;
use Proc::ProcessTable;
use Date::Manip;
use DateTime;
use Date::Parse;
use File::Basename;
use Time::Local;
use JSON;
use Try::Tiny;

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

our $VERSION = '1.00';

################################################################################
sub new() {
    my ( $class, %input ) = @_;
    my $self = {};
    if ( defined $input{service} && length( $input{service} ) > 0 ) {
        unless ( $input{service} eq 'LOAD_CRITERIA'
            or defined $GIOVANNI::WORKFLOW_MAP{ $input{service} } )
        {
            $self->{_ERROR_TYPE} = 1;
            $self->{_ERROR_MESSAGE}
                = "Service not defined : " . $input{service};
            return bless( $self, $class );
        }
    }

    #Check whether the result set location is defined and valid
    unless ( defined $input{resultset_dir} ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Result set directory not defined";
        return bless( $self, $class );
    }
    unless ( -d $input{resultset_dir} ) {
        $self->{_ERROR_TYPE}    = 1;
        $self->{_ERROR_MESSAGE} = "Result set directory doesn't exist";
        return bless( $self, $class );
    }

    my $id = Data::UUID->new();
    my $uuid;
    if ( defined $input{result} ) {

        #See if the input result ID is valid
        eval { $uuid = $id->from_string( $input{result} ); };

    }
    else {

        #Case where a new service is being requested
        #Generate id if result ID doesn't exist
        $uuid = $id->create();
    }
    $self->{_ID} = $id->to_string($uuid) if defined $uuid;
    if ( defined $self->{_ID} ) {
        $self->{_RESULT_DIR}
            = $input{resultset_dir} . '/' . $self->{_ID} . '/';

        unless ( -d $self->{_RESULT_DIR} ) {

            #Case of result directory not existing
            if ( defined $input{service}
                and $input{service} ne 'LOAD_CRITERIA' )
            {

                #Should create result directory only if a service is requested
                unless ( mkdir( $self->{_RESULT_DIR} ) ) {
                    $self->{_ERROR_MESSAGE}
                        = 'Result directory doesnot exist';
                    $self->{_ERROR_TYPE} = 1;
                }
            }
            elsif ( not defined $input{service} ) {

             #If service is not defined, result directory should have existed!
             #Indicate an error
                $self->{_ERROR_MESSAGE} = $input{result} . " doesn't exist";
                $self->{_ERROR_TYPE}    = 1;
            }
        }
        $self->{_DATA} = [];
        chmod( 0775, $self->{_RESULT_DIR} ) if ( -d $self->{_RESULT_DIR} );
    }
    else {
        $self->{_ERROR_MESSAGE} = $input{result} . ' is an invalid ID';
        $self->{_ERROR_TYPE}    = 1;
    }

    #Read/Write options for visualization
    $self->{_OPTIONS} = defined $input{options} ? $input{options} : undef;

    #Short or Long format flag for toXML method (short returns only tree of IDs)
    $self->{_FORMAT} = defined $input{format} ? $input{format} : undef;

    #Read history TODO : Why???
    my $historyFile = $self->{_RESULT_DIR} . '/'
        . $GIOVANNI::VISUALIZER->{HISTORY_FILE_NAME};

    # http connection timeout value; default is 260 seconds;
    $self->{_SESSION_TIMEOUT}
        = defined $input{timeout} ? $input{timeout} : 260;

    # Store session, resultset and result IDs
    $self->{_SESSION_IDS}
        = [ Giovanni::Util::getSessionIds( $self->{_RESULT_DIR} ) ];

    return bless( $self, $class );
}
################################################################################
sub getStatus {
    my ($self) = @_;

    $self->{_CREATIONTIME} = '0';
    $self->loadCriteria();
    if ($self->{_CREATIONTIME} ne '0') {
        $self->{_CREATIONTIME} = Date::Parse::str2time($self->{_CREATIONTIME})
    }
    else {
       $self->{_CREATIONTIME} = 0;
    }
    my $statusMsg = "";
    my $status
        = Giovanni::Status->new( $self->getDir(), $self->{_SESSION_TIMEOUT},
        $self->getPortal() );
    if ( $self->getStatusCode() ) {
        $self->{_STATUS} = {
            code            => $self->getStatusCode(),
            message         => $self->getStatusMessage(),
            percentComplete => 0
        };
        return;
    }
    elsif ( $status->onError() ) {
        $statusMsg = $status->getStatusMessage();
        $self->{_STATUS} = {
            code            => 1,
            message         => $statusMsg,
            percentComplete => 0
        };
        return;
    }
    my $curStatusHash = $status->findCurrentStatus();
    if ( $status->onError() ) {
        $statusMsg = $status->getStatusMessage();
        $self->{_STATUS} = {
            code            => 1,
            message         => $statusMsg,
            percentComplete => 0
        };
        return;
    }
    $self->{_STATUS} = {
        code            => $curStatusHash->{flag},
        message         => $curStatusHash->{message},
        percentComplete => $curStatusHash->{percentComplete}
    };
}
################################################################################
sub loadCriteria {
    my ($self)    = @_;
    my $inputFile = $self->getDir() . '/input.xml';
    my $doc       = Giovanni::Util::parseXMLDocument($inputFile);
    if ( defined $doc ) {
        my ($node) = $doc->findnodes('/input/referer');
        $self->{_REFERER} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/query');
        $self->{_QUERY} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/portal');
        $self->{_PORTAL} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/service');
        $self->{_SERVICE} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/title');
        $self->{_TITLE} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/description');
        $self->{_DESCRIPTION} = $node->textContent() if defined $node;
        ($node) = $doc->findnodes('/input/creationTime');
        $self->{_CREATIONTIME} = $node->textContent() if defined $node;
    }
}

###############################################################################
sub launchWorkflow {
    my ( $self, $input, $logger ) = @_;

    # Record result creation time here
    my $timeNow      = DateTime->now();
    my $creationTime = $timeNow->strftime('%Y-%m-%dT%H:%M:%SZ');

    #If the service requests loading criteria, load and return
    my $service = defined $input->{service} ? $input->{service} : '';
    return $self->loadCriteria() if ( $service eq 'LOAD_CRITERIA' );

    # Create the title
    my ( $resultTitle, $resultDescr )
        = $self->createTitle( $input, \%GIOVANNI::WORKFLOW_MAP );

    #Create input XML file
    my $doc         = Giovanni::Util::createXMLDocument('input');
    my $sessionNode = XML::LibXML::Element->new('result');
    $sessionNode->setAttribute( 'id', $self->getId() || '' );
    $sessionNode->appendTextChild( 'dir', $self->getDir() || '' );
    $doc->appendTextChild( 'referer',      $ENV{HTTP_REFERER} || '' );
    $doc->appendTextChild( 'creationTime', $creationTime      || '' );
    $doc->appendTextChild( 'query',        $ENV{QUERY_STRING} || '' );
    $doc->appendTextChild( 'title',        $resultTitle       || '' );
    $doc->appendTextChild( 'description',  $resultDescr       || '' );
    $doc->appendChild($sessionNode);
    my @keywordList = sort keys %$input;

    $self->{_PORTAL} = $input->{portal} if exists $input->{portal};
    foreach my $keyword (@keywordList) {
        foreach my $value ( split( "\0", $input->{$keyword} ) ) {
            $value =~ s/\^s+|\s+$//g;

            # Chocka: Added code to split data=<varId>:<zDimValue> and put the
            # zVal as the attribute of the <data> element
            if ( $self->getPortal() eq 'GIOVANNI' && $keyword eq "data" ) {
                my ( $dataVar, $operatorStr ) = ( undef, undef );

                # Find any operator that might be included: <var>(<op1>:<op2>)
                if ( $value =~ /([^\(]+)\((.+)\)/ ) {
                    ( $dataVar, $operatorStr ) = ( $1, $2 );
                }
                else {
                    ( $dataVar, $operatorStr ) = ( $value, undef );
                }
                my $dataElement = XML::LibXML::Element->new($keyword);
                $dataElement->appendTextNode($dataVar);
                if ( defined $operatorStr ) {
                    my @operatorList = split( /:/, $operatorStr );
                    foreach my $operator (@operatorList) {
                        my ( $lhs, $rhs ) = split( /=/, $operator );
                        if ( $lhs eq 'units' ) {
                            $dataElement->setAttribute( "units", $rhs );
                        }
                        elsif ( $lhs eq 'z' ) {
                            $dataElement->setAttribute( "zValue", $rhs );
                        }
                    }
                }
                $doc->appendChild($dataElement);
            }
            elsif ( $keyword eq "bbox" ) {
                # parse the bounding box and then write it out in the standard
                # string format.
                my $parsed = Giovanni::BoundingBox->new( STRING => $value );
                $doc->appendTextChild( $keyword, $parsed->getString() );
            }
            else {
                $doc->appendTextChild( $keyword, $value );
            }
        }
    }
    my $inputFile = ( $self->getDir() || './' ) . '/input.xml';
    my $flag = Giovanni::Util::writeFile( $inputFile, $doc->toString(0) );
    unless ($flag) {
        $self->{_ERROR_MESSAGE}
            = "Unable to create input file for " . $self->getId();
        $self->{_ERROR_TYPE} = 1;
        return $flag;
    }

    $self->setStatusMessage('Launching workflow');

#Environment variables that need to be passed to the visualization worker
#   which is a string of the environment variables in JSON format
#   e.g.  my $envJSON = '{"DUMMY_PATH": "/opt/dummy_bin/", "DUMMY_INT": 1}';
#NOTE: If the value of JSON pair is non-string, it will be converted to string before passing it to the worker
    my $envHash = {};
    $envHash->{SCRIPT_URI} = $ENV{SCRIPT_URI} if defined $ENV{SCRIPT_URI};
    $envHash->{HTTP_X_FORWARDED_HOST} = $ENV{HTTP_X_FORWARDED_HOST}
        if defined $ENV{HTTP_X_FORWARDED_HOST};
    my $envJSON = ( keys %$envHash ) ? JSON->new()->encode($envHash) : undef;

    #Logging
    if ( defined $logger ) {
        Log::Log4perl::MDC->put( "component", "Workflow" );
        $logger->info("STATUS:INFO Launching workflow");
    }

    #Submit workflow
    my $sessionDir = $self->getDir();
    my $cmd
        = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} "
        . " PATH=$GIOVANNI::ENV{PATH} "
        . " submitWorkflow.py "
        . " --GIOVANNI_CFGFILE $GIOVANNI::CELERYCONFIG{giovanni_config_dir}/giovanni.cfg"
        . " --WORKFLOW_CFGFILE $GIOVANNI::CELERYCONFIG{giovanni_config_dir}/workflow.cfg"
        . " --SERVICE $input->{service}"
        . " --OUTPUT_DIR $sessionDir"
        . " --WORKFLOW_STATUSFILE $sessionDir/status.txt"
        . " --WORKFLOW_QUEUESTATEFILE $sessionDir/workflow.txt";
    $cmd .= " --ENV '" . $envJSON . "' " if defined $envJSON;
    $logger->info($cmd);
    my $celeryLog = `$cmd`;

    if ($?) {
        $self->setStatusMessage('Failed to submit workflow');
        print STDERR "Failed to submit workflow: $celeryLog\n";
        $self->{_STATUS}{MESSAGE} = $celeryLog;
    }
}

###############################################################################
sub launchVisualizationManager {
    my ( $self, $input, $logger ) = @_;

#Environment variables that need to be passed to the visualization worker
#   which is a string of the environment variables in JSON format
#   e.g.  my $envJSON = '{"DUMMY_PATH": "/opt/dummy_bin/", "DUMMY_INT": 1}';
#NOTE: If the value of JSON pair is non-string, it will be converted to string before passing it to the worker
    my $envHash = {};
    $envHash->{SCRIPT_URI} = $ENV{SCRIPT_URI} if defined $ENV{SCRIPT_URI};

    # Environment variables to support URL mapping in a proxied environment
    $envHash->{HTTP_X_FORWARDED_HOST} = $ENV{HTTP_X_FORWARDED_HOST}
        if defined $ENV{HTTP_X_FORWARDED_HOST};
    $envHash->{HTTP_X_FORWARDED_PROTO} = $ENV{HTTP_X_FORWARDED_PROTO}
        if defined $ENV{HTTP_X_FORWARDED_PROTO};

    my $envJSON = ( keys %$envHash ) ? JSON->new()->encode($envHash) : undef;

    #If the service requests loading criteria, load and return
    my $service = defined $input->{service} ? $input->{service} : '';
    return $self->loadCriteria() if ( $service eq 'LOAD_CRITERIA' );
    $service = $self->getService() if $self->getOptions();
    my $opt
        = defined $self->getOptions()
        ? $self->getOptions()
        : $input->{options};

    #Logging
    if ( defined $logger ) {
        Log::Log4perl::MDC->put( "component", "VisualizationManager" );
        $logger->info("STATUS:INFO Launching visualization manager");
    }

    #Submit visualization manger
    my $sessionDir = $self->getDir();
    my $plotType
        = exists $GIOVANNI::WORKFLOW_MAP{$service}{plot_type}
        ? $GIOVANNI::WORKFLOW_MAP{$service}{plot_type}
        : undef;

    # Submit visualization mangager to the queue
    # It will be running asynchronously
    my $cmd
        = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} "
        . " PATH=$GIOVANNI::ENV{PATH} "
        . ' submitVisualizationManager.py '
        . " --GIOVANNI_CFGFILE $GIOVANNI::CELERYCONFIG{giovanni_config_dir}/giovanni.cfg"
        . " --WORKFLOW_STATUSFILE $sessionDir/status.txt"
        . " --WORKFLOW_QUEUESTATEFILE $sessionDir/workflow.txt"
        . " --SESSION_DIR "
        . $sessionDir
        . " --TARGETS_FILENAME targets.txt "
        . " --VIS_FILENAME visualizer.txt "
        . " --PLOT_TYPE "
        . $plotType
        . " --OUTPUT_DIR "
        . $sessionDir;
    $cmd .= " --OPTIONS '" . $opt . "'"  if defined $opt;
    $cmd .= " --ENV '" . $envJSON . "' " if defined $envJSON;
    $logger->info($cmd);
    my $celeryLog = `$cmd`;

    if ($?) {
        my $currentStatusMessage = $self->getStatusMessage();
        $self->setStatusMessage( $currentStatusMessage
                . '<br>Failed to submit visualization manager' );
        print STDERR "Failed to submit visualization manager: $celeryLog\n";
        $self->{_STATUS}{MESSAGE} = $celeryLog;
    }
}

################################################################################
sub getLineage {
    my ($self) = @_;
    my $sessionIds = $self->getSessionIds();

    # Check for presence of lineage
    my $lineageFile = $self->getDir() . "/Lineage.xml";
    my $lineageUrl
        = 'daac-bin/lineage.pl?session='
        . $sessionIds->[0]
        . '&resultset='
        . $sessionIds->[1]
        . '&result='
        . $sessionIds->[2];
    return $lineageUrl if ( -f $lineageFile );

    # Case of make based provenance
    my $makeFile = $self->getDir() . '/Makefile';
    return '' unless -f $makeFile;

    # Check whether the provenance group file exists without which lineage
    # can't be displayed
    my $provGroupFile = $self->getDir() . '/provenance_group.txt';
    return '' unless -f $provGroupFile;

    # Check whether at least one provenance file exists
    my $targetListFile = $self->getDir() . '/targets.txt';
    my @targetList     = Giovanni::Util::readFile($targetListFile);
    my $provFlag       = 0;
    chomp @targetList;
    foreach my $target (@targetList) {
        my $provFile = $target;
        $provFile =~ s/^mfst/prov/;
        if ( -f $self->getDir() . "/$provFile" ) {
            $provFlag = 1;
            last;
        }
    }

    # If at least one provenance file exists, return the URL; otherwise,
    # return empty string
    return $provFlag ? $lineageUrl : '';
}
################################################################################
# Determines whether to continue with visualization or not based on percent completion of service
sub getVisualizerFlag {
    my ($self) = @_;

    # Figure out whether to visualize or not
    my $percentComplete = $self->getPercentComplete();
    my $visualizerFlag  = 1;
    if ( $percentComplete == 75 ) {
        my $startOfVisualizerFile = $self->getDir() . "/visualizer.txt";
        $visualizerFlag = ( -f $startOfVisualizerFile ) ? 1 : 0;
        unless ($visualizerFlag) {
            Giovanni::Util::writeFile( $startOfVisualizerFile, "\n" );
        }
    }

    return $visualizerFlag;
}

# Gathers data for a given result; returns result a list of hash refs containing result attributes and data files
sub gatherData {
    my ($self)         = @_;
    my $sessionDir     = $self->getDir();
    my $targetListFile = $sessionDir . '/targets.txt';
    my @dataList       = ();
    if ( -f $targetListFile ) {
        my @targetList = Giovanni::Util::readFile($targetListFile);
        chomp @targetList;

        # Prefer mfst.combine if it exists
        # otherwise, mfst.postprocess if it exists
        # otherwise, mfst.result
        my $lookFor = 'mfst.combine';
        unless ( any { $_ =~ /$lookFor/ } @targetList ) {
            $lookFor = 'mfst.postprocess';
        }
        unless ( any { $_ =~ /$lookFor/ } @targetList ) {
            $lookFor = 'mfst.result';
        }

        foreach my $target ( grep( !/^#/, @targetList ) ) {
            next unless ( $target =~ /$lookFor/ );
            my $manifestFile = $self->getDir() . '/' . $target;
            my $dataFileHash
                = Giovanni::Util::getDataFilesFromManifest($manifestFile);
            push( @dataList, $dataFileHash );
        }
    }
    return @dataList;
}

# Gathers plot manifest files from targets.txt for visualization task check
# NOTE it has duplicate code pieces from gatherData since currently I am not confident to change gatherData
# It returns a list of plot manifest file names
sub gatherPlotManifestFiles {
    my ($self)               = @_;
    my $sessionDir           = $self->getDir();
    my $targetListFile       = $sessionDir . '/targets.txt';
    my @plotManifestFileList = ();
    if ( -f $targetListFile ) {
        my @targetList = Giovanni::Util::readFile($targetListFile);
        chomp @targetList;

        # Prefer mfst.combine if it exists
        # otherwise, mfst.postprocess if it exists
        # otherwise, mfst.result
        my $lookFor = 'mfst.combine';
        unless ( any { $_ =~ /$lookFor/ } @targetList ) {
            $lookFor = 'mfst.postprocess';
        }
        unless ( any { $_ =~ /$lookFor/ } @targetList ) {
            $lookFor = 'mfst.result';
        }

        foreach my $target ( grep( !/^#/, @targetList ) ) {
            next unless ( $target =~ /$lookFor/ );
            my $plotManifestFileName = $target;
            $plotManifestFileName =~ s/$lookFor/mfst.plot/;
            my $plotManifestFile = $sessionDir . $plotManifestFileName;
            push( @plotManifestFileList, $plotManifestFile );
        }
    }
    return @plotManifestFileList;
}

# Gather the workflow task status and update times info
# It returns the workflow status and update times
sub gatherWorkflowTaskInfo {
    my ($workflowFile) = @_;
    my @workflowList   = Giovanni::Util::readFile($workflowFile);
    my $updateTimes    = 0;

    my $workflowStatus;
    foreach my $workflow ( grep( !/^#/, @workflowList ) ) {
        my @matches = (
            $workflow =~ /Workflow task \(id: [^\s]+\) status: ([A-Z]+)\n/g );
        if (@matches) {
            my ($tstate) = @matches;
            $workflowStatus = $tstate;
        }
        @matches = ( $workflow =~ /Update times: ([0-9]+)\n/g );
        if (@matches) {
            ($updateTimes) = @matches;
        }
    }

    return ( $workflowStatus, $updateTimes );
}

# Gather the visualization task and update times info
# It returns a hash table {manifestFileName: status} and update times
sub gatherVisualizationTaskInfo {
    my ($visualizerFile) = @_;
    my @visualizeList    = Giovanni::Util::readFile($visualizerFile);
    my $updateTimes      = 0;

    my %visualizerStatus = ();
    foreach my $visualize ( grep( !/^#/, @visualizeList ) ) {
        my @matches
            = ( $visualize
                =~ /Visualization manager \(id: [^\s]+, options: .+\) status: ([A-Z]+)\n/g
            );
        if (@matches) {
            my ($tstate) = @matches;
            $visualizerStatus{manager} = $tstate;
        }
        @matches
            = ( $visualize
                =~ /Visualization task \(id: [^\s]+, options: .+, file: ([^\s]+)\) status: ([A-Z]+)\n/g
            );
        if (@matches) {
            my ( $tfile, $tstate ) = @matches;
            $visualizerStatus{$tfile} = $tstate;
        }
        @matches = ( $visualize =~ /Update times: ([0-9]+)\n/g );
        if (@matches) {
            ($updateTimes) = @matches;
        }
    }

    return ( \%visualizerStatus, $updateTimes );
}

# Get the percentage done of the visualization tasks, which can be reported to UI
# Currently it employs the following ad hoc formula:
#       Percentage_done = (N_completed_tasks*1.0 + N_started_tasks*0.25) / (N_total_tasks*1.0) * 100
sub getVisPercentComplete {

    # parse arguments
    my %visualizerStatus = %{ $_[0] };
    my $numberVisTasks   = $_[1];

    # return 0 if no visualization tasks has been started
    return 0 if ( $numberVisTasks eq 0 );

    # compute the percentage complete
    my $value_done = 0.0;
    foreach my $task ( keys %visualizerStatus ) {
        next unless ( $task ne 'manager' );    # skip visualization manager
        my $status = $visualizerStatus{$task};
        if    ( $status eq "SUCCESS" ) { $value_done += 1.0; }
        elsif ( $status eq "STARTED" ) { $value_done += 0.25; }
    }

    # return the percentage complete
    return int( $value_done / $numberVisTasks * 100 );
}

# Get the visualization status to be reported
# Since there may be multiple visualizationt tasks/manager, and we don't want to get user overwhelmed,
#   we just report the most critical status based on the following order:
#   1. FAILURE
#   2. REVOKED
#   3. TIMEOUT
#   4. PENDING
#   5. STARTED
sub getVisStatusToReport {

    # parse arguments
    my %visualizerStatus = %{ $_[0] };
    my @statusList       = values %visualizerStatus;

    # get the most critical task status
    my $lookFor = "FAILURE";
    unless ( any { $_ =~ /$lookFor/ } @statusList ) {
        $lookFor = "REVOKED";
    }
    unless ( any { $_ =~ /$lookFor/ } @statusList ) {
        $lookFor = "TIMEOUT";
    }
    unless ( any { $_ =~ /$lookFor/ } @statusList ) {
        $lookFor = "PENDING";
    }
    unless ( any { $_ =~ /$lookFor/ } @statusList ) {
        $lookFor = "STARTED";
    }
    unless ( any { $_ =~ /$lookFor/ } @statusList ) {
        $lookFor = "OTHER";
    }

    # return the most critical task status
    return $lookFor;
}

# Get queue Stats to be reported
sub getQueueStats {

    # parse arguments
    my ( $celeryConfigFile, $sessionDir ) = @_;

    # get queue stats file name
    my $json_text = do {
        open( my $json_fh, "<", $celeryConfigFile )
            or die("Can't open \$celeryConfigFile\": $!\n");
        local $/;
        <$json_fh>;
    };
    my $json           = JSON->new;
    my $jsonQueue      = $json->decode($json_text);
    my $queue          = ( keys %{ $jsonQueue->{CELERY_QUEUES} } )[0];
    my $queueStatsFile = $sessionDir . "/" . $queue . ".json";

    # get queue stats
    my $message = '';
    $json_text = do {
        open( my $json_fh, "<", $queueStatsFile )
            or die("Can't open \$queueStatsFile\": $!\n");
        local $/;
        <$json_fh>;
    };
    $json = JSON->new;
    my $jsonStats       = $json->decode($json_text);
    my $numPendingTasks = $jsonStats->{NUM_PENDING_TASKS};

    # generate message
    if ( $numPendingTasks eq 0 ) {
        $message = "you are next in line.";
    }
    else {
        my $pl = 's' if ( $numPendingTasks gt 1 );
        $message = "$numPendingTasks request$pl ahead of you.";
    }

    # return
    return $message;
}

# Serializes result
sub toXML {
    my ($self) = @_;

    my $portal = $self->getPortal();
    $portal = 'GIOVANNI' unless defined $portal;

    # Start serializing
    my $doc = Giovanni::Util::createXMLDocument('result');
    $doc->setAttribute( 'id', $self->getId() );



    # if summary format return 
    # the id                : critical
    # the hidden status code: critical 
    # the description       : for tooltip
    # the title:              for performance
    # the query:              for performance
    # the referer:      not needed, just to be the same as before
    # the creationTime: not needed, just to show that order is correct for developers 
    if (defined $self->getFormat() and $self->getFormat()  eq 'summary') {
        # UI wants not only the ID, but also the status node and title
        my $resultTitle  = $self->getTitle();
        
        if (defined $resultTitle) { # then set all of the other input.xml data
            $doc->setAttribute( 'title', $resultTitle);

            my $criteriaNode = Giovanni::Util::createXMLElement(
               'criteria',
                 'query'   => $self->getQuery(),
                 'referer' => $self->getReferer()
            );
            $doc->appendChild($criteriaNode);

            my $resultDescr = $self->getDescription();
             $doc->setAttribute( 'description', $resultDescr )
                  if defined $resultDescr;
             
            my $creationTime = $self->getCreationTime();
            if (defined $creationTime) {
               $doc->setAttribute( 'creationTime', $creationTime);
            }
        }
        my @hidden = $self->getHideStatus();
        if ( scalar(@hidden) != 0 ) {
            $self->setStatusCode(-1);
        }
        my $statusNode = Giovanni::Util::createXMLElement(
            'status',
            'code'            => $self->getStatusCode(),
        );
        $doc->appendChild($statusNode);
        return $doc 
    }

    # Load the input criteria
    $self->loadCriteria();

    # Local variables for visualization result retreival
    my $plotManifestInfo = undef;
    my $visOptNode       = XML::LibXML::Element->new('visualizerOptions');

    # More local variables
    my $workflowFile   = $self->getDir() . "/workflow.txt";
    my $visualizerFile = $self->getDir() . "/visualizer.txt";
    my %visualizerStatus;

    # Get and set result title and description
    my $resultTitle = $self->getTitle();
    my $resultDescr = $self->getDescription();
    $doc->setAttribute( 'title', $resultTitle ) if defined $resultTitle;
    $doc->setAttribute( 'description', $resultDescr )
        if defined $resultDescr;

    my $service = $self->getService();

    # Gather all data
    my @dataGroupList = $self->gatherData();

    # Gather manifest file name list for visualization task status check
    my @plotManifestFileList = $self->gatherPlotManifestFiles();

    # See if this result was deleted or cancelled.
    my @hidden = $self->getHideStatus();
    if ( scalar(@hidden) != 0 ) {
        $self->setStatusCode(-1);
        $self->setStatusMessage("Result removed.");
    }
    else {

        # Determine whether we need to update the workflow queue status
        my $flag_workflowStatusRequest = 1;
        my ( $workflowStatus, $workflowUpdateTimes )
            = gatherWorkflowTaskInfo($workflowFile)
            if ( -e $workflowFile );
        $flag_workflowStatusRequest = 0
            if ( $workflowStatus =~ m/^(FAILURE|REVOKED|TIMEOUT|SUCCESS)$/ );

        # Update the workflow queue status
        my $updateWorkflowStatus = updateWorkflow($workflowFile)
            if ( $flag_workflowStatusRequest eq 1 );
        if ( $updateWorkflowStatus eq "FAILURE" ) {
            $self->setStatusCode(2);
            my $currentStatusMessage = $self->getStatusMessage();
            $self->setStatusMessage( $currentStatusMessage
                    . "<br>Failed to collect the workflow status from the queue."
            );
        }

        # Update the workflow status message for UI
        $workflowStatus = $self->updateWorkflowStatusMessage($workflowFile);

        # Determine whether we need to update the visualizer queue status
        my $flag_visualizerStatusRequest = 1;
        if ( -e $visualizerFile ) {
            my ( $visualizerStatus_ref, $visualizationUpdateTimes )
                = gatherVisualizationTaskInfo($visualizerFile);
            my %visualizerStatus = %$visualizerStatus_ref;
            my @statusList       = values %visualizerStatus;
            $flag_visualizerStatusRequest = 0
                unless ( any { $_ !~ m/^(FAILURE|REVOKED|TIMEOUT|SUCCESS)$/ }
                @statusList );
        }

     # Update the visualization task status and plot manifest file if the task
     # is done
        my $updateVisualizationStatus = updateVisualization($visualizerFile)
            if ( $flag_visualizerStatusRequest eq 1 );
        if ( $updateVisualizationStatus eq "FAILURE" ) {
            $self->setStatusCode(2);
            my $currentStatusMessage = $self->getStatusMessage();
            $self->setStatusMessage( $currentStatusMessage
                    . "<br>Failed to collect the visualization results from the queue."
            );
        }

        # Update the visualization status and message for UI
        my $visualizerStatus_ref = $self->updateVisualizationStatusMessage(
            $visualizerFile, $workflowStatus,
            $service,        @plotManifestFileList
        );
        %visualizerStatus = %$visualizerStatus_ref;
    }

    # PDF URL list is a temporary solution to get URL for PDFs
    my @pdfUrlList = ();

    # Loop over all data files
    my @globalDataFileList   = ();
    my $dataNode             = Giovanni::Util::createXMLElement('data');
    my $visGroupCount        = 0;
    my $indexOfDataGroupList = 0;
    my $numberOfDataGroup    = scalar @dataGroupList;
    foreach my $dataGroup (@dataGroupList) {
        my $fileGroupNode = Giovanni::Util::createXMLElement('fileGroup');

        # Add data files to global list
        my @dataFileList = @{ $dataGroup->{data} };
        push( @globalDataFileList, @dataFileList )
            if (( exists $dataGroup->{data} )
            and ( @{ $dataGroup->{data} } ) );

       # Get information from plot manifest file for visualization-related XML
       # generation
        my $plotManifestFile
            = $plotManifestFileList[ $indexOfDataGroupList++ ];
        my $plotManifestFileName = basename($plotManifestFile);
        if (    -f $visualizerFile
            and exists $visualizerStatus{$plotManifestFileName}
            and $visualizerStatus{$plotManifestFileName} eq "SUCCESS" )
        {
            $visGroupCount++;
            $plotManifestInfo
                = Giovanni::Util::parseXMLDocument($plotManifestFile);

            # Set PDF links if any
            my $pdfUrl = $plotManifestInfo->findvalue('/fileGroup/@pdfUrl');
            push( @pdfUrlList, $pdfUrl ) if defined $pdfUrl;

            # Set errors if any
            my $visTaskMessage
                = $plotManifestInfo->findvalue('/fileGroup/@message');
            my $visTaskCode
                = $plotManifestInfo->findvalue('/fileGroup/@code');
            my $visTaskPercentComplete
                = $plotManifestInfo->findvalue('/fileGroup/@percentComplete');

            $self->setPercentComplete($visTaskPercentComplete)
                if defined $visTaskPercentComplete
                    && $visTaskPercentComplete < 0;

            if ( defined $visTaskCode ) {
                $self->setStatusCode($visTaskCode);
            }
            if ($visTaskMessage) {
                $self->setStatusMessage($visTaskMessage);
            }
            $fileGroupNode
                = ${ $plotManifestInfo->findnodes('/fileGroup') }[0];

            $dataNode->appendChild($fileGroupNode);
        }
    }

    # For MAPSS/Aerostat portals, get Aeronet user agreement if necessary
    if ( uc($portal) eq 'MAPSS' || uc($portal) eq 'AEROSTAT' ) {
        my $fileList = join( " ", @globalDataFileList );
        my $userAgreement = `get_aeronet_user_agreement.pl $fileList`;
        if ($?) {
            print STDERR
                "Failed to run get_aeronet_user_agreement.pl: $userAgreement\n";
        }
        else {
            if ( $userAgreement =~ /\S+/ ) {
                my $agreementListNode
                    = XML::LibXML::Element->new('agreementList');
                $agreementListNode->appendTextChild( 'agreement',
                    $userAgreement );
                $dataNode->appendChild($agreementListNode);
            }
        }
    }
    if (   ( $visGroupCount eq $numberOfDataGroup )
        && ( not $self->onError() ) )
    {

        # Add the visualization portion of percent complete
        if ( @dataGroupList > 0 ) {

            # Case of at least one data file was produced
            my $totalPercentage;
            if ( @dataGroupList == $visGroupCount ) {
                $totalPercentage = 100;
                $self->setStatusMessage("Visualization completed");
            }
            else {
                $totalPercentage = $self->getPercentComplete()
                    + $visGroupCount * 25 / @dataGroupList;
            }
            $self->setPercentComplete($totalPercentage);
        }
    }

    # Append status node
    my $statusNode = Giovanni::Util::createXMLElement(
        'status',
        'code'            => $self->getStatusCode(),
        'message'         => $self->getStatusMessage(),
        'percentComplete' => $self->getPercentComplete()
    );
    $doc->appendChild($statusNode);

    my $criteriaNode = Giovanni::Util::createXMLElement(
        'criteria',
        'query'   => $self->getQuery(),
        'referer' => $self->getReferer()
    );

    my $lineageNode
        = Giovanni::Util::createXMLElement( 'lineage', $self->getLineage() );

    # Append image collection node if there is a PDF URL
    my $imgCollectionNode
        = ( @pdfUrlList > 0 )
        ? Giovanni::Util::createXMLElement( 'imageCollection',
        $pdfUrlList[0] )
        : undef;

    # Add result viewer access only if the flag is set in giovanni.cfg
    my $resultViewerNode = undef;
    if ( defined $GIOVANNI::RESULT_VIEWER_ACCESS
        and $GIOVANNI::RESULT_VIEWER_ACCESS )
    {
        my $ids      = $self->getSessionIds();
        my $debugUrl = 'daac-bin/restricted/resultViewer.pl?'
            . join( '&',
            "session=$ids->[0]", "resultset=$ids->[1]", "result=$ids->[2]" );
        $resultViewerNode
            = Giovanni::Util::createXMLElement( 'debug', $debugUrl );
    }
    $doc->appendChild($criteriaNode);
    $doc->appendChild($dataNode);
    $doc->appendChild($lineageNode);
    $doc->appendChild($resultViewerNode)  if defined $resultViewerNode;
    $doc->appendChild($imgCollectionNode) if defined $imgCollectionNode;
    return $doc;
}

# Update the workflow status and message
sub updateWorkflowStatusMessage {
    my ( $self, $workflowFile ) = @_;

    # Gather the workflow task status and update times info (that was
    # justed updated by "sub updateWorkflow")
    # and inform UI for special status (revoked/failure/pending)
    my ( $workflowStatus, $workflowUpdateTimes )
        = gatherWorkflowTaskInfo($workflowFile);
    my $workflowMessgePostfix = '.' x ( $workflowUpdateTimes % 6 );

    # Report the workflow status to UI
    if ( $workflowStatus eq "FAILURE" ) {
        my $currentStatusMessage = $self->getStatusMessage();
        $self->setStatusMessage( $currentStatusMessage
                . qq(<br/>Please send us <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">feedback</span> and we'll investigate.)
        );
        $self->setStatusCode(2);
    }
    elsif ( $workflowStatus eq "REVOKED" ) {
        my $currentStatusMessage = $self->getStatusMessage();
        $self->setStatusMessage( $currentStatusMessage
                . qq(<br/>Please send us <span class=\"inlineFeedbackLink\" onclick=\"session.sendFeedback(event,'workspace');\">feedback</span> and we'll investigate.)
        );
        $self->setStatusCode(-1);
    }
    elsif ( $workflowStatus eq "PENDING" ) {
        my $currentStatusMessage = $self->getStatusMessage();
        my $celeryConfigFile = $GIOVANNI::CELERYCONFIG{giovanni_config_dir}
            . "/celeryconfigWorkflow.json";
        my $sessionDir = $self->getDir();
        try {
            my $queueMessage
                = getQueueStats( $celeryConfigFile, $sessionDir );
            $currentStatusMessage
                = "Request pending: "
                . $queueMessage
                . $workflowMessgePostfix;
        }
        catch {
            $currentStatusMessage
                = "Request pending." . $workflowMessgePostfix;
        };
        $self->setStatusMessage($currentStatusMessage);
    }
    elsif ( $workflowStatus eq "TIMEOUT" ) {
        my $currentStatusMessage = $self->getStatusMessage();
        $self->setStatusMessage(
            $currentStatusMessage . "<br>Workflow time out!" );
        $self->setStatusCode(2);
    }

    # return
    return $workflowStatus;
}

# Update the visualization status and message
sub updateVisualizationStatusMessage {
    my ( $self, $visualizerFile, $workflowStatus, $service,
        @plotManifestFileList )
        = @_;

    # Gather the visualization task status and update times info (that was
    # justed updated by "sub updateVisualization")
    # and inform UI for special status (revoked/failure/pending)
    my ( $visualizerStatus_ref, $visualizationUpdateTimes )
        = gatherVisualizationTaskInfo($visualizerFile);
    my %visualizerStatus = %$visualizerStatus_ref;
    my $visualizationMessgePostfix = '.' x ( $visualizationUpdateTimes % 6 );

    # Get percent completion of the visualization tasks
    my $numberVisTasks = scalar @plotManifestFileList;
    my $visPercentDone
        = getVisPercentComplete( \%visualizerStatus, $numberVisTasks );

    # Report the visualization status to UI
    my $visStatusToReport    = getVisStatusToReport( \%visualizerStatus );
    my $currentStatusMessage = $self->getStatusMessage();
    my $plotTypeLabel
        = exists $GIOVANNI::WORKFLOW_MAP{$service}{label}
        ? $GIOVANNI::WORKFLOW_MAP{$service}{label}
        : undef;
    if ( $visStatusToReport eq "FAILURE" ) {
        $self->setStatusMessage( $currentStatusMessage
                . "<br>Visualization failed.<br>Please try again, click the 'Feedback' link (upper right), or contact the Giovanni administrator (gsfc-help-disc\@lists.nasa.gov)."
        );
    }
    elsif ( $visStatusToReport eq "REVOKED" ) {
        $self->setStatusMessage( $currentStatusMessage
                . "<br>Visualization cancelled.<br>Please try again, click the 'Feedback' link (upper right), or contact the Giovanni administrator (gsfc-help-disc\@lists.nasa.gov)."
        );
    }
    elsif ( $visStatusToReport eq "TIMEOUT" ) {
        $self->setStatusMessage(
            $currentStatusMessage . "<br>Visualization time out!" );
    }
    elsif ( $visStatusToReport eq "PENDING" ) {
        my $celeryConfigFile = $GIOVANNI::CELERYCONFIG{giovanni_config_dir}
            . "/celeryconfigVisManager.json";
        my $sessionDir = $self->getDir();

        # only report visualization pending status when workflow is completed
        if ( $workflowStatus eq "SUCCESS" ) {
            try {
                my $queueMessage
                    = getQueueStats( $celeryConfigFile, $sessionDir );
                $currentStatusMessage
                    .= "<br>Visualization pending: "
                    . $queueMessage
                    . $visualizationMessgePostfix;
            }
            catch {
                $currentStatusMessage .= "<br>Visualization pending."
                    . $visualizationMessgePostfix;
            };
        }
        $self->setStatusMessage($currentStatusMessage);
    }
    elsif ( $visualizerStatus{manager} =~ /(PROGRESS|SUCCESS)/ ) {
        if ( $visStatusToReport eq "STARTED" ) {
            $self->setStatusMessage(
                $currentStatusMessage . "<br>Visualization in progress..." );
        }
        elsif ( $visStatusToReport eq "SUCCESS" ) {
            $self->setStatusMessage(
                $currentStatusMessage . "<br>Visualization succeeded." );
        }
    }

    if    ( $visStatusToReport eq "FAILURE" ) { $self->setStatusCode(2); }
    elsif ( $visStatusToReport eq "REVOKED" ) { $self->setStatusCode(-1); }
    elsif ( $visStatusToReport eq "TIMEOUT" ) { $self->setStatusCode(2); }

    # return
    return \%visualizerStatus;
}

# Update the workflow task status
# Return status string
#   "SUCCESS": update succeeded
#   "FAILURE": update failed
sub updateWorkflow {

    # Parse parameter
    my ($workflowFile) = @_;

    # Run script to update the workflow task status from the workflowFile
    my $driver
        = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH}  PATH=$GIOVANNI::ENV{PATH} updateWorkflow.py";
    my $cmd    = "$driver -w $workflowFile";
    my $status = system($cmd);

    # Return the corresponding status string
    if   ( $status eq 0 ) { return "SUCCESS"; }
    else                  { return "FAILURE"; }
}

# Update the visualization task status and plot menifest file if the task is done
# Return status string
#   "SUCCESS": update succeeded
#   "FAILURE": update failed
sub updateVisualization {

    # Parse parameter
    my ($visualizerFile) = @_;

  # Run script to update the visualization task status from the visualizerFile
    my $driver
        = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH}  PATH=$GIOVANNI::ENV{PATH} updateVisualization.py";
    my $cmd    = "$driver -v $visualizerFile";
    my $status = system($cmd);

    # Return the corresponding status string
    if   ( $status eq 0 ) { return "SUCCESS"; }
    else                  { return "FAILURE"; }
}

# Stop workflow tasks
sub stopWorkflow {
    my ( $self, $logger ) = @_;
    my $dir          = $self->getDir();
    my $workflowFile = $dir . "/workflow.txt";
    my $flag         = 0;

    #Logging
    if ( defined $logger ) {
        Log::Log4perl::MDC->put( "component", "Workflow" );
    }

    if ( -d $dir ) {

        # Run script to stop workflow tasks in the queue
        my $driver
            = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} PATH=$GIOVANNI::ENV{PATH} stopWorkflow.py";
        my $cmd    = "$driver -w $workflowFile";
        my $status = system($cmd);

        # Send the result messages
        my $currentStatusMessage = $self->getStatusMessage();
        if ( $status eq 0 ) {
            $self->setStatusCode(-1);
            $flag = 1;
            $logger->info("STATUS:INFO Workflow cancellation request sent.");
        }
        else {
            $self->setStatusMessage( $currentStatusMessage
                    . "<br>Failed to stop workflow tasks from the queue." );
            $self->setStatusCode(2);
            $flag = 0;
            $logger->info(
                "STATUS:INFO Failed to stop workflow tasks from the queue.");
        }
        $self->writeHide("cancelled");
    }
    else {

        # Can't find session directory
        $self->setStatusMessage("Can not locate session directory");
        $self->setStatusCode(2);
        $flag = 0;
    }

    return $flag;
}

# Stop visualization
sub stopVisualization {
    my ($self)         = @_;
    my $dir            = $self->getDir();
    my $visualizerFile = $dir . "/visualizer.txt";
    my $flag           = 0;
    if ( -d $dir ) {

  # Run script to stop the visualization manager/tasks from the visualizerFile
        my $driver
            = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} PATH=$GIOVANNI::ENV{PATH} stopVisualization.py";
        my $cmd    = "$driver -v $visualizerFile";
        my $status = system($cmd);

        # Send the result messages
        my $currentStatusMessage = $self->getStatusMessage();
        if ( $status eq 0 ) {
            $self->setStatusCode(-1);
            $flag = 1;
        }
        else {
            $self->setStatusMessage( $currentStatusMessage
                    . "<br>Failed to stop visualization from the queue." );
            $self->setStatusCode(2);
            $flag = 0;
        }
        $self->writeHide("cancelled");
    }
    else {

        # Can't find session directory
        $self->setStatusMessage("Can not locate session directory");
        $self->setStatusCode(2);
        $flag = 0;
    }
    return $flag;
}

# "delete" a session. Really just hide it.
sub delete {
    my ($self) = @_;
    $self->writeHide("deleted");
}

################################################################################
sub createTitle {
    my ( $self, $input, $workflowHashRef ) = @_;

    # Create title based on input criteria
    my ( $title, $descr );
    if (   exists $input->{service}
        && exists $workflowHashRef->{ $input->{service} } )
    {
        my $serviceHashRef = $workflowHashRef->{ $input->{service} };
        $title = $serviceHashRef->{label} if exists $serviceHashRef->{label};
        $descr = $serviceHashRef->{description}
            if exists $serviceHashRef->{description};
        if ( exists $input->{starttime} && exists $input->{endtime} ) {
            $input->{starttime} =~ s/Z/T00:00:00Z/
                if index( $input->{starttime}, "Z" ) != -1
                    and index( $input->{starttime}, "T" ) == -1;
            $input->{endtime} =~ s/Z/T23:59:59Z/
                if index( $input->{endtime}, "Z" ) != -1
                    and index( $input->{endtime}, "T" ) == -1;

            my $dateToYear = sub {
                my ($dateStr) = @_;
                my $date = Date::Manip::ParseDate($dateStr);
                return UnixDate( $date, "%Y" );
            };
            my $timeStr
                = "from "
                . $dateToYear->( $input->{starttime} ) . " to "
                . $dateToYear->( $input->{endtime} );
            if ( exists $input->{months} ) {
                my @monthList
                    = Giovanni::Util::getSeasonLabels( $input->{months} );
                $timeStr .= " for " . join( ", ", @monthList );
            }
            elsif ( exists $input->{seasons} ) {
                my @seasonList
                    = Giovanni::Util::getSeasonLabels( $input->{seasons} );
                $timeStr .= " for " . join( ",", @seasonList );
            }
            else {
                $timeStr = "from $input->{starttime} to $input->{endtime}";
            }
            $descr .= " " . $timeStr;
        }
        if ( exists $input->{bbox} ) {
            $descr .= " over $input->{bbox}";
        }
    }
    return ( $title, $descr );
}

################
# Write the hide.txt file with a message about why the result is being hidden -
# i.e. - "cancelled" or "deleted"
sub writeHide {
    my ( $self, $message ) = @_;
    my $path = $self->_getHideFilePath();
    open( HIDE, ">", $path ) or die "Unable to create hide file $path, $!";
    print HIDE $message . "\n";
    close(HIDE);
}

sub getHideStatus {
    my ($self) = @_;
    my $path = $self->_getHideFilePath();

    if ( !( -e $path ) ) {

        # There's no hide file, so the result is not hidden
        return ();
    }

    open( HIDE, "<", $path ) or die "Unable to open hide file $path, $!";
    my @lines = <HIDE>;
    close(HIDE);

    return @lines;
}

sub _getHideFilePath {
    my ($self) = @_;
    my $path = $self->getDir() . "/hide.txt";
    return $path;
}

################################################################################
sub AUTOLOAD {
    my ( $self, $arg ) = @_;
    if ( $AUTOLOAD =~ /.*::getDir/ ) {
        return $self->{_RESULT_DIR};
    }
    elsif ( $AUTOLOAD =~ /.*::onError/ ) {
        my $flag = $self->{_ERROR_TYPE} ? 1 : 0;
        return $flag if $flag;
        $flag = $self->getStatusCode() ? 1 : 0;
        return $flag;
    }
    elsif ( $AUTOLOAD =~ /.*::errorMessage/ ) {
        return $self->{_ERROR_MESSAGE};
    }
    elsif ( $AUTOLOAD =~ /.*::getFormat/ ) {
        return $self->{_FORMAT};
    }
    elsif ( $AUTOLOAD =~ /.*::getId/ ) {
        return $self->{_ID};
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorMessage/ ) {
        $self->{_ERROR_MESSAGE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::setErrorType/ ) {
        $self->{_ERROR_TYPE} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getPercentComplete/ ) {
        return $self->{_STATUS}{percentComplete} || 0;
    }
    elsif ( $AUTOLOAD =~ /.*::setPercentComplete/ ) {
        return $self->{_STATUS}{percentComplete} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getStatusMessage/ ) {
        return $self->{_STATUS}{message} || '';
    }
    elsif ( $AUTOLOAD =~ /.*::setStatusMessage/ ) {
        return $self->{_STATUS}{message} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getStatusCode/ ) {
        return $self->{_STATUS}{code} || 0;
    }
    elsif ( $AUTOLOAD =~ /.*::setStatusCode/ ) {
        $self->{_STATUS}{code} = $arg;
    }
    elsif ( $AUTOLOAD =~ /.*::getData/ ) {
        return @{ $self->{_DATA} };
    }
    elsif ( $AUTOLOAD =~ /.*::getQuery/ ) {
        return $self->{_QUERY};
    }
    elsif ( $AUTOLOAD =~ /.*::getReferer/ ) {
        return $self->{_REFERER};
    }
    elsif ( $AUTOLOAD =~ /.*::getOptions/ ) {
        return $self->{_OPTIONS};
    }
    elsif ( $AUTOLOAD =~ /.*::getHistory/ ) {
        return $self->{_HISTORY};
    }
    elsif ( $AUTOLOAD =~ /.*::getPortal/ ) {
        return $self->{_PORTAL};
    }
    elsif ( $AUTOLOAD =~ /.*::getService/ ) {
        return $self->{_SERVICE};
    }
    elsif ( $AUTOLOAD =~ /.*::getTitle/ ) {
        return $self->{_TITLE};
    }
    elsif ( $AUTOLOAD =~ /.*::getCreationTime/ ) {
        return $self->{_CREATIONTIME};
    }
    elsif ( $AUTOLOAD =~ /.*::getDescription/ ) {
        return $self->{_DESCRIPTION};
    }
    elsif ( $AUTOLOAD =~ /.*::getSessionIds/ ) {
        return $self->{_SESSION_IDS};
    }
    elsif ( $AUTOLOAD =~ /.*::DESTROY/ ) {
    }

}
################################################################################
1;
__END__

=head1 NAME
 
 Giovanni::Result - Perl module encapsualting Giovanni Result.
 
 =head1 SYNOPSIS
 
 use Giovanni::Result;
 
 =head1 DESCRIPTION
 
 Giovanni::Result encapsulates Giovanni Result. It creates input.xml upon a new service invocation, launches a service and returns the result ID. During the service execution, the status can be tracked using the result ID. As the service results are available, data is visualized.
 
 =head2 EXPORT
 
 None by default.
 
 =head1 SEE ALSO
 
 Giovanni::ResultSet
 Giovanni::Session
 Giovanni::Visualizer
 
 =head1 AUTHOR
 
 Mahabaleshwara S. Hegde
 
 =cut
