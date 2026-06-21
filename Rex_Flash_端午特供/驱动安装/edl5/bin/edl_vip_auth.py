#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import argparse
import logging
import os
import sys
import time

from edlclient.Config.usb_ids import default_ids
from edlclient.Library.Connection.usblib import usb_class
from edlclient.Library.firehose import firehose
from edlclient.Library.sahara import sahara
from edlclient.Library.xmlparser import xmlparser


def parse_hex(value):
    if value is None:
        return None
    text = value.strip().lower()
    if text.startswith("0x"):
        text = text[2:]
    if not text:
        return None
    return int(text, 16)


def read_file(path):
    with open(path, "rb") as f:
        return f.read()


def connect_device(cdc, sah):
    loop = 0
    while not cdc.connected:
        cdc.connected = cdc.connect(portname="")
        if not cdc.connected:
            time.sleep(1)
            loop += 1
            if loop > 60:
                return {"mode": "error"}
            continue
        try:
            return sah.connect()
        except Exception as err:  # pylint: disable=broad-except
            print("sahara connect error:", err)
            try:
                cdc.close()
            except Exception:
                pass
            cdc.connected = False
            time.sleep(1)
    return {"mode": "error"}


def ensure_firehose(sah, resp):
    mode = resp.get("mode")
    if mode == "sahara":
        data = resp.get("data")
        version = getattr(data, "version", 2)
        mode = sah.upload_loader(version=version)
    return mode


def build_firehose_args(memory, maxpayload, skipstorageinit):
    return {
        "--memory": memory,
        "--skipstorageinit": skipstorageinit,
        "--skipwrite": False,
        "--maxpayload": maxpayload,
        "--sectorsize": 0,
        "--skipresponse": False,
        "--devicemodel": None,
        "--lun": None,
        "--signeddigests": None,
        "--portname": None,
        "--serial": False,
    }


def send_xml(fh, path, label):
    if not path:
        return True
    data = read_file(path)
    resp = fh.xmlsend(data)
    if not resp.resp:
        print("ERROR:", label, resp.error)
        return False
    return True


def send_digest(fh, path, label):
    if not path:
        return True
    if not fh.send_signed_digest(path):
        print("ERROR:", label, "failed")
        return False
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--loader", required=True)
    parser.add_argument("--digest", required=True)
    parser.add_argument("--sig", required=True)
    parser.add_argument("--transfer", required=True)
    parser.add_argument("--verify", required=True)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--cfg", required=True)
    parser.add_argument("--vid", default="05c6")
    parser.add_argument("--pid", default="9008")
    parser.add_argument("--memory", default="ufs")
    parser.add_argument("--maxpayload", default="0x1000")
    parser.add_argument("--skipstorageinit", action="store_true")
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()

    loader = args.loader
    if not os.path.exists(loader):
        print("ERROR: loader not found:", loader)
        return 2

    vid = parse_hex(args.vid)
    pid = parse_hex(args.pid)
    interface = -1
    if vid is not None and pid is not None:
        portconfig = [[vid, pid, interface]]
    else:
        portconfig = default_ids

    loglevel = logging.DEBUG if args.debug else logging.INFO
    cdc = usb_class(loglevel=loglevel, portconfig=portconfig)
    sah = sahara(cdc, loglevel=loglevel)
    sah.programmer = loader

    resp = connect_device(cdc, sah)
    if resp.get("mode") == "error":
        print("ERROR: device not detected")
        return 3

    mode = ensure_firehose(sah, resp)
    if mode != "firehose":
        print("ERROR: not in firehose mode:", mode)
        return 4

    cdc.timeout = None
    fh_args = build_firehose_args(args.memory, args.maxpayload, args.skipstorageinit)
    cfg = firehose.cfg()
    cfg.MemoryName = args.memory
    cfg.ZLPAwareHost = 1
    cfg.SkipStorageInit = 1 if args.skipstorageinit else 0
    cfg.SkipWrite = 0
    cfg.MaxPayloadSizeToTargetInBytes = int(args.maxpayload, 0)
    cfg.SECTOR_SIZE_IN_BYTES = 0
    fh = firehose(
        cdc=cdc,
        xml=xmlparser(),
        cfg=cfg,
        loglevel=loglevel,
        devicemodel="",
        serial=sah.serial,
        skipresponse=False,
        luns=[0],
        args=fh_args,
    )
    fh.cfg.programmer = loader

    print("Connecting firehose (no auto configure)...")
    fh.connect()

    print("Send digest...")
    if not fh.send_signed_digest(args.digest):
        print("ERROR: digest failed")
        return 6
    print("Send transfercfg...")
    if not send_xml(fh, args.transfer, "transfercfg"):
        return 7
    print("Send verify...")
    if not send_xml(fh, args.verify, "verify"):
        return 8
    print("Send sig...")
    if not fh.send_signed_digest(args.sig):
        print("ERROR: sig failed")
        return 9
    print("Send sha256init...")
    if not send_xml(fh, args.sha, "sha256init"):
        return 10
    print("Send cfg...")
    if not send_xml(fh, args.cfg, "cfg"):
        return 11

    print("VIP auth done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
