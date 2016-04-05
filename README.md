# s2Converter

Convert Sentinel-2 JPEG2000 Tile image store on Amazon S3 into human readable RGB JPEG / TIFF image

    Usage s2Converter.sh [-i] [-o] [-f] [-w] [-n] [-h] [-K]

        -i | --input S2 tile directory or path to Amazon S3 bucket tile directory (e.g. aws:38/S/KC/2016/3/18)"
        -o | --output Output directory (default current directory)
        -f | --format Output format (i.e. GTiff or JPEG - default JPEG)
        -w | --width Output width in pixels (Default same size as input image)
        -q | --quality Output quality between 1 and 100 (For JPEG output only - default is no degradation (i.e. 100))
        -y | --ycbr Add a "PHOTOMETRIC=YCBCR" option to gdal_translate
        -n | --no-clean Do not remove intermediate files"
        -K | --use-kakadu Use kdu_exand instead of gdal to uncompress JPEG2000 files (WARNING! Kakadu must be installed)"
        -h | --help show this help

    Note: this script requires gdal with JP2000 reading support and/or kdu_expand application from [Kakadu](http://kakadusoftware.com/downloads/)

## Examples

### Make a 1000x1000 JPEG quicklook from a tile located on [Amazon S3 storage](http://sentinel-s2-l1c.s3-website.eu-central-1.amazonaws.com/)

    s2Converter.sh -w 1000 -o output -i aws:30/T/YN/2015/12/3

### Make a 1000x1000 JPEG quicklook from the same local tile S2A_OPER_MSI_L1C_TL_SGS__20151203T163340_A002336_T30TYN_N02.00

    s2Converter.sh -w 1000 -o output -i S2A_OPER_MSI_L1C_TL_SGS__20151203T163340_A002336_T30TYN_N02.00

![quicklook](https://raw.githubusercontent.com/jjrom/s2Converter/master/output/30_T_YN_2015_12_3.jpg)
