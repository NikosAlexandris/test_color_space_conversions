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

# Test roundtrip for all bitnesses from 6 to 16
for BAND in lsat7_2002_10 lsat7_2002_20 lsat7_2002_30 ;do
    echo "${BAND}:"
    for BITS in $(seq 6 16) ;do
        TO=$(echo 2^${BITS}-1 |bc)
        MIN=$(r.info -r "$BAND" |grep ^min=)
        MAX=$(r.info -r "$BAND" |grep ^max=)
        r.rescale --o \
            $BAND \
            from=${MIN#*=},${MAX#*=} \
            output=${BAND}_${BITS} \
            to=${MIN#*=},${TO}
    done 
    echo 
done

for BITS in $(seq 6 16) ;do
    i.rgb.his --o --q \
        r=lsat7_2002_30_${BITS} \
        g=lsat7_2002_20_${BITS} \
        bl=lsat7_2002_10_${BITS} \
        h=h${BITS} \
        i=i${BITS} \
        s=s${BITS} \
        bits=$BITS
done

for BITS in $(seq 6 16) ;do
    i.his.rgb --o --q \
    h=h${BITS} \
    i=i${BITS} \
    s=s${BITS} \
    r=r${BITS} \
    g=g${BITS} \
    bl=b${BITS} \
    bits=$BITS
done

for BITS in $(seq 6 16) ;do
    echo $BITS
    for VALUE in lsat7_2002_30_ lsat7_2002_20_ lsat7_2002_10_ h i s r g b ;do
        echo $(echo "${VALUE}${BITS}:" && r.info -r ${VALUE}${BITS})
    done
    echo
done


# remove test maps
echo "Removing test maps"
g.remove --q raster pattern=[rgb]* -f
g.remove --q raster pattern=[his]* -f
g.remove --q raster pattern=lsat7_2002_?0_* -f  # Best to use temporary map names!
