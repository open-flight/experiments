# Sends ESP-WebSDR's SYNC and CAPS commands at one baud rate and prints the replies.
import os, sys, time, termios, fcntl, struct, select

PORT, BAUD = sys.argv[1], int(sys.argv[2])
IOSSIOSPEED = 0x80085402

fd = os.open(PORT, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
attrs = termios.tcgetattr(fd)
attrs[0] = 0; attrs[1] = 0
attrs[2] = termios.CS8 | termios.CREAD | termios.CLOCAL
attrs[3] = 0
termios.tcsetattr(fd, termios.TCSANOW, attrs)
fcntl.ioctl(fd, IOSSIOSPEED, struct.pack('L', BAUD))

def read_for(sec):
    out, end = b'', time.time() + sec
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: out += os.read(fd, 65536)
            except BlockingIOError: pass
    return out

read_for(1.0)  # drain anything left from boot
termios.tcflush(fd, termios.TCIFLUSH)
marker = 'SYNC %d' % int(time.time() * 1000)
os.write(fd, ('\n' + marker + '\n').encode())
resp = read_for(1.5)
print('SYNC echoed:', (marker + '\n').encode() in resp, repr(resp[:120]))
os.write(fd, b'CAPS\n')
print('CAPS reply:', repr(read_for(1.5)[:600]))
os.close(fd)
