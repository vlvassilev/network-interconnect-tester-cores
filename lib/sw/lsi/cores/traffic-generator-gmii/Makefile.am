bin_SCRIPTS = traffic-generator

bin_PROGRAMS = traffic-generator-gmii

traffic_generator_gmii_SOURCES = \
$(top_srcdir)/common/devmem-map.c \
$(top_srcdir)/common/hexstr.c \
traffic-generator-gmii.c


traffic_generator_gmii_CPPFLAGS = -I $(top_srcdir)/common/
traffic_generator_gmii_LDFLAGS =

if SIMULATION

traffic_generator_gmii_SOURCES += $(top_srcdir)/common/sim-ioreg.c
traffic_generator_gmii_CPPFLAGS += -DSIMULATION

else

traffic_generator_gmii_SOURCES += $(top_srcdir)/common/ioreg.c

endif
