import os
import sys
import numpy as np

target_list = "/mnt/data/zhiye/Python/DNCON4/data/CASP13/lists-test-train/test.lst"
target_list = "/mnt/data/zhiye/Python/DistRank/output/CASP_common/target.lst"
# dist_map_dir = "/mnt/data/zhiye/Python/DNCON4/architecture_distance/Test/DeepDist/casp13_ag_v3rc_v3rcmsa_domain_R/ensemble2/pred_map_ensem_dm/real_dist/"
dist_map_dir = "/mnt/data/zhiye/Python/DNCON4/architecture_distance/Test/DeepDist/casp13_ag_v3rc_v3rcmsa_domain_R_11k/ensemble/pred_map_ensem_dm/real_dist/"
dist_map_dir = "/mnt/data/zhiye/Python/DistRank/output/CASP_common/distmap/"
# dist_map_dir = "/mnt/data/zhiye/Python/DistRank/output/CASP_common//"
# temp_rank_dir = "/mnt/data/zhiye/Python/DistRank/output/multicom/"
# temp_rank_dir = "/mnt/data/zhiye/Python/DistRank/output/m_r_AGR_11k/"
temp_rank_dir = "/mnt/data/zhiye/Python/DistRank/output/CASP_common/"
# fasta_dir = "/mnt/data/zhiye/Python/DNCON4/data/CASP13/fasta/" 
fasta_dir = "/mnt/data/zhiye/Python/DistRank/output/CASP_common/fasta/"

method = 'DFOLD' # TEMP DFOLD

f = open(target_list, 'r')
for line in f.readlines():
	single_line = line.strip('\n')
	seq_name = single_line
	print("process %s..."%seq_name)

	input_folder = temp_rank_dir + '/' + seq_name + '/'
	dist_map_file = dist_map_dir + '/' + seq_name + '.txt'
	fasta_file = fasta_dir + '/' + seq_name + '.fasta'
	output_dir = temp_rank_dir + '/' + seq_name + '/'

	GLOABL_Path = os.path.dirname(sys.path[0])
	if method == 'TEMP':
		os.system("python %s/lib/template_rank.py -f %s -d %s -fa %s -o %s"%(GLOABL_Path, input_folder, dist_map_file, fasta_file, output_dir))
	elif method == 'DFOLD':
		os.system("python %s/lib/dfold_rank.py -f %s -d %s -fa %s -o %s"%(GLOABL_Path, input_folder, dist_map_file, fasta_file, output_dir))

summary = temp_rank_dir + '/summary31.txt'
rank_top1 = temp_rank_dir + '/rank31.txt'
for_train = temp_rank_dir + '/train_data_int.txt'
if os.path.exists(summary):os.remove(summary)
if os.path.exists(rank_top1):os.remove(rank_top1)
if os.path.exists(for_train):os.remove(for_train)
f = open(target_list, 'r')
for line in f.readlines():
	single_line = line.strip('\n')
	seq_name = single_line
	print("process %s..."%seq_name)

	if method == 'TEMP':
		with open(summary, 'a') as myfile:
			myfile.write("%s\n"%seq_name)
			myfile.write("fasta_name\ttb_dist_name\tevalu\tprob\trmse\tpearson\tprecl2\tprecl2long\ttb_psnr\ttb_psnr_local\ttb_ssim\ttb_ssim_local\ttb_phash\ttb_gist\torb_num\tsum_info_ori\tsum_info\ttm_score\trank\n")
		info_txt =temp_rank_dir + '/' + seq_name +'/sum_info.txt'
		rank_txt = temp_rank_dir + '/' +  seq_name +'/rank.txt'
		true_rank_txt = temp_rank_dir + '/' + seq_name +'/true_rank.txt'
	elif method == 'DFOLD':
		with open(summary, 'a') as myfile:
			myfile.write("%s\n"%seq_name)
			myfile.write("fasta_name\ttb_dist_name\trmse\tpearson\tprecl2\tprecl2long\trecall\trecalllong\ttb_psnr\ttb_ssim\ttb_phash\ttb_gist\torb_num\tsum_info_ori\tsum_info\tsum_info_avg\ttm_score\trank\n")	
		info_txt =temp_rank_dir + '/' + seq_name +'/sum_info.txt'
		rank_txt = temp_rank_dir + '/' +  seq_name +'/rank.txt'
		true_rank_txt = temp_rank_dir + '/' + seq_name +'/true_rank.txt'
		# train_txt = temp_rank_dir + '/' + seq_name +'/X.txt'

	rank_file = open(rank_txt, 'r')
	rank = []
	for l in rank_file.readlines():
		rank.append(l.strip('\n').split('\t')[0])
	true_rank = []
	tm_score = []
	if os.path.exists(true_rank_txt):
		true_rank_file = open(true_rank_txt, 'r')
		for l in true_rank_file.readlines():
			true_rank.append(l.strip('\n').split(' ')[0])
			tm_score.append(l.strip('\n').split(' ')[6])
		tm_score = np.array(tm_score, dtype=np.float16)
		tm_index = np.argsort(-tm_score)

	info_file = open(info_txt, 'r')
	info_line = []
	info_name = []
	for l in info_file.readlines():
		original_line = l.strip('\n')
		if original_line == '':
			continue
		if 'tb_dist_name' in original_line:
			continue
		info_line.append(original_line)
		info_name.append(original_line.split('\t')[0])

	# if method == 'DFOLD':
	# 	train_file = open(train_txt, 'r')
	# 	train_line = []
	# 	train_name = []
	# 	for l in train_file.readlines():
	# 		original_line = l.strip('\n')
	# 		if original_line == '':
	# 			continue
	# 		if 'tb_dist_name' in original_line:
	# 			continue
	# 		train_line.append(original_line)
			# train_name.append(original_line.split('\t')[0])

	if method == 'TEMP':
		for i in range(len(tm_index)):
			tm = tm_score[tm_index[i]]
			temp_name = true_rank[tm_index[i]] + '_local'
			rank_index = rank.index(temp_name)
			# print(rank_index)
			info_index = info_name.index(temp_name)
			original_line = info_line[info_index]
			new_line = seq_name + '\t' + original_line + '\t' + str(tm) + '\t' + str(rank_index + 1) + '\n'
			with open(summary, 'a') as myfile:
				myfile.write(new_line)
			if rank_index == 0:
				with open(rank_top1, 'a') as myfile:
					myfile.write(new_line)
	elif method == 'DFOLD':
		if os.path.exists(true_rank_txt):
			for i in range(len(tm_index)):
				tm = tm_score[tm_index[i]]
				temp_name = true_rank[tm_index[i]]
				rank_index = rank.index(temp_name)
				# print(rank_index)
				info_index = info_name.index(temp_name)
				original_line = info_line[info_index]
				new_line = seq_name + '\t' + original_line + '\t' + str(tm) + '\t' + str(rank_index + 1) + '\n'
				with open(summary, 'a') as myfile:
					myfile.write(new_line)
				if rank_index == 0:
					with open(rank_top1, 'a') as myfile:
						myfile.write(new_line)
				# train_index = train_name.index(temp_name)
				# original_line = train_line[train_index]
				# new_line = original_line + '\t' + str(i)+'\n'
				# with open(for_train, 'a') as myfile:
				# 	myfile.write(seq_name + '\t' + new_line)
		else:
			for i in range(len(rank)):
				temp_name = rank[i]
				# print(rank_index)
				info_index = info_name.index(temp_name)
				original_line = info_line[info_index]
				new_line = original_line + '\t' + str(i + 1) + '\n'
				with open(summary, 'a') as myfile:
					myfile.write(new_line)
				if i == 0:
					with open(rank_top1, 'a') as myfile:
						myfile.write(seq_name + '\t' + new_line)


