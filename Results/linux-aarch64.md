| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 100 | c | 0.0128 | +0.0% | 128.0 | 2.424 | matches C |
| sprites | 100 | raw-array | 0.0139 | +8.6% | 139.0 | 2.380 | matches C |
| sprites | 100 | raw-buffer | 0.0120 | -6.2% | 120.0 | 2.458 | matches C |
| sprites | 100 | overlay-struct | 0.0130 | +1.6% | 130.0 | 2.340 | matches C |
| sprites | 100 | overlay-span | 0.0129 | +0.8% | 129.0 | 2.492 | matches C |
| sprites | 100 | overlay-class | 0.0150 | +17.2% | 150.0 | 2.443 | matches C |
| sprites | 1000 | c | 0.0681 | +0.0% | 68.1 | 4.646 | matches C |
| sprites | 1000 | raw-array | 0.0763 | +12.0% | 76.3 | 4.640 | matches C |
| sprites | 1000 | raw-buffer | 0.0656 | -3.7% | 65.6 | 4.508 | matches C |
| sprites | 1000 | overlay-struct | 0.0760 | +11.6% | 76.0 | 4.841 | matches C |
| sprites | 1000 | overlay-span | 0.0638 | -6.3% | 63.8 | 4.704 | matches C |
| sprites | 1000 | overlay-class | 0.0815 | +19.7% | 81.5 | 4.670 | matches C |
| sprites | 10000 | c | 0.6734 | +0.0% | 67.3 | 24.469 | matches C |
| sprites | 10000 | raw-array | 0.8035 | +19.3% | 80.4 | 24.604 | matches C |
| sprites | 10000 | raw-buffer | 0.6752 | +0.3% | 67.5 | 24.413 | matches C |
| sprites | 10000 | overlay-struct | 0.7688 | +14.2% | 76.9 | 24.675 | matches C |
| sprites | 10000 | overlay-span | 0.6985 | +3.7% | 69.8 | 24.512 | matches C |
| sprites | 10000 | overlay-class | 0.8071 | +19.9% | 80.7 | 24.619 | matches C |
| text | 100 | c | 0.7822 | +0.0% | 7822.0 | 17.395 | matches C |
| text | 100 | swift | 0.7886 | +0.8% | 7886.0 | 17.372 | matches C |
| text | 1000 | c | 8.6989 | +0.0% | 8698.9 | 141.446 | matches C |
| text | 1000 | swift | 8.2135 | -5.6% | 8213.5 | 139.363 | matches C |
