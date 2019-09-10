# Giovanni:     The Bridge Between Data And Science 
https://giovanni.gsfc.nasa.gov/giovanni/

Giovanni is an online (Web) environment for the display and analysis of geophysical parameters in which the provenance (data lineage) can easily be accessed. 

GES DISC is making our Giovanni (currently at version 4.31)  code base available on github

Giovanni locally is split into several repositories:
<br/>Under agiovanni, there is a top level perl Makefile.PL (perl Makefile.PL PREFIX=/opt/giovanni4; make; make install)
<br/>Under agiovanni/Dev-Tools/other/rpmbuild there is a build script and RPM spec file that gives an  indication as to
Giovanni's software dependencies.

In agiovanni_algorithms and agiovanni_data_access subdirectories there is also a perl Makefile.PL

agiovanni_www, agiovanni_shapes, and agiovanni_giovanni all have  top level Makefiles. ( make install PREFIX=/opt/giovanni4)


<b>Disclaimer:We will update the software but not maintain the pull requests.</b>





