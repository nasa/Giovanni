# Giovanni:     The Bridge Between Data And Science 
https://giovanni.gsfc.nasa.gov/giovanni/

Giovanni is an online (Web) environment for the display and analysis of geophysical parameters in which the provenance (data lineage) can easily be accessed. 

GES DISC is making our Giovanni (currently at version 4.31)  code base available on github

<h4> Getting Started with the code </h4>
Giovanni locally is split into several repositories:

Each subdirectory has either a Makefile or Perl Makefile.PL

<br/><b>agiovanni:</b><br>
<br/><b>agiovanni_algorithms</b>
<br/><b>agiovanni_data_access</b>
<br/><b>agiovanni_www</b>, 
<br/><b>agiovanni_shapes</b>
<br/><b> agiovanni_giovanni</b> 

<br/><b>agiovanni/Dev-Tools/other/rpmbuild</b><br/> Contains  a build script and RPM spec file that gives an indication as to Giovanni's software dependencies.

<br/><b>AESIR</b><br/>refers to Giovanni's variable metadata SOLR database. Giovanni's File database is <a href="https://earthdata.nasa.gov/about/science-system-description/eosdis-components/common-metadata-repository">CMR</a>

<b>Disclaimer:We will update the software but not maintain the pull requests.</b>

<br/>Direct comments and questions to: <b>gsfc-help-disc@lists.nasa.gov</b>

<br/>To give more indication of Giovanni's dependencies:
Giovanni is powered by:<br/>
<br/><a href="http://nco.sourceforge.net/">NCO netCDF Operator</a>
<br/><a href="https://earthdata.nasa.gov/about/science-system-description/eosdis-components/common-metadata-repository">CMR Common Metadata Repository</a>
<br/><a href="http://developer.yahoo.com/yui/">YUI</a>
<br/><a href="http://openlayers.org/">OpenLayers</a>
<br/><a href="http://www.mapserver.org/ogc/">MapServer</a>
<br/><a href="http://opendap.org/">OPeNDAP</a>





