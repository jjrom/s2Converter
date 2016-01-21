# s2Converter

Convert Sentinel-2 JPEG2000 Tile image into human readable RGB JPEG / TIFF image

    Usage s2Converter.sh [-i] [-o] [-f] [-w] [-n] [-h]

        -i | --input S2 tile directory
        -o | --output Output directory (default current directory)
        -f | --format Output format (i.e. GTiff or JPEG - default JPEG)
        -w | --width Output width in pixels (Default same size as input image)
        -n | --no-clean Do not remove intermediate files
        -h | --help show this help

    Note: this script requires gdal with JP2000 reading support

Example: to make a 1000x1000 JPEG quicklook from tile S2A_OPER_MSI_L1C_TL_SGS__20151203T163340_A002336_T30TYN_N02.00

    s2Converter.sh -w 1000 -o output -i S2A_OPER_MSI_L1C_TL_SGS__20151203T163340_A002336_T30TYN_N02.00


![quicklook](https://raw.githubusercontent.com/jjrom/s2Converter/master/output/S2A_OPER_MSI_L1C_TL_SGS__20151203T163340_A002336_T30TYN.jpg)

Notes :

* JPEG2000 to GeoTIFF conversion is pretty long with OpenJPEG driver. Test should be performed using other jpeg2000 drivers
* the 16bits to 8 bits conversion use an empiric stretching with values in a range [200, 2000].
Next version should use the histogram values from each band to have a better color rendering
