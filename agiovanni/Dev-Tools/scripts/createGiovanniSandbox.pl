#!/usr/bin/perl

# $Id: createGiovanniSandbox.pl,v 1.36 2015/05/13 15:15:23 mhegde Exp $
# $Version$
use LWP::UserAgent;
use Getopt::Long;
use File::Temp;
use File::Basename;
use File::Copy;
use Data::Dumper;
use Safe;
use URI;
use Cwd;
use Giovanni::Util;
use URI;
use XML::LibXSLT;
use XML::LibXML;
use strict;

my ( $repoUrl,  $srcSandbox, $task,     $prefix,
     $opt_h,    $verbose,    $branch,   $force,
     $instance, $cfgFile,    $queueUrl, $remoteWorker,
     $appId
);
$verbose = 0;
Getopt::Long::GetOptions(
    'repo=s'        => \$repoUrl,
    'sandbox=s'     => \$srcSandbox,
    'task=s'        => \$task,
    'prefix=s'      => \$prefix,
    'config=s'      => \$cfgFile,
    'h'             => \$opt_h,
    'verbose'       => \$verbose,
    'version=s'     => \$branch,
    'force'         => \$force,
    'instance=s'    => \$instance,
    'queue_url=s'   => \$queueUrl,
    'remote-worker' => \$remoteWorker,
    'app_id=s'      => \$appId,
);

if ( !defined($branch) ) {
    $branch = 'HEAD';
}

# Default instance is giovanni4
$instance = 'giovanni4' unless defined $instance;

# Default application id is GIOVANNI
$appId = 'GIOVANNI' unless defined $appId;

unless ( exists $ENV{TMPDIR} and ( -d $ENV{TMPDIR} ) ) {
    print STDERR
        "Define TMPDIR environment variable and make sure that directory exists\n";
    exit(1);
}

if (`mount | grep " $ENV{TMPDIR} " | cut -d ' ' -f6 | grep noexec`) {
    print STDERR
        "TMPDIR is set to $ENV{TMPDIR}, which cannot be used because it is on a file system that is disallowed from running executables. Please redefine to another directory.\n";
    exit(1);
}

if ( defined $opt_h ) {
    print STDERR
        "$0 -repo [ecc or cvs or http://discette-ts2.gsfc.nasa.gov/HUDSON/]\n"
        . "-sandbox [Dir for checking out code]\n"
        . "-task [config or install or deploy]\n"
        . "-prefix [Installation dir]\n"
        . "-config [git repo list file]\n"
        . "-version [optional tab or branch in CVS to install; default is HEAD]\n"
        . "-force [optional flag to touch files to force installation of each file]\n"
        . "-instance [optional instance name; default is giovanni4]\n"
        . "-queue_url [optional celery queue URL]\n"
        . "-remote-worker [optional flag to start the celery worker on remote worker; if specified, you need to start the celery worker manually on the remote worker.  Default is local-worker, where celery worker will be automatically started on the local machine]\n"
        . "-app_id [optional string to identify application, e.g. to distinguish between baselines]\n";

    exit(0);
}

# By default, task is to deploy (install+config)
$task = 'deploy' unless defined $task;
die
    "Task must be 'install' (installs code) or 'config' (creates configuration)"
    . " or 'deploy' (install+config)\n"
    unless ( $task eq 'install' or $task eq 'config' or $task eq 'deploy' );

# Set ~/public_html as the target prefix if none defined
if ( defined $prefix ) {
    die "Target prefix (-prefix), $prefix, doesn't exist" unless -d $prefix;
}

# By default, use ~/public_html/ as the target prefix
unless ( defined $prefix ) {
    $prefix = "$ENV{HOME}/public_html/";
    unless ( -d $prefix ) {
        die "Failed to create $prefix ($!)" unless mkdir($prefix);
    }
}
$prefix =~ s/\/+$//;

# Use a temporary dir for storing src code
$srcSandbox = File::Temp::tempdir( CLEANUP => 1 ) unless defined $srcSandbox;

my $curDir = getcwd();

if ( defined $repoUrl ) {
    if ( uc($repoUrl) eq 'CVS' ) {
        my $flag = fetchSourceCodeFromCvs(
            $srcSandbox,
            $branch,
            [ qw(aGiovanni aGiovanni_www aGiovanni_GIOVANNI aGiovanni_Algorithms aGiovanni_DataAccess aGiovanni_Admin/Giovanni-Session-Viewer jasmine)
            ]
        );
        unless ($flag) {
            chdir($curDir);
            die "Failed to download source code from $repoUrl";
        }
    }
    elsif ( uc($repoUrl) eq 'ECC' ) {
        my @gitProjects = (
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_www.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_GIOVANNI.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_DataAccess.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_Algorithms.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_Admin.git',
            'https://git.earthdata.nasa.gov/scm/fedgianni/jasmine.git',
        );
        my $flag
            = fetchSourceCodeFromEcc( $srcSandbox, $cfgFile, \@gitProjects,
            $verbose );
        unless ($flag) {
            chdir($curDir);
            die "Failed to download source code from $repoUrl";
        }
    }
    else {
        my $archUrl = $repoUrl . '/aGiovanni_Latest.tgz';
        fetchSourceCodeFromArchive( $archUrl, $srcSandbox )
            || die "Failed to download source code from $repoUrl";
    }
}

# If src sandbox exists, proceed with the specified task
if ( -d $srcSandbox ) {
    if ( $task eq 'deploy' ) {

        # Deploy (configure + install)
        installGiovanni( $srcSandbox, $prefix, $instance, $force );
        configureGiovanni( $srcSandbox, $prefix, $instance, $queueUrl, $appId );
        addServices( $srcSandbox, $prefix, $instance );
        startCeleryWorker( $prefix, $instance, $queueUrl, $remoteWorker )
            if ( defined $queueUrl );
    }
    elsif ( $task eq 'config' ) {

        # Configure
        configureGiovanni( $srcSandbox, $prefix, $instance, $queueUrl, $appId );
    }
    elsif ( $task eq 'install' ) {

        # Install src code
        installGiovanni( $srcSandbox, $prefix, $instance, $force );
        addServices( $srcSandbox, $prefix, $instance );
        startCeleryWorker( $prefix, $instance, $queueUrl, $remoteWorker )
            if ( defined $queueUrl );
    }

}

chdir($curDir);

# Installs Giovanni-4 code base
sub installGiovanni {
    my ( $srcSandbox, $prefix, $instance, $force, $verbose ) = @_;

    if ($force) {

        # touch all the files in the directory to make sure
        # newer versions get installed
        my $ret = system('find $srcSandbox -exec touch {} \\;');
        if ( $ret != 0 ) {
            warn "Unable to touch files in $srcSandbox\n";
        }
    }

    foreach my $project (
        qw(aGiovanni aGiovanni_DataAccess aGiovanni_Admin/Giovanni-Session-Viewer)
        )
    {
        print STDERR "Installing $project...";
        my $projDir = "$srcSandbox/$project";
        die "Failed to find $projDir" unless defined $projDir;
        chdir $projDir;
        foreach my $cmd ( "perl Makefile.PL PREFIX=$prefix/$instance",
            "make", "make install" )
        {
            my $out = `$cmd 2>&1`;
            if ($?) {
                print STDERR "\n$out\n";
                die "Failed to run $cmd ($!)";
            }
        }
        print STDERR " completed\n";
    }
    foreach my $project (qw(jasmine aGiovanni_www aGiovanni_GIOVANNI)) {
        print STDERR "Installing $project...";
        my $projDir = "$srcSandbox/$project";
        die "Failed to find $projDir" unless defined $projDir;
        chdir $projDir;
        my $cmd = "make install PREFIX=$prefix/$instance";
        my $out = `$cmd 2>&1`;
        if ($?) {
            print STDERR "\n$out\n";
            die "Failed to run $cmd ($!)";
        }
        print STDERR " completed\n";
    }
}

# Create giovanni.cfg
sub createGiovanniConfig {
    my ( $srcSandbox, $prefix, $instance, $appId, $verbose ) = @_;

    my $srcConfigDir = "$srcSandbox/aGiovanni/cfg";
    my $tarRootDir   = "$prefix/$instance";
    my $tarConfigDir = "$tarRootDir/cfg";

    my $cpt     = Safe->new('GIOVANNI');
    my $cfgFile = "$srcConfigDir/giovanni.cfg";
    unless ( $cpt->rdo($cfgFile) ) {
        warn "Failed to read $cfgFile";
        return 0;
    }

    # Create missing URL file
    $GIOVANNI::MISSING_URL_FILE = "$tarRootDir/cfg/missing_url.txt";
    unless ( writeFile( $GIOVANNI::MISSING_URL_FILE, '' ) ) {
        warn
            "Failed to create missing URL file ($GIOVANNI::MISSING_URL_FILE)";
        return 0;
    }

    # Enable debug link
    $GIOVANNI::RESULT_VIEWER_ACCESS = 1;

    # Identify the Giovanni application
    $GIOVANNI::APPLICATION = $appId;

    $GIOVANNI::JAR_DIR     = "$tarRootDir/jar";
    $GIOVANNI::SLD_LIST    = swapDirs( $GIOVANNI::SLD_LIST, $tarConfigDir );
    $GIOVANNI::ENV{PATH}   = "$tarRootDir/bin" . ":" . $GIOVANNI::ENV{PATH};
    $GIOVANNI::LINEAGE_XSL = "$tarRootDir/cfg/GiovanniLineage.xsl";
    $GIOVANNI::ENV{PERL5LIB}
        = "$tarRootDir/share/perl5/" . ":" . $GIOVANNI::ENV{PERL5LIB};
    $GIOVANNI::PLOT_OPTIONS_SCHEMAS_DIR = "$tarRootDir/cfg/json_schemas";

    # Set the units conversion configuration location
    $GIOVANNI::UNITS_CFG = "$tarRootDir/cfg/unitsCfg.xml";

    # get the version of python
    my $cmd = 'python --version 2>&1';
    my @out = `$cmd`;
    chomp(@out);
    my $version = '';
    if ( $out[0] =~ /Python (\d+[.]\d+)[.]/ ) {
        $version = $1;
    }
    else {
        warn "Unable to determine python version by running $cmd.";
        return 0;
    }
    $GIOVANNI::ENV{PYTHONPATH}
        = "$tarRootDir/lib/python$version/site-packages/:"
        . $GIOVANNI::ENV{PYTHONPATH};

    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Purity   = 1;
    my @strList = ();
    foreach my $name ( sort keys %GIOVANNI:: ) {
        next
            if ( $name eq 'INC'
            or $name =~ /::$/
            or $name =~ /^_/
            or $name =~ /^\W/ );
        my $glob = $GIOVANNI::{$name};

        # Modify paths for WMS related files
        if ( $name eq 'WMS' ) {
            foreach
                my $key (qw(map_xml_xslt map_xml_template ))
            {
                my $fileName
                    = File::Basename::basename( $GIOVANNI::WMS{$key} );
                $GIOVANNI::WMS{$key} = "$tarRootDir/cfg/$fileName";
            }
        }

        # Modify paths for CELERY related files
        if ( $name eq 'CELERYCONFIG' ) {
            $GIOVANNI::CELERYCONFIG{giovanni_config_dir} = "$tarRootDir/cfg/";
        }
        if ( defined %{$glob} ) {
            push( @strList, dumpHash( $name, %{$glob} ) );
        }
        elsif ( defined ${$glob} ) {
            push( @strList, Data::Dumper->Dump( [ ${$glob} ], [$name] ) );
        }
        elsif ( defined @{$glob} ) {
            push( @strList, dumpArray( $name, @{$glob} ) );
        }
    }
    my $giovanniConfig = "$tarConfigDir/giovanni.cfg";
    die unless ( writeFile( $giovanniConfig, @strList ) );
}

# Create redis.conf in user sandbox
sub createRedisConfig {

    # to be editted
    my ( $srcSandbox, $prefix, $instance, $queueUrl, $verbose )
        = @_
        ; # NOTE $verbose seems never used, and therefore $queueUrl is currenlty placed between $instance and $verbose

    my $srcConfigDir = "$srcSandbox/aGiovanni/cfg";
    my $tarConfigDir = "$prefix/$instance/cfg";

    my $cpt     = Safe->new('GIOVANNI');
    my $cfgFile = "$tarConfigDir/giovanni.cfg";
    unless ( $cpt->rdo($cfgFile) ) {
        warn "Failed to read $cfgFile";
        return 0;
    }

    # Copy redis configuration files
    my $file = 'redis.conf';
    die "Failed to copy $srcConfigDir/$file to $tarConfigDir ($!)"
        unless ( File::Copy::copy( "$srcConfigDir/$file", $tarConfigDir ) );
    print STDERR "Copied $srcConfigDir/$file to $tarConfigDir\n"
        if $verbose;

    # Get host/port from URL, in a cumbersome way
    my $uri = URI->new($queueUrl);
    $uri->scheme('http');
    my $host = $uri->host();
    my $port = $uri->port();
    $port = 6379 if ( $port eq 80 );

    # Process redis configuration files
    my $fileContent = Giovanni::Util::readFile("$tarConfigDir/$file");
    $fileContent =~ s/bind ([^\s]*)/bind $host/g;
    $fileContent =~ s/port ([^\s]*)/port $port/g;
    $fileContent =~ s/logfile ([^\s]*)\.log/logfile \1_$ENV{LOGNAME}.log/g;
    $fileContent
        =~ s/dbfilename ([^\s]*)\.rdb/dbfilename \1_$ENV{LOGNAME}.rdb/g;
    die unless ( writeFile( "$tarConfigDir/$file", $fileContent ) );

}

# Copy celeryconfigWorkflow.json celeryconfigVisManager.json, and celeryconfigVisTask.json to cfg/ folder
# NOTE: These files are in json format so that it can be easily read by celeryconfig python module
#       $queueUrl will be literally placed in the celery configuration file, and the error/typo from the user input can be handled from the python module
sub createCeleryConfig {

    # to be editted
    my ( $srcSandbox, $prefix, $instance, $queueUrl, $verbose )
        = @_
        ; # NOTE $verbose seems never used, and therefore $queueUrl is currenlty placed between $instance and $verbose

    my $srcConfigDir = "$srcSandbox/aGiovanni/cfg";
    my $tarConfigDir = "$prefix/$instance/cfg";

    # Copy celery configuration files
    foreach my $file (
        qw(celeryconfigWorkflow.json celeryconfigVisManager.json celeryconfigVisTask.json)
        )
    {
        die "Failed to copy $srcConfigDir/$file to $tarConfigDir ($!)"
            unless (
            File::Copy::copy( "$srcConfigDir/$file", $tarConfigDir ) );
        print STDERR "Copied $srcConfigDir/$file to $tarConfigDir\n"
            if $verbose;
        my $fileContent = Giovanni::Util::readFile("$tarConfigDir/$file");
        $fileContent =~ s/redis:\/\/localhost:6379/$queueUrl/g;
        $fileContent =~ s/wwwuser/$ENV{LOGNAME}/g;
        die unless ( writeFile( "$tarConfigDir/$file", $fileContent ) );
    }

}

# Create workflow.cfg
sub createWorklowConfig {
    my ( $srcSandbox, $prefix, $instance, $verbose ) = @_;

    my $srcConfigDir = "$srcSandbox/aGiovanni/cfg";
    my $tarConfigDir = "$prefix/$instance/cfg";

    my $cpt     = Safe->new('WORKFLOW');
    my $cfgFile = "$srcConfigDir/workflow.cfg";
    unless ( $cpt->rdo($cfgFile) ) {
        warn "Failed to read $cfgFile";
        return 0;
    }

    # Copy workflows
    foreach my $service ( keys %WORKFLOW::WORKFLOW_MAP ) {
        foreach my $file (
            @{ $WORKFLOW::WORKFLOW_MAP{$service}{file} },
            qw(comparison.make singlefield.make)
            )
        {
            next if ( $file =~ /aerostat|mapss/i );
            die "Failed to copy $srcConfigDir/$file to $tarConfigDir ($!)"
                unless (
                File::Copy::copy( "$srcConfigDir/$file", $tarConfigDir ) );
            print STDERR "Copied $srcConfigDir/$file to $tarConfigDir\n"
                if $verbose;
        }
    }

    # Set the workflw directory to prefix/cfg/giovanni
    $WORKFLOW::WORKFLOW_DIR = "$prefix/$instance/cfg";
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Purity   = 1;
    my $str1
        = Data::Dumper->Dump( [$WORKFLOW::WORKFLOW_DIR], [qw(WORKFLOW_DIR)] );
    my $str2 = dumpHash( 'WORKFLOW_MAP', %WORKFLOW::WORKFLOW_MAP );
    my $workflowConfig = "$tarConfigDir/workflow.cfg";
    die unless ( writeFile( $workflowConfig, $str1, $str2 ) );
}

sub swapDirs {
    my $configitem = shift;
    my $newdir     = shift;
    my $orgdir     = dirname($configitem);
    $orgdir     =~ s#/#\\/#g;
    $configitem =~ s/$orgdir/$newdir/;
    return $configitem;
}

sub dumpArray {
    my ( $arrName, @list ) = @_;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Purity   = 1;
    my $str = Data::Dumper->Dump( [ \@list ], [$arrName] );
    my ( $lhs, $rhs ) = split( /=/, $str, 2 );
    $lhs =~ s/^\$(\S+)/\@$1/;
    $rhs =~ s/^\s*\[/\(/;
    $rhs =~ s/\](\s*;\s*)/\)$1/;
    $str = "$lhs=$rhs";
    return $str;
}

sub dumpHash {
    my ( $hashName, %hash ) = @_;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Purity   = 1;
    my $str = Data::Dumper->Dump( [ \%hash ], [$hashName] );
    my ( $lhs, $rhs ) = split( /=/, $str, 2 );
    $lhs =~ s/^\$(\S+)/\%$1/;
    $rhs =~ s/^\s*\{/\(/;
    $rhs =~ s/\}(\s*;\s*)/\)$1/;
    $str = "$lhs=$rhs";
    return $str;
}

sub writeFile {
    my ( $file, @strList ) = @_;
    unless ( open( FH, ">$file" ) ) {
        warn "Failed to write to $file";
        return 0;
    }
    foreach my $str (@strList) {
        print FH "$str\n";
    }
    unless ( close(FH) ) {
        warn "Failed to close $file";
        return 0;
    }
    print STDERR "Created $file\n";
    return 1;
}

# Configures Giovanni-4
sub configureGiovanni {
    my ( $srcSandbox, $prefix, $instance, $queueUrl, $appId, $verbose )
        = @_
        ; # NOTE $verbose seems never used, and therefore $queueUrl is currenlty placed between $instance and $verbose

    # If aGiovanni/cfg dir is not found stop!
    my $cfgDir
        = ( -d "$srcSandbox/aGiovanni/cfg/" )
        ? "$srcSandbox/aGiovanni/cfg/"
        : "$srcSandbox/agiovanni/cfg/";
    die "Failed to find $srcSandbox/aGiovanni/cfg/"
        unless ( -d "$srcSandbox/aGiovanni/cfg" );

    # Create necessary directories
    my @dirList = (
        "$prefix/$instance",         "$prefix/$instance/cfg",
        "$prefix/$instance/cgi-bin", "$prefix/$instance/www",
    );
DIR_LOOP: foreach my $dir ( sort @dirList ) {
        if ( -d $dir ) {
            print STDERR "$dir exists\n" if $verbose;
            next DIR_LOOP;
        }
        die "Failed to create $dir ($!)" unless mkdir($dir);
        print STDERR "Created $dir\n" if $verbose;
    }

    # First create necessary symlinks
    my %linkHash = ( "$prefix/$instance/www" => "$prefix/giovanni", );
LINK_LOOP: foreach my $key ( keys %linkHash ) {
        if ( -l $linkHash{$key} ) {
            print STDERR "$linkHash{$key} is already a symlink\n" if $verbose;
            next LINK_LOOP;
        }
        die "Failed to create symlink (ln -s $key $linkHash{$key}): $!\n"
            unless symlink( $key, $linkHash{$key} );
        print STDERR "Created symlink $linkHash{$key} to $key\n" if $verbose;
    }

    createWorklowConfig( $srcSandbox, $prefix, $instance );
    createGiovanniConfig( $srcSandbox, $prefix, $instance, $appId );
    createCeleryConfig( $srcSandbox, $prefix, $instance, $queueUrl )
        if ( defined $queueUrl );
    createRedisConfig( $srcSandbox, $prefix, $instance, $queueUrl )
        if ( defined $queueUrl );
}

# Adds Giovanni algorithms following Giovanni science algorithm wrapper specs
sub addServices {
    my ( $srcSandbox, $prefix, $instance ) = @_;

    my $algorithmProject = "$srcSandbox/aGiovanni_Algorithms";
    my @algorithmList    = ();
    if ( opendir( DH, $algorithmProject ) ) {
        my @algorithmList
            = grep { !/^(\.|\.\.)/ && -d "$algorithmProject/$_" } readdir(DH);
        foreach my $algorithm (@algorithmList) {
            next if ( $algorithm eq 'CVS' );
            next unless chdir("$algorithmProject/$algorithm");
            print STDERR "Installing $algorithm...";
            foreach my $cmdExe ( "perl Makefile.PL PREFIX=$prefix/$instance",
                "make install", "make cfg" )
            {
                my $out = `$cmdExe 2>&1`;
                if ($?) {
                    print STDERR "\n$out\n";
                    die "Failed to run $cmdExe ($!)";
                }
            }
            print STDERR " completed\n";
        }
    }

    # Note: this subroutine is supposed to handle 'new' services not
    # already hardcoded in the stylesheet
    orderServices( $srcSandbox, $prefix, $instance );

}

sub orderServices {
    my $srcSandbox = shift;
    my $prefix     = shift;
    my $instance   = shift;


    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();
    my $services_doc = $parser->parse_file("$prefix/$instance/cfg/giovanni_services.xml");
    my $styleDoc           = $parser->parse_string(orderingStyleSheet());
    my $styleSheet         = $xslt->parse_stylesheet($styleDoc);
    my $resultsOfTransform = $styleSheet->transform($services_doc);
    my $PAGE               = $resultsOfTransform->toString(1);
    unless ( open( FH, ">$prefix/$instance/cfg/giovanni_services.xml" ) ) {
        warn "Failed to open output file for writing";
        return 0;
    }
    print FH $PAGE;
    unless ( close(FH) ) {
        warn "Failed to flush outfile";
        return 0;
    }
}

# First section goes through the list in order and copies them from
# the giovanni_services.xml that was populated during addServices() loop.
# The 2nd section goes through the giovanni_services.xml again and writes
# out any 'new' services not already hardcoded in the list

sub orderingStyleSheet {


    my $sheet = <<SHEET;
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:template match="/services">
    <xsl:copy>
      <!-- The order of these copy-of elements determines the order of
           the services. -->
      <xsl:copy-of select="service[\@name='TmAvMp']"/>
      <xsl:copy-of select="service[\@name='AcMp']"/>
      <xsl:copy-of select="service[\@name='DiTmAvMp']"/>
      <xsl:copy-of select="service[\@name='MpAn']"/>
      <xsl:copy-of select="service[\@name='QuCl']"/>
      <xsl:copy-of select="service[\@name='TmAvOvMp']"/>

      <xsl:copy-of select="service[\@name='CoMp']"/>
      <xsl:copy-of select="service[\@name='ArAvSc']"/>
      <xsl:copy-of select="service[\@name='IaSc']"/>
      <xsl:copy-of select="service[\@name='StSc']"/>
      <xsl:copy-of select="service[\@name='TmAvSc']"/>

      <xsl:copy-of select="service[\@name='CrLt']"/>
      <xsl:copy-of select="service[\@name='CrLn']"/>
      <xsl:copy-of select="service[\@name='CrTm']"/>
      <xsl:copy-of select="service[\@name='VtPf']"/>

      <xsl:copy-of select="service[\@name='ArAvTs']"/>
      <xsl:copy-of select="service[\@name='DiArAvTs']"/>
      <xsl:copy-of select="service[\@name='InTs']"/>
      <xsl:copy-of select="service[\@name='HvLt']"/>
      <xsl:copy-of select="service[\@name='HvLn']"/>


      <xsl:copy-of select="service[\@name='ZnMn']"/>
      <xsl:copy-of select="service[\@name='HiGm']"/>
      <!-- Copy each service (presumably new) whose name is not listed
           above. When a new service is added, add an xsl:copy-of
           above, and add the new name attribute to the list of those
           excluded below (to prevent it from being copied twice). -->
      <xsl:copy-of select="service[not(\@name='TmAvMp' or \@name='AcMp' or \@name='DiTmAvMp' or \@name='MpAn' 
                or \@name='QuCl' or \@name='TmAvOvMp' or \@name='CoMp' or \@name='ArAvSc' or \@name='IaSc' 
                or \@name='StSc' or \@name='TmAvSc' or \@name='ArAvTs' or \@name='DiArAvTs' 
                or \@name='InTs' or \@name='HvLt' or \@name='HvLn' or \@name='CrLt' or \@name='CrLn' 
                or \@name='CrTm' or \@name='VtPf' or \@name='ZnMn' or \@name='HiGm')]"/>
   </xsl:copy>
 </xsl:template>
</xsl:stylesheet>
SHEET

    return $sheet;
}

# Start celery workers
# NOTE For user input simplicity, currenlty assume celery worker and client using the same broker/result host/url
sub startCeleryWorker {
    my ( $prefix, $instance, $queueUrl, $remoteWorker ) = @_;

    if ( defined $queueUrl ) {
        my $tarRootDir   = "$prefix/$instance";
        my $tarConfigDir = "$tarRootDir/cfg";
        chdir $tarRootDir;
        my $cpt     = Safe->new('GIOVANNI');
        my $cfgFile = "$tarConfigDir/giovanni.cfg";
        unless ( $cpt->rdo($cfgFile) ) {
            warn "Failed to read $cfgFile";
            return 0;
        }
        my $redisconfigFile = "$tarConfigDir/redis.conf";

        # stop running celery worker
        my $cmd
            = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} $tarRootDir/bin/stopQueue.py ";
        my $status = system( $cmd. ' >> /dev/null 2>&1 ' );
        if ( $status == -1 ) {
            print STDERR
                "failed to launch the driver script to stop the queue: $!\n";
        }
        elsif ( $status & 0x7F ) {
            print STDERR "driver script killed by signal "
                . ( $status & 0x7F ) . "\n";
        }
        elsif ( ( $status >> 8 ) gt 0 ) {
            print STDERR " failed to stop the running queue\n";
        }

        # collect the environments to pass to celery worker
        my $envHash = {};
        foreach my $k ( keys %GIOVANNI::ENV ) {
            $envHash->{$k} = $GIOVANNI::ENV{$k};
        }
        my $envJSON = ( keys %$envHash ) ? JSON->new()->encode($envHash) : undef;
        $envJSON =~ s/"/\\"/g; # envJSON need to escape quote so that it can be passed to "sg wwwuser"
                               # start celery worker
        print STDERR "Starting celery worker...";
        $cmd = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} $tarRootDir/bin/startQueue.py -r $redisconfigFile -q $queueUrl -d /var/log/celery/ ";
        $cmd .= " -e '" . $envJSON . "' " if ( defined $envJSON );
        $cmd .= " --remote-worker " if ( defined $remoteWorker );
        $cmd .= " -g wwwuser ";    # run celery worker as wwwuser group
        $cmd = "sg wwwuser \"" . $cmd . "\"";
        $status = system( $cmd. ' 2>/dev/null' );
        if ( $status == -1 ) { print STDERR "failed to launch the driver script to start the queue: $!\n"; return; }
        elsif ( $status & 0x7F ) { print STDERR "driver script killed by signal " . ( $status & 0x7F ) . "\n"; return; }
        elsif ( ( $status >> 8 ) eq 1 ) { print STDERR " failed with a bad port number (will perform sychronous visualization)\n"; return; }
        elsif ( ( $status >> 8 ) eq 2 ) { print STDERR " failed with un-supported broker (will perform sychronous visualization)\n"; return; }
        elsif ( ( $status >> 8 ) eq 3 ) { print STDERR " failed to start redis server (will perform sychronous visualization)\n"; return; }
        elsif ( ( $status >> 8 ) eq 4 ) { print STDERR " failed to start celery worker (will perform sychronous visualization; NOTE: redis server was already started.)\n"; return; }
        elsif ( ( $status >> 8 ) eq 5 ) { print STDERR " the sandbox creater does not have write permission in \/var\/log\/celery\/ that saves the celery log (will perform sychronous visualization; NOTE: redis server was already started.)\n"; return; }
        elsif ( ( $status >> 8 ) ne 0 ) { print STDERR " failed with an unknown error (will perform sychronous visualization)\n"; return; }

        # make sure queue is ready
        $cmd
            = "PYTHONPATH=$GIOVANNI::ENV{PYTHONPATH} $tarRootDir/bin/checkQueueStatus.py ";
        my $counter = 10;
        $status = system( $cmd. ' >> /dev/null 2>&1 ' );
        while ( $counter > 0 && ( $status >> 8 ) ne 0 ) {
            sleep(1);
            $status = system( $cmd. ' >> /dev/null 2>&1 ' );
            $counter -= 1;
        }
        if ( $status == -1 ) {
            print STDERR
                "failed to launch the driver script to check queue status: $!\n";
            return;
        }
        elsif ( $status & 0x7F ) {
            print STDERR "driver script killed by signal "
                . ( $status & 0x7F ) . "\n";
            return;
        }
        elsif ( ( $status >> 8 ) eq 0 ) { print STDERR " completed\n"; }
        else {
            print STDERR " queue was not started correctly!\n";
            return;
        }
    }
}

# Fetches Giovanni-4 codebase given the code base location and the src sandbox
sub fetchSourceCodeFromArchive {
    my ( $url, $archDir, $verbose ) = @_;

    print STDERR "Fetching Giovanni code base...\n";

    # See whether we can chdir to archive dir
    unless ( chdir $archDir ) {
        warn "Failed to change to $archDir";
        return 0;
    }

    # Fetch the source code archive (zipped tar file with
    # aGiovanni, aGiovanni_www, aGiovanni_GIOVANNI projects)
    my $agent = LWP::UserAgent->new();
    $agent->env_proxy;
    my $response = $agent->get($url);
    unless ( $response->is_success() ) {
        warn "Failed to download the source code";
        return 0;
    }
    my $archFile = basename( URI->new($url)->path() );
    unless ( open( FH, ">$archFile" ) ) {
        warn "Failed to open $archFile in $archDir for writing";
        return 0;
    }
    print FH $response->content();
    unless ( close(FH) ) {
        warn "Failed to flush $archFile";
        return 0;
    }

    # Untar the package
    my $tarOut = `tar xvf $archFile`;
    if ($?) {
        warn "Failed to un-tar $archFile";
        return 0;
    }
    return 1;
}

# Fetching from ECC
sub fetchSourceCodeFromEcc {
    my ( $archDir, $cfgFile, $projList, $verbose ) = @_;

    print STDERR "Fetching Giovanni code base...\n";

    # Read configuration file containing git repositories
    my $repoHash = {};
    foreach my $proj (@$projList) {
        $repoHash->{$proj}{branch} = undef;
    }

    # Case of a config file being specified
    if ( defined $cfgFile ) {

        # Read config file containing info on git repos
        if ( not -r $cfgFile ) {
            die "Can't read $cfgFile";
        }
        else {
            my @repoList = Giovanni::Util::readFile($cfgFile);
            chomp @repoList;
        REPO_LOOP: foreach my $str (@repoList) {
                my ( $repo, $branch ) = split( /\s*,\s*/, $str, 2 );

                # Make sure the repo is a supported one
                next REPO_LOOP unless ( $repo =~ /\S+/ );
                $repo   =~ s/^\s+|\s+$//g;
                $branch =~ s/^\s+|\s+$//g;
                if ( exists $repoHash->{$repo} ) {
                    $repoHash->{$repo}{branch} = $branch if $branch =~ /\S+/;
                }
                else {
                    my $repoFile = lc( basename( URI->new($repo)->path() ) );
                    my $repoFoundFlag = 0;
                PROJ_LOOP: foreach my $proj (@$projList) {
                        my $projFile
                            = lc( basename( URI->new($proj)->path() ) );
                        if ( $projFile eq $repoFile ) {
                            $repoHash->{$proj}{branch} = $branch
                                if $branch =~ /\S+/;
                            $repoFoundFlag = 1;
                            last PROJ_LOOP;
                        }
                    }
                    die "Doesn't know how to install repo=$repo"
                        unless $repoFoundFlag;
                }
            }
        }
    }

    # See whether we can chdir to archive dir
    my $curDir = undef;
    unless ( chdir $archDir ) {
        warn "Failed to change to $archDir";
        return 0;
    }

    my $status = 1;
    foreach my $proj (@$projList) {
        print STDERR "Cloning $proj\n";
        my $output = `git clone $proj`;
        if ($?) {
            warn "Failed to clone $proj ($!)";
            return 0;
        }
        my $gitUri  = URI->new($proj);
        my $gitDir  = basename( $gitUri->path, '.git' );
        my $message = "repo=$proj";
        my $gitCmd  = 'git checkout';
        if ( exists $repoHash->{$proj}
            && exists $repoHash->{$proj}{branch}
            && $repoHash->{$proj}{branch} =~ /\S+/ )
        {
            $gitCmd  .= " $repoHash->{$proj}{branch}";
            $message .= " branch/tag=$repoHash->{$proj}{branch}";
        }

        print STDERR "Checking out $message\n";
        $output = `cd $gitDir; $gitCmd`;
        if ($?) {
            warn "Failed to checkout $message\n";
            return 0;
        }
    }
    return $status;
}

# Fetching from CVS
sub fetchSourceCodeFromCvs {
    my ( $archDir, $branch, $projList, $verbose ) = @_;
    print STDERR "Fetching Giovanni code base...\n";

    # See whether we can chdir to archive dir
    unless ( chdir $archDir ) {
        warn "Failed to change to $archDir";
        return 0;
    }

    my $status = 1;
    my $projStr = join( " ", @$projList );
    print STDERR "Checking out $branch of $projStr\n";
    my $output = `cvs co -r "$branch" $projStr`;
    if ($?) {
        warn "Failed to download $projStr from CVS ($!)";
        return 0;
    }
    return $status;
}

__END__

=head1 NAME

createGivoanniSandbox.pl - Script to create Giovanni in a user's public_html directory

=head1 PROJECT

Giovanni

=head1 SYNOPSIS

createGiovanniSandbox.pl
 B<--repo> "git" or "cvs" or "http://discette-ts2.gsfc.nasa.gov/HUDSON/"
 B<--sandbox> Dir for checking out code; uses TMPDIR by default
 B<--task> "config" or "install" or "deploy"; set to "deploy" by default
 B<--prefix> Installation directory; set to ~/public_html by default
 B<--config> git repo list file 
 B<--version> optional tab or branch in CVS to install; default is HEAD
 B<--force> optional flag to touch files to force installation of each file
 B<--instance> optional instance name; default is giovanni4
 B<--queue_url> optional celery queue url; B<NOTE: In the current implementation, the same broker/result url is assumed for both celery client and worker.>
 B<-remote-worker> optional flag to start the celery worker on remote worker; if specified, you need to start the celery worker manually on the remote worker.  Deault is local-worker, where celery worker will be automatically started on the local machine
 B<-h> prints command synopsis

=head1 DESCRIPTION

Creates an instance of Giovanni given the location of source code.

=head1 OPTIONS

=over 4

=item B<-h>

Prints command synopsis

=item B<--repo> 

Specifies the location of source code: valid values are "git" or "cvs" or "http://discette-ts2.gsfc.nasa.gov/HUDSON/"

=item B<--sandbox>

Specifies the directory for checking out code; uses TMPDIR by default.

=item B<--task>

Specifies task to accomplish: "config" or "install" or "deploy"; set to "deploy" by default. The description of the task is as follows:
config = configures an existing Giovanni instance
install = installs Giovanni code
deploy = install+deploy

=item B<--prefix>

Installation directory; set to ~/public_html by default.

=item B<--config>

Specifies git repo list file. It is a file which contains a comma spearated list of git repo (URL), branch name and tag name. For example, if the file contained following:
    https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni.git,feature/comparison-tool
    https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_www.git
    https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_GIOVANNI.git
    https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_DataAccess.git
    https://git.earthdata.nasa.gov/scm/fedgianni/aGiovanni_Algorithms.git
    https://git.earthdata.nasa.gov/scm/fedgianni/jasmine.git

Except for aGiovanni repo, rest will use the 'dev' branch. For aGiovanni, "feature/comparison-tool" will be checked out.

=item B<--version>

Optional tab or branch in CVS to install; default is HEAD.

=item B<--force>

Optional flag to touch files to force installation of each file]

=item B<--instance>

Optional instance name; default is giovanni4]

=item B<--queue_url>

Optional queue url

=item B<--remote-worker>

Optional flag to start the celery worker on remote worker; if specified, you need to start the celery worker manually on the remote worker.  Deault is local-worker, where celery worker will be automatically started on the local machine

=back

=head1 RESOURCES

None

=head1 ENVIRONMENT VARIABLES

TMPDIR

=head1 EXAMPLES

=over 4

=item perl createGiovanniSandbox.pl --task deploy --repo cvs

=item perl createGiovanniSandbox.pl --task deploy --repo ecc

=item perl createGiovanniSandbox.pl --task deploy --repo ecc --version "Sprint-100-A"

=item perl createGiovanniSandbox.pl --task deploy --repo ecc --config git.txt

=item perl createGiovanniSandbox.pl --task deploy --repo ecc --config git.txt --queue_url redis://localhost:6379/

=item perl createGiovanniSandbox.pl --task deploy --repo ecc --config git.txt --queue_url redis://localhost:6379/ --remote-worker


=back

=head1 AUTHOR

M. Hegde (Mahabaleshwa.S.Hegde@nasa.gov)

=head1 SEE ALSO

=cut
