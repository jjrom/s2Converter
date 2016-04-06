#! /bin/bash
#
# Convert Sentinel-2 13 bands JPEG2000 Tile image into human readable
# RGB JPEG / TIFF image 
#
# Author : Jérôme Gasperi (https://github.com/jjrom)
# Date   : 2016.01.20
#
# Licensed under the Apache License, version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

function showUsage {
    echo ""
    echo "   Convert Sentinel-2 13 bands JPEG2000 Tile image into human readable RGB JPEG / TIFF image"
    echo ""
    echo "   Usage $0 [-i] [-o] [-f] [-w] [-q] [-y] [-n] [-K] [-h]"
    echo ""
    echo "      -i | --input S2 tile directory or path to Amazon S3 bucket tile directory (e.g. aws:38/S/KC/2016/3/18)"
    echo "      -o | --output Output directory (default current directory)"
    echo "      -f | --format Output format (i.e. GTiff or JPEG - default JPEG)"
    echo "      -w | --width Output width in pixels (Default same size as input image)"
    echo "      -q | --quality Output quality between 1 and 100 (For JPEG output only - default is no degradation (i.e. 100))"
    echo "      -y | --ycbr Add a "PHOTOMETRIC=YCBCR" option to gdal_translate"
    echo "      -n | --no-clean Do not remove intermediate files"
    echo "      -K | --use-kakadu Use kdu_exand instead of gdal to uncompress JPEG2000 files (WARNING! Kakadu must be installed)"
    echo "      -h | --help show this help"
    echo ""
    echo "   Note: this script requires gdal with JP2000 reading support"
    echo ""
}

function generateWorldFile {
python << EOF
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
    generate_tfw('$1')
EOF
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
        -K|--use-kakadu)
            KAKADU=1
            shift # past argument
            ;;
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
mkdir -p ${OUTPUT_DIRECTORY}

# Tile identifier extracted from the input directory
IS_AWS=`echo $INPUT_DIRECTORY | awk -F\: '{print tolower($1)}'`
if [ "${IS_AWS}" == "aws" ]
then
    TILE_ID=`echo $INPUT_DIRECTORY | awk -F\: '{print $2}' | tr '/' '_'`
    TILE_ID_WITH_EXT=${TILE_ID}
    AWS=`echo $INPUT_DIRECTORY | awk -F\: '{print "http://sentinel-s2-l1c.s3.amazonaws.com/tiles/"$2"/0"}'`
    INPUT_DIRECTORY=from_aws
    mkdir -p ${INPUT_DIRECTORY}
    if [ ! -f ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2 ]; then
        wget -O ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2 ${AWS}/B04.jp2
    else
        echo " Use local ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2 file"
    fi
    if [ ! -f ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2 ]; then
        wget -O ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2 ${AWS}/B03.jp2
    else
        echo " Use local ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2 file"
    fi
    if [ ! -f ${INPUT_DIRECTORY}/${TILE_ID}_B02.jp2 ]; then
        wget -O ${INPUT_DIRECTORY}/${TILE_ID}_B02.jp2 ${AWS}/B02.jp2
    else
        echo " Use local ${INPUT_DIRECTORY}/${TILE_ID}_B02.jp2 file"
    fi
else
    TILE_ID=`basename $INPUT_DIRECTORY | rev | cut -c 8- | rev`
    TILE_ID_WITH_EXT=`basename $INPUT_DIRECTORY`
    INPUT_DIRECTORY=${INPUT_DIRECTORY}/IMG_DATA
fi

# Convert each band to RGB at the right size
if [ "${KAKADU}" == "" ]
then
    echo " --> Convert JP2 bands B04 (Red), B03 (Green) and B02 (Blue) to TIF with gdal"
    gdal_translate -of GTiff ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2 ${OUTPUT_DIRECTORY}/${TILE_ID}_B04.tif &
    gdal_translate -of GTiff ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2 ${OUTPUT_DIRECTORY}/${TILE_ID}_B03.tif &
    gdal_translate -of GTiff ${INPUT_DIRECTORY}/${TILE_ID}_B02.jp2 ${OUTPUT_DIRECTORY}/${TILE_ID}_B02.tif &

    # Parallel executions
    wait

else
    echo " --> Convert JP2 band B04s (Red), B03 (Green) and B02 (Blue) to TIF with Kakadu"
    kdu_expand -i ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2 -o ${OUTPUT_DIRECTORY}/${TILE_ID}_B04.tif &
    kdu_expand -i ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2 -o ${OUTPUT_DIRECTORY}/${TILE_ID}_B03.tif &
    kdu_expand -i ${INPUT_DIRECTORY}/${TILE_ID}_B02.jp2 -o ${OUTPUT_DIRECTORY}/${TILE_ID}_B02.tif &

    # Parallel executions
    wait

    generateWorldFile ${INPUT_DIRECTORY}/${TILE_ID}_B04.jp2
    generateWorldFile ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2
    generateWorldFile ${INPUT_DIRECTORY}/${TILE_ID}_B03.jp2
    mv ${INPUT_DIRECTORY}/*.tfw ${OUTPUT_DIRECTORY}
fi

if [ "${OUTPUT_WIDTH}" != "" ]
then
    echo " --> Resize bands B04 (Red), B03 (Green) and B02 (Blue) to $OUTPUT_WIDTH pixels width"
    gdalwarp -ts $OUTPUT_WIDTH 0 ${OUTPUT_DIRECTORY}/${TILE_ID}_B04.tif ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B04.tif &
    gdalwarp -ts $OUTPUT_WIDTH 0 ${OUTPUT_DIRECTORY}/${TILE_ID}_B03.tif ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B03.tif &
    gdalwarp -ts $OUTPUT_WIDTH 0 ${OUTPUT_DIRECTORY}/${TILE_ID}_B02.tif ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B02.tif &

    # Parallel executions
    wait

    mv ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B04.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B04.tif
    mv ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B03.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B03.tif
    mv ${OUTPUT_DIRECTORY}/_tmp_${TILE_ID}_B02.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B02.tif
fi

echo " --> Convert 16 bits to 8 bits"
gdalenhance -ot Byte -equalize ${OUTPUT_DIRECTORY}/${TILE_ID}_B04.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B04_8bits.tif &
gdalenhance -ot Byte -equalize ${OUTPUT_DIRECTORY}/${TILE_ID}_B03.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B03_8bits.tif &
gdalenhance -ot Byte -equalize ${OUTPUT_DIRECTORY}/${TILE_ID}_B02.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B02_8bits.tif &

# Parallel executions
wait

echo " --> Merge bands into one single file"
gdal_merge.py -of GTiff -separate -o ${OUTPUT_DIRECTORY}/${TILE_ID}_uncompressed.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B04_8bits.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B03_8bits.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_B02_8bits.tif
gdal_translate ${YCBR} -co COMPRESS=JPEG -co JPEG_QUALITY=${OUTPUT_QUALITY} ${OUTPUT_DIRECTORY}/${TILE_ID}_uncompressed.tif ${OUTPUT_DIRECTORY}/${TILE_ID_WITH_EXT}.tif

if [ "${OUTPUT_FORMAT}" == "JPEG" ]
then
    echo " --> Convert to JPEG"
    gdal_translate ${YCBR} -co JPEG_QUALITY=${OUTPUT_QUALITY} -of JPEG ${OUTPUT_DIRECTORY}/${TILE_ID_WITH_EXT}.tif ${OUTPUT_DIRECTORY}/${TILE_ID_WITH_EXT}.jpg
fi

if [ "${CLEAN}" == "" ]
then
    echo " --> Clean intermediate files"
    rm ${OUTPUT_DIRECTORY}/${TILE_ID}_B0*.tif ${OUTPUT_DIRECTORY}/${TILE_ID}_uncompressed.tif ${OUTPUT_DIRECTORY}/*.aux.xml
    if [ "${KAKADU}" != "" ]
    then
        rm ${OUTPUT_DIRECTORY}/*.tfw
    fi
    if [ "${OUTPUT_FORMAT}" == "JPEG" ]
    then
        rm ${OUTPUT_DIRECTORY}/${TILE_ID_WITH_EXT}.tif
    fi
fi

echo "Finished :)"
echo ""


