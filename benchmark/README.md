# Multicolor outline performance

Run from the package root:

```sh
flutter test --no-pub benchmark/multicolor_outline_benchmark_test.dart --concurrency=1
```

This synthetic, tile-free benchmark compares ordinary polylines, uniform-color
multicolor polylines, gradients, and gradients with a separate uniform outline.
It exercises pan and zoom with 5,000 and 20,000 vertices. Each case warms up for
15 frames and reports the median and minimum of five 30-frame samples.

These are widget-test CPU build/paint timings, not GPU frame times or an FPS
prediction. Run before and after changes on the same machine, without concurrent
benchmarks. Both kinds of polyline now use the existing projection and floored-zoom
simplification cache. Multicolor lines additionally preserve changes exceeding
0.02 per RGBA channel, so they may retain more vertices than ordinary lines.
Setting the layer's `simplificationTolerance` to zero disables simplification.

The opaque uniform-color fast path uses the standard batched path painter while
retaining multicolor projection and culling.
Nonuniform and translucent lines retain the segment-gradient renderer. Immutable
vertex colors allow uniformity and transparency checks to be cached per line.

On the development machine, compared with cc3dc7f, the 5,000-point outlined route
decreased from 21.34 to 12.80 ms per pan frame and 22.00 to 12.78 ms per zoom frame.
The uniform outline alone decreased from about 10 ms to 2 ms. The gradient-only
case remained around 11 ms: this optimization does not eliminate gradient cost.

A subsequent segment optimization uses `Canvas.drawLine` instead of repeatedly
building and resetting a two-point path. The same 5,000-point benchmark measured
11.19 to 10.02 ms for gradient pan and 11.21 to 10.22 ms for gradient zoom;
outlined routes decreased from 13.03 to 12.02 ms and 13.05 to 11.91 ms respectively.
This preserves per-segment gradients, visibility checks, and explicit joins/caps;
it does not quantize colors or discard samples. Results are local CPU measurements
and should be rechecked on the target device and renderer.

Color-aware simplification stores explicit original sample indices, also sliced
when viewport culling splits a line. A separate outline should supply its
foreground's `vertexColors` as `simplificationColors`, selecting the same vertices
without changing the outline's paint. Separate polylines remain separate; no gaps
are joined. No predictive prewarming or raster cache is added.

The 5,000-point synthetic benchmark with warm zoom caches measured approximately
0.88 ms gradient pan, 0.83 ms gradient zoom, 0.98 ms outlined pan, and 0.85 ms
outlined zoom after simplification. These are dataset-dependent: noisy geometry
or colors deliberately retain more points. Warm timings exclude initial cache
construction and are not claims about first-open latency or GPU frame rate.

Pixel tests compare uniform multicolor and ordinary simplification across caps,
borders, duplicate vertices, and offscreen endpoints. Additional
tests cover original color indices after simplification and culling, brief color
and alpha peaks, duplicate coordinates, zoom changes, and zero-tolerance mode.
