#!/usr/bin/env python

import argparse
import os
import subprocess
from multiprocessing import Process
from functools import reduce

MEMORY='2G'

def getArch(iid):
    query = 'select arch from image where id=' + iid + ';'
    arch = dbquery(query)[0][0]
    if arch == 'armel':
        arch = 'arm'
    elif arch == 'mipseb':
        arch = 'mips'
    return arch

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

def extract(iid, bindir):
    print('Extracting binaries......')
    query = '''select filename from object_to_image where iid=''' + iid + ''' and score>0 and (mime='application/x-executable; charset=binary' or mime='application/x-object; charset=binary' or mime='application/x-sharedlib; charset=binary') order by score DESC;'''
    wanted = dbquery(query)
    wanted = reduce((lambda a, b: a + b), wanted)
    wanted = map((lambda a: '.' + a), wanted)
    wanted = reduce((lambda a, b: a + ' ' + b), wanted)
    cmd = 'tar xf ' + bindir + '/../../../../images/' + iid + '.tar.gz -C ' + bindir + ' ' + wanted
    subprocess.run([cmd], shell=True)

    print('Extracting library links......')
    query = '''select filename from object_to_image where iid=''' + iid + ''' and regular_file='f';'''
    wanted = dbquery(query)
    wanted = reduce((lambda a, b: a + b), wanted)
    wanted = filter((lambda a: 'lib' in a), wanted)
    wanted = map((lambda a: '.' + a), wanted)
    wanted = reduce((lambda a, b: a + ' ' + b), wanted)
    cmd = 'tar xf ' + bindir + '/../../../../images/' + iid + '.tar.gz -C ' + bindir + ' ' + wanted
    subprocess.run([cmd], shell=True)

def setenvs(iid):
    arch = getArch(iid)
    afl_path = subprocess.run(['which', 'afl-qemu-trace'], stdout=subprocess.PIPE).stdout.decode().replace('\n', '') + '-' + arch
    if len(afl_path) == 0:
        print("Unknown architecture: " + arch)
        sys.exit(1)
    env = dict(os.environ.copy(), **{'AFL_INST_LIBS':'1'}, **{'AFL_EXIT_WHEN_DONE':'1'}, **{'AFL_NO_AFFINITY':'0'}, **{'AFL_PATH':afl_path})
    return env

def runAFL(args, ENVS):
    p = subprocess.Popen(args, env = ENVS)
    try:
        p.wait(timeout=20 * 60) # 20 min
    except subprocess.TimeoutExpired:
        # may check the status here to decide whether to terminate
        p.terminate()

def fuzz(target, bindir, outdir, ENVS):
    print('Fuzzing ' + target + '......')
    if not os.path.isdir(outdir):
        if os.path.exists(outdir):
            os.remove(outdir)
        os.makedirs(outdir, 0o755)
        inputcase = '/usr/share/afl/testcases/others/text'
    else:
        inputcase = '-'

    args = ['afl-fuzz', '-Q', '-M', 'master', '-m', MEMORY, '-i', inputcase, '-o', outdir, '-L', bindir, bindir + '/' + target]
    m = Process(target=runAFL, args=(args, ENVS))
    m.start()
    args = ['afl-fuzz', '-Q', '-S', 'slave1', '-m', MEMORY, '-i', inputcase, '-o', outdir, '-L', bindir, bindir + '/' + target]
    s1 = Process(target=runAFL, args=(args, ENVS))
    s1.start()
    args = ['afl-fuzz', '-Q', '-S', 'slave2', '-m', MEMORY, '-i', inputcase, '-o', outdir, '-L', bindir, bindir + '/' + target]
    s2 = Process(target=runAFL, args=(args, ENVS))
    s2.start()
    args = ['afl-fuzz', '-Q', '-S', 'slave3', '-m', MEMORY, '-i', inputcase, '-o', outdir, '-L', bindir, bindir + '/' + target]
    s3 = Process(target=runAFL, args=(args, ENVS))
    s3.start()

    # join
    m.join()
    s1.join()
    s2.join()
    s3.join()

    # process the output
    merge_stats(outdir)

def merge_stats(outdir):
    ocwd = os.getcwd()
    os.chdir(outdir)

    raw = []
    try:
        raw += open('master/fuzzer_stats', 'r').read().split('\n')
    except FileNotFoundError:
        print('could not find ' + outdir + '/master/fuzzer_stats')
    try:
        raw += open('slave1/fuzzer_stats', 'r').read().split('\n')
    except FileNotFoundError:
        print('could not find ' + outdir + '/slave1/fuzzer_stats')
    try:
        raw += open('slave2/fuzzer_stats', 'r').read().split('\n')
    except FileNotFoundError:
        print('could not find ' + outdir + '/slave2/fuzzer_stats')
    try:
        raw += open('slave3/fuzzer_stats', 'r').read().split('\n')
    except FileNotFoundError:
        print('could not find ' + outdir + '/slave3/fuzzer_stats')
    output = open('total_fuzzer_stats', 'w')

    cycles_done = filter(lambda l: 'cycles_done' in l, raw)
    num = 0
    for each in cycles_done:
        num += int(each.split(':')[1])
    output.write('cycles_done       : ' + str(num) + '\n')

    execs_done = filter(lambda l: 'execs_done' in l, raw)
    num = 0
    for each in execs_done:
        num += int(each.split(':')[1])
    output.write('execs_done        : ' + str(num) + '\n')

    execs_per_sec = filter(lambda l: 'execs_per_sec' in l, raw)
    num = 0
    for each in cycles_done:
        num += int(each.split(':')[1])
    output.write('execs_per_sec     : ' + str(num) + '\n')

    paths_total = filter(lambda l: 'paths_total' in l, raw)
    num = 0
    for each in cycles_done:
        num += int(each.split(':')[1])
    output.write('paths_total       : ' + str(num) + '\n')

    unique_crashes = filter(lambda l: 'unique_crashes' in l, raw)
    num = 0
    for each in cycles_done:
        num += int(each.split(':')[1])
    output.write('unique_crashes    : ' + str(num) + '\n')

    unique_hangs = filter(lambda l: 'unique_hangs' in l, raw)
    num = 0
    for each in cycles_done:
        num += int(each.split(':')[1])
    output.write('unique_hangs      : ' + str(num) + '\n')

    output.close()
    os.chdir(ocwd)


def process(iid, resultdir):
    subprocess.run(['echo core | sudo tee /proc/sys/kernel/core_pattern >/dev/null'], shell=True)
    bindir = resultdir + '/bin'
    outdir = resultdir + '/out'

    if not os.path.isdir(bindir):
        if os.path.exists(bindir):
            os.remove(bindir)
        os.makedirs(bindir, 0o755)

    if not os.path.isdir(outdir):
        if os.path.exists(outdir):
            os.remove(outdir)
        os.makedirs(outdir, 0o755)

    extract(iid, bindir)
    AFL_ENVS = setenvs(iid)
    query = '''select filename from object_to_image where iid=''' + iid + ''' and score>0 and mime='application/x-executable; charset=binary' order by score DESC;'''
    targets = dbquery(query)
    targets = reduce((lambda a, b: a + b), targets)
    targets = list(map((lambda a: '.' + a), targets))
    for target in targets:
        fuzz(target, bindir, outdir + '/' + target, AFL_ENVS)


def main():
    parser = argparse.ArgumentParser(description="AFL wrapper program")
    parser.add_argument("id", action="store", help="firmware image ID")
    arg = parser.parse_args()
    resultdir = os.path.dirname(os.path.realpath(__file__)) + '/../results/' + arg.id + '/afl'
    process(arg.id, resultdir)

if __name__ == '__main__':
    main ()
