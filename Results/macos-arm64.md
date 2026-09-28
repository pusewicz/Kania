| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 100 | c | 0.0063 | +0.0% | 63.0 | 2.578 | matches C |
| sprites | 100 | raw-array | 0.0076 | +20.6% | 76.0 | 2.880 | matches C |
| sprites | 100 | raw-buffer | 0.0063 | +0.0% | 63.0 | 2.645 | matches C |
| sprites | 100 | overlay-struct | 0.0075 | +19.0% | 75.0 | 2.719 | matches C |
| sprites | 100 | overlay-span | 0.0071 | +12.7% | 71.0 | 2.529 | matches C |
| sprites | 100 | overlay-class | 0.0080 | +27.0% | 80.0 | 2.691 | matches C |
| sprites | 1000 | c | 0.0493 | +0.0% | 49.3 | 2.623 | matches C |
| sprites | 1000 | raw-array | 0.0646 | +31.0% | 64.6 | 2.772 | matches C |
| sprites | 1000 | raw-buffer | 0.0504 | +2.2% | 50.4 | 2.384 | matches C |
| sprites | 1000 | overlay-struct | 0.0589 | +19.5% | 58.9 | 2.505 | matches C |
| sprites | 1000 | overlay-span | 0.0548 | +11.2% | 54.8 | 2.658 | matches C |
| sprites | 1000 | overlay-class | 0.0665 | +34.9% | 66.5 | 2.635 | matches C |
| sprites | 10000 | c | 0.5317 | +0.0% | 53.2 | 2.098 | matches C |
| sprites | 10000 | raw-array | 0.6268 | +17.9% | 62.7 | 2.192 | matches C |
| sprites | 10000 | raw-buffer | 0.5233 | -1.6% | 52.3 | 2.146 | matches C |
| sprites | 10000 | overlay-struct | 0.5786 | +8.8% | 57.9 | 2.180 | matches C |
| sprites | 10000 | overlay-span | 0.5256 | -1.1% | 52.6 | 2.414 | matches C |
| sprites | 10000 | overlay-class | 0.6436 | +21.0% | 64.4 | 2.417 | matches C |
| text | 100 | c | 0.8350 | +0.0% | 8350.0 | 2.969 | matches C |
| text | 100 | swift | 0.8078 | -3.3% | 8078.0 | 3.351 | matches C |
| text | 1000 | c | 8.4629 | +0.0% | 8462.9 | 9.590 | matches C |
| text | 1000 | swift | 8.5945 | +1.6% | 8594.5 | 9.874 | matches C |
