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

# check range of 8-bit Landsat bands
echo -e "Check range of 8-bit Landsat bands 10, 20 and 30\n"
for BAND in 10 20 30; do
    echo `echo -e "Landsat band ${BAND}: " && r.info -r lsat7_2002_${BAND}`
done
echo

# rescale to 16-bit in order to test the `bits` option
echo -e "Rescale Landsat bands 10, 20 and 30 to 16-bit\n"
for BAND in 10 20 30; do
    r.rescale lsat7_2002_$BAND from=0,255 output=lsat7_2002_${BAND}_16 to=0,65535
done
echo

# convert (rgb) to his, 8-bit
echo -e "Convert color space from 8-bit RGB to HSL\n"
i.rgb.his --q r=lsat7_2002_30 g=lsat7_2002_20 bl=lsat7_2002_10 h=h8 i=i8 s=s8

# convert again, bits=16
echo -e "Convert color space from 16-bit RGB to HSL\n"
i.rgb.his --q r=lsat7_2002_30_16 g=lsat7_2002_20_16 bl=lsat7_2002_10_16 h=h16 i=i16 s=s16 bits=16

# check h, i, s output ranges, 8 & 16-bit
echo -e "Check range of Hue, Intensity and Saturation maps for both 8- and 16-bit:\n"
for DIMENSION in h i s; do
    echo $(echo "${DIMENSION}  8:" r.info -r ${DIMENSION}8)
    echo $(echo -e "${DIMENSION} 16:" && r.info -r ${DIMENSION}16)
done
echo

# convert (his) back to rgb
echo -e "Convert color space from HSL to 8-bit RGB\n"
i.his.rgb --q h=h8 i=i8 s=s8 r=r8 g=g8 bl=b8 bits=8

echo -e "Convert color space from HSL to 16-bit RGB\n"
i.his.rgb --q h=h16 i=i16 s=s16 r=r16 g=g16 bl=b16 bits=16

# check rgb ranges
echo -e "Check range of Red, Green and Blue maps after roundtrip, for both 8- and 16-bit:\n"
for COLOR in r g b; do
    echo $(echo "${COLOR}  8:" && r.info -r ${COLOR}8)
    echo $(echo -e "${COLOR} 16:" && r.info -r ${COLOR}16)
done
echo

# There is some "loss" or "smoothing" after the roundtrip. Note, for red the
# minimum is now `0.99` and not `1`.

# Some stats to verify

# input 8-bit Landsat 7 bands
echo -e "Input 8-bit Landsat 7 bands\n"
for BAND in 10 20 30; do
    echo "lsat7_2002_${BAND} (8-bit): "
    r.univar -g --q lsat7_2002_${BAND}
    echo -e '\n'
done

# rescaled to 16-bit Landsat 7 bands
echo -e "Rescaled to 16-bit Landsat 7 bands\n"
for BAND in 10 20 30; do
    echo "lsat7_2002_${BAND} (16-bit): "
    r.univar -g --q lsat7_2002_${BAND}_16
    echo -e '\n'
done

# his, 8-bit
echo -e "HIS, 8-bit\n"
for DIMENSION in h i s; do
    echo "${DIMENSION} (8-bit): "
    r.univar -g --q ${DIMENSION}8
    echo -e '\n'
done

# his, 16-bit
echo -e "HIS, 16-bit\n"
for DIMENSION in h i s; do
    echo "${DIMENSION} (16-bit): "
    r.univar -g --q ${DIMENSION}16
    echo -e '\n'
done

# colors, 8-bit
echo -e "Colors, 8-bit\n"
for COLOR in r g b; do
    echo "${COLOR} (8-bit):"
    r.univar -g --q ${COLOR}8
    echo -e '\n'
done

# colors, 16-bit
echo -e "Colors, 16-bit\n"
for COLOR in r g b; do
    echo "${COLOR} (16-bit):"
    r.univar -g --q ${COLOR}16
    echo -e '\n'
done


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
print "Removing test maps"
g.remove --q raster pattern=[rgb]* -f
g.remove --q raster pattern=[his]* -f
g.remove --q raster pattern=lsat7_2002_?0_* -f  # Best to use temporary map names!
