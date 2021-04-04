import os
import sys
import numpy as np

# target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/chain_added_casp8_scwrl_all_predictions_final/' #T0455 T0501
# target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/chain_added_casp9_scwrl_all_predictions_final/' #T0518 T0606
# target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/chain_added_casp10_scwrl_all_predictions_final/' #T0719 T0713
# target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/chain_added_casp11_scwrl_all_predictions_final/' #T0793 T0852 
# target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/chain_added_casp12_scwrl_all_predictions_final/' #T0868
target_dir = '/mnt/data/zhiye/Python/DistRank/output/DeepRank3/casp13_server_models/' # 979 980s2

dist_map_dir = "/mnt/data/zhiye/Python/DistRank/output/DeepRank3/deepdist/"
fasta_dir = "/mnt/data/zhiye/Python/DistRank/output/DeepRank3/all_fasta/"

method = 'DFOLD' # TEMP DFOLD

def chkdirs(fn):
	'''create folder if not exists'''
	dn = os.path.dirname(fn)
	if not os.path.exists(dn): os.makedirs(dn)

files = os.listdir(target_dir)
for file in files:
	if 'T' in file:
		seq_name = file
		print("process %s..."%seq_name)

		input_folder = target_dir + '/' + seq_name + '/'
		dist_map_file = dist_map_dir + '/' + seq_name + '.txt'
		fasta_file = fasta_dir + '/' + seq_name + '.fasta'
		output_dir = target_dir + '/' + seq_name + '/'
		if os.path.exists(dist_map_file) == False:
			print('Dist map not exits, continue!')
			continue

		GLOABL_Path = os.path.dirname(sys.path[0])
		os.system("python %s/lib/dfold_rank.py -f %s -d %s -fa %s -o %s -r %s"%(GLOABL_Path, input_folder, dist_map_file, fasta_file, output_dir, True))
		# sys.exit(1)

# summary_dir = target_dir + '/features/'
# chkdirs(summary_dir)
# for file in files:
# 	if 'T' in file:
# 		seq_name = file
# 		print("process %s..."%seq_name)
# 		tar_fea_dir = summary_dir + '/' + seq_name
# 		chkdirs(tar_fea_dir)
# 		info_txt =target_dir + '/' + seq_name +'/sum_info.txt'

# 		info_file = open(info_txt, 'r')
# 		info_line = []
# 		info_name = []
# 		for l in info_file.readlines():
# 			original_line = l.strip('\n')
# 			if original_line == '':
# 				continue
# 			if 'tb_dist_name' in original_line:
# 				continue
# 			info_line.append(original_line)
# 			info_name.append(original_line.split('\t')[0])

# 		rmse = 

# 	if method == 'DFOLD':
# 		with open(summary, 'a') as myfile:
# 			myfile.write("%s\n"%seq_name)
# 			myfile.write("fasta_name\ttb_dist_name\trmse\tpearson\tprecl2\tprecl2long\trecall\trecalllong\ttb_psnr\ttb_ssim\ttb_phash\ttb_gist\torb_num\tsum_info_ori\tsum_info\n")	
# 		info_txt =target_dir + '/' + seq_name +'/sum_info.txt'
# 		rank_txt = target_dir + '/' +  seq_name +'/rank.txt'

# 	rank_file = open(rank_txt, 'r')
# 	rank = []
# 	for l in rank_file.readlines():
# 		rank.append(l.strip('\n').split('\t')[0])
# 	true_rank = []
# 	tm_score = []
# 	if os.path.exists(true_rank_txt):
# 		true_rank_file = open(true_rank_txt, 'r')
# 		for l in true_rank_file.readlines():
# 			true_rank.append(l.strip('\n').split(' ')[0])
# 			tm_score.append(l.strip('\n').split(' ')[6])
# 		tm_score = np.array(tm_score, dtype=np.float16)
# 		tm_index = np.argsort(-tm_score)

# 	info_file = open(info_txt, 'r')
# 	info_line = []
# 	info_name = []
# 	for l in info_file.readlines():
# 		original_line = l.strip('\n')
# 		if original_line == '':
# 			continue
# 		if 'tb_dist_name' in original_line:
# 			continue
# 		info_line.append(original_line)
# 		info_name.append(original_line.split('\t')[0])

# 	if method == 'TEMP':
# 		for i in range(len(tm_index)):
# 			tm = tm_score[tm_index[i]]
# 			temp_name = true_rank[tm_index[i]] + '_local'
# 			rank_index = rank.index(temp_name)
# 			# print(rank_index)
# 			info_index = info_name.index(temp_name)
# 			original_line = info_line[info_index]
# 			new_line = seq_name + '\t' + original_line + '\t' + str(tm) + '\t' + str(rank_index + 1) + '\n'
# 			with open(summary, 'a') as myfile:
# 				myfile.write(new_line)
# 			if rank_index == 0:
# 				with open(rank_top1, 'a') as myfile:
# 					myfile.write(new_line)
# 	elif method == 'DFOLD':
# 		if os.path.exists(true_rank_txt):
# 			for i in range(len(tm_index)):
# 				tm = tm_score[tm_index[i]]
# 				temp_name = true_rank[tm_index[i]]
# 				rank_index = rank.index(temp_name)
# 				# print(rank_index)
# 				info_index = info_name.index(temp_name)
# 				original_line = info_line[info_index]
# 				new_line = seq_name + '\t' + original_line + '\t' + str(tm) + '\t' + str(rank_index + 1) + '\n'
# 				with open(summary, 'a') as myfile:
# 					myfile.write(new_line)
# 				if rank_index == 0:
# 					with open(rank_top1, 'a') as myfile:
# 						myfile.write(new_line)
# 				# train_index = train_name.index(temp_name)
# 				# original_line = train_line[train_index]
# 				# new_line = original_line + '\t' + str(i)+'\n'
# 				# with open(for_train, 'a') as myfile:
# 				# 	myfile.write(seq_name + '\t' + new_line)
# 		else:
# 			for i in range(len(rank)):
# 				temp_name = rank[i]
# 				# print(rank_index)
# 				info_index = info_name.index(temp_name)
# 				original_line = info_line[info_index]
# 				new_line = original_line + '\t' + str(i + 1) + '\n'
# 				with open(summary, 'a') as myfile:
# 					myfile.write(new_line)
# 				if i == 0:
# 					with open(rank_top1, 'a') as myfile:
# 						myfile.write(seq_name + '\t' + new_line)


