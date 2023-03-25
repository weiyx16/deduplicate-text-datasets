# datasource
C4_en: 740GB (1024*740MB txt)
Openwebtext: 30GB (64*460MB txt)
Openwebtext-2: 78GB (30*4GB jsonl; or 28,496 * 3MB jsonl)
Pile-CC (pile): 227GB (30*7.3GB jsonl)
CC-202050 (kosmos): 300GB (1*300G jsonl)
CC-202104 (kosmos): 360GB (1*360G jsonl)

## resources
Sing: 2TB disk; 500G ram
Our A100: 2.4TB disk; 880G ram
Our V100(BJ1): 24TB disk; 1.4T ram
Max Ram on Azure: 672G (pure CPU) [E96-24ds_v5 Southeast_asia Zone-2]

> 500G ram is not able to deal with Pile-CC (~200G)
> 一种方案就是还是把tokenizer搞定，这里200G可以save成100G？500G ram基本可以处理
> 另一种方案就是分块处理，只做局部的去重，然后再在每个块之间交叉去重，其他部分交给fuzzy deduplication处理


## timelines
+ [self-dedup] CC-202050 [done]
    - BJ1 : jsonl to ids [done] [127G]
    - Suffix: [done] (15:20 run it) 17:45 begin to merge TMR 23:20 done;
    - Self-similar: totally 2114353401; Duplicates found: 16613742304
    - Collect: 
    - Dedup&detokenized: 104G token id; [先把这个备份了，后边直接detokenize这个就可以;.ids.tmp] [差不多整个detokenize需要1小时]
       - 223G; Warning: suc: 68152885 with fail: 1761923 [还好这个也ok了]
+ [self-dedup] CC-202104 [done]
    - BJ1 : jsonl to ids [done] [152G]
    - Suffix: [doing] (16:10 run it) merged to day after TMR 8:00 done;
    - Self-similar: totally 2542170868; Duplicates found: 20077416451
    - Collect: 
    - Dedup&detokenized: 126G token id; 
        - 269G; Warning: suc: 82359775 with fail: 2165265
+ [self-dedup] Pile-CC [done]
    - CPU machine : jsonl to ids [done] [100G]
    - Suffix: stuck for a long time at merging and auto-retried.. [failed]
    - We split 100G into 2 parts. [running] [time est: 2*6=12h]
        - Part0of2 [done]: 7~8h; 
        - Part1of2 [done]: during saving: 22349446 with fail: 371667
        Compress: 227G -> 186G (99G(53G raw tokens)+87G(47G raw tokens))

+ [merged-self-dedup] Openwebtext 1&2 -> OWT [done]
    - CPU machine : separately jsonl to ids [OWT1 done; OWT2 done] [44G] [source:108G]
    - Merged and build Suffix: done [it seems that **merging** the suffix is time-consuming]
    (about time: 96cores+768RAM: 2.3mins for 4GB; 12hs for 350GB to build suffix; ~1 hour to deduplicate C4) [90X large; 300X time comsumer;] 
    We have 44GB: ~40X time comsumer + less cores(60); ~60X time? -> 60*2.3=2.3h [~14:20 run it] [finish at 19:00] (4.7h) [merge花了4个半小时，主要就在merge上了...]
    try on only OWT1 (with 13G): 17:45 run it -> 18:52 (1.1h)
    - Self-similar: totally: 723216298; Duplicates found: 4860238776 5mins
    - Collect: 6mins
    - Dedup&detokenized: 13mins Warning: suc: 21678394 with fail: 513800 [44G->33G->65G raw text] 感觉dedup了好多，并且出现了好多破碎的句子，不知道是不是这边的问题。
        - 尝试filter掉过短的句子。
    V2: duplength=200
    - Self-similar: totally: 723216298; Duplicates found: 1578646815
    - Collect
    - Dedup&detokenized: Warning: suc: 23774211 with fail: 178366 [44G->40G->82G raw text]
        - 看起来好多了，之后还是可以filter掉过短的。
    - Compress: 108G -> 82G


+ [self-dedup] C4_en [we split into 8 subsets] [time est: 8*6=48h]
    - Part0of8: total 686471370; Duplicates found: 208925238
    - Part1of8 [done]:
    - Part2of8 [done]:
    - Part3of8 [done]:
    - Part4of8 [done]: ~5h; 
    Compress: 92.5G -> 91G(41G raw tokens)
    - Part5of8 [done]:
    Compress: 92.5G -> 91G(41G raw tokens)
    - Part6of8 [done]: 91G
    - Part7of8 [done]: 91G

> Too much RAM cosuming with cross-validation; we skip it and keep focus on fuzzy dedup
+ [cross-dedup] CC-202050 and CC-202104 -> CC-Kosmos ?
+ [cross-dedup] CC-Kosmos and Pile-CC -> CC-KP ?
+ [cross-dedup] C4_en and OWT -> C4OWT ?
+ [cross-dedup] CC-KP and C4OWT -> CC ?


## Questions
1. is 100 duplength too short [maybe ok] [the unit is bytes I think.]
> e.g. we remove any document that does not contain between 50 and 100,000 words, or whose mean word length is outside the range of 3 to 10 characters; we remove any document with a symbol-to-word ratio greater than 0.1 for either the hash symbol or the ellipsis; and we remove any document with more than 90% of lines starting with a bullet point, or more than 30% ending with an ellipsis. -> 90 tokens (180 bytes)
> e.g. We also require that 80% of words in a document contain at least one alphabetic character, and apply a "stop word" filter, to remove documents that do not contain at least two of the following English words -> 44 tokens (100 bytes)
1.1. final we switch to 200, since setting to 100 has too many broken sentences.
2. works on fuzzy dedup


## Notice
1. Exact Dedup don't delete the passages directly which has 50 bytes overlap with others, but only remove this term. 
> [From the paper: In our paper we suggest just taking all of these duplicate sequences that have been identified and completely striking them from the dataset. This somewhat breaks the flow of text, for example if previously had an example "Alice wanted to go to the store" and we deduplicated at the level of 10 characters, we might completely strike " to go to the " and be left with "Alice wantedstore". In practice we have found this doesn't break the language model because we remove relatively little text, and so these breaks don't cause harm.]
