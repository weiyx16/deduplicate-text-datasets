# Copyright 2022 Google LLC
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import numpy as np
from transformers import GPT2Tokenizer
import multiprocessing as mp

original = sys.argv[1]
remove_file = sys.argv[2]
deduped = sys.argv[3]
tokenized = sys.argv[4]

if tokenized == "True":
    # assert False, "we don't support it due to de-tokenizer part"
    tokenizer = GPT2Tokenizer.from_pretrained('gpt2')
else:
    tokenizer = None

def tok(x):
    if tokenizer is not None:
        # x = np.frombuffer(x, dtype=np.uint16) #.view(np.uint16)
        # we have ensure that we start with \xff\xff id id with np.split in the previous part.
        x = x[3:] # we pop out the head of text here during loading (prefix + idx)
        x = np.split(x, np.argwhere(x == 65534).flatten()) # we split it with \n
        try:
            out = [tokenizer.decode(_x[1:]) if _x[0]==65534 else tokenizer.decode(_x) for _x in x if len(_x) > 0]
            out = '\n'.join(list(filter(lambda x: len(x) > 1, out)))  # re join with \n
            out = out.strip('\n')
            out += '\n\n'         # re add back with document separator
        except:
            out = "a bad sentence!"
    else:
        try:
            out = x.decode('utf-8')
        except:
            out = "a bad sentence!"
    return out

remove = []
fin = open(remove_file)
for line in fin:
    if 'out' in line: break
for line in fin:
    remove.append(list(map(int,line.split())))
remove = remove[::-1]

ds = open(original,"rb")
new_ds = open(deduped+'.tmp',"wb")
# new_ds = open(deduped,"wb")

start = 0
while len(remove) > 0:
    a,b = remove.pop()
    if tokenized:
        # when tokenized, the dedup is performed on sub-token level
        a = a // 2 * 2
        b = b // 2 * 2
    new_ds.write(ds.read(a-start))
    ds.seek(a)
    torm = ds.read(b-a)
    if torm.endswith(b'\xff\xff'):
        # we need to keep this, actually we also have other cases where \xff\xff is identified as duplicated.
        new_ds.write(b'\xff\xff')
    ds.seek(b)
    start = b
new_ds.write(ds.read())

save_ds = open(deduped,"w")
if tokenized == "True":
    lines = open(deduped+'.tmp', "rb").read()
    lines = np.frombuffer(lines, dtype=np.uint16)
    # heads = 65535, id_p1, id_p0
    lines = np.split(lines, np.argwhere(lines == 65535).flatten())[1:] # 65535 is the magic prefix
else:
    lines = open(deduped+'.tmp', "rb").readlines() 
suc_count, fail_count = 1, 1
with mp.get_context("fork").Pool(mp.cpu_count()) as p:
    lines = p.map(tok, lines)
    for l in lines:
        if l != "a bad sentence!":
            save_ds.write(l)
            suc_count += 1
        else:
            fail_count += 1
print(f"Warning: suc: {suc_count} with fail: {fail_count}")

# save_ds = open(deduped,"w")
# for l in open(deduped+'.tmp', "rb").readlines():
#     if l.startswith(b'\xff'):
#         save_ds.write(l[6:].decode('utf-8'))  # we pop out the head of text here during loading
#     else:
#         save_ds.write(l.decode('utf-8'))  # we pop out the head of text here during loading