bin_SCRIPTS = traffic-analyzer

bin_PROGRAMS = traffic-analyzer-gmii

traffic_analyzer_gmii_SOURCES = \
$(top_srcdir)/common/devmem-map.c \
$(top_srcdir)/common/hexstr.c \
traffic-analyzer-gmii.c

traffic_analyzer_gmii_CPPFLAGS = -I $(top_srcdir)/common/
traffic_analyzer_gmii_LDFLAGS =

if SIMULATION

traffic_analyzer_gmii_CPPFLAGS += -DSIMULATION
traffic_analyzer_gmii_SOURCES += $(top_srcdir)/common/sim-ioreg.c


else

traffic_analyzer_gmii_SOURCES += $(top_srcdir)/common/ioreg.c

endif
