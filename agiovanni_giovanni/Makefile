css: force_ok 
	cd css && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

html: force_ok
	cd html && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

js: force_ok
	cd js && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

test: force_ok
	cd test && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

doc: force_ok
	cd doc && make $(MFLAGS) PREFIX=$(PREFIX) install && cd ..

install: test html doc
	
force_ok:
	true
