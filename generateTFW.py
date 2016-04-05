# Written by Jerome Gasperi (jerome dot gasperi at gmail dot com), 2016
# Based on code written by MerseyViking (mersey dot viking at gmail dot com), 2011.
# Released into the public domain - April 4, 2016
# I accept no responsibility for any errors or loss of data, revenue, or life this script may cause. Use at your own risk.

import osgeo.gdal as gdal
import osgeo.osr as osr
import os
import sys

def generate_tfw(infile):
    src = gdal.Open(infile)
    xform = src.GetGeoTransform()
    edit1=xform[0]+xform[1]/2
    edit2=xform[3]+xform[5]/2
    tfw = open(os.path.splitext(infile)[0] + '.tfw', 'wt')
    tfw.write("%0.8f\n" % xform[1])
    tfw.write("%0.8f\n" % xform[2])
    tfw.write("%0.8f\n" % xform[4])
    tfw.write("%0.8f\n" % xform[5])
    tfw.write("%0.8f\n" % edit1)
    tfw.write("%0.8f\n" % edit2)
    tfw.close()

if __name__ == '__main__':
    generate_tfw(sys.argv[1])
