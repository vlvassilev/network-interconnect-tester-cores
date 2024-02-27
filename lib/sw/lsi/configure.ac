AC_INIT([network-interconnect-tester-cores-sw], [0.50], [vladimir@lightside-instruments.com])

AC_CANONICAL_SYSTEM
AM_INIT_AUTOMAKE([foreign])
LT_INIT([disable-static])

AC_PROG_CC
AC_PROG_CXX
AM_PROG_AS
AC_PROG_LIBTOOL

AC_ARG_ENABLE([simulation],
[  --enable-simulation    Build ioreg_ interface for simulation],
[case "${enableval}" in
  yes) simulation=true ;;
  no)  simulation=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-simulation]) ;;
esac],[simulation=true])
AM_CONDITIONAL([SIMULATION], [test x$simulation = xtrue])

CFLAGS="$CFLAGS -g -fPIC -DDEBUG=1 -DLINUX=1 -DGCC=1 -DRELEASE=0"
AC_SUBST(CFLAGS)

netconfmoduledir="$libdir/yuma"
AC_SUBST(netconfmoduledir)

lsi_yangdir=${datarootdir}/yuma/modules/lsi
AC_SUBST(lsi_yangdir)

AM_PATH_XML2

AC_CONFIG_FILES([
        Makefile \
        common/Makefile \
        common/simulation/Makefile \
        cores/gmii-mux/Makefile \
        cores/traffic-analyzer-gmii/Makefile \
        cores/traffic-generator-gmii/Makefile \
        cores/loopback/Makefile \
        cores/rtclock/Makefile \
        cores/gnss-clock/Makefile \
        cores/power-distribution-unit/Makefile
])

AC_OUTPUT
