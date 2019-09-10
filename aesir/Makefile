#
# $Id: Makefile,v 1.3 2015/07/14 23:33:48 eseiler Exp $
#
install: force_ok
	cd bin; make $(MFLAGS) PREFIX=$(PREFIX) install; cd ..
	cd EDDA; make $(MFLAGS) PREFIX=$(PREFIX) PREFIX_INSTALL=$(PREFIX_INSTALL) install; cd ..

force_ok:
	true
