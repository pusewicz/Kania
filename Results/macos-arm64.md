| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 100 | c | 0.0062 | +0.0% | 62.0 | 2.429 | matches C |
| sprites | 100 | raw-array | 0.0071 | +14.5% | 71.0 | 2.408 | matches C |
| sprites | 100 | raw-buffer | 0.0063 | +1.6% | 63.0 | 2.581 | matches C |
| sprites | 100 | overlay-struct | 0.0073 | +17.7% | 73.0 | 2.514 | matches C |
| sprites | 100 | overlay-span | 0.0063 | +1.6% | 63.0 | 2.577 | matches C |
| sprites | 100 | overlay-class | 0.0080 | +29.0% | 80.0 | 2.524 | matches C |
| sprites | 1000 | c | 0.0471 | +0.0% | 47.1 | 2.440 | matches C |
| sprites | 1000 | raw-array | 0.0608 | +29.1% | 60.8 | 2.529 | matches C |
| sprites | 1000 | raw-buffer | 0.0492 | +4.5% | 49.2 | 2.416 | matches C |
| sprites | 1000 | overlay-struct | 0.0585 | +24.2% | 58.5 | 2.529 | matches C |
| sprites | 1000 | overlay-span | 0.0520 | +10.4% | 52.0 | 2.417 | matches C |
| sprites | 1000 | overlay-class | 0.0670 | +42.3% | 67.0 | 2.567 | matches C |
| sprites | 10000 | c | 0.5185 | +0.0% | 51.8 | 2.166 | matches C |
| sprites | 10000 | raw-array | 0.6156 | +18.7% | 61.6 | 2.006 | matches C |
| sprites | 10000 | raw-buffer | 0.5315 | +2.5% | 53.2 | 1.933 | matches C |
| sprites | 10000 | overlay-struct | 0.5939 | +14.5% | 59.4 | 2.086 | matches C |
| sprites | 10000 | overlay-span | 0.5267 | +1.6% | 52.7 | 2.026 | matches C |
| sprites | 10000 | overlay-class | 0.6613 | +27.5% | 66.1 | 2.039 | matches C |
| text | 100 | c | 0.8042 | +0.0% | 8042.0 | 2.797 | matches C |
| text | 100 | swift | 0.7980 | -0.8% | 7980.0 | 2.766 | matches C |
| text | 1000 | c | 8.4415 | +0.0% | 8441.5 | 9.540 | matches C |
| text | 1000 | swift | 8.3856 | -0.7% | 8385.6 | 9.488 | matches C |
