#ifndef __EGA_DIST_LOG_H_INCLUDED__
#define __EGA_DIST_LOG_H_INCLUDED__ 1

#include <stdlib.h>
#include <stddef.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#define D1(...)
#define D2(...)
#define D3(...)
#define E(fmt, ...) fprintf(stderr, fmt "\n", ##__VA_ARGS__)

/* kill syslog */
#undef HAVE_SYSLOG_H

#ifdef HAVE_SYSLOG_H
#error "Not using syslog"

#include <syslog.h>

#define LOG_FUNC(level, fmt, ...) syslog(LOG_MAKEPRI(LOG_USER, LOG_ERR), level" "fmt"\n", ##__VA_ARGS__)

#undef E
#define E(fmt, ...) LOG_FUNC("ERROR", fmt, ##__VA_ARGS__)

#if DEBUG > 0
#undef D1
#define D1(fmt, ...) LOG_FUNC("debug1", fmt, ##__VA_ARGS__)
#endif

#if DEBUG > 1
#undef D2
#define D2(fmt, ...) LOG_FUNC("debug2", fmt, ##__VA_ARGS__)
#endif

#if DEBUG > 2
#undef D3
#define D3(fmt, ...) LOG_FUNC("debug3", fmt, ##__VA_ARGS__)
#endif

#endif /* ! HAVE_SYSLOG_H */

#endif /* !__EGA_DIST_LOG_H_INCLUDED__ */
