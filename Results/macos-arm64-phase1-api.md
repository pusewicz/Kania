| count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---:|---|---:|---:|---:|---:|---|
| 1000 | c | 0.1399 | +0.0% | 139.9 | 2.526 | matches C |
| 1000 | overlay-span-inplace | 0.1308 | -6.5% | 130.8 | 2.972 | matches C |
| 1000 | kania | 0.1270 | -9.2% | 127.0 | 2.710 | matches C |
| 10000 | c | 0.5170 | +0.0% | 51.7 | 2.054 | matches C |
| 10000 | overlay-span-inplace | 0.5190 | +0.4% | 51.9 | 2.005 | matches C |
| 10000 | kania | 0.5454 | +5.5% | 54.5 | 1.885 | matches C |
