exp=exp
data=data

mkdir -p $exp
mkdir -p $data

LEXICON_NAME='simple'
MFA_DOWNLOAD_DIR=local/

if [ ! -f "$exp/$LEXICON_NAME.lexicon" ]; then
    echo "generating lexicon..."
    python local/generate_lexicon.py "$exp/$LEXICON_NAME" --with-r --with-tone
    echo "lexicon done"
fi

if [ ! -d $exp/aishell3_corpus ]; then
    echo "reorganizing aishell3 corpus..."
    python local/reorganize_aishell3.py --root-dir=~/work/sky/dataset --output-dir=$exp/aishell3_corpus 
    echo "reorganization done. Check output in $exp/aishell3_corpus."
    echo "audio files are resampled to 16kHz"
    echo "transcription for each audio file is saved with the same namd in $exp/aishell3_corpus "
fi


echo "detecting oov..."
python local/detect_oov.py $exp/aishell3_corpus $exp/"$LEXICON_NAME.lexicon"
echo "detecting oov done. you may consider regenerate lexicon if there is unexpected OOVs."


if [ ! -f "$MFA_DOWNLOAD_DIR/montreal-forced-aligner_linux.tar.gz" ]; then
    echo "downloading mfa..."
    (cd $MFA_DOWNLOAD_DIR && wget https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner/releases/download/v1.0.1/montreal-forced-aligner_linux.tar.gz)
    echo "download mfa done!"
fi

if [ ! -d "$MFA_DOWNLOAD_DIR/montreal-forced-aligner" ]; then
    echo "extracting mfa..."
    (cd $MFA_DOWNLOAD_DIR && tar xvf "montreal-forced-aligner_linux.tar.gz")
    echo "extraction done!"
fi

export PATH="$MFA_DOWNLOAD_DIR/montreal-forced-aligner/bin"

if [ ! -d "$exp/aishell3_alignment" ]; then
    echo "Start MFA training..."
    PATH=$MFA_DOWNLOAD_DIR/montreal-forced-aligner/bin/:$PATH \
    LD_LIBRARY_PATH=$MFA_DOWNLOAD_DIR/montreal-forced-aligner/lib/:$LD_LIBRARY_PATH \
    ./$MFA_DOWNLOAD_DIR/montreal-forced-aligner/bin/mfa_train_and_align \
        $exp/aishell3_corpus "$exp/$LEXICON_NAME.lexicon" $exp/aishell3_alignment -o $exp/aishell3_model --clean --verbose -j 10 --temp_directory $exp/.mfa_train_and_align
    echo "training done!"
    echo "results: $exp/aishell3_alignment"
    echo "model: $exp/aishell3_model"
fi

