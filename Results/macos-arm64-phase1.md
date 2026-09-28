| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 1000 | c | 0.0493 | +0.0% | 49.3 | 2.608 | matches C |
| sprites | 1000 | overlay-span | 0.0521 | +5.7% | 52.1 | 2.530 | matches C |
| sprites | 1000 | overlay-inout | 0.0544 | +10.3% | 54.4 | 2.100 | matches C |
| sprites | 1000 | overlay-unique | 0.0590 | +19.7% | 59.0 | 2.576 | matches C |
| sprites | 10000 | c | 0.5087 | +0.0% | 50.9 | 2.267 | matches C |
| sprites | 10000 | overlay-span | 0.5276 | +3.7% | 52.8 | 2.215 | matches C |
| sprites | 10000 | overlay-inout | 0.5545 | +9.0% | 55.4 | 2.219 | matches C |
| sprites | 10000 | overlay-unique | 0.5743 | +12.9% | 57.4 | 2.201 | matches C |
