
bin_PROGRAMS = devmem32

if SIMULATION

SUBDIRS=simulation

bin_PROGRAMS += sim-run sim-finish sim-devmem32

sim_devmem32_SOURCES = sim-ioreg.c \
sim-devmem32.c

sim_run_SOURCES = \
sim-run.c \
sim-ioreg.c

sim_finish_SOURCES = \
sim-finish.c \
sim-ioreg.c


else

bin_SCRIPTS = get-core-offset

devmem32_SOURCES = \
devmem32.c \
devmem-map.c

endif
