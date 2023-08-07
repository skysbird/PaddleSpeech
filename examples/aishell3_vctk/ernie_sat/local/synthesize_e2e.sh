# not ready yet
#!/bin/bash

config_path=$1
train_output_path=$2
ckpt_name=$3

stage=0
stop_stage=1

#if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
#    echo 'speech cross language from en to zh !'
#    FLAGS_allocator_strategy=naive_best_fit \
#    FLAGS_fraction_of_gpu_memory_to_use=0.01 \
#    python3 ${BIN_DIR}/synthesize_e2e.py \
#        --task_name=synthesize \
#        --wav_path=source/p243_313.wav \
#        --old_str='For that reason cover should not be given' \
#        --new_str='今天天气很好' \
#        --source_lang=en \
#        --target_lang=zh \
#        --erniesat_config=${config_path} \
#        --phones_dict=dump/phone_id_map.txt \
#        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
#        --erniesat_stat=dump/speech_stats.npy \
#        --voc=hifigan_aishell3 \
#        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
#        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
#        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
#        --output_name=exp/pred_clone_en_zh.wav
#fi
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo 'speech cross language from zh to en !'
    FLAGS_allocator_strategy=naive_best_fit \
    FLAGS_fraction_of_gpu_memory_to_use=0.01 \
    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/t.wav \
        --old_str='挺挺就过去了' \
        --new_str="it will be ok" \
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en.wav

    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/2.wav \
        --old_str='你要是不想砸了我们班的牌子' \
        --new_str="If you don't want to smash our brand" \
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en2.wav



    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/5.wav \
        --old_str='你还不如让朱韵来个反手摸肚脐' \
        --new_str="Why don't you ask Zhu Yun to touch her navel with a backhand" \
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en3.wav


    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/13.wav \
        --old_str='真有那么差啊' \
        --new_str="It's really that bad" \
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en5.wav

    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/10.wav \
        --old_str='我觉得应该叫活体雕塑' \
        --new_str="I think it should be called living sculpture"\
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en6.wav

    python3 ${BIN_DIR}/synthesize_e2e.py \
        --task_name=synthesize \
        --wav_path=source/13.wav \
        --old_str='你不在天台敲你的电脑' \
        --new_str="You're not knocking on your computer on the rooftop" \
        --source_lang=zh \
        --target_lang=en \
        --erniesat_config=${config_path} \
        --phones_dict=dump/phone_id_map.txt \
        --erniesat_ckpt=${train_output_path}/checkpoints/${ckpt_name} \
        --erniesat_stat=dump/speech_stats.npy \
        --voc=hifigan_aishell3 \
        --voc_config=hifigan_aishell3_ckpt_0.2.0/default.yaml \
        --voc_ckpt=hifigan_aishell3_ckpt_0.2.0/snapshot_iter_2500000.pdz \
        --voc_stat=hifigan_aishell3_ckpt_0.2.0/feats_stats.npy \
        --output_name=exp/pred_clone_zh_en7.wav












fi

