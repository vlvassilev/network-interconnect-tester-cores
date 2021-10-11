lsi_yang_DATA = lsi-gnss-clock.yang

netconfmodule_LTLIBRARIES = liblsi-gnss-clock.la

liblsi_gnss_clock_la_SOURCES = \
lsi-gnss-clock.c

liblsi_gnss_clock_la_CPPFLAGS = -I${includedir}/yuma/agt -I${includedir}/yuma/ncx -I${includedir}/yuma/platform  $(XML_CPPFLAGS)
liblsi_gnss_clock_la_LDFLAGS = -module -lyumaagt -lyumancx


bin_SCRIPTS = gnss-clock-config


