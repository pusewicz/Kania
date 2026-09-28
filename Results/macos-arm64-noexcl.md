| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 100 | c | 0.0061 | +0.0% | 61.0 | 2.506 | matches C |
| sprites | 100 | raw-array | 0.0072 | +18.0% | 72.0 | 2.668 | matches C |
| sprites | 100 | raw-buffer | 0.0067 | +9.8% | 67.0 | 2.700 | matches C |
| sprites | 100 | overlay-struct | 0.0071 | +16.4% | 71.0 | 2.590 | matches C |
| sprites | 100 | overlay-class | 0.0072 | +18.0% | 72.0 | 2.590 | matches C |
| sprites | 1000 | c | 0.0516 | +0.0% | 51.6 | 2.487 | matches C |
| sprites | 1000 | raw-array | 0.0569 | +10.3% | 56.9 | 2.243 | matches C |
| sprites | 1000 | raw-buffer | 0.0525 | +1.7% | 52.5 | 2.658 | matches C |
| sprites | 1000 | overlay-struct | 0.0578 | +12.0% | 57.8 | 2.439 | matches C |
| sprites | 1000 | overlay-class | 0.0566 | +9.7% | 56.6 | 2.286 | matches C |
| sprites | 10000 | c | 0.5250 | +0.0% | 52.5 | 2.128 | matches C |
| sprites | 10000 | raw-array | 0.5526 | +5.3% | 55.3 | 2.063 | matches C |
| sprites | 10000 | raw-buffer | 0.5139 | -2.1% | 51.4 | 2.109 | matches C |
| sprites | 10000 | overlay-struct | 0.5550 | +5.7% | 55.5 | 2.056 | matches C |
| sprites | 10000 | overlay-class | 0.5405 | +3.0% | 54.0 | 2.044 | matches C |
| text | 1000 | c | 8.4811 | +0.0% | 8481.1 | 9.543 | matches C |
| text | 1000 | swift | 8.5243 | +0.5% | 8524.3 | 9.575 | matches C |
