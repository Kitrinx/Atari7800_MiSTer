#!/bin/bash
python ./bin2mif.py A7800_NTSC_CRT_WARM_2021.pal ../rtl/palettes/NWARM.mif 24
python ./bin2mif.py A7800_NTSC_CRT_COOL_2021.pal ../rtl/palettes/NCOOL.mif 24
python ./bin2mif.py A7800_NTSC_CRT_HOT_2021.pal ../rtl/palettes/NHOT.mif 24
python ./bin2mif.py A7800_PAL_CRT_WARM_2021.pal ../rtl/palettes/PWARM.mif 24
python ./bin2mif.py A7800_PAL_CRT_COOL_2021.pal ../rtl/palettes/PCOOL.mif 24
python ./bin2mif.py A7800_PAL_CRT_HOT_2021.pal ../rtl/palettes/PHOT.mif 24
python ./bin2mif.py atari7800.bas.bin ../rtl/mem0.mif 8