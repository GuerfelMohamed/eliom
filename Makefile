
REPS = lwt xmlp4 http server moduleexample

all: $(REPS)

.PHONY: $(REPS) krokoutils clean


lwt:
	make -C lwt depend all

xmlp4:
	make -C xmlp4 depend all

http :
	make -C http depend all

moduleexample:
	make -C moduleexample all

server:
	make -C server depend all

krokoutils:
	make -C krokoutils depend all install

clean:
	@for i in $(REPS) krokoutils ; do make -C $$i clean ; done
	-rm -f lib/* *~
	-rm -f bin/* *~

depend: xmlp4
	@for i in $(REPS) krokoutils ; do make -C $$i depend ; done
