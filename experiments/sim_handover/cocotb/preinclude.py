import os
import re
import pathlib

def comment_remover(text): # https://stackoverflow.com/questions/241327/remove-c-and-c-comments-using-python
    def replacer(match):
        s = match.group(0)
        if s.startswith('/'):
            return " " # note: a space and not an empty string
        else:
            return s
    pattern = re.compile(
            r'//.*?$|/\*.*?\*/|\'(?:\\.|[^\\\'])*\'|"(?:\\.|[^\\"])*"',
            re.DOTALL | re.MULTILINE
            )
    return re.sub(pattern, replacer, text)

def svinclude(sorig,vhlist,oneline=False):
    cnt=0
    for vh in vhlist:
        basename=os.path.basename(vh)
        sre=r'`include\s+"%s"'%basename
        if re.findall(sre,sorig):
            with open(vh) as fvh:
                svh=fvh.read()
            if oneline:
                svh=comment_remover(svh)
                svh=re.sub("\n"," ",svh)
            sorig=re.sub(sre,svh,sorig)
            [cntnew,sorig]=svinclude(sorig,vhlist,oneline=oneline)
            cnt=cnt+cntnew+1
    return [cnt,sorig]
#def vhreplace(orig,vhlist):
#    vhre='|'.join([p for p in vhdict.keys()])
#    with open(orig) as f:
#        match=re.findall(vhre,f.read())
#    if match:
#        for s in match:
#            re.sub(s,vhdict[
#            print(orig,match,[vhdict[m] for m in match])

def preinclude(dep, oneline, basepath=None):
    with open(dep,'r') as fd:
        sd=fd.read().split('\n')
    files=dict(v=[],sv=[],vh=[])
    for p in [l for l in sd if l]:
        if basepath is not None:
            p = os.path.join(basepath, p)
        if os.path.isfile(p):
            ext=pathlib.Path(p).suffix[1:]
            if ext not in files:
                files[ext]=[]
            files[ext].append(p)
        else:
            print("%s is not a file\n"%p)
    vsv=files['v']+files['sv']
    #if abspath:
    #    vsv = [os.path.abspath(f) for f in vsv]
    if not os.path.isdir('gensrc'):
        os.makedirs('./gensrc')
    for index,f in enumerate(vsv):
        with open(f) as fread:
            orig=fread.read()
        cnt,srep=svinclude(orig,files['vh'],oneline=oneline)
        if cnt>0:
            fnew='./gensrc/'+os.path.basename(f)
            vsv[index]=fnew
            with open(fnew,'w') as fw:
                fw.write(srep)
    return vsv

if __name__=="__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument(type=str, help='dependent', dest="dep")
    parser.add_argument( "-oneline","--oneline", dest='oneline',action='store_true', default=False,help="remove all \\n in vh")
    parser.add_argument( "-a","--abspath", dest='abspath',action='store_true', default=False,help="return absolute path\\n in vh")
    clargs = parser.parse_args()
    if clargs.abspath:
        basepath = os.path.dirname(os.path.abspath(clargs.dep))
    else:
        basepath = None
    vsv = preinclude(clargs.dep, clargs.oneline, basepath)
    #if clargs.abspath:
    #    print('\n'.join(os.path.abspath(f) for f in vsv))
    print('\n'.join(vsv))
