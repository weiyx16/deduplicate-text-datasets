import os
import struct
import jsonlines
import numpy as np
from tqdm import tqdm
from transformers import GPT2Tokenizer, T5Tokenizer
import multiprocessing as mp

import argparse

parser = argparse.ArgumentParser(description='Load a dataset.')
parser.add_argument('--data_dir', default='./', type=str)
parser.add_argument('--data_file', default='./', type=str)
parser.add_argument('--save_dir', default='./', type=str)
parser.add_argument('--save_file', default='./', type=str)
parser.add_argument('--tokenize', action='store_true')
parser.add_argument('--tokenizer', type=str, default="gpt2")
parser.add_argument('--pre_sep', type=bytes, default=b"\xff\xff")
parser.add_argument('--post_sep', type=bytes, default=b"")
args = parser.parse_args()

if args.tokenize:
    assert False, "we don't support it due to de-tokenizer part"
    if args.tokenizer == 'gpt2':
        tokenizer = GPT2Tokenizer.from_pretrained('gpt2')
    elif args.tokenizer == 't5':
        tokenizer = T5Tokenizer.from_pretrained('t5-small')
    else:
        raise
else:
    tokenizer = None

pre_sep = args.pre_sep
post_sep = args.post_sep

data_dir = args.data_dir
save_dir = args.save_dir
data_file = args.data_file
save_file = args.save_file

UID = 0
def sep():
    global UID
    UID += 1
    return pre_sep+struct.pack("<I", UID)+post_sep

def tok(x):
    if args.tokenize:
        out = tokenizer.encode(x.decode("utf-8"))
        out = np.array(out, dtype=np.uint16).tobytes() # np.array(out, dtype=np.uint16).view(np.uint8).tobytes()
    else:
        out = x
    return out


if not os.path.exists(save_dir):
    os.mkdir(save_dir)


if len(data_file) > 5:
    fout = open(save_file, "wb")


    with mp.get_context("fork").Pool(mp.cpu_count()) as p:
        if data_file.endswith('txt'):
            # e.g. openwebtext
            src_text = open(data_file).readlines()
            text = []
            # we need to merge document into a single line with \n to seperate the sentences or paragraphs.
            prev = ''
            for x in tqdm(src_text, miniters=1000000, mininterval=60):
                if x != '\n':
                    prev += x
                else:
                    # we reach the end of documents
                    prev = prev.strip('\n')+'\n\n'
                    text.append(prev.encode('utf-8'))
                    prev = ''
            if prev != '' and prev != '\n':
                prev = prev.strip('\n')+'\n\n'
                text.append(prev.encode('utf-8'))
            del src_text
        elif data_file.endswith('jsonl'):
            src_text = list(jsonlines.open(args.file, 'r'))
            text = []
            for l in tqdm(src_text, miniters=1000000, mininterval=60):
                prev = l['text'].strip('\n')+'\n\n'
                text.append(prev.encode('utf-8'))
            del src_text
            
        text = p.map(tok, text)
        for x in text:
            next_line = x # sep() + x
            fout.write(next_line)