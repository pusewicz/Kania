| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 1000 | c | 0.0538 | +0.0% | 53.8 | 9.729 | matches C |
| sprites | 1000 | raw-buffer | 0.0530 | -1.5% | 53.0 | 7.118 | matches C |
| sprites | 1000 | overlay-span | 0.0542 | +0.7% | 54.2 | 6.622 | matches C |
| sprites | 1000 | overlay-span-inplace | 0.0523 | -2.8% | 52.3 | 8.493 | matches C |
| sprites | 10000 | c | 0.5193 | +0.0% | 51.9 | 16.464 | matches C |
| sprites | 10000 | raw-buffer | 0.5268 | +1.4% | 52.7 | 16.574 | matches C |
| sprites | 10000 | overlay-span | 0.5491 | +5.7% | 54.9 | 16.583 | matches C |
| sprites | 10000 | overlay-span-inplace | 0.5255 | +1.2% | 52.6 | 16.677 | matches C |
