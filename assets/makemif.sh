#!/bin/bash
python ./bin2mif.py A7800_NTSC_WARM_FINAL2021.pal ../rtl/palettes/NWARM.mif 24
python ./bin2mif.py A7800_NTSC_COOL_FINAL2021.pal ../rtl/palettes/NCOOL.mif 24
python ./bin2mif.py A7800_NTSC_HOT_FINAL2021.pal ../rtl/palettes/NHOT.mif 24
python ./bin2mif.py A7800_PAL_WARM_FINAL2021.pal ../rtl/palettes/PWARM.mif 24
python ./bin2mif.py A7800_PAL_COOL_FINAL2021.pal ../rtl/palettes/PCOOL.mif 24
python ./bin2mif.py A7800_PAL_HOT_FINAL2021.pal ../rtl/palettes/PHOT.mif 24
python ./bin2mif.py 7800title.bin ../rtl/mem0.mif 8
python ./bin2mif.py not_supported.bin ../rtl/ooo.mif 8