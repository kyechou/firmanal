#!/usr/bin/env python

import argparse
import sys
import os
import subprocess
from multiprocessing import Process


def dbquery(query):
    import psycopg2
    db = psycopg2.connect(dbname = "firmware", user = "firmadyne", password = "firmadyne", host = "127.0.0.1")
    ret = None
    try:
        cur = db.cursor()
        cur.execute(query)
    except BaseException:
        traceback.print_exc()
    finally:
        if cur:
            ret = cur.fetchall()
            cur.close()
    return ret

def source(iid):
    script = os.getcwd() + '/analysis/source.sh'
    p = subprocess.run([script, str(iid)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(p.stdout.decode())
    print(p.stderr.decode())

def angr(iid):
    print('warning: the Angr function is under development')
    # TODO

def afl(iid):
    sys.path.append('./analysis')
    import afl
    resultdir = os.getcwd() + '/results/' + iid + '/afl'
    afl.process(iid, resultdir)

def netafl(iid, ip):
    resultdir = os.getcwd() + '/results/' + iid + '/netafl'
    script = os.getcwd() + '/analysis/netafl.py'
    print('warning: the network AFL function is under development')
    # TODO

def metasploit(iid, ip):
    sys.path.append('./analysis/metasploit')
    import runExploits
    exploits = list (runExploits.METASPLOIT_EXPLOITS.keys()) + list (runExploits.SHELL_EXPLOITS.keys())
    resultdir = os.getcwd() + '/results/' + iid + '/metasploit'
    if not os.path.isdir(resultdir):
        if os.path.exists(resultdir):
            os.remove(resultdir)
        os.makedirs(resultdir, 0o755)
    outfile = resultdir + "/%(exploit)s.log"
    runExploits.process(ip, exploits, outfile)


def extract(input_file):
    sys.path.append('./scripts')
    import extractor
    e = extractor.Extractor(input_file, 'images', True, False, False, '127.0.0.1', None)
    ocwd = os.getcwd()
    (iid, repeated) = e.extract()
    os.chdir(ocwd)
    return (iid, repeated)

def importdb(iid):
    sys.path.append('./db')
    import importdb
    image = './images/' + str(iid) + '.tar.gz'
    importdb.getarch(image)
    importdb.process(iid, image)

def makeimage(iid):
    p = subprocess.run(['sudo', './qemu/scripts/makeImage.sh', str(iid)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(p.stdout.decode())
    print(p.stderr.decode())

def infernetwork(iid):
    p = subprocess.run(['./qemu/scripts/inferNetwork.sh', str(iid)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(p.stdout.decode())
    print(p.stderr.decode())

def getIP(iid):
    ip = None
    import psycopg2
    db = psycopg2.connect(dbname = "firmware", user = "firmadyne", password = "firmadyne", host = "127.0.0.1")
    try:
        cur = db.cursor()
        cur.execute("SELECT ip FROM image WHERE id=" + iid)
    except BaseException:
        traceback.print_exc()
    finally:
        if cur:
            ip = cur.fetchone()[0]
            cur.close()
    return ip

def rootfs_extracted(iid):
    query = 'select rootfs_extracted from image where id=' + iid + ';'
    return dbquery(query)[0][0]

def main():
    os.chdir(os.path.dirname(os.path.realpath(__file__)))

    parser = argparse.ArgumentParser(description="Linux-based firmware analysis")
    parser.add_argument("input_file", action="store", help="Input firmware image")
    parser.add_argument("-i", dest="id", action="store",
                        default=None, help="firmware ID")
    parser.add_argument("-s", dest="source", action="store_true",
                        default=False, help="Enable source code analysis")
    parser.add_argument("-a", dest="angr", action="store_true",
                        default=False, help="Enable static analysis with Angr")
    parser.add_argument("-f", dest="afl", action="store_true",
                        default=False, help="Fuzzing the firmware binaries with AFL")
    parser.add_argument("-n", dest="netafl", action="store_true",
                        default=False, help="Fuzzing the network services with AFL")
    parser.add_argument("-m", dest="metasploit", action="store_true",
                        default=False, help="Penetration test with metasploit exploits")
    arg = parser.parse_args()

    (iid, repeated) = extract(arg.input_file)
    if arg.id != None and iid != arg.id:
        print('error: frontend firmware ID and backend image ID conflict')
        sys.exit(1)

    if not rootfs_extracted(iid):
        print('error: cannot find rootfs')
        sys.exit(1)

    # importdb
    if not repeated:
        importdb(iid)

    if arg.source:
        s = Process(target=source, args=(iid,))
        s.start()

    # makeImage, inferNetwork
    if not repeated:
        makeimage(iid)
        infernetwork(iid)
    ip = getIP(iid)
    if not ip:
        print('warning: no interface detected')

    if arg.angr:
        a = Process(target=angr, args=(iid,))
        a.start()

    if arg.afl:
        f = Process(target=afl, args=(iid,))
        f.start()

    if arg.netafl and ip:
        n = Process(target=netafl, args=(iid, ip))
        n.start()

    if arg.metasploit and ip:
        m = Process(target=metasploit, args=(iid, ip))
        m.start()

    # join
    if arg.source:
        s.join()
    if arg.angr:
        a.join()
    if arg.afl:
        f.join()
    if arg.netafl and ip:
        n.join()
    if arg.metasploit and ip:
        m.join()


if __name__ == '__main__':
    main ()
