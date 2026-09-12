/* mttap - inject real multi-touch taps into an evdev touchscreen (protocol B).
 * usage: mttap -i <dev>                       print ABS ranges
 *        mttap <dev> x,y,startMs,holdMs ...   schedule taps (screen px)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/ioctl.h>
#include <linux/input.h>

#define MAXT 128

static int fd;

static void emit(int type, int code, int val) {
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type; ev.code = code; ev.value = val;
    if (write(fd, &ev, sizeof(ev)) != (ssize_t)sizeof(ev))
        fprintf(stderr, "write failed: %s\n", strerror(errno));
}

struct act { long t_ms; int kind; int slot; int x; int y; int tid; }; /* kind: 1=down 0=up 2=move */

static int cmp(const void *a, const void *b) {
    long d = ((const struct act *)a)->t_ms - ((const struct act *)b)->t_ms;
    return d < 0 ? -1 : (d > 0 ? 1 : 0);
}

int main(int argc, char **argv) {
    int arg = 1, info = 0;
    if (argc > 1 && strcmp(argv[1], "-i") == 0) { info = 1; arg = 2; }
    if (argc <= arg) { fprintf(stderr, "usage: mttap [-i] <dev> [x,y,startMs,holdMs ...]\n"); return 1; }
    const char *dev = argv[arg++];
    fd = open(dev, O_RDWR);
    if (fd < 0) { fprintf(stderr, "open %s: %s\n", dev, strerror(errno)); return 1; }

    struct input_absinfo ax, ay;
    ioctl(fd, EVIOCGABS(ABS_MT_POSITION_X), &ax);
    ioctl(fd, EVIOCGABS(ABS_MT_POSITION_Y), &ay);
    if (info) {
        printf("ABS_MT_POSITION_X min=%d max=%d\n", ax.minimum, ax.maximum);
        printf("ABS_MT_POSITION_Y min=%d max=%d\n", ay.minimum, ay.maximum);
        struct input_absinfo as;
        ioctl(fd, EVIOCGABS(ABS_MT_SLOT), &as);
        printf("ABS_MT_SLOT min=%d max=%d\n", as.minimum, as.maximum);
        return 0;
    }

    static struct act acts[MAXT * 24];
    int na = 0, ntap = 0;
    for (; arg < argc && ntap < MAXT; arg++, ntap++) {
        int x, y, dx = 0, dy = 0; long s, h;
        int got = sscanf(argv[arg], "%d,%d,%ld,%ld,%d,%d", &x, &y, &s, &h, &dx, &dy);
        if (got < 4) { fprintf(stderr, "bad spec '%s'\n", argv[arg]); return 1; }
        int slot = ntap % 8;
        int tid = 1000 + ntap;
        acts[na].t_ms = s; acts[na].kind = 1; acts[na].slot = slot;
        acts[na].x = x; acts[na].y = y; acts[na].tid = tid; na++;
        if (dx || dy) {                    /* drift across the hold, ~10ms steps */
            int steps = h / 10; if (steps > 20) steps = 20; if (steps < 1) steps = 1;
            for (int k = 1; k <= steps; k++) {
                acts[na].t_ms = s + (h * k) / (steps + 1); acts[na].kind = 2;
                acts[na].slot = slot; acts[na].tid = tid;
                acts[na].x = x + (dx * k) / steps; acts[na].y = y + (dy * k) / steps; na++;
            }
        }
        acts[na].t_ms = s + h; acts[na].kind = 0; acts[na].slot = slot;
        acts[na].x = x + dx; acts[na].y = y + dy; acts[na].tid = tid; na++;
    }
    qsort(acts, na, sizeof(struct act), cmp);

    struct timespec t0;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    int fingers = 0;
    for (int i = 0; i < na; i++) {
        struct timespec tw = t0;
        tw.tv_nsec += (acts[i].t_ms % 1000) * 1000000L;
        tw.tv_sec  += acts[i].t_ms / 1000 + tw.tv_nsec / 1000000000L;
        tw.tv_nsec %= 1000000000L;
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &tw, NULL);

        emit(EV_ABS, ABS_MT_SLOT, acts[i].slot);
        if (acts[i].kind == 2) {
            emit(EV_ABS, ABS_MT_POSITION_X, acts[i].x);
            emit(EV_ABS, ABS_MT_POSITION_Y, acts[i].y);
            emit(EV_SYN, SYN_REPORT, 0);
            continue;
        }
        if (acts[i].kind == 1) {
            emit(EV_ABS, ABS_MT_TRACKING_ID, acts[i].tid);
            emit(EV_ABS, ABS_MT_POSITION_X, acts[i].x);
            emit(EV_ABS, ABS_MT_POSITION_Y, acts[i].y);
            emit(EV_ABS, ABS_MT_TOUCH_MAJOR, 8);
            if (fingers == 0) emit(EV_KEY, BTN_TOUCH, 1);
            fingers++;
        } else {
            emit(EV_ABS, ABS_MT_TRACKING_ID, -1);
            fingers--;
            if (fingers == 0) emit(EV_KEY, BTN_TOUCH, 0);
        }
        emit(EV_SYN, SYN_REPORT, 0);
    }
    close(fd);
    return 0;
}
