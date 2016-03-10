#! /bin/bash
#
# Convert Sentinel-2 13 bands JPEG2000 Tile image into human readable
# RGB JPEG / TIFF image 
#
# Author : Jérôme Gasperi (https://github.com/jjrom)
# Date   : 2016.01.20
#

function showUsage {
    echo ""
    echo "   Convert Sentinel-2 13 bands JPEG2000 Tile image into human readable RGB JPEG / TIFF image"
    echo ""
    echo "   Usage $0 [-i] [-o] [-f] [-w] [-q] [-y] [-n] [-h]"
    echo ""
    echo "      -i | --input S2 tile directory"
    echo "      -o | --output Output directory (default current directory)"
    echo "      -f | --format Output format (i.e. GTiff or JPEG - default JPEG)"
    echo "      -w | --width Output width in pixels (Default same size as input image)"
    echo "      -q | --quality Output quality between 1 and 100 (For JPEG output only - default is no degradation (i.e. 100))"
    echo "      -y | --ycbr Add a "PHOTOMETRIC=YCBCR" option to gdal_translate"
    echo "      -n | --no-clean Do not remove intermediate files"
    echo "      -h | --help show this help"
    echo ""
    echo "   Note: this script requires gdal with JP2000 reading support"
    echo ""
}

# Parsing arguments with value
while [[ $# > 1 ]]
do
	key="$1"
	
	case $key in
        -i|--input)
            INPUT_DIRECTORY="$2"
            shift # past argument
            ;;
        -o|--output)
            OUTPUT_DIRECTORY="$2"
            shift # past argument
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift # past argument
            ;;
        -w|--width)
            OUTPUT_WIDTH="$2"
            shift # past argument
            ;;
        -q|--quality)
            OUTPUT_QUALITY="$2"
            shift # past argument
            ;;
            *)
        # unknown option
        shift # past argument
        ;;
	esac
	shift # past argument or value
done

# Parsing arguments without value
while [[ $# > 0 ]]
do
	key="$1"
    
	case $key in
        -n|--no-clean)
            CLEAN=1
            shift # past argument
            ;;
        -y|--ycbr)
            YCBR="-co PHOTOMETRIC=YCBCR"
            shift # past argument
            ;;
        -h|--help)
            showUsage
            exit 0
            shift # past argument
            ;;
            *)
        shift # past argument
        # unknown option
        ;;
	esac
done

if [ "${INPUT_DIRECTORY}" == "" ]
then
    showUsage
    echo ""
    echo "   ** Missing mandatory S2 tile directory ** ";
    echo ""
    exit 0
fi

if [ "${OUTPUT_DIRECTORY}" == "" ]
then
    OUTPUT_DIRECTORY=`pwd`
fi

if [ "${OUTPUT_FORMAT}" == "" ]
then
    OUTPUT_FORMAT=JPEG
fi

if [ "${OUTPUT_QUALITY}" == "" ]
then
    OUTPUT_QUALITY=100
fi

# Create output directory
mkdir -p $OUTPUT_DIRECTORY

# Tile identifier extracted from the output directory
TILE_ID=`basename $INPUT_DIRECTORY | rev | cut -c 8- | rev`

# Convert each band to RGB at the right size
echo " --> Convert JP2 band B04 (Red) to TIF"
gdal_translate -of GTiff ${INPUT_DIRECTORY}/IMG_DATA/${TILE_ID}_B04.jp2 $OUTPUT_DIRECTORY/${TILE_ID}_B04.tif
echo " --> Convert JP2 band B03 (Green) to TIF"
gdal_translate -of GTiff ${INPUT_DIRECTORY}/IMG_DATA/${TILE_ID}_B03.jp2 $OUTPUT_DIRECTORY/${TILE_ID}_B03.tif
echo " --> Convert JP2 band B02 (Blue) to TIF"
gdal_translate -of GTiff ${INPUT_DIRECTORY}/IMG_DATA/${TILE_ID}_B02.jp2 $OUTPUT_DIRECTORY/${TILE_ID}_B02.tif

if [ "${OUTPUT_WIDTH}" != "" ]
then
    echo " --> Resize band B04 (Red) to $OUTPUT_WIDTH pixels width"
    gdalwarp -ts $OUTPUT_WIDTH 0 $OUTPUT_DIRECTORY/${TILE_ID}_B04.tif $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B04.tif
    mv $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B04.tif $OUTPUT_DIRECTORY/${TILE_ID}_B04.tif
    echo " --> Resize band B03 (Green) to $OUTPUT_WIDTH pixels width"
    gdalwarp -ts $OUTPUT_WIDTH 0 $OUTPUT_DIRECTORY/${TILE_ID}_B03.tif $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B03.tif
    mv $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B03.tif $OUTPUT_DIRECTORY/${TILE_ID}_B03.tif
    echo " --> Resize band B02 (Blue) to $OUTPUT_WIDTH pixels width"
    gdalwarp -ts $OUTPUT_WIDTH 0 $OUTPUT_DIRECTORY/${TILE_ID}_B02.tif $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B02.tif
    mv $OUTPUT_DIRECTORY/_tmp_${TILE_ID}_B02.tif $OUTPUT_DIRECTORY/${TILE_ID}_B02.tif
fi

echo " --> Convert 16 bits to 8 bits"
gdal_translate -ot Byte -scale 200 2000 $OUTPUT_DIRECTORY/${TILE_ID}_B04.tif $OUTPUT_DIRECTORY/${TILE_ID}_B04_8bits.tif
gdal_translate -ot Byte -scale 200 2000 $OUTPUT_DIRECTORY/${TILE_ID}_B03.tif $OUTPUT_DIRECTORY/${TILE_ID}_B03_8bits.tif
gdal_translate -ot Byte -scale 200 2000 $OUTPUT_DIRECTORY/${TILE_ID}_B02.tif $OUTPUT_DIRECTORY/${TILE_ID}_B02_8bits.tif

echo " --> Merge bands into one single file"
gdal_merge.py -of GTiff -separate -o ${OUTPUT_DIRECTORY}/${TILE_ID}_uncompressed.tif $OUTPUT_DIRECTORY/${TILE_ID}_B04_8bits.tif $OUTPUT_DIRECTORY/${TILE_ID}_B03_8bits.tif $OUTPUT_DIRECTORY/${TILE_ID}_B02_8bits.tif
gdal_translate ${YCBR} -co COMPRESS=JPEG -co JPEG_QUALITY=${OUTPUT_QUALITY} $OUTPUT_DIRECTORY/${TILE_ID}_uncompressed.tif $OUTPUT_DIRECTORY/${TILE_ID}.tif

if [ "${OUTPUT_FORMAT}" == "JPEG" ]
then
    echo " --> Convert to JPEG"
    gdal_translate ${YCBR} -co JPEG_QUALITY=${OUTPUT_QUALITY} -of JPEG ${OUTPUT_DIRECTORY}/${TILE_ID}.tif ${OUTPUT_DIRECTORY}/${TILE_ID}.jpg
fi

if [ "${CLEAN}" == "" ]
then
    echo " --> Clean intermediate files"
    rm $OUTPUT_DIRECTORY/${TILE_ID}_B0*.tif $OUTPUT_DIRECTORY/${TILE_ID}_uncompressed.tif 
    if [ "${OUTPUT_FORMAT}" == "JPEG" ]
    then
        rm $OUTPUT_DIRECTORY/${TILE_ID}.tif
    fi
fi

echo "Finished :)"
echo ""
