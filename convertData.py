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
# parser.add_argument('--save_dir', default='./', type=str)
parser.add_argument('--save_file', default='./', type=str)
parser.add_argument('--subset', default='0/1', type=str)
parser.add_argument('--tokenize', action='store_true')
parser.add_argument('--tokenizer', type=str, default="gpt2")
parser.add_argument('--pre_sep', type=bytes, default=b"\xff\xff")
parser.add_argument('--post_sep', type=bytes, default=b"")
args = parser.parse_args()

if args.tokenize:
    # assert False, "we don't support it due to de-tokenizer part"
    if args.tokenizer == 'gpt2':
        tokenizer = GPT2Tokenizer.from_pretrained('gpt2')
    # elif args.tokenizer == 't5':
    #     tokenizer = T5Tokenizer.from_pretrained('t5-small')
    else:
        raise
else:
    tokenizer = None

xth, ytotal = list(map(lambda x: int(x),  args.subset.split('/')))
assert xth < ytotal, f"xth should be smaller than ytotal: subset = {args.subset}"
if ytotal > 1:
    assert len(args.data_dir) > 5, "We don't support subset for single file input"

pre_sep = args.pre_sep
post_sep = args.post_sep

data_dir = args.data_dir
# save_dir = args.save_dir
data_file = args.data_file
save_file = args.save_file

UID = 0
def sep():
    if not args.tokenize:
        return b''
    global UID
    UID += 1
    return pre_sep+struct.pack("<I", UID)+post_sep

def tok(x):
    if args.tokenize:
        x = x.decode("utf-8")
        x = x.split('\n')
        out = [tokenizer.encode(_x) for _x in x]
        out_convert = []
        for _out in out:
            _out = _out + [65534]
            out_convert.extend(_out) # 65535 is the beginning
        # we don't need the separator of documents since we have sep()
        out = np.array(out_convert, dtype=np.uint16).tobytes() # np.array(out, dtype=np.uint16).view(np.uint8).tobytes()
    else:
        out = x
    return out


# if not os.path.exists(save_dir):
#     os.mkdir(save_dir)


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
            # e.g. CC202050 and Pile-CC
            src_text = list(jsonlines.open(data_file, 'r'))
            text = []
            for l in tqdm(src_text, miniters=1000000, mininterval=60):
                prev = l['text'].replace('\n\n', '\n').replace('\n\n\n', '\n').strip('\n')+'\n\n'
                text.append(prev.encode('utf-8'))
            del src_text
        else:
            raise NotImplementedError(data_file)

        text = p.map(tok, text)
        for x in text:
            next_line = sep() + x
            fout.write(next_line)
        del text

elif len(data_dir) > 5:
    # for folder input, we also save it to a single file
    data_files = os.listdir(data_dir)
    data_files = [os.path.join(data_dir, data_file) for data_file in data_files]
    data_files.sort()
    if ytotal > 1:
        files_per_subset = len(data_files) // ytotal + 1
        data_files = data_files[xth * files_per_subset: min((xth+1) * files_per_subset, len(data_files))]
        print(f" Use subset: {len(data_files)}")
    fout = open(save_file, "wb")

    for data_file in data_files:
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
                        # we add \n\n use special tokens
                        prev = prev.strip('\n')
                        if not args.tokenize:
                            prev += '\n\n'
                        text.append(prev.encode('utf-8'))
                        prev = ''
                if prev != '' and prev != '\n':
                    prev = prev.strip('\n')
                    text.append(prev.encode('utf-8'))
                del src_text
            elif data_file.endswith('jsonl'):
                # e.g. CC202050 and Pile-CC
                src_text = list(jsonlines.open(data_file, 'r'))
                text = []
                for l in tqdm(src_text, miniters=1000000, mininterval=60):
                    prev = l['text'].replace('\n\n', '\n').replace('\n\n\n', '\n').strip('\n')+'\n\n'
                    text.append(prev.encode('utf-8'))
                del src_text
            else:
                raise NotImplementedError(data_file)

            text = p.map(tok, text)
            for x in text:
                next_line = sep() + x
                fout.write(next_line)
            del text