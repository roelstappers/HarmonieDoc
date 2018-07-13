#!/usr/bin/env python
#
# Python script to convert from the GMTED2010 GeoTIFF format
# to the binary format used for the HARMONIE PGD setup.
#

import sys
try:
    import gdal
except Exception:
    print "No GDAL available"
    sys.exit(1)

infile=sys.argv[1]
outfile=sys.argv[2]
ds = gdal.Open(infile)
b = ds.GetRasterBand(1)
# Open a filehandler in append mode
f = open(outfile, 'a')
# Do the processing one scanline at a time:
for iY in range(ds.RasterYSize):
    # Read one line of infile
    data = b.ReadAsArray(0,iY,ds.RasterXSize,1)
    # Set all missing values to 0 meter height: 
    sel = (data==-32768)
    data[sel] = 0 
    # Write one line to outfile
    data.byteswap().astype('int16').tofile(f)
f.close()
sys.exit(0)
