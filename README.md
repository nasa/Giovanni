# Giovanni:     The Bridge Between Data And Science 
https://giovanni.gsfc.nasa.gov/giovanni/

Giovanni is an online (Web) environment for the display and analysis of geophysical parameters in which the provenance (data lineage) can easily be accessed. 

GES DISC is making our Giovanni (currently at version 4.31)  code base available on github

Giovanni locally is split into several repositories:
<br/><b>agiovanni:</b>There is a top level perl Makefile.PL (perl Makefile.PL PREFIX=/opt/giovanni4; make; make install)
<br/>Also under agiovanni/Dev-Tools/other/rpmbuild there is a build script and RPM spec file that gives an  indication as to
Giovanni's software dependencies.
<br/><b>agiovanni_algorithms</b> and <b>agiovanni_data_access</b> subdirectories there is also a perl Makefile.PL
<br/><b>agiovanni_www</b>,<b>agiovanni_shapes</b>, and <b> agiovanni_giovanni</b> all have  top level Makefiles. ( make install PREFIX=/opt/giovanni4)


<b>Disclaimer:We will update the software but not maintain the pull requests.</b>





