#!/bin/bash

config_path=$1
train_output_path=$2

FLAGS_cudnn_exhaustive_search=true \
FLAGS_conv_workspace_size_limit=4000 \
#python local/finetune.py \
#    --train-metadata=dump/train/norm/metadata.jsonl \
#    --dev-metadata=dump/dev/norm/metadata.jsonl \
#    --config=${config_path} \
#    --pretrained_model_dir=pwg_vctk_ckpt_0.5 \
#    --output-dir=${train_output_path} \
#    --epoch 10000 \
#    --ngpu=2


python local/train.py \
    --train-metadata=dump/train/norm/metadata.jsonl \
    --dev-metadata=dump/dev/norm/metadata.jsonl \
    --config=${config_path} \
    --output-dir=${train_output_path} \
    --ngpu=2



