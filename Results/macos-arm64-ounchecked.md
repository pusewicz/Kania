| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 100 | c | 0.0057 | +0.0% | 57.0 | 2.198 | matches C |
| sprites | 100 | raw-array | 0.0065 | +14.0% | 65.0 | 2.480 | matches C |
| sprites | 100 | raw-buffer | 0.0063 | +10.5% | 63.0 | 2.618 | matches C |
| sprites | 100 | overlay-struct | 0.0067 | +17.5% | 67.0 | 2.561 | matches C |
| sprites | 100 | overlay-class | 0.0065 | +14.0% | 65.0 | 2.290 | matches C |
| sprites | 1000 | c | 0.0469 | +0.0% | 46.9 | 2.257 | matches C |
| sprites | 1000 | raw-array | 0.0514 | +9.6% | 51.4 | 2.495 | matches C |
| sprites | 1000 | raw-buffer | 0.0457 | -2.6% | 45.7 | 2.573 | matches C |
| sprites | 1000 | overlay-struct | 0.0543 | +15.8% | 54.3 | 2.359 | matches C |
| sprites | 1000 | overlay-class | 0.0524 | +11.7% | 52.4 | 2.168 | matches C |
| sprites | 10000 | c | 0.5092 | +0.0% | 50.9 | 2.163 | matches C |
| sprites | 10000 | raw-array | 0.5320 | +4.5% | 53.2 | 2.053 | matches C |
| sprites | 10000 | raw-buffer | 0.5206 | +2.2% | 52.1 | 2.143 | matches C |
| sprites | 10000 | overlay-struct | 0.5650 | +11.0% | 56.5 | 2.051 | matches C |
| sprites | 10000 | overlay-class | 0.5289 | +3.9% | 52.9 | 2.044 | matches C |
| text | 1000 | c | 8.4154 | +0.0% | 8415.4 | 9.511 | matches C |
| text | 1000 | swift | 8.4835 | +0.8% | 8483.5 | 9.630 | matches C |
