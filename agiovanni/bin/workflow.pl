#!/usr/bin/env perl

=head1 NAME
    
workflow.pl -- workflow task driver 
    
=head1 SYNOPSIS
      
workflow.pl -c cfgFile -d outputDir

=head1 DESCRIPTION
  
Driver script for workflow task
This code is originally written for workflow task queue submission
  
=head1 ARGUMENTS

=over 5

=item -c cfgFile

The giovanni cfg file

=item -f workFlowConfigFile

The workflow cfg file

=item -s giovanniService

The giovanni service type

=item -d outputDir

Output directory name

=item -w workflowStatusFile

Workflow status file : 0 for failed, non-0 for success

=back

=head1 AUTHOR
  
Hailiang Zhang <hailiang.zhang@nasa.gov>
  
=cut 

use strict;

use Getopt::Std;
use File::Basename;
use File::Copy;
use XML::LibXML;
use Safe;

use Giovanni::Workflow;
use Giovanni::Util;
use Giovanni::Serializer;

################################################################################

# Define and parse argument vars
use vars qw($opt_c $opt_f $opt_s $opt_d $opt_w);
getopts('c:f:s:d:w:');
usage() unless ( $opt_c && $opt_f && $opt_s && $opt_d && $opt_w );

# Set umask for r+w by group
my $oldMask = umask(002);

# Read workflow configuration file
my $cpt                = Safe->new('GIOVANNI');
my $workFlowConfigFile = $opt_f;
unless ( $cpt->rdo($workFlowConfigFile) ) {
    Giovanni::Util::exit_with_error( 'Workflow Configuration Error' );
}

# Read the configuration file: giovanni.cfg in to GIOVANNI name space
# I am doing this because they were lost after previous python call
my $cfgFile = $opt_c;
my $error   = Giovanni::Util::ingestGiovanniEnv($cfgFile);
Giovanni::Util::exit_with_error($error) if ( defined $error );

# local variables
my $giovanniService = $opt_s;
my $outputDir = $opt_d;
my $workflowStatusFile = $opt_w;

#Copy the workflow template
my @workflowFileList
    = (
    ref $GIOVANNI::WORKFLOW_MAP{ $giovanniService }{file} eq
        'ARRAY' )
    ? @{ $GIOVANNI::WORKFLOW_MAP{ $giovanniService }{file} }
    : ( $GIOVANNI::WORKFLOW_MAP{ $giovanniService }{file} );

if ( $workflowFileList[0] =~ /\.make$/ ) {
    my @localWorkflowFileList = ();
    foreach my $workflowFile (@workflowFileList) {

        # Copy workflow files to session directory
        my $file = "$GIOVANNI::WORKFLOW_DIR/$workflowFile";
        next unless -f $file;
        my $localWorkflowFile = $outputDir . '/' . $workflowFile;
        if ( copy( $file, $localWorkflowFile ) ) {

            # Place holder for future logging
            push( @localWorkflowFileList, $workflowFile );
        }
        else {

            # Complain on failure to copy
            warn(
                "Failed to copy $file to $localWorkflowFile: " . $! );
        }
    }

    # Case of Makefile based workflow
    my $workflow = Giovanni::Workflow->new(
        WORKFLOW_DIR => $outputDir,
        WORKFLOW     => \@localWorkflowFileList
    );
    my $maxJobCount
        = defined $GIOVANNI::MAX_JOB_COUNT
        ? $GIOVANNI::MAX_JOB_COUNT
        : 1;
    my $flag = $workflow->launch( MAX_JOB_COUNT => $maxJobCount );

    # Save workflow status
    Giovanni::Util::writeFile( $workflowStatusFile, $flag );

    # exit with non-zero code if workflow failed
    exit(1) if ( $flag eq '0' );
}

# Reset umask
umask($oldMask);

################################################################################
sub usage {
    die
        "Usage: $0 -c cfgFile -f workFlowConfigFile -s giovanniService -d outputDir -w workflowStatusFile\n";
}
################################################################################
