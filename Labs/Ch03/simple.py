#!/usr/bin/python

import time
import socket

while True:
  host = socket.gethostname()
  date = time.strftime("%Y-%m-%d %H:%M:%S")
  now = str(date)

  with open("date.out", "a") as f:
    f.write("[%s] - %s\n" % (now, host))
  
  time.sleep(5)
