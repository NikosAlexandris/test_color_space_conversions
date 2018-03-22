#!/usr/bin/python\<nl>\
# -*- coding: utf-8 -*-

"""
Name       Tests on RGB to HIS color space comversion
Purpose    Test if NULL compression preserves raster data
Source     <>

License    (C) 2018 by the GRASS Development Team
           This program is free software under the GNU General Public License
           (>=v2). Read the file COPYING that comes with GRASS for details.

:authors: Nikos Alexandris
"""

"""Librairies"""
# import os
# import StringIO
# import grass.pygrass.modules as pymod
from grass.gunittest.case import TestCase
# from grass.gunittest.gmodules import SimpleModule
import grass.script as g

"""Globlas"""

PRECISSION=0.01
BITNESSES = [bits for bits in range(6,17)]
IMAGES = ['lsat7_2002_10', 'lsat7_2002_20', 'lsat7_2002_30']
RGB=[255,0,0]  # to use for "random" r, g, b triplet generation

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
# red_map = StringIO.StringIO(RED_ASCII)

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
# green_map=StringIO.StringIO(GREEN_ASCII)

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
# blue_map=StringIO.StringIO(BLUE_ASCII)

"""Helper functions"""

def get_raster_univariate_statistics(raster):
    """
    """
    univar_string = g.read_command('r.univar', flags='g', map=raster)
    # message = MESSAGE.format(testmap=raster) + '\n' + univar_string
    # print message
    return univar_string

"""Test Case Class"""

class TestRGB2HIS(TestCase):

    # TODO: replace by unified handing of maps
    to_remove = []

    @classmethod
    def setUpClass(cls):
        """
        Set up
        """

        # use a temporary region
        cls.use_temp_region()

        # create input raster maps
        cls.runModule('r.in.ascii', input='-', stdin=RED_ASCII,
                output='red_map')

        cls.runModule('r.in.ascii', input='-', stdin=GREEN_ASCII,
                output='green_map')

        cls.runModule('r.in.ascii', input='-', stdin=BLUE_ASCII,
                output='blue_map')

        # append them in list "to_remove"
        cls.to_remove.append('red_map')
        cls.to_remove.append('green_map')
        cls.to_remove.append('blue_map')

        # set region to map(s)
        # cls.runModule('g.region', raster='red_map')
        cls.runModule('g.region', raster=IMAGES[0])

        for image in IMAGES:
            print image + ":"

            # univar_string = get_raster_univariate_statistics(band)

            for bitness in BITNESSES:

                # print "Bitness: " + str(bitness)
                rescaled_image = image + "_" + str(bitness)
                # print "Output map name: ", rescaled_image

                to_min = g.raster_info(image)['min']
                to_max = 2**bitness - 1
                to_range = "{min}".format(min=to_min),"{max}".format(max=to_max)
                # print "to: ", to_range

                # rescale_output = g.read_command('r.rescale', overwrite=True, verbose=True,
                #         input=band, output=output_map_name, to=to_range)
                # print rescale_output

                cls.runModule('r.rescale', overwrite=True, verbose=True,
                        input=image, output=rescaled_image, to=to_range)

                # What is expecting_stdout=True useful for?

                # cls.runModule('r.rescale', expecting_stdout=True, overwrite=True, verbose=True,
                #         input=band, output=output_map_name, to=to_range)


        for bitness in BITNESSES:

            rescaled_image = image + "_" + str(bitness)

            bits = str(bitness)

            red_image = IMAGES[2] + '_' + bits
            green_image = IMAGES[1] + '_' + bits
            blue_image = IMAGES[0] + '_' + bits

            hue = 'hue' + '_' + bits
            intensity = 'intensity' + '_' + bits
            saturation = 'saturation' + '_' + bits

            red = 'red' + '_' + bits
            green = 'green' + '_' + bits
            blue = 'blue' + '_' + bits

            # rgb -> his
            cls.runModule('i.rgb.his', overwrite=True, verbose=True,
                    red = red_image, green = green_image, blue = blue_image,
                    hue = hue, intensity = intensity, saturation = saturation,
                    bits = bitness)

            # rgb <- his
            cls.runModule('i.his.rgb', overwrite=True, verbose=True,
                    hue = hue, intensity = intensity, saturation = saturation,
                    red = red, green = green, blue = blue,
                    bits = bitness)

            cls.to_remove.append(red_image)
            cls.to_remove.append(green_image)
            cls.to_remove.append(blue_image)
            cls.to_remove.append(hue)
            cls.to_remove.append(intensity)
            cls.to_remove.append(saturation)
            cls.to_remove.append(red)
            cls.to_remove.append(green)
            cls.to_remove.append(blue)

    def setUp(self):
        """
        Set up region and create test raster maps
        """

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

    def test_difference(self):
        """
        Test for no or minimal differences between
        """
        # assertRastersNoDifference(actual, reference, precision, statistics=None, msg=None)

        for bitness in BITNESSES:

            bits = str(bitness)
            print "Bitness: " + bits

            red_image = 'red' + '_' + bits
            green_image = 'green' + '_' + bits
            blue_image = 'blue' + '_' + bits

            red = IMAGES[2] + '_' + bits
            green = IMAGES[1] + '_' + bits
            blue = IMAGES[0] + '_' + bits

            image_names = "Red: " + str(red) + ", "
            image_names += "Green: " + str(green) + ", "
            image_names += "Blue: " + str(blue)

            print str(image_names)

            self.assertRastersNoDifference(actual=red, reference=red_image,
                    precision=PRECISSION)

            self.assertRastersNoDifference(actual=green, reference=green_image,
                    precision=PRECISSION)

            self.assertRastersNoDifference(actual=blue, reference=blue_image,
                    precision=PRECISSION)

            print

    def test_his_range(self):
        """
        Test for range of Hue, Intensity and Saturation
        """
        for bitness in BITNESSES:

            bits = str(bitness)

            hue = 'hue' + '_' + bits
            intensity = 'intensity' + '_' + bits
            saturation = 'saturation' + '_' + bits

            self.assertRasterMinMax(map=hue, refmin=0, refmax=360, msg=None)
            self.assertRasterMinMax(map=intensity, refmin=0, refmax=1, msg=None)
            self.assertRasterMinMax(map=saturation, refmin=0, refmax=1, msg=None)

    def test_min_of_rgb(self):
        """
        Test for minimum value of Red, Green and Blue
        """
        pass

    def test_max_of_rgb(self):
        """
        Test for maximum value of Red, Green and Blue
        """
        pass

if __name__ == '__main__':
    from grass.gunittest.main import test
    test()

