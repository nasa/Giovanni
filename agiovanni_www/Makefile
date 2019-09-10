css: force_ok 
	cd css && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

image: force_ok
	cd image && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

js: force_ok
	cd js && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

install: css image js


force_ok:
	true
