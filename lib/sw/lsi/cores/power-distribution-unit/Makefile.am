lsi_yang_DATA = lsi-power-distribution-unit.yang

netconfmodule_LTLIBRARIES = liblsi-power-distribution-unit.la

liblsi_power_distribution_unit_la_SOURCES = \
lsi-power-distribution-unit.c

liblsi_power_distribution_unit_la_CPPFLAGS = -I${includedir}/yuma/agt -I${includedir}/yuma/ncx -I${includedir}/yuma/platform  $(XML_CPPFLAGS)
liblsi_power_distribution_unit_la_LDFLAGS = -module -lyumaagt -lyumancx


bin_SCRIPTS = power-distribution-unit

