#!/usr/bin/env python3
#coding:utf-8
from os.path import dirname
from os.path import basename
from os.path import realpath

CONFIG_ROOT_PATH = dirname(dirname(dirname(realpath(__file__))))
TOOLS_ROOT_PATH = CONFIG_ROOT_PATH + "/tools"
XML_ROOT_PATH = CONFIG_ROOT_PATH + "/xml"
AUTOCODE_CLIENT_ROOT_PATH = CONFIG_ROOT_PATH + "/autocode/client"
AUTOCODE_SERVER_ROOT_PATH = CONFIG_ROOT_PATH + "/autocode/server"
