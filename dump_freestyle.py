# Copyright Daniel Nebdal <daniel@nebdal.net> 2013. 
# https://github.com/dnebdal/freestyle-dump/
# Distributed under the 2-clause BSD license, ref. LICENSE.

import datetime
import serial as s

dataPort = s.Serial("/dev/ttyUSB0", baudrate=19200)
dataPort.write("mem")
dump = ""
while True:
  if dump.endswith("END"):
    break
  chr = dataPort.read()
  dump += chr

dump=dump.strip()
deviceID = dump[1:13]

dumpFile = open("freestyle-%s-%s.txt" % (deviceID, datetime.date.today().isoformat(), ), "w" )
dumpFile.write(dump)
dumpFile.close()
