#!/usr/bin/perl

my $aesir_catalog_dir = $ARGV[0];
my $baseline = $ARGV[1];
my $group = $ARGV[2];

unless ((defined $aesir_catalog_dir) && (defined $baseline) && (defined $group)) {
    die "Usage: $0 aesir_catalog_dir baseline group\n";
}

unless (-d $aesir_catalog_dir) {
    unless (mkdir $aesir_catalog_dir, 0775) {
	die "Could not create directory $aesir_catalog_dir: $!\n";
    }
    `chgrp $group $aesir_catalog_dir`;
    if ($?) {
	die "Could not change $aesir_catalog_dir to group $group\n";
    }
}

my @dirs = ('dataFieldsStatus', 'dataProductsStatus', $baseline);
my @baselineDirs = ('dataProducts', 'deletedDataProducts', 'dataFields',
                    'publishedDataFields', 'rollbackDataFields',
                    'deletedDataFields');

my $catalogXml = <<END_XML;
<update>
  <delete>
    <query>*:*</query>
  </delete>
  <add overwrite="true">
  </add>
</update>
END_XML

my $dir;
foreach $dir (@dirs) {
    my $path = "$aesir_catalog_dir/$dir";
    next if -d $path;
    unless (mkdir $path, 0775) {
	die "Could not create directory $path: $!\n";
    }
    unless (chmod 0775, $path) {
	warn "Could not chmod $path: $!\n";
    }
    `chgrp $group $path`;
    if ($?) {
	die "Could not change $path to group $group\n";
    }
}

foreach $dir (@baselineDirs) {
    my $path = "$aesir_catalog_dir/$baseline/$dir";
    next if -d $path;
    unless (mkdir $path, 0775) {
	die "Could not create directory $path: $!\n";
    }
    unless (chmod 0775, $path) {
	warn "Could not chmod $path: $!\n";
    }
    `chgrp $group $path`;
    if ($?) {
	die "Could not change $path to group $group\n";
    }
}

my $catalog = "$aesir_catalog_dir/$baseline/aesir_solr_catalog.xml";
unless (-f $catalog) {
    open(CATALOG, "> $catalog") or die "could not open $catalog for writing: $!\n";
    print CATALOG $catalogXml;
    close(CATALOG);
    unless (chmod 0664, $catalog) {
	warn "Could not chmod $catalog: $!\n";
    }
    `chgrp $group $catalog`;
    if ($?) {
	die "Could not change $catalog to group $group\n";
    }
}

# Copy/generate $AESIR_CATALOG_DATA_FIELDS_SLD_VALIDS_DOC?
# Run generateDataFieldSldValids.pl

exit 0;
