use 5.008008;
use ExtUtils::MakeMaker;

@AUTOCONF_PACKAGES = qw(Giovanni-Algorithm-Correlation);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      => 'Giovanni',
    VERSION   => '1.0',        # finds $VERSION
    PREREQ_PM => {},           # e.g., Module::Name => 1.1
    DIR       => [
        qw(
            Dev-Tools
            Giovanni-Agent
            Giovanni-Algorithm-AreaAveragerNco
            Giovanni-Algorithm-CorrelationWrapper
            Giovanni-Algorithm-Shapefiles
            Giovanni-Algorithm-TimeAveragerNco
            Giovanni-Algorithm-Wrapper
            Giovanni-BoundingBox
            Giovanni-Cache
            Giovanni-Catalog
            Giovanni-CGI
            Giovanni-Classify
            Giovanni-CombineManifests
            Giovanni-Data-NcFile
            Giovanni-DataField
            Giovanni-DataStager
            Giovanni-DimensionAverager
            Giovanni-HTML
            Giovanni-History
            Giovanni-Logger
            Giovanni-Map-Info
            Giovanni-Map-Util
            Giovanni-OGC-SLD
            Giovanni-OGC-WCS
            Giovanni-OGC-WMS
            Giovanni-Plot
            Giovanni-PostProcess
            Giovanni-Profile
            Giovanni-Provenance-Text
            Giovanni-Result
            Giovanni-ResultSet
            Giovanni-ScienceCommand
            Giovanni-Scrubber
            Giovanni-Search
            Giovanni-Serializer
            Giovanni-Serializer-TimeSeries
            Giovanni-Session
            Giovanni-Status
            Giovanni-Testing
            Giovanni-UnitsConversion
            Giovanni-Untaint
            Giovanni-UrlDownloader
            Giovanni-Util
            Giovanni-Visualizer
            Giovanni-Visualizer-Animation
            Giovanni-Visualizer-ContourMap
            Giovanni-Visualizer-Curtain
            Giovanni-Visualizer-Gnuplot
            Giovanni-Visualizer-Hints
            Giovanni-Visualizer-Histogram
            Giovanni-Visualizer-Hovmoller
            Giovanni-Visualizer-Preferences
            Giovanni-Visualizer-TimeTics
            Giovanni-Workflow
            Giovanni-WorldLongitude
            XML-XML2JSON
            bin
            )
    ],
    PERM_RWX    => 0775,
    PERM_RW     => 0664,
    INST_BIN    => 'blib/bin',
    INSTALLBIN  => '$(PREFIX)/bin',
    INST_SCRIPT => 'blib/script',
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => '',    # retrieve abstract from module
            AUTHOR => 'Mahabaleshwara S. Hegde <mhegde@localdomain>'
            )
        : ()
    ),
);

sub MY::install {
    my ($self) = @_;

    package MY;
    my $str = $self->SUPER::install();
    my $newTarget = join( " ", map { $_ . '_install' } @::AUTOCONF_PACKAGES );
    $str =~ s/(test\s*::)/\1 $newTarget/;
    $str
        =~ s/(pure_site_install\s*::)/\1 $newTarget web cgi python cfg/;

    #make_jar ant_jar ant_jar_2 ant_aGiovanni_jar cgi python/;
    return $str;
}

sub MY::test {
    my ($self) = @_;

    package MY;
    my $str = $self->SUPER::test();
    my $newTarget = join( " ", map { $_ . '_test' } @::AUTOCONF_PACKAGES );
    $str =~ s/(test\s*::)/\1 $newTarget/;
    $str =~ s/(test\s*::)/\1 pytest/;
    return $str;
}

sub MY::top_targets {
    my ($self) = @_;

    package MY;
    my $str = $self->SUPER::top_targets();
    my $newTarget = join( " ", @::AUTOCONF_PACKAGES );
    $str =~ s/(all\s*::)/\1 $newTarget/;
    return $str;
}

sub MY::postamble {
    my $autoConfTarget = "";
    foreach my $tool (@AUTOCONF_PACKAGES) {
        my @buildCommandList = ( "cd $tool", "make check" );
        my $commandStr = join( "; ", @buildCommandList );
        $autoConfTarget .= "${tool}_test: $tool\n\t$commandStr\n";
        @buildCommandList = (
            "cd $tool",
            "./configure --prefix=\$\(PREFIX)",
            "autoreconf --force --install --symlink",

            #       "rm libtool",
            #       "ln -s /usr/bin/libtool ./libtool",
            "make"
        );
        $commandStr = join( "; ", @buildCommandList );
        $autoConfTarget .= "$tool:Makefile\n\t$commandStr\n";
        @buildCommandList = ( "cd $tool", "make install" );
        $commandStr = join( "; ", @buildCommandList );
        $autoConfTarget .= "${tool}_install:Makefile\n\t$commandStr\n";
    }
    return <<BLOCK;
CFGDIR = \$(PREFIX)/cfg

cgi: FORCE
	cd cgi && perl Makefile.PL PREFIX=\$(PREFIX) && make && make install

web: xsl sld
	\@for i in \$^;\\
	do\\
		cd "\$\$i";\\
		make install PREFIX=\$(PREFIX); \\
		cd "..";\\
	done

python: FORCE
	cd python && python setup.py install --prefix=\$(PREFIX)
	cd ..
	cd cgi && python setup.py install --prefix=\$(PREFIX) --install-scripts=\$(PREFIX)/cgi-bin
	cd ..

export LD_LIBRARY_PATH:=/usr/local/hdf5/lib/

.PHONY: cfg

cfg: 
	if [ ! -d \$(CFGDIR) ]; then install -d \$(CFGDIR); fi 
	if [ ! -d \$(CFGDIR)/fonts ]; then install -d \$(CFGDIR)/fonts; fi 
	if [ ! -d \$(CFGDIR)/json_schemas ]; then install -d \$(CFGDIR)/json_schemas; fi 
	\@for filename in "cfg/fonts/*.*";\\
	do \\
		cp \$\$filename \$(CFGDIR)/fonts;\\
	done 
	\@for filename in "cfg/json_schemas/*.*";\\
	do \\
		cp \$\$filename \$(CFGDIR)/json_schemas;\\
	done 
	for filename in cfg/*;\\
	do \\
	if [ "\$\$filename" == "cfg/giovanni.cfg" -a "\$\$ENABLE_DEBUG_LINK" == "1" ];then cat \$\$filename | sed 's/^\\s*\$\$RESULT_VIEWER_ACCESS\\s*=\\s*0/\$\$RESULT_VIEWER_ACCESS = 1/' > \$(CFGDIR)/giovanni.cfg; else cp \$\$filename \$(CFGDIR); fi;\\
	done 

pytest:
	# --safe means will always exit with exit code 0
	bash run_python_tests.sh --safe

$autoConfTarget
BLOCK
}
