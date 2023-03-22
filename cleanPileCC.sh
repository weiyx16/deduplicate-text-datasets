set -x

echo 0
### ========= Install Rust ============
### We assume we are in the node setup in GPT-style
sudo chmod -R 777 /home/$USER/.profile
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rust.sh
sh rust.sh -y
source $HOME/.cargo/env
### ========= End ============

echo 1
### ========= Setup Envs ============
# ! Warning: [OPTIONAL] (used to download tf datasets for wiki-40B)
# ! Warning: with newest version we can't download the data.. (but notice that, the latest wiki40b is 1.3.0, for tfds with 3.0.0, the version of wiki40b is 1.1.0)
sudo /opt/conda/bin/pip install jsonlines tensorflow tensorflow_datasets==3.0.0 sentencepiece transformers apache_beam apache-beam[gcp]
### ========= End ============

echo 2
###  ========= Buildup Rust Envs ===========
cargo build
### ========= End ==============

echo 3
### ========== Download Data ===============
/output/azcopy copy "https://vlpretraineastus.blob.core.windows.net/crawl-text/the-pile/train/Pile-CC?sv=2021-04-10&st=2022-09-06T05%3A36%3A34Z&se=2025-09-05T05%3A36%3A00Z&sr=c&sp=racwdxltf&sig=8yIkemAX4aA8frrJoW1snsJB07suONjEHC5zR736MQw%3D" --recursive ./
### ========= End ==============

echo 4
### =========== Convert the dataformat ============
export dataset=PileCC.txt
python convertData.py --data_dir ./Pile-CC --save_file data/$dataset.convert # --tokenize
sudo rm -r ./Pile-CC
export dataset=$dataset.convert
### ========= End ============

echo 5
### =========== Build Suffix_array ================
# Finding all repeated substrings within a document
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset # --tokenize
sudo rm ./data/$dataset.part.*
### ========= End ============

echo 6
### =========== Deduplicate ================
# Output means: This means that the deduplicator found $output sequences of length $length that existed somewhere else in the dataset.
# In our paper, we used 50 tokens (which is 100 bytes---so remember that if you pass --tokenize you'll need to double the number of bytes for the length threshold).
export duplength=50
cargo run self-similar --data-file data/$dataset --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
sudo rm ./tmp/*

# gather lines of documents to be removed with has over $duplength overlap with others
cargo run collect --data-file data/$dataset --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file

sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset ./tmp/drop_tokens_file data/$dataset.dedup False # the last one means detokenized or not
sudo rm ./tmp/*
sudo rm /tmp/cache/*
sudo rm ./data/$dataset.part.*
sudo rm ./data/$dataset.dedup.tmp
### ========= End ============

echo 7
### ========== Upload Data ===============
/output/azcopy copy data/$dataset.dedup "https://vlpretraineastus.blob.core.windows.net/crawl-text/cc_merged/PileCC.dedup.txt?sv=2021-04-10&st=2022-09-06T05%3A36%3A34Z&se=2025-09-05T05%3A36%3A00Z&sr=c&sp=racwdxltf&sig=8yIkemAX4aA8frrJoW1snsJB07suONjEHC5zR736MQw%3D"