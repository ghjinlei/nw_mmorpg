#!/usr/bin/env python3
import sys

class Logger:
    def __init__(self, out=sys.stderr):
        self.out = out

    def info(self, msg):
        self.out.write("[info]" + msg + "\n")

    def error(self, msg):
        self.out.write("[error]" + msg + "\n")

    def warning(self, msg):
        self.out.write("[warning]" + msg + "\n")

    def debug(self, msg):
        self.out.write("[debug]" + msg + "\n")

