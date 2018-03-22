# check range of Landsat bands
for BAND in 10 20 30; do echo `echo -e "Landsat band ${BAND}: " && r.info -r lsat7_2002_${BAND}` ;done

Landsat band 10: min=42 max=255  # this is blue
Landsat band 20: min=28 max=255  # this is green
Landsat band 30: min=1 max=255   # this is red

# convert (rgb) to his, 8-bit
i.rgb.his r=lsat7_2002_30 g=lsat7_2002_20 bl=lsat7_2002_10 h=h8 i=i8 s=s8

# rescale to 16-bit in order to test the `bits` option
for BAND in 10 20 30; do r.rescale lsat7_2002_$BAND from=0,255 output=lsat7_2002_${BAND}_16 to=0,65535 ;done

Rescale lsat7_2002_10[0,255] to lsat7_2002_10_16[0,65535]
Rescale lsat7_2002_20[0,255] to lsat7_2002_20_16[0,65535]
Rescale lsat7_2002_30[0,255] to lsat7_2002_30_16[0,65535]

# convert again, bits=16
i.rgb.his r=lsat7_2002_30_16 g=lsat7_2002_20_16 bl=lsat7_2002_10_16 h=h16 i=i16 s=s16 bits=16

# check h, i, s output ranges, 8 & 16-bit
for DIMENSION in h i s; do echo `echo "${DIMENSION}  8:" && r.info -r ${DIMENSION}8` && echo `echo -e "${DIMENSION} 16:" && r.info -r ${DIMENSION}16` ;done

h 8: min=0 max=359.434
h 16: min=0 max=359.434
i 8: min=0.08431373 max=1
i 16: min=0.08431373 max=1
s 8: min=0 max=1
s 16: min=0 max=1

# convert (his) back to rgb
i.his.rgb h=h8 i=i8 s=s8 r=r8 g=g8 bl=b8 bits=8
i.his.rgb h=h16 i=i16 s=s16 r=r16 g=g16 bl=b16 bits=16

# check rgb ranges
for COLOR in r g b; do echo `echo "${COLOR}  8:" && r.info -r ${COLOR}8` && echo `echo -e "${COLOR} 16:" && r.info -r ${COLOR}16` ;done

r 8: min=0 max=255
r 16: min=256 max=65535
g 8: min=28 max=255
g 16: min=7195.999 max=65535
b 8: min=42 max=255
b 16: min=10794 max=65535

# There is some "loss" or "smoothing" after the roundtrip. Note, for red the
# minimum is now `1` and not `0`.


# Some stats to verify

# input 8-bit Landsat 7 bands
for BAND in 10 20 30; do echo "lsat7_2002_${BAND} (8-bit): " && r.univar -g --q lsat7_2002_${BAND} && echo -e '\n' ;done

lsat7_2002_10 (8-bit):
n=250325
null_cells=0
cells=250325
min=42
max=255
range=213
mean=85.473624288425
mean_of_abs=85.473624288425
stddev=20.6960320098858
variance=428.325740954217
coeff_var=24.2133549175924
sum=21396185

lsat7_2002_20 (8-bit):
n=250325
null_cells=0
cells=250325
min=28
max=255
range=227
mean=70.9216418655748
mean_of_abs=70.9216418655748
stddev=23.3183338152895
variance=543.744691921275
coeff_var=32.8790101327423
sum=17753460

lsat7_2002_30 (8-bit):
n=250325
null_cells=0
cells=250325
min=1
max=255
range=254
mean=66.6989074203535
mean_of_abs=66.6989074203535
stddev=34.7033706761684
variance=1204.32393628754
coeff_var=52.029893769412
sum=16696404

# rescaled to 16-bit Landsat 7 bands
for BAND in 10 20 30; do echo "lsat7_2002_${BAND} (16-bit): " && r.univar -g --q lsat7_2002_${BAND}_16 && echo -e '\n' ;done

lsat7_2002_10 (16-bit):
n=250325
null_cells=0
cells=250325
min=10794
max=65535
range=54741
mean=21966.7214421252
mean_of_abs=21966.7214421252
stddev=5318.88022654064
variance=28290486.8642851
coeff_var=24.2133549175924
sum=5498819545

lsat7_2002_20 (16-bit):
n=250325
null_cells=0
cells=250325
min=7196
max=65535
range=58339
mean=18226.8619594527
mean_of_abs=18226.8619594527
stddev=5992.81179052941
variance=35913793.1567083
coeff_var=32.8790101327423
sum=4562639220

lsat7_2002_30 (16-bit):
n=250325
null_cells=0
cells=250325
min=257
max=65535
range=65278
mean=17141.6192070309
mean_of_abs=17141.6192070309
stddev=8918.76626377528
variance=79544391.667856
coeff_var=52.029893769412
sum=4290975828

# his, 8-bit
for DIMENSION in h i s; do echo "${DIMENSION} (8-bit): " && r.univar -g --q ${DIMENSION}8 && echo -e '\n' ;done

h (8-bit):
n=250007
null_cells=318
cells=250325
min=0
max=359.433959960938
range=359.433959960938
mean=232.677368810375
mean_of_abs=232.677368810375
stddev=47.0943195962118
variance=2217.87493823014
coeff_var=20.2401805714901
sum=58170970.9441754

i (8-bit):
n=250325
null_cells=0
cells=250325
min=0.084313727915287
max=1
range=0.915686272084713
mean=0.294945252267712
mean_of_abs=0.294945252267712
stddev=0.10312914101826
variance=0.0106356197271642
coeff_var=34.9655199483101
sum=73832.1702739149

s (8-bit):
n=250325
null_cells=0
cells=250325
min=0
max=1
range=1
mean=0.188441316597818
mean_of_abs=0.188441316597818
stddev=0.105874696347741
variance=0.0112094513267264
coeff_var=56.1844388795609
sum=47171.5725773489

# his, 16-bit
for DIMENSION in h i s; do echo "${DIMENSION} (16-bit): " && r.univar -g --q ${DIMENSION}16 && echo -e '\n' ;done

h (16-bit):
n=250007
null_cells=318
cells=250325
min=0
max=359.433959960938
range=359.433959960938
mean=232.677368810375
mean_of_abs=232.677368810375
stddev=47.0943195962118
variance=2217.87493823014
coeff_var=20.2401805714901
sum=58170970.9441754

i (16-bit):
n=250325
null_cells=0
cells=250325
min=0.084313727915287
max=1
range=0.915686272084713
mean=0.294945252267712
mean_of_abs=0.294945252267712
stddev=0.10312914101826
variance=0.0106356197271642
coeff_var=34.9655199483101
sum=73832.1702739149

s (16-bit):
n=250325
null_cells=0
cells=250325
min=0
max=1
range=1
mean=0.188441316597818
mean_of_abs=0.188441316597818
stddev=0.105874696347741
variance=0.0112094513267264
coeff_var=56.1844388795609
sum=47171.5725773489

# colors, 8-bit
for COLOR in r g b; do echo "${COLOR} (8-bit):" && r.univar -g --q ${COLOR}8 &&
    echo -e '\n' ;done
r (8-bit):
n=250007
null_cells=318
cells=250325
min=0
max=255
range=255
mean=66.2976036670973
mean_of_abs=66.2976036670973
stddev=34.0979922976592
variance=1162.67307873122
coeff_var=51.4317115726787
sum=16574865

g (8-bit):
n=250007
null_cells=318
cells=250325
min=27.9999961853027
max=255
range=227.000003814697
mean=70.6895694237074
mean_of_abs=70.6895694237074
stddev=22.3983713595429
variance=501.687039559992
coeff_var=31.6855393831711
sum=17672887.1829128

b (8-bit):
n=250007
null_cells=318
cells=250325
min=42
max=255
range=213
mean=85.2600618087387
mean_of_abs=85.2600618087387
stddev=19.8145003705753
variance=392.614424935528
coeff_var=23.2400727259904
sum=21315612.2726173

# colors, 16-bit
for COLOR in r g b; do echo "${COLOR} (16-bit):" && r.univar -g --q ${COLOR}16 && echo -e '\n' ;done

r (16-bit):
n=250007
null_cells=318
cells=250325
min=256
max=65535
range=65279
mean=17080.4321518997
mean_of_abs=17080.4321518997
stddev=8757.35508357642
variance=76691268.0598418
coeff_var=51.2712734999647
sum=4270227601

g (16-bit):
n=250007
null_cells=318
cells=250325
min=7195.9990234375
max=65535
range=58339.0009765625
mean=18167.2193426611
mean_of_abs=18167.2193426611
stddev=5756.38144044411
variance=33135927.2878894
coeff_var=31.6855393875644
sum=4541932006.20068

b (16-bit):
n=250007
null_cells=318
cells=250325
min=10794
max=65535
range=54741
mean=21911.8358886264
mean_of_abs=21911.8358886264
stddev=5092.32659532506
variance=25931790.1534549
coeff_var=23.2400727223788
sum=5478112355.00781

# Pan-Sharpening

# using i.pansharpen is impossible (at the moment?) because it assumes that
# images have 256 integer grey values.
# see author's comment: "https://lists.osgeo.org/pipermail/grass-dev/2013-November/066342.html
