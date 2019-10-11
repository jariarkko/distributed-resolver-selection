
base:	draft-arkko-abcd-distributed-resolver-selection.txt

LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b master https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

cleantrash:
	rm -f *~

jaricompile:	draft-arkko-abcd-distributed-resolver-selection.txt Makefile
	scp draft-arkko-abcd-distributed-resolver-selection.txt \
		jar@cloud1.arkko.eu:/var/www/www.arkko.com/html/ietf/dns

#		draft-arkko-abcd-distributed-resolver-selection.diff.html \
#	rfcdiff draft-arkko-abcd-distributed-resolver-selection-00.txt draft-arkko-abcd-distributed-resolver-selection.txt
#	cp draft-arkko-abcd-distributed-resolver-selection-from--00.diff.html draft-arkko-abcd-distributed-resolver-selection.diff.html
