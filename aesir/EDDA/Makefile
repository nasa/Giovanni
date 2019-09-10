#
# $Id: $
#
install: force_ok
	cd EDDA; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd EDDA-Compare; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd EDDA-DataProbe; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd EDDA-Ingest; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd WebContent; make $(MFLAGS) PREFIX=$(PREFIX) install; cd ..
	cd cfg; make $(MFLAGS) PREFIX=$(PREFIX) PREFIX_INSTALL=$(PREFIX_INSTALL) install; cd ..
	cd cgi-bin; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd bin; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..
	cd XML2JSON; perl Makefile.PL PREFIX=$(PREFIX); make $(MFLAGS); make $(MFLAGS) install; cd ..

clean: force_ok
	cd EDDA; make clean; cd ..
	cd EDDA-Compare; make clean; cd ..
	cd EDDA-DataProbe; make clean; cd ..
	cd EDDA-Ingest; make clean; cd ..
	cd cgi-bin; make clean; cd ..
	cd bin; make clean; cd ..
	cd XML2JSON; make clean; cd ..

force_ok:
	true
