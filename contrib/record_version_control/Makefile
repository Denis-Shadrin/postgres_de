# contrib/record_version_control/Makefile
#MODULES = record_version_control
EXTENSION = record_version_control

DATA = record_version_control--1.0.sql
#PGFILEDESC = "test extension"
#REGRESS = record_version_control

ifdef USE_PGXS
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
else
subdir = contrib/record_version_control
top_builddir = ../..
include $(top_builddir)/src/Makefile.global
include $(top_srcdir)/contrib/contrib-global.mk
endif

