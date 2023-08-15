from pathlib import Path
from pypinyin import pinyin, lazy_pinyin, Style

from paddlespeech.cli.asr.infer import ASRExecutor
asr = ASRExecutor()
p = Path('cusdata')

wav_file = p.rglob("*.wav")
"""
text = asr_executor(
    model='conformer_wenetspeech',
    lang='zh',
    sample_rate=16000,
    config=None,  # Set `config` and `ckpt_path` to None to use pretrained model.
    ckpt_path=None,
    audio_file='./zh.wav',
    force_yes=False,
    device=paddle.get_device())
    """


def _replace_file_extension(path, suffix):
    return (path.parent / path.name.split(".")[0]).with_suffix(suffix)

name = "lables.txt"
with open(name,"w") as label:
    for w in wav_file:
        try:
            print(w)
            result = asr(
            model='conformer_wenetspeech',
            lang='zh',
            sample_rate=16000,
            config=None,  # Set `config` and `ckpt_path` to None to use pretrained model.
            ckpt_path=None,
            audio_file=w,
            force_yes=True,
            device='cpu')
    
            #write
    
            #txt_file = _replace_file_extension(w,".normalized.txt")
            #with open(txt_file,'w') as t:
            #    t.write(result)

            pout = lazy_pinyin(result, style=Style.TONE3, neutral_tone_with_five=True)

            ph = " ".join(pout)
            label.write(f"{w.stem}|{ph}\n")
        except Exception as e:
            print(e)
