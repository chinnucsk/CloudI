ACLOCAL_AMFLAGS = -I m4
SUBDIRS = api lib tests

all-local: rebar 
	./rebar compile

clean-local: rebar
	./rebar clean
	rm -f api/python/cloudi.pyc api/python/erlang.pyc

clean-configure: config.log
	rm -f aclocal.m4 config.h config.h.in config.h.in~ config.log \
          config.status stamp-h1 \
          config/config.guess config/config.sub config/depcomp \
          config/install-sh config/ltmain.sh config/missing \
          rebar Makefile Makefile.in configure \
          m4/libtool.m4 m4/ltoptions.m4 m4/ltsugar.m4 \
          m4/ltversion.m4 m4/lt~obsolete.m4 libtool \
          external/rebar/ebin/*.beam
	rm -rf autom4te.cache
	rm -rf api/c/.deps/ \
           lib/cloudi/cxx_src/.deps/ \
           tests/hexpi/cxx_src/.deps/
	find api -name "Makefile.in" -o -name "Makefile" | xargs rm -f
	find lib -name "Makefile.in" -o -name "Makefile" | xargs rm -f
	find tests -name "Makefile.in" -o -name "Makefile" | xargs rm -f

dialyze: rebar
	./rebar dialyze

run: all
	$(ERLANG_ROOT_DIR)/bin/erl -config config/sys \
      -pz external/epgsql/ebin \
      -pz external/emysql/ebin \
      -pz external/etokyotyrant/ebin \
      -pz external/ememcached/ebin \
      -pz external/ecouchdb/ebin \
      -pz external/misultin/ebin \
      -pz tests/hexpi/ebin \
      `find lib/ -name "ebin" -o -name "priv" | sed 's/^/-pz /'`

#./rebar generate
#./rebar console
