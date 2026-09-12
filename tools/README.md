# Touch test tools

`mttap.c` / `mtrec.c` inject and record **real** touchscreen events (evdev
protocol B) on the device, which `uitest uiInput` cannot do: it spawns a
process per tap (~3 taps/s) and two concurrent taps reuse pointer id 0, so
MMI cancels the first touch — an artifact that looks like a multi-touch bug.

```bash
CLANG=$OHOS_SDK/native/llvm/bin/aarch64-unknown-linux-ohos-clang
$CLANG -O2 -o mttap tools/mttap.c && hdc file send mttap /data/local/tmp/mttap
hdc shell "chmod 755 /data/local/tmp/mttap"

hdc shell "/data/local/tmp/mttap -i /dev/input/event4"          # ABS ranges
# x,y,startMs,holdMs[,driftX,driftY] — overlapping taps = rolling typing
hdc shell "/data/local/tmp/mttap /dev/input/event4 65,1816,0,140 171,1816,100,140"
hdc shell "/data/local/tmp/mtrec /dev/input/event4"             # watch contacts
```

On the Volla Plinius the panel is `fts_ts` = `/dev/input/event4` and its ABS
range (1080x2400) maps 1:1 to screen pixels, so key coordinates can be taken
straight from `uitest dumpLayout`.
