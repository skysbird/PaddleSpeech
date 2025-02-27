#!/bin/bash

stage=3
stop_stage=100

config_path=$1

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    # get durations from MFA's result
    echo "Generate durations.txt from MFA results for aishell3 ..."
    python3 ${MAIN_ROOT}/utils/gen_duration_from_textgrid.py \
        --inputdir=./aishell3_alignment_tone \
        --output durations_aishell3.txt \
        --config=${config_path}
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    # get durations from MFA's result
    echo "Generate durations.txt from MFA results for libritts ..."
    python3 ${MAIN_ROOT}/utils/gen_duration_from_textgrid.py \
        --inputdir=./libritts_alignment \
        --output durations_libritts.txt \
        --config=${config_path}

    # get durations from MFA's result
    echo "Generate durations.txt from MFA results for vctk ..."
    python3 ${MAIN_ROOT}/utils/gen_duration_from_textgrid.py \
        --inputdir=./vctk_alignment \
        --output durations_vctk.txt \
        --config=${config_path}
fi



if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    # get durations from MFA's result
    echo "concat durations_aishell3.txt and durations_vctk.txt to durations.txt"
    cat durations_aishell3.txt durations_vctk.txt durations_libritts > durations.txt
fi


if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    # extract features
    echo "Extract features ..."
    python3 ${BIN_DIR}/preprocess.py \
        --dataset=libritts \
        --rootdir=LibriTTS \
        --dumpdir=dump \
        --dur-file=durations.txt \
        --config=${config_path} \
        --num-cpu=20 \
        --cut-sil=True
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    # extract features
    echo "Extract features ..."
    python3 ${BIN_DIR}/preprocess.py \
        --dataset=aishell3 \
        --rootdir=~/work/sky/dataset/ \
        --dumpdir=dump \
        --dur-file=durations.txt \
        --config=${config_path} \
        --num-cpu=20 \
        --cut-sil=True
fi

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    # extract features
    echo "Extract features ..."
    python3 ${BIN_DIR}/preprocess.py \
        --dataset=vctk \
        --rootdir=~/work/sky/dataset/VCTK/ \
        --dumpdir=dump \
        --dur-file=durations.txt \
        --config=${config_path} \
        --num-cpu=20 \
        --cut-sil=True
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    # get features' stats(mean and std)
    echo "Get features' stats ..."
    python3 ${MAIN_ROOT}/utils/compute_statistics.py \
        --metadata=dump/train/raw/metadata.jsonl \
        --field-name="speech"
fi

if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    # normalize and covert phone/speaker to id, dev and test should use train's stats
    echo "Normalize ..."
    python3 ${BIN_DIR}/normalize.py \
        --metadata=dump/train/raw/metadata.jsonl \
        --dumpdir=dump/train/norm \
        --speech-stats=dump/train/speech_stats.npy \
        --phones-dict=dump/phone_id_map.txt \
        --speaker-dict=dump/speaker_id_map.txt

    python3 ${BIN_DIR}/normalize.py \
        --metadata=dump/dev/raw/metadata.jsonl \
        --dumpdir=dump/dev/norm \
        --speech-stats=dump/train/speech_stats.npy \
        --phones-dict=dump/phone_id_map.txt \
        --speaker-dict=dump/speaker_id_map.txt

    python3 ${BIN_DIR}/normalize.py \
        --metadata=dump/test/raw/metadata.jsonl \
        --dumpdir=dump/test/norm \
        --speech-stats=dump/train/speech_stats.npy \
        --phones-dict=dump/phone_id_map.txt \
        --speaker-dict=dump/speaker_id_map.txt
fi
