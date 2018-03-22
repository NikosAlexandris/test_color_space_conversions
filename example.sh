#!/bin/bash -

#===============================================================================
#
#          FILE: example.sh
#
#         USAGE: ./example.sh
#
#   DESCRIPTION:
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES:
#                On using i.pansharpen: it is impossible to use it with the
#                "new" i.rgb.his and i.his.rgb modules. `i.pansharpen` assumes
#                that images have 256 integer grey values, see author's comment:
#                <https://lists.osgeo.org/pipermail/grass-dev/2013-November/066342.html>
#
#        AUTHOR: Nikos Alexandris (), nik@nikosalexandris.net
#  ORGANIZATION:
#       CREATED: 03/22/2018 12:53
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

# There is some "loss" or "smoothing" after the roundtrip. Note, for red the
# minimum is now `0.99` and not `1`.

MINIMUM_BITNESS=$1
MAXIMUM_BITNESS=$2
BLUE_IMAGE=$3
GREEN_IMAGE=$4
RED_IMAGE=$5
RGB_IMAGES="$RED_IMAGE $GREEN_IMAGE $BLUE_IMAGE"
BLUE_IMAGE_PREFIX="${BLUE_IMAGE}_"
GREEN_IMAGE_PREFIX="${GREEN_IMAGE}_"
RED_IMAGE_PREFIX="${RED_IMAGE}_"
RGB_IMAGE_PREFIXES="$RED_IMAGE_PREFIX $GREEN_IMAGE_PREFIX $BLUE_IMAGE_PREFIX"

# Test roundtrip for all bitnesses from $MINIMUM_BITNESS to $MAXIMUM_BITNESS
for IMAGE in $RGB_IMAGES ;do
    echo "${IMAGE}:"
    for BITS in $(seq $MINIMUM_BITNESS  $MAXIMUM_BITNESS) ;do
        TO=$(echo 2^${BITS}-1 |bc)
        MIN=$(r.info -r "$IMAGE" |grep ^min=)
        MAX=$(r.info -r "$IMAGE" |grep ^max=)
        r.rescale --o \
            $IMAGE \
            from=${MIN#*=},${MAX#*=} \
            output=${IMAGE}_${BITS} \
            to=${MIN#*=},${TO}
    done
    echo
done

for BITS in $(seq $MINIMUM_BITNESS  $MAXIMUM_BITNESS) ;do

    echo $BITS

    i.rgb.his --o --q \
        r="${RED_IMAGE_PREFIX}${BITS}" \
        g="${GREEN_IMAGE_PREFIX}${BITS}" \
        bl="${BLUE_IMAGE_PREFIX}${BITS}" \
        h=h${BITS} \
        i=i${BITS} \
        s=s${BITS} \
        bits=$BITS

    i.his.rgb --o --q \
    h=h${BITS} \
    i=i${BITS} \
    s=s${BITS} \
    r=r${BITS} \
    g=g${BITS} \
    bl=b${BITS} \
    bits=$BITS

    for VALUE in $RGB_IMAGE_PREFIXES h i s r g b ;do
        echo $(echo "${VALUE}${BITS}:" && r.info -r ${VALUE}${BITS})
    done
    echo
done

# remove test maps
echo "Removing test maps"
g.remove --q raster pattern=[rgb]* -f
g.remove --q raster pattern=[his]* -f
g.remove --q raster pattern=lsat7_2002_?0_* -f  # Best to use temporary map names!
