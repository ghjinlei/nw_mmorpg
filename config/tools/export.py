#!/usr/bin/env python3
#coding:utf-8

import os, sys
from sys import exit
from utils.excel import read_excel_data
import utils.path as utils_path
from utils.logger import Logger

os.chdir(utils_path.TOOLS_ROOT_PATH)

key_map = {
    "cmd"            : "string",
    "lang"           : "string",
    "script"         : "string",
    "args"           : "string",
    "output_client"  : "string",
    "output_server"  : "string",
}
cmd_info_map = read_excel_data("./export_cmds.xlsx", "main", key_map, "cmd")

logger = Logger(sys.stderr)

def save_autocode(filepath, data):
    dirpath = os.path.dirname(filepath)
    if not os.path.exists(dirpath):
        os.makedirs(dirpath)

    data = data.replace("\r\n", "\n")
    with open(filepath, "w+") as f:
        f.write(data)
        f.flush()
        f.close()


def gen_autocode_by_info(cmd_info):
    if "output_client" in cmd_info:
        pfile = os.popen("%s %s %s %s"%(cmd_info["lang"], cmd_info["script"], "-t c", cmd_info["args"]))
        data = pfile.read()
        pfile.close()
        save_autocode(cmd_info["output_client"], data)

    if "output_server" in cmd_info:
        pfile = os.popen("%s %s %s %s"%(cmd_info["lang"], cmd_info["script"], "-t s", cmd_info["args"]))
        data = pfile.read()
        pfile.close()
        save_autocode(cmd_info["output_server"], data)

    return True

def gen_autocode(cmd):
    cmd_info = cmd_info_map[cmd]

    logger.info("start gen %s"%cmd)
    ok = gen_autocode_by_info(cmd_info)
    if ok:
        logger.info("gen %s success"%cmd)
    else:
        logger.info("gen %s failed"%cmd)

def main():
    if len(sys.argv) == 1:
        while(True):
            cmd = input("cmd:")
            gen_autocode(cmd)
    elif len(sys.argv) == 2:
        cmd = sys.argv[1]
        gen_autocode(cmd)

if __name__ == "__main__":
    main()

