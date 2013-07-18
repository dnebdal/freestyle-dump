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
