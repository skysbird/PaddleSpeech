#!/bin/bash

stage=0
stop_stage=100

config_path=$1


input_dir=./cusdata
newdir_name="newdir"
new_dir=${input_dir}/${newdir_name}
mfa_dir=./mfa_result
lang=zh
pretrained_model_dir=./fastspeech2_mix_ckpt_1.2.0
output_dir=./exp/default

# check oov
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "check oov"
    python3 local/check_oov.py \
        --input_dir=${input_dir} \
        --pretrained_model_dir=${pretrained_model_dir} \
        --newdir_name=${newdir_name} \
        --lang=${lang}
fi


# get mfa result
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "get mfa result"
    python3 local/get_mfa_result.py \
        --input_dir=${new_dir} \
        --mfa_dir=${mfa_dir} \
        --lang=${lang}
fi

# generate durations.txt
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "generate durations.txt"
    python3 local/generate_duration.py \
        --mfa_dir=${mfa_dir}
fi


#if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
#    # get durations from MFA's result
#    echo "Generate durations.txt from MFA results ..."
#    python3 ${MAIN_ROOT}/utils/gen_duration_from_textgrid.py \
#        --inputdir=./vctk_alignment \
#        --output=durations.txt \
#        --config=${config_path}
#fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    # extract features
    echo "Extract features ..."
    python3 local/preprocess.py \
        --rootdir=${new_dir} \
        --dataset=vctk \
        --dumpdir=dump \
        --dur-file=durations.txt \
        --config=${config_path} \
        --cut-sil=True \
        --num-cpu=20
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    # get features' stats(mean and std)
    echo "Get features' stats ..."
    python3 ${MAIN_ROOT}/utils/compute_statistics.py \
        --metadata=dump/train/raw/metadata.jsonl \
        --field-name="feats"
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    # normalize, dev and test should use train's stats
    echo "Normalize ..."
   
    python3 ${BIN_DIR}/../normalize.py \
        --metadata=dump/train/raw/metadata.jsonl \
        --dumpdir=dump/train/norm \
        --stats=dump/train/feats_stats.npy \
        --skip-wav-copy

    python3 ${BIN_DIR}/../normalize.py \
        --metadata=dump/dev/raw/metadata.jsonl \
        --dumpdir=dump/dev/norm \
        --stats=dump/train/feats_stats.npy \
        --skip-wav-copy
    
    #python3 ${BIN_DIR}/../normalize.py \
    #    --metadata=dump/test/raw/metadata.jsonl \
    #    --dumpdir=dump/test/norm \
    #    --stats=dump/train/feats_stats.npy \
    #    --skip-wav-copy
fi


# create finetune env
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "create finetune env"
    python3 local/prepare_env.py \
        --pretrained_model_dir=${pretrained_model_dir} \
        --output_dir=${output_dir}
fi
