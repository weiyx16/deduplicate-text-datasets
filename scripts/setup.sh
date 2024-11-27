echo 0
### ========= Install Rust ============
### We assume we are in the node setup in GPT-style
sudo chmod -R 777 /home/t-yixuanwei/.profile
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  # we need to enter 1 via command
source $HOME/.cargo/env
### ========= End ============

echo 1
### ========= Setup Envs ============
# ! Warning: [OPTIONAL] (used to download tf datasets for wiki-40B)
# ! Warning: with newest version we can't download the data.. (but notice that, the latest wiki40b is 1.3.0, for tfds with 3.0.0, the version of wiki40b is 1.1.0)
sudo /opt/conda/bin/pip install tensorflow tensorflow_datasets==3.0.0 sentencepiece apache_beam apache-beam[gcp]
### ========= End ============

echo 2
###  ========= Buildup Rust Envs ===========
glt clone https://github.com/weiyx16/deduplicate-text-datasets
cd deduplicate-text-datasets
cargo build
### ========= End ============

echo 3
############# FROM TENSORFLOW DATASETS #####################
# ! Warning: We can't load wiki40b actually...
### =========== Load data ===============
# This will create a file that's called data/wiki40b.test and data/wiki40b.test.size. The first file contains the entire Wiki40B test set smashed together, and the second file has the **byte offset** of where each individual training example begins, in sorted order.
sudo /opt/conda/bin/python scripts/load_dataset.py --data_dir ./tensorflow_datasets --save_dir data --name wiki40b --split test --tokenize # tokenize using gpt2-tokenizer to save space by round a factor of 2
sudo rm -r ./tensorflow_datasets
### =========== Build Suffix_array ================
# This will create a file data/wiki40b.test.table.bin containing the suffix array.
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/wiki40b.test
### ========= End ============
############# FROM TENSORFLOW DATASETS #####################

echo 3
############# FROM Our Datasets #####################
# We take a single openwebtext as an example
# ! Warning: For datasets with separated files, we need to merge them first.
# ! Warning: We may need another approach to tokenize them first. 
# ! Warning: 466M text => 1.9G table.bin (with 8.9M duplication occures) -> 452M text (rerun with 833 duplication occurs)
# We now support it tokenized. And we prefer to use it tokenized.
### =========== Convert the dataformat ============
export dataset=openwebtext.1.txt
python convertData.py --data_file data/$dataset --save_file data/$dataset.convert # --tokenize
export dataset=$dataset.convert
### ========= End ============

### =========== Build Suffix_array ================
# Finding all repeated substrings within a document
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset # --tokenize
sudo rm ./data/$dataset.part.*
### ========= End ============

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
############# FROM Our Datasets #####################

echo 3
############# To Our True Datasets From MultiSources ##################### 
# Assume dataset is the ancher, and we dedup the dataset2
# Validated with across-similar between dataset1 and dataset1 and we remove all sentences!!
export dataset2=openwebtext.2.txt
python convertData.py --data_file data/$dataset2 --save_file data/$dataset2.convert # --tokenize
export dataset2=$dataset2.convert
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset2 # --tokenize
sudo rm ./data/$dataset2.part.*

cargo run across-similar --data-file-1 data/$dataset --data-file-2 data/$dataset2 --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
sudo rm ./tmp/*

# gather lines of documents to be removed with has over $duplength overlap with others
cargo run collect --data-file data/$dataset2 --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file
sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset2 ./tmp/drop_tokens_file data/$dataset2.dedup False # the last one means detokenized or not
sudo rm ./tmp/*
sudo rm /tmp/cache/*
sudo rm ./data/$dataset2.part.*
sudo rm ./data/$dataset2.dedup.tmp

# the problems are how to fit it into RAM?

############# To Our True Datasets From MultiSources #####################

echo -1
############# Tutorials on illustration #####################
### [after suffix create] See how much times a query contained in suffix files
sudo /opt/conda/bin/python scripts/count_occurrences.py --suffix data/$dataset --query " on Tuesday" # --tokenize
### See how much times a query contained in original files
cat data/$dataset | grep -ao " on Tuesday" | wc -l

### [after deduplicate (self-similar and collect)] See the exact duplicated ones
data = open("$dataset","rb").read()
import re
tofind = data[22668:22727]
data.count(tofind)
indexes = [m.start() for m in re.finditer(tofind, data)]
for  index in indexes:
    print(data[index:index+200])
############# Tutorials on illustration #####################