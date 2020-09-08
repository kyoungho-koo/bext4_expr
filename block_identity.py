import argparse

def is_in_range(rangeinfos, blocknr):
    rangeinfos.replace(" ","")
    rangeinfolist = rangeinfos.split(',')
    for rangeinfo in rangeinfolist:
        ranges = rangeinfo.split('-')
        if blocknr >= int(ranges[0]) and blocknr <= int(ranges[1]):
            return 1
    return 0

groupid = -1
def find_block_identity(diskinfo,blocknr):
    global groupid
    layout = 0
    ret = "" 
    for line in diskinfo:
        # remove newline
        line = line.strip()
        line_datas = line.split(':')

        if (line_datas[0] == "Group"):
                groupid = line_datas[1]
                layout = 0
                continue
        elif (groupid == -1):
                continue

        if (line_datas[0] == "Layout"):
                layout = 1
                continue
        elif (layout == 0):
                continue
        
        try:
                rangeinfos = ''
                if ( '-' in line_datas[1]):
                        rangeinfos = line_datas[1]
                        if (is_in_range(rangeinfos,blocknr)):
                                ret = [groupid,line_datas[0]]

                else:
                        continue
        except IndexError:
                pass
    groupid = -1
    return ret

def convert_key_str(identity):
    table = {
            "Super Block":"sb",
            "Group Descriptor Table": "gdt",
            "Group Descriptor Growth Blocks": "gdgb",
            "Data bitmap": "dbm",
            "Inode bitmap": "ibm",
            "Inode Table" : "it",
            "Data Blocks":"db"
            }
    return table[identity]


if __name__ =='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--disk-info')
    parser.add_argument('--pcl-info')
    parser.add_argument('--out-file')

    gArgs = parser.parse_args()

    diskinfo = []
    pclinfo = []
    pcldic = {
            "sb":0,
            "gdt":0,
            "gdgb":0,
            "dbm":0,
            "ibm":0,
            "it":0,
            "db":0
            }

    pclWaitDic = {
            "sb":0,
            "gdt":0,
            "gdgb":0,
            "dbm":0,
            "ibm":0,
            "it":0,
            "db":0
            }

    with open(gArgs.disk_info,"r") as file1:
        diskinfo = file1.readlines()

    with open(gArgs.pcl_info,"r") as file2:
        pclinfo = file2.readlines()
        pclinfo.sort(key=lambda x: x.split(" ")[0])


    outfile = open(gArgs.out_file,"w+")
    for pc in pclinfo:
        pc = pc.strip()
        blocknr = int(pc.split(' ')[0])
        ret = find_block_identity(diskinfo, blocknr)
        pcldic[convert_key_str(ret[1])] += int(pc.split(' ')[1])
        pclWaitDic[convert_key_str(ret[1])] += int(pc.split(' ')[2])
        outfile.write(pc + " #" + "gid" +ret[0]+" "+ret[1]+"\n")
    outfile.close()

    outfile = open(gArgs.out_file+".jc","w+")
    outfile1 = open(gArgs.out_file+".wait","w+")
    for key,val in pcldic.items():
        outfile.write(key+" "+str(val)+" "+"\n")
    for key,val in pclWaitDic.items():
        outfile1.write(key+" "+str(val)+" "+"\n")
    outfile.close()
    outfile1.close()
    print (pcldic)
    print (pclWaitDic)
