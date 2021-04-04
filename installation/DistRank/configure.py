import sys,os,glob,re

#configure_file(filepath, filetype, 'feature_dir', db_dir)
def configure_file(filepath, filetype, flag, keyword, db_dir):
    os.chdir(filepath)
    for filename in glob.glob(filepath + '/*.' + filetype):
        temp_in = filename
        temp_out = temp_in+'.tmp'
        f = open(temp_in, 'r')
        tar_flag = False
        change_flag = False
        line_old = None
        line_new = None
        for line in f.readlines():
            if flag in line:
                tar_flag = True
            if keyword in line and tar_flag == True:
                tar_flag = False
                change_flag = True
                line_old = line.strip('\n')
                fix_str = line.strip('\n').split('=')[0]
                if '\'' in line:
                    fix_str2 = line.strip('\n').split('\'')[-1]
                    line_new = fix_str + '=' + db_dir + '\'' + fix_str2
                else:
                    line_new = fix_str + '=' + db_dir
                # print(line_old)
                # print(line_new)
        f.close()
        #replace target line
        if change_flag:
            print(temp_in)
            change_flag = False
            f1 = open(temp_in)
            con = f1.read()
            f1.close()
            con_new = con.replace(line_old, line_new)
            f2 = open(temp_out, 'w')
            f2.write(con_new)
            f2.close()
            os.system('mv ' + temp_out + ' ' + temp_in)
            os.system('chmod -R 777 ' + temp_in)

def configure_database(filepath, filetype, flag, keyword, db_dir):
    os.chdir(filepath)
    for filename in glob.glob(filepath + '/*.' + filetype):
        temp_in = filename
        temp_out = temp_in+'.tmp'
        f = open(temp_in, 'r')
        tar_flag = False
        change_flag = False
        line_old = []
        line_new = []
        for line in f.readlines():
            if flag in line:
                tar_flag = True
            if '#####' in line:
                tar_flag = False
            for i in range(len(keyword)):
                if keyword[i] in line and tar_flag == True:
                    change_flag = True
                    line_old.append(line.strip('\n'))
                    fix_str = line.strip('\n').split('=')[0]
                    line_new.append(fix_str + '=' + '\'' + db_dir[i] + '\'')
        f.close()
        #replace target line
        if change_flag:
            print(temp_in)
            change_flag = False
            f1 = open(temp_in)
            con = f1.read()
            f1.close()
            for i in range(len(line_old)):
                if i == 0:
                    con_new = con.replace(line_old[i], line_new[i])
                else:
                    con_new = con_new.replace(line_old[i], line_new[i])
            f2 = open(temp_out, 'w')
            f2.write(con_new)
            f2.close()
            os.system('mv ' + temp_out + ' ' + temp_in)
            os.system('chmod -R 777 ' + temp_in)


temp_path = sys.path[0]
DistRank_path = ''
if sys.version_info[0] < 3:
    intall_flag = raw_input("Intall DistRank to "+ temp_path +". Press any button to continue...")
else:
    intall_flag = input("Intall DistRank to "+ temp_path +". Press any button to continue...")
DistRank_path = temp_path
    # if 'Y' in intall_flag or 'y' in intall_flag:
    #     DistRank_path = temp_path
    # else:
    #     custom_path = input("Please input the path you want to install...")
    #     print("The DistRank will be installed to %s, please wait...\n"%custom_path)
    #     DistRank_path = custom_path
	## copy all file to the custom path, then need to change all shell gloable_dir

install_info_file = DistRank_path+'/installation/path.inf'
DistRank_run_script=''
if not os.path.exists(install_info_file):
    print("Can't find %s, please check!"%install_info_file)
    sys.exit(1)
else:
    f = open(install_info_file, 'r')
    for line in f.readlines():
        if line.startswith('#'):
            continue
        else:
            if 'run_script' in line:
                DistRank_run_script = line.strip('\n').split('=')[1]
                if ' ' in DistRank_run_script:DistRank_run_script.replace(' ','')
                DistRank_run_script = DistRank_path +'/' + DistRank_run_script

print("configure runing script...")
configure_file(DistRank_run_script, 'sh', 'GLOBAL_FLAG', 'global_dir', DistRank_path)

print("install python environment...")
os.chdir(DistRank_path);
os.system('sh installation/set_env.sh');
