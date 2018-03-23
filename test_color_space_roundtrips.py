#!/usr/bin/python\<nl>\
# -*- coding: utf-8 -*-

"""
Name       Tests on RGB to HIS color space comversion
Purpose    Test for no or minimal difference between the input the and output
RGB images after a color space roundtrip from RGB to HIS and back to RGB

Source     <https://trac.osgeo.org/grass/ticket/774>

License    (C) 2018 by the GRASS Development Team
           This program is free software under the GNU General Public License
           (>=v2). Read the file COPYING that comes with GRASS for details.

:authors: Nikos Alexandris
"""

"""Libraries"""

from grass.gunittest.case import TestCase
from grass.gunittest.gmodules import SimpleModule
import grass.script as g

"""Globals"""

# PRECISION=[0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001]
PRECISION=[0.1, 0.01, 0.001]  # 0.001 will fail for >= 15-bits


#BITNESSES = [bits for bits in range(2,17)]
BITNESSES = [bits for bits in range(6,17)]  # for bitness < 2, r.rescale flaw?

IMAGES = ['lsat7_2002_10', 'lsat7_2002_20', 'lsat7_2002_30']

RGB=[255,0,0]  # to use for "random" r, g, b triplet generation

# Create in-test synthetic images?

RED_ASCII="""north:                   2
south:                   0
east:                    2
west:                    0
rows:                    2
cols:                    2
null:                -9999
type: int
multiplier: 1

0 0
0 255"""

GREEN_ASCII="""north:                   2
south:                   0
east:                    2
west:                    0
rows:                    2
cols:                    2
null:                -9999
type: int
multiplier: 1

0 0
255 0"""

BLUE_ASCII="""north:                   2
south:                   0
east:                    2
west:                    0
rows:                    2
cols:                    2
null:                -9999
type: int
multiplier: 1

0 255
0 0"""

red_image = IMAGES[2]
red_prefix = 'red'

green_image = IMAGES[1]
green_prefix = 'green'

blue_image = IMAGES[0]
blue_prefix = 'blue'

hue_prefix = 'hue'
intensity_prefix = 'intensity'
saturation_prefix = 'saturation'

"""Test Case Class"""

class TestRGB2HIS(TestCase):

    gisenv = SimpleModule('g.gisenv', get='MAPSET')
    TestCase.runModule(gisenv, expecting_stdout=True)
    print "Mapset: ", gisenv.outputs.stdout.strip()

    # TODO: replace by unified handing of maps
    to_remove = []

    def image_name(self, name, prefix, bitness):
        """
        Return a meaningful name for any map by adding the bitness as a suffix.
        To Do -- The idea is to avoid duplication of the following map names:

        red_input = red_image + '_' + bits
        green_input = green_image + '_' + bits
        blue_input = blue_image + '_' + bits

        hue = hue_prefix + '_' + bits
        intensity = intensity_prefix + '_' + bits
        saturation = saturation_prefix + '_' + bits

        red_output = red_prefix + '_' + bits
        green_output = green_prefix + '_' + bits
        blue_output = blue_prefix + '_' + bits
        """
        return name + '_' + bits

    @classmethod
    def setUpClass(cls):
        """
        Set up
        """

        # use a temporary region
        cls.use_temp_region()

        # # create input raster maps
        # cls.runModule('r.in.ascii', input='-', stdin=RED_ASCII,
        #         output='red_map')

        # cls.runModule('r.in.ascii', input='-', stdin=GREEN_ASCII,
        #         output='green_map')

        # cls.runModule('r.in.ascii', input='-', stdin=BLUE_ASCII,
        #         output='blue_map')

        # # append them in list "to_remove"
        # cls.to_remove.append('red_map')
        # cls.to_remove.append('green_map')
        # cls.to_remove.append('blue_map')

        # set region to map(s)
        cls.runModule('g.region', raster=IMAGES[0])

        for image in IMAGES:

            # print "Image:", image

            for bitness in BITNESSES:

                # print "Bitness:", bitness

                rescaled_image = image + "_" + str(bitness)

                # print "Rescaled image name:", rescaled_image

                to_min = g.raster_info(image)['min']
                to_max = 2**bitness - 1
                to_range = "{min}".format(min=to_min),"{max}".format(max=to_max)

                cls.runModule('r.rescale', overwrite=True, verbose=True,
                        input=image, output=rescaled_image, to=to_range)

        for bitness in BITNESSES:

            # print "Bitness:", bitness

            bits = str(bitness)

            red_input = red_image + '_' + bits
            green_input = green_image + '_' + bits
            blue_input = blue_image + '_' + bits

            hue = hue_prefix + '_' + bits
            intensity = intensity_prefix + '_' + bits
            saturation = saturation_prefix + '_' + bits

            red_output = red_prefix + '_' + bits
            green_output = green_prefix + '_' + bits
            blue_output = blue_prefix + '_' + bits

            cls.runModule('i.rgb.his', overwrite=True, verbose=True,
                    red = red_input, green = green_input, blue = blue_input,
                    hue = hue, intensity = intensity, saturation = saturation,
                    bits = bitness)

            cls.runModule('i.his.rgb', overwrite=True, verbose=True,
                    hue = hue, intensity = intensity, saturation = saturation,
                    red = red_output, green = green_output, blue = blue_output,
                    bits = bitness)

            cls.to_remove.append(red_input)
            cls.to_remove.append(green_input)
            cls.to_remove.append(blue_input)
            cls.to_remove.append(hue)
            cls.to_remove.append(intensity)
            cls.to_remove.append(saturation)
            cls.to_remove.append(red_output)
            cls.to_remove.append(green_output)
            cls.to_remove.append(blue_output)

    def setUp(self):
        """
        Set up region and create test raster maps
        """
        pass

    @classmethod
    def tearDownClass(cls):

        """
        Remove temporary region and test raster maps
        """
        cls.del_temp_region()
        print
        print "Removing test raster maps:\n"
        print ', '.join(cls.to_remove)
        if cls.to_remove:
            cls.runModule('g.remove', flags='f', type='raster',
                name=','.join(cls.to_remove), verbose=True)

    def tearDown(self):
        """
        ...
        """
        pass

    def test_his_range(self):
        """
        Test for range of Hue, Intensity and Saturation
        """
        for bitness in BITNESSES:

            bits = str(bitness)

            hue = hue_prefix + '_' + bits
            intensity = intensity_prefix + '_' + bits
            saturation = saturation_prefix + '_' + bits

            self.assertRasterMinMax(map=hue, refmin=0, refmax=360, msg=None)
            self.assertRasterMinMax(map=intensity, refmin=0, refmax=1, msg=None)
            self.assertRasterMinMax(map=saturation, refmin=0, refmax=1, msg=None)

    def test_difference(self):
        """
        Test for no or minimal differences between
        """
        # assertRastersNoDifference(actual, reference, precision, statistics=None, msg=None)

        for precision in PRECISION:

            print "Precision: " + str(precision) + "\n"

            for bitness in BITNESSES:

                bits = str(bitness)
                print bits + " bits:\n"

                red_input = red_image + '_' + bits
                green_input = green_image + '_' + bits
                blue_input = blue_image + '_' + bits

                hue = hue_prefix + '_' + bits
                intensity = intensity_prefix + '_' + bits
                saturation = saturation_prefix + '_' + bits

                red_output = red_prefix + '_' + bits
                green_output = green_prefix + '_' + bits
                blue_output = blue_prefix + '_' + bits

                # image_names = "Red input: " + str(red_input) + ", "
                # image_names += "Red output: " + str(red_output) + ", "
                # image_names += "Green input: " + str(green_input) + ", "
                # image_names += "Green output: " + str(green_input) + ", "
                # image_names += "Blue input: " + str(blue_input) + ", "
                # image_names += "Blue output: " + str(blue_input)
                # print str(image_names)

                # red

                self.assertRastersNoDifference(actual=red_output, reference=red_input,
                        precision=precision)

                info = SimpleModule('r.info', flags='r', map=red_input)
                TestCase.runModule(info, expecting_stdout=True)
                red_input_line = [red_input] + info.outputs.stdout.splitlines()

                info = SimpleModule('r.info', flags='r', map=red_output)
                TestCase.runModule(info, expecting_stdout=True)
                red_output_line = [red_output] + info.outputs.stdout.splitlines()

                # green

                self.assertRastersNoDifference(actual=green_output, reference=green_input,
                        precision=precision)

                info = SimpleModule('r.info', flags='r', map=green_input)
                TestCase.runModule(info, expecting_stdout=True)
                green_input_line = [green_input] + info.outputs.stdout.splitlines()

                info = SimpleModule('r.info', flags='r', map=green_output)
                TestCase.runModule(info, expecting_stdout=True)
                green_output_line = [green_output] + info.outputs.stdout.splitlines()

                # blue

                self.assertRastersNoDifference(actual=blue_output, reference=blue_input,
                        precision=precision)

                info = SimpleModule('r.info', flags='r', map=blue_input)
                TestCase.runModule(info, expecting_stdout=True)
                blue_input_line = [blue_input] + info.outputs.stdout.splitlines()

                info = SimpleModule('r.info', flags='r', map=blue_output)
                TestCase.runModule(info, expecting_stdout=True)
                blue_output_line = [blue_output] + info.outputs.stdout.splitlines()

                # hue

                info = SimpleModule('r.info', flags='r', map=hue)
                TestCase.runModule(info, expecting_stdout=True)
                hue_line = [hue] + info.outputs.stdout.splitlines()

                # intensity

                info = SimpleModule('r.info', flags='r', map=intensity)
                TestCase.runModule(info, expecting_stdout=True)
                intensity_line = [intensity] + info.outputs.stdout.splitlines()

                # saturation

                info = SimpleModule('r.info', flags='r', map=saturation)
                TestCase.runModule(info, expecting_stdout=True)
                saturation_line = [saturation] + info.outputs.stdout.splitlines()

                # inform

                for row in red_input_line, green_input_line, blue_input_line, hue_line, intensity_line, saturation_line, red_output_line, green_output_line, blue_output_line:
                    print("{: >20} {: >25} {: >20}".format(*row))

                print

    def test_rgb_range(self):
        """
        Test for minimum value of Red, Green and Blue
        """

        for bitness in BITNESSES:

            bitmax = 2**bitness
            bits = str(bitness)
            print bits + " bits:\n"

            red_input = red_image + '_' + bits
            green_input = green_image + '_' + bits
            blue_input = blue_image + '_' + bits

            red_output = red_prefix + '_' + bits
            green_output = green_prefix + '_' + bits
            blue_output = blue_prefix + '_' + bits

            self.assertRasterMinMax(map=red_input, refmin=0, refmax=bitmax, msg=None)
            self.assertRasterMinMax(map=green_input, refmin=0, refmax=bitmax, msg=None)
            self.assertRasterMinMax(map=blue_input, refmin=0, refmax=bitmax, msg=None)

            self.assertRasterMinMax(map=red_output, refmin=0, refmax=bitmax, msg=None)
            self.assertRasterMinMax(map=green_output, refmin=0, refmax=bitmax, msg=None)
            self.assertRasterMinMax(map=blue_output, refmin=0, refmax=bitmax, msg=None)

if __name__ == '__main__':
    from grass.gunittest.main import test
    test()
