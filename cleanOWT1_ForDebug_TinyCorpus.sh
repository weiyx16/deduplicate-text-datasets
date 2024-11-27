export dataset=OWT_tiny_wotokenize.txt
mkdir data
python convertData.py --data_dir ./openwebtext_tiny --save_file data/$dataset.convert
export dataset=${dataset}.convert
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset  #22:42->23:45
sudo rm ./data/$dataset.part.*
export duplength=100
cargo run self-similar --data-file data/$dataset --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
cargo run collect --data-file data/$dataset --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file_$dataset
sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset ./tmp/drop_tokens_file_$dataset data/$dataset.dedup False
sudo rm ./data/$dataset.part.*
sudo rm ./data/$dataset.dedup.tmp













export dataset=OWT_tiny_withtokenize.txt
mkdir data
python convertData.py --data_dir ./openwebtext_tiny --save_file data/$dataset.convert --tokenize
export dataset=${dataset}.convert
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset
sudo rm ./data/$dataset.part.*
export duplength=50
cargo run self-similar --data-file data/$dataset --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
cargo run collect --data-file data/$dataset --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file_$dataset
sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset ./tmp/drop_tokens_file_$dataset data/$dataset.dedup True
sudo rm ./data/$dataset.part.*
sudo rm ./data/$dataset.dedup.tmp




2023-0404

直接在450MB的上头看（openwebtext.1.txt），基本和5GB然后最开始第一个eval点的效果是一致的
> Without Dedup [487624990 bytes]
    -> 8.33
> Raw text [477994706 bytes] [4018111 lines] 118.96 bytes/line
    -> 8.37
> After tokenized dup50 + fix detokenize + tokenize V2 [478391790 bytes] [4022071 lines] 118.94 bytes/line
    -> 8.85
只相差了400kb的东西。。。竟然差别那么大？也太神奇啦。
甚至第2个eval点，40/120，也即17k个2048 sequence就看出来区别了sos。。差不多30的数据量

def j(sentA, sentB):
    s1 = set(sentA.lower().split(" "))
    s2 = set(sentB.lower().split(" "))
    return float(len(s1.intersection(s2))) / float(len(s1.union(s2))) 

for i in range(3230, 4022071):
    if j(tokentext[i+7].strip("\n"), rawtext[i].strip("\n")) < 0.5:
        print(i, tokentext[i+7], rawtext[i])
        break

1. 11: example1 【+2,0】
2. 208: GPU. v.s. GPU .
3. 351: on'real' v.s. on 'real'
-> switch to jaccorb
4. 1915: miss matched [+4,0]

    'Still, Mr. Benson’s complaint said Renee and her two children “will continue to enjoy hundreds of millions of dollars they have been given; they simply will not have the specific assets they would like
    to have.”\n',
    '\n',
    ' an excellent warrior with a score of burning enemies in your wake, but your many trials have left only your driver and gunner unhurt.\n',
    'And the enemy is hot on your heels.\n'

    'Still, Mr. Benson’s complaint said Renee and her two children “will continue to enjoy hundreds of millions of dollars they have been given; they simply will not have the specific assets they would like to have.”are an excellent warrior with a score of burning enemies in your wake, but your many trials have left only your driver and gunner unhurt.\n',
    'And the enemy is hot on your heels.\n',

5. 2702: miss matched [+1,0]

    'NEW DELHI: The first signs of a Pakistani footprint is showing up in the bloody mutiny that shook Bangladesh this week.\n',
    'As mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of days.In fact, Pakistan president Asif Ali Zardari sent an emissary to Sheikh Hasina, Pervez Ispahani, to persuade her to put off this trial as it could embarrass the Pak army considerably.\n',
    'After the dust has settled down, Sheikh Hasina and Ahmed are likely to launch a purge of their own in the army, which is likely to create its own tensions.\n',
    "In any case, it promises to keep Sheikh Hasina off balance for a while, as Bangladesh joins other tottering nations on India's periphery.\n",

    'NEW DELHI: The first signs of a Pakistani footprint is showing up in the bloody mutiny that shook Bangladesh this week..\n',
    'Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.\n',
    '.\n',
    '\n',
    'As mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of daysSalauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decadesIn fact, Pakistan president Asif Ali Zardari sent an emissary to Sheikh Hasina, Pervez Ispahani, to persuade her to put off this trial as it could embarrass the Pak army considerably.\n',
    'After the dust has settled down, Sheikh Hasina and Ahmed are likely to launch a purge of their own in the army, which is likely to create its own tensions.\n',
    "In any case, it promises to keep Sheikh Hasina off balance for a while, as Bangladesh joins other tottering nations on India's periphery.\n",

6. 2763: miss matched [+3,0]
    'Max Payne did it well, but if it’s too hard or too easy would anyone want to fight for the prize?\n',
    '\n',
    'DOM HEARTS HD 2.8 Final Chapter Prologue was featured in the latest issue of Jump!\n',
    'The scan shows off screenshots of KiNGDOM HEARTS 0.2, X Back Cover and Dream Drop Distance HD, as well as new renders of Sora and Riku.\n',

    'Max Payne did it well, but if it’s too hard or too easy would anyone want to fight for the prizeKINGDOM HEARTS HD 2.8 Final Chapter Prologue was featured in the latest issue of Jump!\n',
    'The scan shows off screenshots of KiNGDOM HEARTS 0.2, X Back Cover and Dream Drop Distance HD, as well as new renders of Sora and Riku.\n',
7. 2828: miss matched [+5,0] 这个在原文的2877行附近
    'Nothing like ma ka haath ka khana after all – but only if the photographers are in attendance\n',
    '\n',
    'For the past several years, memory makers have been releasing high performance RAM kits aimed at Intel platforms.\n',
    "Now it's AMD's turn.\n"

    'Nothing like ma ka haath ka khana after all – but only if the photographers are in attendpast several years, memory makers have been releasing high performance RAM kits aimed at Intel platforms.\n',
    "Now it's AMD's turn.\n",

    原文是这样的：这样子看还是tokentext（前者）更好？
    Nothing like ma ka haath ka khana after all – but only if the photographers are in attendance.
    Firstpost is now on WhatsApp.
    For the latest analysis, commentary and news updates, sign up for our WhatsApp services.
    Just go to Firstpost.com/Whatsapp and hit the Subscribe button.

    For the past several years, memory makers have been releasing high performance RAM kits aimed at Intel platforms.
    Now it's AMD's turn.
    With the release of Ryzen, G.Skill wasted little time in unveiling two new memory lines, Flare X and Fortis, both of which are specifically aimed at Ryzen builds.
8. 3223: miss matched [+7,0] rawtext经常把document分割给干掉

    'Originally published in Queue vol.\n',
    '14, no. 4—\n',
    'We may be on the cusp of a new revolution in web development.\n',
    'We have to choose to build a web that is accessible to everyone\n',
    '\n'
    "LONDON -– There's a lesson here: If you decide to go up against J.K. Rowling on Twitter, you will almost certainly lose.\n",

    '14, no. 4—\n',
    'We may be on the cusp of a new revolution in web development.\n',
    "We have to choose to build a web that is accessible to everyonLONDON -– There's a lesson here: If you decide to go up against J.K. Rowling on Twitter, you will almost certainly lose.\n",

9. 3695 [+8,0]
10. 4316 [+7,0] 终于有一次tokentext把截断吃掉了

    'The judgment describes this water treatment, and I quote, "theOne man, Yukio Asano, was sentenced to fifteen years hard labor by the allies for waterboarding American troops to obtain information.\n',
    'Since Yukio Asano was trying to get information to help defend his country--exactly what you, Mr. Ashcroft, say is acceptible for Americans to do--do you believe that his sentence was unjust?\n',

    'The judgment describes this water treatment, and I quote, "t\n',
    'One man, Yukio Asano, was sentenced to fifteen years hard labor by the allies for waterboarding American troops to obtain information.\n',
    'Since Yukio Asano was trying to get information to help defend his country--exactly what you, Mr. Ashcroft, say is acceptible for Americans to do--do you believe that his sentence was unjust?\n',

11. 4335 [+6,0] 同理
    ME: "TheASHCROFT: (shouting) You hear that\n?

    ME: "T\n
    'ASHCROFT: (shouting) You hear that?\n'
12. 13.
    4539 Achievements!
    Achievements !

    4960 There's...
    There's . . .
14. 5038 [+6,0]
    'Trevor Fiore was responsible for the "break monocorps" Xenia.\n',
    'Fiore envisaged it as a GT for the year 2000.\n',
    'Unfortunately the concept was not developed any further.\n',
    'Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform.\n',
    ' fashion in the early eighties was for motor manufacturers to display scale models of concept cars rather than vehicles that could actually be driven and Citroën was no exception.Trevor Fiore was responsible for the "break monocorps" Xenia.Fiore envisaged it as a GT for the year 2000.\n'
    'Unfortunately the concept was not developed any further.Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform. four-passenger Xenia was designed for the American market.\n',
    "With clean lines and loads of glass, the Xenia was also safely-designed, with a straight body line set over the car's 168-inch length and 40-inch height.\n",

    'Trevor Fiore was responsible for the "break monocorps" Xenia.\n',
    '\n',
    'Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform.\n',
    'It was not until the launch of Evasion/Synergie that Citroën produced an MPV.\n',
    'The fashion in the early eighties was for motor manufacturers to display scale models of concept cars rather than vehicles that could actually be driven and Citroën was no exception.Trevor Fiore was responsible for the "break monocorps" Xenia..Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform.It was not until the launch of Evasion/Synergie that Citroën produced an MPV.\n',
    'The four-passenger Xenia was designed for the American market.\n',
    "With clean lines and loads of glass, the Xenia was also safely-designed, with a straight body line set over the car's 168-inch length and 40-inch height.\n",

    原文：这时候可以发现，raw text还是错误得分隔了，但是还是效果更好，什么鬼？但是由于这里重复字段缺少空格，所以tokentext没有检测出来（tokenizer id不一致了）只能说各有千秋。。
    Trevor Fiore was responsible for the "break monocorps" Xenia.
    Fiore envisaged it as a GT for the year 2000.
    Unfortunately the concept was not developed any further.
    Throughout the eighties, Citroën turned down the idea of a single volume car, notwithstanding the success enjoyed by the Renault Espace.
    Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform.
    It was not until the launch of Evasion/Synergie that Citroën produced an MPV.
    The fashion in the early eighties was for motor manufacturers to display scale models of concept cars rather than vehicles that could actually be driven and Citroën was no exception.Trevor Fiore was responsible for the "break monocorps" Xenia.Fiore envisaged it as a GT for the year 2000.
    Unfortunately the concept was not developed any further.Throughout the eighties, Citroën turned down the idea of a single volume car, notwithstanding the success enjoyed by the Renault Espace.Indeed, PSA turned down the idea when Matra first showed them the idea, based on a BX platform.It was not until the launch of Evasion/Synergie that Citroën produced an MPV.
    The four-passenger Xenia was designed for the American market.
    With clean lines and loads of glass, the Xenia was also safely-designed, with a straight body line set over the car's 168-inch length and 40-inch height.

15. 5803 [+8,0]
    这里raw text又吞了一次文本分割符
    'And that’s not even taking in account the number of RTS you can run in WINE or via other means (Dune2 can be run in the Dune Dynasty Engine for example).\n',
    '\n',
    'MINOT, N.D. -- A federal judge sentenced disgraced former Minot neurosurgeon Dr. Marc Eichler on Thursday to 36 months in prison for possession of child pornography, according to court records.\n',
    'Eichler was originally charged with child sex abuse offenses in district court in Minot.\n',

    'And that’s not even taking in account the number of RTS you can run in WINE or via other means (Dune2 can be run in the Dune Dynasty Engine for exampleMINOT, N.D. -- A federal judge sentenced disgraced former Minot neurosurgeon Dr. Marc Eichler on Thursday to 36 months in prison for possession of child pornography, according to court records.\n',
    'Eichler was originally charged with child sex abuse offenses in district court in Minot.\n',

16. 6208 [+9,0]

    'Anti-CD62L and –IFN-γ antibodies were purchased from BD Pharmingen (BD Biosciences); others were obtained from eBiosciences.\n',
    'Mod, which is described in detail in SI Materials and Methods.\n',
    'Th-Cell Differentiation and Testing of Suppressive Capacity.\n',
    'Naive CD4+CD62LhiCD25− T cells were purified from spleen and LN cell suspensions using the Dynal mouse CD4+CD62L+ T-cell isolation kit II mouse (Miltenyi Biotec) or by sorting on a MoFlo (DakoCytomation).\n',

    'Anti-CD62L and –IFN-γ antibodies were purchased from BD Pharmingen (BD Biosciences); others were obtained from eBiosciences., which is described in detail in SI Materials and Methods.\n',
    'Th-Cell Differentiation and Testing of Suppressive Capacity.\n',
    'Naive CD4+CD62LhiCD25− T cells were purified from spleen and LN cell suspensions using the Dynal mouse CD4+CD62L+ T-cell isolation kit II mouse (Miltenyi Biotec) or by sorting on a MoFlo (DakoCytomation).\n',

17. 7555 [+10,0] [终于看到tokentext合并了一句]
    'And it’s very hard to see what’s wrong with that (now there’s a curve ball for those who thought they knew where I was coming from, right?)The role of the critic in fact is not be to berate “the masses”
    for their choices.\n',
    'That would indeed be a bad form of elitism.\n',

    'And it’s very hard to see what’s wrong with that (now there’s a curve ball for those who thought they knew where I was coming from, right?)\n',
    'The role of the critic in fact is not be to berate “the masses” for their choices.\n',
    'That would indeed be a bad form of elitism.\n',

18. 8335 [+14,0]

    8355 The First Amendment says that "Congress shall make no law respecting an establishment of religion, or prohibiting the free exercise thereof."
    The First Amendment says that justices have a good deal of discretion to frame the competing issues and could reach a limited "compromise" through narrow statutory interpretation.
    
    tokentext下一句是'The justices have a good deal of discretion to frame the competing issues and could reach a limited "compromise" through narrow statutory interpretation.\n'，raw text多删了一点

19 8545 [+16,0]
    'Update your appBring an external battery packSet your phone to use as little battery as possible.\n',
    'Lower your screen brightness, mute the volume, and disable background apps.\n',
    'Turn off bluetooth and wi-fi.\n',

    'Update your ap\n',
    'Bring an external battery pac\n',
    'Set your phone to use as little battery as possible .\n',
    'Lower your screen brightness, mute the volume, and disable background apps.\n',
    'Turn off bluetooth and wi-fi.\n'

20. In [107]: for i in range(8675, 4022071):
     ...:     if j(tokentext[i+14].strip("\n"), rawtext[i].strip("\n")) < 0.5:
     ...:         print(i, tokentext[i+14], rawtext[i])
     ...:         break
     ...:
    9419 This article is reproduced with permission from the magazine Nature.
    \n

21. In [109]: for i in range(9420, 4022071):
     ...:     if j(tokentext[i+16].strip("\n"), rawtext[i].strip("\n")) < 0.5:
     ...:         print(i, tokentext[i+16], rawtext[i])
     ...:         break
     ...:
    9831 Queries become very complexQueries become slower over timeUsing constraints (UC, FK) is impossible.
    Queries become very complexQueries become slower over tim


***************** 就看这一万行我甚至觉得tokentext更好 *************************

tokentext (head -n 10000): 9.148 (run 10000 samples base model 2048 sequence lengths; without rampup; decay 9000 steps) ~39 iters; bs 256
rawtext (head -n 10000): 8.86 (run xxx) ~39 iters; bs 256
别太荒谬，这都行？这都有区别？
head -n 10000 openwebtext.1.txt: 8.85
真的有区别？？别太荒谬...


把这一万行拿出来line by line 在vscode里再比一次。。。。。。
:和miaosen看了没啥区别


@yixuan: test different 10k line version?
    1. normalized spaces
    2. xxx
    3. xxx
    4. until we reach similar to raw version
    @ sync with miaosen [done]
@yixuan: delect document directly (need to test partition)

@zhenghong : test on other benchmarks including gpt-2 perplexity        @ applied
@ruihang: run minhash on OWT1                                           @ applied

@all: run text level only ?
@all: run minhash directly ?




+++++++++++++++ 在8卡机器上 重新跑 +++++++++++++++
可能setting有一点点不同

rawtext （head -n 10000）：9.15
original ：9.28
tokentext ：9.83

把lr调到一样4e-4，lr decay 9000->8500;

rawtext ：8.90 （eval iter=10:8.90）
original ：8.91 
tokentext ：9.16

这样基本align了

tokentext with normalspace: 8.88（也即把tokenize encode和decode之后删掉的space加回来）
啊？？？？？？？？？？？别太荒谬

In [5]: sentence = "During the album’s long-gestating pre-production and production phases, D'Angelo, ?"

In [6]: id = tokenizer.encode(sentence)
", ".join(list(map(lambda x: str(x), id)))
'7191, 262, 5062, 447, 247, 82, 890, 12, 3495, 803, 662, 12, 25493, 290, 3227, 21164, 11, 360, 6, 45585, 11, 5633'

In [8]: tokenizer.decode(id)
Out[8]: "During the album’s long-gestating pre-production and production phases, D'Angelo,?"
-> new_sentence

In [8]: tokenizer.encode(new_sentence)
'7191, 262, 5062, 447, 247, 82, 890, 12, 3495, 803, 662, 12, 25493, 290, 3227, 21164, 11, 360, 6, 45585, 11, 30'

过了tokenizer之后自然会把这标点符号前头的空格去掉。
而且前后竟然不一样，这里是考虑merge or not的问题吗
In [14]: tokenizer.decode([30])
Out[14]: '?'

In [16]: tokenizer.decode([5633])
Out[16]: '?'

In [18]: tokenizer.decode([11, 30])
Out[18]: ',?'

In [19]: tokenizer.decode([11, 5633])
Out[19]: ',?'

In [20]: tokenizer.decode([5633]) == tokenizer.decode([30])
Out[20]: True


跑一个original with space rm（删掉punctuation之前的space）：9.09
很奇怪。。。
按道理这个差别很细微啊，真的有这个影响吗？

在更大的数据集上测试
500MB的original openwebtext.1.txt with space rm 跑一组看看：8.74 【通过re来实现】 [之前应该是8.33，在新的8卡机器重新跑是：8.35，然后tokenized dedup是8.85]
500MB的original openwebtext.1.txt encode + decode跑一组看看： 8.89【通过来tokenizer来实现, 39363 行前后不一致，大约是1%】

跑一组5GB的1.3B model的实验：
prepare data: done
submit: done
running: wikitext-103的validation loss升高到了5.75，但是训练loss正常3.97. 和tokenized之后去重的效果差不多

可能还真是这个原因。。？？？？？？
要不就是wikitext-103这个测试方式有点欠妥。。。。。。
等zhenghong看看其他数据集的情况吧

看了一下wikitext-103的数据集：还真都是标点符号单列的sos
In [13]: id = tokenizer.encode(texts[:1024])

In [14]: tokenizer.decode(id)
Out[14]: '\n\n = Robert Boulter = \n\n\n\n\n Robert Boulter is an English film, television and theatre actor. He had a guest @-@ starring role on the television series The Bill in 2000. This was followed by a starring role in the play Herons written by Simon Stephens, which was performed in 2001 at the Royal Court Theatre. He had a guest role in the television series Judge John Deed in 2002. In 2004 Boulter landed a role as " Craig " in the episode " Teddy\'s Story " of the television series The Long Firm ; he starred alongside actors Mark Strong and Derek Jacobi. He was cast in the 2005 theatre productions of the Philip Ridley play Mercury Fur, which was performed at the Drum Theatre in Plymouth and the <unk> Chocolate Factory in London. He was directed by John Tiffany and starred alongside Ben Whishaw, Shane Zaza, Harry Kent, Fraser Ayres, Sophie Stanton and Dominic Hall. \n\n\n In 2006, Boulter starred alongside Whishaw in the play Citizenship written by Mark Ravenhill. He appeared on a 2006 episode of the tel'

In [15]: texts[:1024]
Out[15]: '\n\n = Robert Boulter = \n\n\n\n\n Robert Boulter is an English film , television and theatre actor . He had a guest @-@ starring role on the television series The Bill in 2000 . This was followed by a starring role in the play Herons written by Simon Stephens , which was performed in 2001 at the Royal Court Theatre . He had a guest role in the television series Judge John Deed in 2002 . In 2004 Boulter landed a role as " Craig " in the episode " Teddy \'s Story " of the television series The Long Firm ; he starred alongside actors Mark Strong and Derek Jacobi . He was cast in the 2005 theatre productions of the Philip Ridley play Mercury Fur , which was performed at the Drum Theatre in Plymouth and the <unk> Chocolate Factory in London . He was directed by John Tiffany and starred alongside Ben Whishaw , Shane Zaza , Harry Kent , Fraser Ayres , Sophie Stanton and Dominic Hall . \n\n\n In 2006 , Boulter starred alongside Whishaw in the play Citizenship written by Mark Ravenhill . He appeared on a 2006 episode of the tel'å

那么：
500MB的original openwebtext.1.txt encode + decode再在wikitext-103也做过encode/decode再tokenize的数据集上测：跑出来只有8.02，比之前一票都低。。
貌似megatron里面的tokenizer不一样，还不会触发前后不同，只有transformers.GPT2Tokenizer.from_pretrained("gpt2")才会有这个神奇的特性。
所以这里encode+decode就用的是transformers里的那个。

那么：
甚至新加的两个改动也不是很必要。。