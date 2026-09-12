/* mtrec - record touchscreen contacts (evdev protocol B) with timestamps.
 * usage: mtrec <dev>   -> one line per contact begin/end
 */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <linux/input.h>

#define NSLOT 10

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: mtrec <dev>\n"); return 1; }
    int fd = open(argv[1], O_RDONLY);
    if (fd < 0) { fprintf(stderr, "open: %s\n", strerror(errno)); return 1; }
    struct input_event ev;
    int slot = 0;
    int tid[NSLOT], x[NSLOT], y[NSLOT], dirty[NSLOT];
    long t0 = 0;
    memset(tid, -1, sizeof(tid)); memset(x, 0, sizeof(x));
    memset(y, 0, sizeof(y)); memset(dirty, 0, sizeof(dirty));
    setvbuf(stdout, NULL, _IOLBF, 0);
    while (read(fd, &ev, sizeof(ev)) == (ssize_t)sizeof(ev)) {
        long ms = ev.time.tv_sec * 1000L + ev.time.tv_usec / 1000;
        if (t0 == 0) t0 = ms;
        if (ev.type == EV_ABS) {
            if (ev.code == ABS_MT_SLOT) slot = ev.value % NSLOT;
            else if (ev.code == ABS_MT_TRACKING_ID) {
                if (ev.value >= 0) { tid[slot] = ev.value; dirty[slot] = 1; }
                else {
                    printf("%8ld UP   slot=%d id=%d x=%d y=%d\n", ms - t0, slot, tid[slot], x[slot], y[slot]);
                    tid[slot] = -1;
                }
            }
            else if (ev.code == ABS_MT_POSITION_X) x[slot] = ev.value;
            else if (ev.code == ABS_MT_POSITION_Y) y[slot] = ev.value;
        } else if (ev.type == EV_SYN && ev.code == SYN_REPORT) {
            for (int s = 0; s < NSLOT; s++) {
                if (dirty[s]) {
                    printf("%8ld DOWN slot=%d id=%d x=%d y=%d\n", ms - t0, s, tid[s], x[s], y[s]);
                    dirty[s] = 0;
                }
            }
        }
    }
    return 0;
}
