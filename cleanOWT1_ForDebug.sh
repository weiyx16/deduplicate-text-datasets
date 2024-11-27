20230403 Documented

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
/output/azcopy copy "https://vlpretraineastus.blob.core.windows.net/crawl-text/openwebtext?sv=2021-04-10&st=2022-09-06T05%3A36%3A34Z&se=2025-09-05T05%3A36%3A00Z&sr=c&sp=racwdxltf&sig=8yIkemAX4aA8frrJoW1snsJB07suONjEHC5zR736MQw%3D" --recursive ./
### ========= End ==============

+++++++++ We randomly sampled 7GB from openwebtext with subset 1/7/14/16/19/22/27/32/35/37/48/51/52/54/63 subset








+++++++++ V1 Without tokenizer +++++++++++++

echo 4
### =========== Convert the dataformat ============
export dataset=OWT_subset_wotokenize.txt
mkdir data
python convertData.py --data_dir ./openwebtext_subset --save_file data/$dataset.convert
export dataset=${dataset}.convert
### ========= End ============

echo 5
### =========== Build Suffix_array ================
# Finding all repeated substrings within a document
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset  #22:42->23:45
sudo rm ./data/$dataset.part.*
### ========= End ============

echo 6
### =========== Deduplicate ================
# Output means: This means that the deduplicator found $output sequences of length $length that existed somewhere else in the dataset.
# In our paper, we used 50 tokens (which is 100 bytes---so remember that if you pass --tokenize you'll need to double the number of bytes for the length threshold).
export duplength=100
cargo run self-similar --data-file data/$dataset --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
sudo rm ./tmp/*

# gather lines of documents to be removed with has over $duplength overlap with others
cargo run collect --data-file data/$dataset --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file_$dataset

sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset ./tmp/drop_tokens_file_$dataset data/$dataset.dedup False # the last one means detokenized or not
# Warning: suc: 59449423 with fail: 28389
sudo rm ./data/$dataset.part.*
sudo rm ./data/$dataset.dedup.tmp
### ========= End ============




## VISUALIZATION
t-yixuanwei@GCRHYPCBJ007:/tmp/code/deduplicate-text-datasets$ sudo /opt/conda/bin/python scripts/count_occurrences.py --suffix data/$dataset --query "Will the media learn anything from their biased reporting of the Jussie Smollett story?"
b'Will the media learn anything from their biased reporting of the Jussie Smollett story?'
Number of times present: 927
t-yixuanwei@GCRHYPCBJ007:/tmp/code/deduplicate-text-datasets$ cat data/$dataset | grep -ao "Will the media learn anything from their biased reporting of the Jussie Smollett story?" | wc -l
927

Examples of ./tmp/drop_tokens_file
    1200 1886
    36299 36695
    36699 37099
    213060 213204
    234926 235201
    269097 269293
    306233 306584
    306585 306813
    306914 307545
    307546 307738
    307739 307862
    307863 308166
    308167 308395
    308627 309206
    309305 310782
    317060 317209

>>> data = open('OWT_subset_wotokenize.txt.convert', 'rb').read()
>>> import re
>>> tofind = data[1200:1886]
>>> tofind
b"ast.\nWill the media learn anything from their biased reporting of the Jussie Smollett story?\nWill the media learn anything from their biased reporting of the Jussie Smollett story?\nWill the media learn anything from their biased reporting of the Jussie Smollett story?\n* Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.\nNo, they suffer from a bad case of Trump Derangement Syndrome.\nJussie who?\nName This field is for validation purposes and should be left unchanged.\nCompleting this poll grants you access to The Black Sphere updates free of charge.\nYou may opt out at anytime.\nYou also agree to this site's Privacy Policy and Terms of Use.\n\n"
-------- Here is the source --------
    We’ve know for some time that the Main Stream Media takes license with editing of remarks and video.
    The arrogance of MSNBC is stunning.
    And the notion that MSM usually does this sort of hijinx with impunity is horrifying.
    Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast to coast.
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Name This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to The Black Sphere updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.
------------------------------------

Anothers May duplicate in corresponding part: 
    Back in January, we reported the story of Mark Witaschek, whose D.C. home was raided by SWAT agents with a search warrant for “firearms and ammunition … gun cleaning equipment, holsters, bullet holders and ammunition receipts.”
    The raid was conducted by 30 agents in full tactical gear whose rampage through the home caused $10,000 in damage and terrified Witaschek’s teenaged children.
    take our poll - story continues below Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Comments This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to Freedom Outpost updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.
    Trending: Ex-CNN Reporter Amber Lyon Explains How They Fake The News “One live round of 12-gauge shotgun ammunition,” which was an inoperable shell that misfired during a hunt years earlier.
    Witaschek had kept it as a souvenir.
    “One handgun holster” was found, which is perfectly legal.
    “One expended round of .270 caliber ammunition,” which was a spent brass casing.
    The police uncovered “one box of Knight bullets for reloading.”
    These are actually not for reloading, but are used in antique-replica, single-shot, muzzle-loading rifles.
    A successful financial adviser with no criminal history, Witaschek is now the first known case of a citizen being prosecuted in D.C. for inoperable ammunition.
    Yesterday, a D.C. judge found Witaschek guilty of “attempted possession of unlawful ammunition” for possessing antique replica muzzleloader bullets.
    Judge Robert Morin sentenced Mr. Witaschek to time served, a $50 fine and required him to enroll with the Metropolitan Police Department’s firearm offenders’ registry within 48 hours.
    Until the final hours of the trial, both the defense and government focused the case on whether the single 12 gauge shotgun shell that was found in Mr. Witaschek’s D.C. home was operable.
    The judge, however, never ruled on it.
    In the afternoon on Wednesday, Judge Morin shook the plastic shell and tried to listen to something inside.
    He said he could not hear any gunpowder.
    He then asked the lawyers to open the shell to see if there was powder inside.

    A new Wall Street Journal article revealed that Target’s CEO knows he made a mistake.
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Comments This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to The Black Sphere updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.
    When the Left targeted Hobby Lobby, Conservative made sure our dollars were spent at Hobby Lobby.
    The Left then targeted Chick-fil-A, and the cars lined up in huge numbers at the Christian-based fast food restaurant.
    For Target, things didn’t work out so well.
    The Target policy was not about transgender bathrooms, but instead a slap in the face of Conservatives.
    Target believed the hype of Leftism and their attempts to social-engineer the most loving, caring, humanitarian country the world has ever known.
    Target wanted their transgender bathroom policy to shout loudly that they believe in Leftism.
    Moreover, they didn’t want the Conservative dollar.
    We wrote recently of Starbucks CEO Howard Schulz feeling the pain, as he succumbed to Leftism.
    It didn’t work out too well for him either.
    Although the CEO wanted the policy to remain hush-hush, the public statement about the policy remains on Target’s website today.
    Target headquarters circulated an internal memo to store managers on April 15, 2016, but didn’t copy the CEO.
    Target’s chief risk officer, Jackie Rice, and its chief external-engagement officer, Laysha Ward approved the post.
    North Carolina shopper, Mary McCandless told the WSJ,
    Leftist loons who run the company thought the backlash would die down.
    But it didn’t, and foot traffic inside Target stores declined significantly after the American Family Association launched a major boycott against the retailer.
    So far, the AFA boycott forced Target’s stock value to plummet 35 percent.
    Because of the stock drop, Target was forced to squash plans for major expansion projects.
    The AFA petition demands that Target return to “a common sense bathroom and dressing room policy that links use of these rooms to a person’s biological sex”.
    Their current goal is 1.5 million signatures.

    Democrats won’t give Republicans time to heal.
    In the wake of the shooting of Representative Steve Scalise, we’ve learned of threats against Representative Chaffetz.
    Sadly, more vile Leftists prepare to kill for their demented leaders.
    With this latest story, people are questioning how many of these clowns there are.
    As according to The Dispatch,
    A voice mail that threatened U.S. Rep. Steve Stivers and his family landed a Westerville man in federal court Wednesday, charged with a crime that carries a 10-year prison term if he is convicted.
    take our poll - story continues below Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Email This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to The Black Sphere updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.
    Trending: SCOTUS Justice Send Warning to FAKE NEWS Journalists In the voice mail that authorities said was left with the Upper Arlington Republican’s Hilliard district office on Sunday, the caller mentioned the June 14 baseball practice during which House Majority Whip Steve Scalise, R-La., and four others were wounded or injured in Alexandria, Virginia.
    “I’ve seen the prayer ya’ll were saying at the baseball diamond … I think ya’ll better hit your knees and pray for the people that you’re screwin’ up their lives,” the message stated, according to a criminal complaint filed by Capitol Police in U.S. District Court in Columbus.
    “We’re coming to get every goddamn one of you and your families.
    Maybe the next one taken down will be your daughter.
    Huh?
    Or your wife.
    Or even you.”
    Consider how bold you must be to actually leave a voicemail of the threat.
    If you’re a serious political pundit on the Right, you’ve received many death threats.
    I certainly have.
    If I had a dollar for the number of death threats I’ve received over the 8+ years I’ve been doing this, I’d have enough for a downpayment on a nice car.
    And make no mistake about it, you must take the threats seriously, as I’m sure the Stivers family did.
    E. Stanley Hoff, 68, is charged with threatening to “assault, kidnap, or murder a United States official.”
    He appeared in federal court wearing a Mickey Mouse T-shirt, jeans and sandals in addition to ankle and wrist chains.

    Trump said that he would drain the swamp and much to the surprise of his detractors, he appears committed to his campaign pledges.
    Comey’s unceremonious but well-deserved firing was a warning shot across the bow, and it appears that former National Security Advisor to Obama, Susan Rice, has heard the shot loud and clear.
    For the record, let's be very clear here.
    Regardless what nonsense the Democrats or the mainstream media will be spouting in the coming days ahead (and there will be plenty of it), make no mistake, it will all be pure B.S., and it will all be in an attempt to distract Americans from what is easily going to be the largest scandal in our nation's history…
    In the following video, Right Wing News looks at reports which claim that Rice is now seeking immunity in exchange for spilling the beans on higher ups.
    The stakes are high for Rice; she stands accused of ordering illegal wiretaps on Trump and disseminating the information to journalists, a very serious offence.
    If someone as high up as Rice testifies, who will she implicate?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Name This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to Freedom Outpost updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.
    The recent firing of former FBI Director James Comey has put many Democrats on notice.
    Now, the lawyers for another former top official in the Obama administration are seeking immunity for their client.
    Susan Rice, the former National Security Advisor to Obama, is now seeking a way to testify without facing the music herself.
    Rice’s lawyers have approached the FBI with the idea that Rice, who stands accused of ordering illegal wiretaps on journalists and President Donald Trump, with spill the beans so long as she’s free from a major criminal investigation, via Infowars.
    Ever since the scandal has come to light, Rice has tried to avoid the glare of the interrogator’s light.For instance, she refused to testify before the Senate during their investigation into the Russian hacking conspiracy, via CNN.
    On other counts, Rice has attempted to clear her own name by giving supposedly candid interviews to “serious” journalists.
    In each interview, the fact that Rice is a compulsive liar comes through time and time again, via FOX News.
    Rice has a reason to be evasive.
    The House is currently looking into whether or not Rice ordered the NSA to spy on Donald Trump and his team before the inauguration.
    According to some evidence, all of this was done with foreign intelligence services as cover, via Washington Times.
    If convicted, Rice could face serious jail time.
    With immunity, she may name bigger names than herself.
    Now, with Comey gone, the investigation into Rice and her cronies looks likely to continue.
    One of the major reasons why Rice is seeking immunity now is because, without Comey, the FBI no longer serves the interests of the Democratic Party.
    Rice’s testimony could implicate people like Hillary Clinton, Loretta Lynch, or even Obama himself.
    From the emails that have been leaked by WikiLeaks, it is clear that former AG Lynch tried everything in her power to stop the investigation into Clinton from proceeding too far.
    Similarly, the defeated Clinton campaign launched the Russian hacking theory a mere 24 hours after the final election results.
    This means that they may have been involved in espionage to find evidence for their claims, via Breitbart.


..........

>>> data.count(tofind)
1
>>> for i in range(100):
...     print(data.count(data[1200+i*5:1300+i*5]))
...
3, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 308, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 311, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 77, 298, 298, 104, 58, 58, 58, 58, 58, 58, 58, 58


>>> tofind = data[36299:36695]
>>> tofind
b"God, I've had a hard time at times.\nI'm doing the best with what I've given.\nI'm not in control over the story lines, so I've at times been frustrated with certain things.\nSo I totally see why it's been difficult for fans.\nShe's been trying to do this good thing, but she always seems to upset people.\nThere's always someone upset with Katrina.\nHer son or Ichabod or Abbie or Headless, you know?\n"
-------- Here is the source --------
    Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina.
    God, I've had a hard time at times.
    I'm doing the best with what I've given.
    I'm not in control over the story lines, so I've at times been frustrated with certain things.
    So I totally see why it's been difficult for fans.
    She's been trying to do this good thing, but she always seems to upset people.
    There's always someone upset with Katrina.
    Her son or Ichabod or Abbie or Headless, you know?
    ... She hasn't really had that strength that I think people expect from a witch.
    Especially because it's been said so many times in the series, "She's got so much power!"
    and then she hasn't been able to prove it yet.
    So I think that's where a lot of the frustration lies.
    And also the fact that a lot of people don't like the idea of Ichabod being with someone else other than Abbie.
    That doesn't help.
    That latter quote pretty much sums up our gripes about Katrina, although I’m not sure it’s a sharp move for the actress to complain about her personal problems to a reporter without a heads up to the Sleepy Hollow staff.
    Winter’s preaching truths, though.
    Her character is not particularly faithful to Ichabod and seems pretty sneaky.
    Although she is sneaky, she’s not a particularly strong female character and has had to be saved in numerous situations.
    Yet, fans are still expected to believe that she is a powerful witch with numerous skill sets, instead of an annoyance who looks good in a corset.
    Winter’s frustrated, fans are frustrated, but will Sleepy Hollow do anything about her character?
    We’ll have to tune in to find out, I guess.
    Interestingly, I think it’s worth pointing out that killing off the character might solve some of the show’s big problems this season.
    However, while Sleepy Hollow has had a penchant for killing off characters, those characters often return.
    Sleepy Hollow, and I’m not sure Fox’s drama is angling for that, anyway.
    One thing is for certain, Winter is not happy with her character’s direction, and hopefully that will be reflected in the long game.
------------------------------------

Another Source (36299):
    If she does align herself with Henry, how will Ichabod react?
    Winter: Wait until Monday, then you'll see!
    Not so well.
    Obviously, he feels betrayed and has been betrayed by Katrina many times.
    But it's her point of view.
    She doesn't see it that way.
    She's frustrated because nobody seems to understand that she did all those things for the greater good, for the bigger picture.
    She's not necessarily focused on these little things.
    I think this will probably be the ultimate betrayal in Ichabod's eyes, but it's a betrayal on both sides.
    Knowing that she is going to betray Ichabod again in Monday's episode, are you a little nervous about the fan reaction?
    Winter: Maybe.
    Yeah, a little bit.
    I think it pans out.
    She doesn't really have a choice.
    And I'm hoping fans will be on board with the direction she's going.
    But it's always going to be mixed.
    There's always a divide.
    I am prepared for that.
    Why do you think fans have had such a hard time connecting to and rooting for Katrina?
    Winter: God, I've had a hard time at times.
    I'm doing the best with what I've given.
    I'm not in control over the story lines, so I've at times been frustrated with certain things.
    So I totally see why it's been difficult for fans.
    Because Katrina wasn't really established in Season 1.
    She came out of Purgatory in Season 2 and Ichabod already has a relationship with Abbie that works great and they have great chemistry.
    I think Katrina hasn't really had her purpose until this point.
    She's been a source, an asset, in moments and times, and she's been torn between Ichabod and Headless.
    She's been trying to do this good thing, but she always seems to upset people.
    There's always someone upset with Katrina.
    Her son or Ichabod or Abbie or Headless, you know?
    She seems to be in that situation a lot, which has been frustrating on all ends.
    She might go to the evil side, but still that's a strong choice.
    She hasn't really had that strength that I think people expect from a witch.
    Especially because it's been said so many times in the series, "She's got so much power!"
    and then she hasn't been able to prove it yet.
    So I think that's where a lot of the frustration lies.
    And also the fact that a lot of people don't like the idea of Ichabod being with someone else other than Abbie.
    That doesn't help.
    What do you think of the idea of Ichabod and Abbie getting together?
    Winter: Um... I don't think that's ever been the plan.
    But I do see why people like them together.
>>> data.count(tofind)
1

>>> for i in range(70): # should be 695-299-100 / 5 ~ 60
...     print(data.count(data[36299+i*5:36399+i*5]))
...
2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
为什么中间有19个1，应该是这样的，有个子串[a:a+100]是重复的，然后[a+95:a+95+100]是重复的，但是你看[a+5:a+5+100]确实不重复，但是由于a+100 > a+95 所以现在也会把他们合起来


>>> tofind = data[213060:213204]
>>> tofind
b'.\xe2\x80\x9d\n\nThis news was published on the old version of the website.\nThere may be some problems with news display in specific browser versions.\nYou '

indexes = [m.start() for m in re.finditer(tofind, data)]



Another Source (306233):
    >>> file[306233:310782]
    b'The preliminary interrogation of some of the rebels has thrown up the name of Salauddin Qadeer Chowdhury, a well-known shipping magnate and reportedly very close to the Pakistan military-intelligence complex and the opposition BNP.\nAccording to sources monitoring the situation, about one crore taka has already changed hands to help the mutiny along.\nChowdhury, a close associate of opposition BNP leader Begum Khaleda Zia, was closely connected to the Chittagong arms drop case of April 2004 - the arms were apparently intended for ULFA.\nThe ships were caught carrying the arms.\nSalauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.\nTrouble continues to brew in Dhaka, where the army cadres, particularly mid-level officers, are spoiling for a fight with the Bangladesh Rifles (BDR) cadres.\nSo far, the Bangladesh army leaders, led by army chief Moeen Ahmed, have kept the officers in check, which is making the present situation slightly different from 1975.\nAccording to the fire service operations chief, Sheikh Mohammad Shahjalal, 50 officers are still missing.\n"We have so far removed 10 dead bodies.\nThey are badly decomposed and many are mutilated," he said.\n"They not only shot them dead but some bodies were badly mutilated with bayonets," Shahjalal said.\nIt is increasingly clear that the chief targets are the army chief Moeen Ahmed and prime minister Sheikh Hasina who, reports say, has been moved to an army guest house for her personal safety.\nIn fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.\nSources are also pointing to the scale of the brutality of the murders, the mutilations, etc, which they say are tell-tale signs of the Islamist ideologies that have infiltrated the lower cadres of the BDR, thanks to their extensive Jamaat-e-Islami and Jamaat-ul-Mujahideen Bangladesh (JMB) connections.\nBehind the mutiny is the war crimes tribunal that Sheikh Hasina promised to set up for the trial of Pakistani collaborators or razakars from the independence war.\nThis had created trouble inside Bangladesh and Pakistan as well.\nAs mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of days.The preliminary interrogation of some of the rebels has thrown up the name of Salauddin Qadeer Chowdhury, a well-known shipping magnate and reportedly very close to the Pakistan military-intelligence complex and the opposition BNP.\nAccording to sources monitoring the situation, about one crore taka has already changed hands to help the mutiny along.Chowdhury, a close associate of opposition BNP leader Begum Khaleda Zia, was closely connected to the Chittagong arms drop case of April 2004 - the arms were apparently intended for ULFA.\nThe ships were caught carrying the arms.Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.Trouble continues to brew in Dhaka, where the army cadres, particularly mid-level officers, are spoiling for a fight with the Bangladesh Rifles (BDR) cadres.\nSo far, the Bangladesh army leaders, led by army chief Moeen Ahmed, have kept the officers in check, which is making the present situation slightly different from 1975.\nAccording to the fire service operations chief, Sheikh Mohammad Shahjalal, 50 officers are still missing.\n"We have so far removed 10 dead bodies.\nThey are badly decomposed and many are mutilated," he said.\n"They not only shot them dead but some bodies were badly mutilated with bayonets," Shahjalal said.It is increasingly clear that the chief targets are the army chief Moeen Ahmed and prime minister Sheikh Hasina who, reports say, has been moved to
    an army guest house for her personal safety.In fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.Sources are also pointing to the scale of the brutality of the murders, the mutilations, etc, which they say are tell-tale signs of the Islamist ideologies that have infiltrated the lower cadres of the BDR, thanks to their extensive Jamaat-e-Islami and Jamaat-ul-Mujahideen Bangladesh (JMB) connections.Behind the mutiny is the war crimes tribunal that Sheikh Hasina promised to set up for the trial of Pakistani collaborators or razakars from the independence war.\nThis had created trouble inside Bangladesh and Pakistan as well.\n'

>>> indexes = [m.start() for m in re.finditer(file[306233:306233+100], file)]
>>> indexes
[306233, 308627]
原文还真的是这样的：head -c 310782 openwebtext.1.txt | tail -c 5000
不过为啥两个都删了。。??


+++++++++ V2 With tokenizer +++++++++++++

echo 4
### =========== Convert the dataformat ============
export dataset=OWT_subset_withtokenize.txt
mkdir data
python convertData.py --data_dir ./openwebtext_subset --save_file data/$dataset.convert --tokenize
export dataset=$dataset.convert
### ========= End ============

echo 5
### =========== Build Suffix_array ================
# Finding all repeated substrings within a document
ulimit -Sn 1000000
sudo /opt/conda/bin/python scripts/make_suffix_array.py data/$dataset
sudo rm ./data/$dataset.part.*
### ========= End ============

echo 6
### =========== Deduplicate ================
# Output means: This means that the deduplicator found $output sequences of length $length that existed somewhere else in the dataset.
# In our paper, we used 50 tokens (which is 100 bytes---so remember that if you pass --tokenize you'll need to double the number of bytes for the length threshold).
export duplength=50
cargo run self-similar --data-file data/$dataset --length-threshold $duplength --cache-dir /tmp/cache --num-threads 64
sudo rm ./tmp/*
# 17626907 (duplength=200)
# 59817636 (duplength=50)
# 64654849 (duplength=50 with new converting)
# 59779982 (duplength=50 with new new converting)

# gather lines of documents to be removed with has over $duplength overlap with others
cargo run collect --data-file data/$dataset --cache-dir /tmp/cache --length-threshold $duplength > ./tmp/drop_tokens_file_dup${duplength}_fixtokenize

sudo /opt/conda/bin/python scripts/finish_single_file.py data/$dataset ./tmp/drop_tokens_file_dup${duplength}_fixtokenize data/$dataset.dedup_${duplength}_fixtokenize True # the last one means detokenized or not
# Warning: suc: 1802365 with fail: 2002
# Warning: suc: 1717265 with fail: 17098 (duplength=50)
# Warning: suc: 1812842 with fail: 1 (duplength=50 with new converting)

sudo rm ./data/$dataset.part.*
sudo rm ./data/$dataset.dedup.tmp
### ========= End ============


### ========= Analysis ============


对于第一个例子而言，tokenized版本变成了：
    We’ve know for some time that the Main Stream Media takes license with editing of remarks and video.
    The arrogance of MSNBC is stunning.
    And the notion that MSM usually does this sort of hijinx with impunity is horrifying.
    Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast to$!Ryan John McPartlin[1] (born July 3, 1975) is an American actor, known for his role as Devon "Captain Awesome" Woodcomb on the NBC action-comedy series Chuck.
    McPartlin was born in Chicago, Illinois, the son of Steve and Lois McPartlin.
    He was raised in Glen Ellyn, Illinois (a suburb of Chicago),[2] and attended Glenbard South High School.
    McPartlin graduated with a degree in speech communication from the University of Illinois at Urbana–Champaign.
    He was a member of the Illinois Fighting Illini football team as a walk-on tight end from 1993-95.
    McPartlin's older brother, Chris, was also a member of the Illinois football team, earning a varsity letter as a linebacker in 1994.  
    [3] After six months in Australia and New Zealand, McPartlin moved to Southern California to pursue acting as a career.
    McPartlin spent years as an Abercrombie & Fitch model.
    [2] McPartlin's first acting role was on The Nanny with Fran Drescher as a Leonardo DiCaprio-type character in a Titanic spoof.
    [2] McPartlin has been mostly known for his role as Hank Bennett on the popular soap opera Passions replacing Dalton James from April 2001 until June 2004 and made a brief appearance in the series L.A.7 as Ryan.
    McPartlin worked with Drescher again as Riley Martin on the television sitcom Living with Fran playing her much younger live-in boyfriend.
    [2] Living with Fran was canceled on May 17, 2006, after two seasons.
    McPartlin originally auditioned for the role of Clark Kent/Superman in the film Superman Returns, but lost the role to Brandon Routh.
    In 2008, Ryan participated in Mad Men, playing an affair of January Jones's character, Betty Draper.
    McPartlin also played Devon "Captain Awesome" Woodcomb on NBC's Chuck from 2007 to 2012.
    In mid-2011, McPartlin appeared in Sugarland's music video "Stuck Like Glue" as a man being stalked and abducted by lead singer Jennifer Nettles.
    McPartlin appears in commercials for Kate Walsh's perfume "Boyfriend".
    In March 2012, McPartlin began working with the website LiveLifeLocal to help promote active lifestyles and is filming a series of videos for the site.
    In 2014, he portrayed the recurring roles of police detective Dwayne Freeman on Mystery Girls and Billy the fireman on Bad Judge.
    McPartlin is a certified personal trainer.
    He has been married to actress Danielle Kirlin since October 26, 2002, and has two sons.
    McPartlin's hobbies include scuba diving, tennis, snowboarding and racquetball.

raw text版本变成了：
    We’ve know for some time that the Main Stream Media takes license with editing of remarks and video.
    The arrogance of MSNBC is stunning.
    And the notion that MSM usually does this sort of hijinx with impunity is horrifying.
    Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast to coRyan John McPartlin[1] (born July 3, 1975) is an American actor, known for his role
    as Devon "Captain Awesome" Woodcomb on the NBC action-comedy series Chuck.
    McPartlin was born in Chicago, Illinois, the son of Steve and Lois McPartlin.
    He was raised in Glen Ellyn, Illinois (a suburb of Chicago),[2] and attended Glenbard South High School.
    McPartlin graduated with a degree in speech communication from the University of Illinois at Urbana–Champaign.
    He was a member of the Illinois Fighting Illini football team as a walk-on tight end from 1993-95.
    McPartlin's older brother, Chris, was also a member of the Illinois football team, earning a varsity letter as a linebacker in 1994.
    [3] After six months in Australia and New Zealand, McPartlin moved to Southern California to pursue acting as a career.
    McPartlin spent years as an Abercrombie & Fitch model.
    [2] McPartlin's first acting role was on The Nanny with Fran Drescher as a Leonardo DiCaprio-type character in a Titanic spoof.
    [2] McPartlin has been mostly known for his role as Hank Bennett on the popular soap opera Passions replacing Dalton James from April 2001 until June 2004 and made a brief appearance in the series L.A.
    7 as Ryan.

而原来是：
    We’ve know for some time that the Main Stream Media takes license with editing of remarks and video.
    The arrogance of MSNBC is stunning.
    And the notion that MSM usually does this sort of hijinx with impunity is horrifying.
    Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast to coast.
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    Will the media learn anything from their biased reporting of the Jussie Smollett story?
    * Yes, they've gotten so much wrong recently that they're bound to be on their best behavior.
    No, they suffer from a bad case of Trump Derangement Syndrome.
    Jussie who?
    Name This field is for validation purposes and should be left unchanged.
    Completing this poll grants you access to The Black Sphere updates free of charge.
    You may opt out at anytime.
    You also agree to this site's Privacy Policy and Terms of Use.

    Ryan John McPartlin[1] (born July 3, 1975) is an American actor, known for his role as Devon "Captain Awesome" Woodcomb on the NBC action-comedy series Chuck.
    McPartlin was born in Chicago, Illinois, the son of Steve and Lois McPartlin.
    He was raised in Glen Ellyn, Illinois (a suburb of Chicago),[2] and attended Glenbard South High School.
    McPartlin graduated with a degree in speech communication from the University of Illinois at Urbana–Champaign.
    He was a member of the Illinois Fighting Illini football team as a walk-on tight end from 1993-95.
    McPartlin's older brother, Chris, was also a member of the Illinois football team, earning a varsity letter as a linebacker in 1994.
    [3] After six months in Australia and New Zealand, McPartlin moved to Southern California to pursue acting as a career.
    McPartlin spent years as an Abercrombie & Fitch model.
    [2] McPartlin's first acting role was on The Nanny with Fran Drescher as a Leonardo DiCaprio-type character in a Titanic spoof.

可以发现：
    tokenizer版本：from coast to$!Ryan这里，本来应该是from coast to co\n\nRyan，但是被错误decode了。但是确实重复的部分被删掉了
    而raw版本：from coast to coRyan John，也是没有了分段。主要是因为duplicate range里就含了\n\n..
    所以可能raw版本是能保留分段的，但是tokenizer版本出现这里有问题


对于第二个例子而言，tokenized版本完全没有删，因为它的duplicated是这样的：
    559 874
    140737 141036
    141801 142100
    310143 310368
    我觉得主要是因为那个例子重复长度没有超过100个token ids（200 bytes），所以完全没有考虑

raw text变成了：[注意这里删除了连续两段，就是因为在原来的部分也是连续两个]
    Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina.
    ...
    That latter quote pretty much sums up our gripes about Katrina, although I’m not sure it’s a sharp move for the actress to complain about her personal problems to a reporter without a heads up to the Sleepy Hollow staff.
    Winter’s preaching truths, though.
    Her character is not particularly faithful to Ichabod and seems pretty sneaky.
    Although she is sneaky, she’s not a particularly strong female character and has had to be saved in numerous situations.
    Yet, fans are still expected to believe that she is a powerful witch with numerous skill sets, instead of an annoyance who looks good in a corset.
    Winter’s frustrated, fans are frustrated, but will Sleepy Hollow do anything about her character?
    We’ll have to tune in to find out, I guess.
    Interestingly, I think it’s worth pointing out that killing off the character might solve some of the show’s big problems this season.
    However, while Sleepy Hollow has had a penchant for killing off characters, those characters often return.
    Sleepy Hollow, and I’m not sure Fox’s drama is angling for that, anyway.
    One thing is for certain, Winter is not happy with her character’s direction, and hopefully that will be reflected in the long game.



但是对于duplength=50的tokenized version 这个，这一部分去除是有的，看看结果：
首先例子一的问题依然存在：
    they could be fresh air in the fetid newsrooms from coast to$!Ryan John McPartlin[1] (born July 3, 1975)
    问题一的原因是special head 65535也被包括进去了重复部分：422,  7051,   284,  3,     0, 21868, 这里本来应该是65535, 3, 0
其次看看例子二：
    Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina.
    God... SheThat latter quote pretty much sums up our gripes about Katrina, although I’m not sure it’s a sharp move for the actress to complain about her personal problems to a reporter without a heads up to the Sleepy Hollow staff.
    Winter’s preaching truths, though.
    Her character is not particularly faithful to Ichabod and seems pretty sneaky.
    Although she is sneaky, she’s not a particularly strong female character and has had to be saved in numerous situations.
    Yet, fans are still expected to believe that she is a powerful witch with numerous skill sets, instead of an annoyance who looks good in a corset.
    Winter’s frustrated, fans are frustrated, but will Sleepy Hollow do anything about her character?
    We’ll have to tune in to find out, I guess.
    Interestingly, I think it’s worth pointing out that killing off the character might solve some of the show’s big problems this season.
    However, while Sleepy Hollow has had a penchant for killing off characters, those characters often return.
    Sleepy Hollow, and I’m not sure Fox’s drama is angling for that, anyway.
    One thing is for certain, Winter is not happy with her character’s direction, and hopefully that will be reflected in the long game.

-> 多了一个 `God... She` 其他基本是一样的。因为它是从", I've"开始到'you know?'，然后再从"hasn't really"到"doesn't help."
奇怪的是为什么都多留了前3个字母 or 一个单词
不是detokenize的问题，因为rm ids之后剩下来就是这样子的。为什么这里转成tokenize之后多留了点东西。。
难道是把\n加进去tokenize的问题？
因为一个是这样写的：\nGod, I've had a hard time at times.
一个是这样写的：Winter: God, I've had a hard time at times.

还真是：
In [3]: a = "\nGod, I've had a hard time at times."

In [4]: tokenizer.encode(a)
Out[4]: [198, 13482, 11, 314, 1053, 550, 257, 1327, 640, 379, 1661, 13]

In [6]: b = "Winter: God, I've had a hard time at times."

In [8]: tokenizer.encode(b)
Out[8]: [35376, 25, 1793, 11, 314, 1053, 550, 257, 1327, 640, 379, 1661, 13]

In [9]: a = "\n God, I've had a hard time at times."

In [10]: tokenizer.encode(a)
Out[10]: [198, 1793, 11, 314, 1053, 550, 257, 1327, 640, 379, 1661, 13]

在"\n"变成" \n "可能会好一点。

这两个问题可能都可以改，接下来的问题反而是 ++++++++++++ 以及为什么这个影响那么大啊。。+++++++++++++++++

把问题一，也即$!的问题改了之后error就detokenize的error就没了，存下来的大小也从6.5G涨到了6.7G
现在变成了：from coast toRyan John，和文本那边略有区别：那边是from coast to coRyan John，这边多删了一个 " co"

然后接着改了tokenize （在\n前后加空格来确保更好的tokenize一致性）
问题二变成了：和rawtext有点不同，但是好了不少
    Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina. ... That latter quote pretty much sums up our gripes about Katrina, although I’m not sure it’s a sharp move for the actress to complain about her personal problems to a reporter without a heads up to the Sleepy Hollow staff.
    Winter’s preaching truths, though.
    Her character is not particularly faithful to Ichabod and seems pretty sneaky.
    Although she is sneaky, she’s not a particularly strong female character and has had to be saved in numerous situations.

> Without Dedup
    -> 3.96 train loss & 5.02 on wikitext-103 loss
> Raw text
    -> 3.97 train loss & 4.98 on wikitext-103 loss
    最开始8.36
> After tokenized dup200 (OWT1+2 exact dup 200; 5.57)
    -> 3.96 train loss & 5.72 on wikitext-103 loss
    最开始8.76
> After tokenized dup50
    最开始8.76，几乎没区别，看来length不是问题
> After tokenized dup50 + fix detokenize
    最开始8.70，第二个checkpoint一样差
> After tokenized dup50 + fix detokenize + tokenize
    最开始8.72。。最后5.61 on wikitext-103 loss 无语了，到底是哪里的问题
> After tokenized dup50 + fix detokenize + tokenize V2
    最开始8.76，我是真的真的无语了


接着可能就是要对比tokenize和raw text line by line的区别了。找不到别的问题所在。
Version: > After tokenized dup50 + fix detokenize + tokenize

在deconvert的时候多了一个空行。
D-1一样
D-2是from coast toRyan John v.s. from coast to coRyan John
其他没有删的都是一样的
但这也不是办法
还是用code看吧

    In [1]: rawtext = open('openwebtext_5G_4_abl_data_dedup_raw.txt').readlines()

    In [2]: len(rawtext)
    Out[2]: 59449422

    In [3]: tokentext = open('openwebtext_5G_4_abl_data_dedup_tokenized_dup50_fixendetoken.txt').readlines()

    In [4]: len(tokentext)
    Out[4]: 61028698

    In [6]: newtokentext = []

    In [7]: for idx, t in enumerate(tokentext):
    ...:     if t == '\n':
    ...:         if tokentext[idx-1] == '\n':
    ...:             continue
    ...:         else:
    ...:             newtokentext.append(t)
    ...:     else:
    ...:         newtokentext.append(t)
    ...:

    In [8]: len(newtokentext)
    Out[8]: 59329126


    In [12]: for i in range(60000000):
        ...:     if tokentext[i] != rawtext[i]:
        ...:         print(i)
        ...:         break
        ...:
    11

    这是之前的第一个例子；

    In [13]: tokentext[11]
    Out[13]: 'Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast toRyan John McPartlin[1] (born July 3, 1975) is an American actor, known for his role as Devon "Captain Awesome" Woodcomb on the NBC action-comedy series Chuck.\n'

    In [14]: rawtext[11]
    Out[14]: 'Koch brothers Let’s hope thepursue the Tribune Company: they could be fresh air in the fetid newsrooms from coast to coRyan John McPartlin[1] (born July 3, 1975) is an American actor, known for his role as Devon "Captain Awesome" Woodcomb on the NBC action-comedy series Chuck.\n'

    after 11：208
    这个无伤大雅。

    In [17]: tokentext[i]
    Out[17]: 'The framerate uplift just isn\x92t there and the money you save could easily be put towards a better GPU.\n'

    In [18]: rawtext[i]
    Out[18]: 'The framerate uplift just isn\x92t there and the money you save could easily be put towards a better GPU .\n'

    ++++++ Summary 我现在觉得还是删掉有ExactArray matching的 Document好了。。

    after 208：285
    这是例子2
    In [20]: tokentext[i]
    Out[20]: 'Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina. ... That latter quote pretty much sums up our gripes about Katrina, although I’m not sure it’s a sharp move for the actress to complain about her personal problems to a reporter without a heads up to the Sleepy Hollow staff.\n'

    In [21]: rawtext[i]
    Out[21]: 'Here’s what Winter had to say in a recent interview with TV Guide when asked why fans have had troubling falling in love with Katrina.\n'

    所以接下来：
    In [24]: for i in range(286, 60000000):
        ...:     if tokentext[i] != rawtext[i+2]:
        ...:         print(i)
        ...:         prev_i = i
        ...:         break
        ...:
    337

    这个也误伤大雅
    In [25]: rawtext[i+2]
    Out[25]: "And so the genre neo-soul—with its retro emphasis on 'real’ instruments, sophisticated musicianship and hip Afrocentricity—was officially born.\n"

    In [26]: tokentext[i]
    Out[26]: "And so the genre neo-soul—with its retro emphasis on'real’ instruments, sophisticated musicianship and hip Afrocentricity—was officially born.\n"

    393：
    In [28]: tokentext[i]
    Out[28]: "During the album’s long-gestating pre-production and production phases, D'Angelo,?\n"

    In [29]: rawtext[i+2]
    Out[29]: "During the album’s long-gestating pre-production and production phases, D'Angelo, ?\n"

    394，396，407，450相同

    接着有一个不一样的了，这下子是rawtext版本把两个document merge起来了，这下子rawtext的+2可以免除了
    In [36]: for i in range(prev_i+1, 60000000):
        ...:     if tokentext[i] != rawtext[i+2]:
        ...:         print(i, tokentext[i], rawtext[i+2])
        ...:         prev_i = i
        ...:         break
        ...:
    1900 Still, Mr. Benson’s complaint said Renee and her two children “will continue to enjoy hundreds of millions of dollars they have been given; they simply will not have the specific assets they would like to have.”
    Still, Mr. Benson’s complaint said Renee and her two children “will continue to enjoy hundreds of millions of dollars they have been given; they simply will not have the specific assets they would like to haveare an excellent warrior with a score of burning enemies in your wake, but your many trials have left only your driver and gunner unhurt.
    In [37]: tokentext[i+1]
    Out[37]: '\n'

    In [38]: tokentext[i+2]
    Out[38]: 'an excellent warrior with a score of burning enemies in your wake, but your many trials have left only your driver and gunner unhurt.\n'

    接下来是tokentext的\n少了一个，rawtext的idx又要加一了
    In [48]: for i in range(prev_i+1, 60000000):
        ...:     if tokentext[i] != rawtext[i]:
        ...:         print(i, tokentext[i], rawtext[i])
        ...:         prev_i = i
        ...:         break
        ...:
    2090 And on Tuesday, with fortuitous timing, reports broke that the Manhattan DA is now preparing an indictment against Weinstein to be detailed next week It will be, like seemingly many of these 2017 elections, a bellwether for Democrats in 2018.
    And on Tuesday, with fortuitous timing, reports broke that the Manhattan DA is now preparing an indictment against Weinstein to be detailed next week

    In [49]: rawtext[i+1]
    Out[49]: 'It will be, like seemingly many of these 2017 elections, a bellwether for Democrats in 2018.\n'

    然后是2371，tokentext的\n又少了一个。rawtext的idx又要加一了
    In [59]: for i in range(prev_i+1, 60000000):
        ...:     if tokentext[i] != rawtext[i+1]:
        ...:         print(i, tokentext[i], rawtext[i+1])
        ...:         prev_i = i
        ...:         break
        ...:
    2371 If I were President Obama, I would quickly release the suspected operatives, send them back to Moscow with bottles of champagne and follow that up with a visit by the Secretary of State to ask what it is the Kremlin doesn't know about the U.S. that it wants to knowStar Trek is a science fiction series.
    If I were President Obama, I would quickly release the suspected operatives, send them back to Moscow with bottles of champagne and follow that up with a visit by the Secretary of State to ask what it is the Kremlin doesn't know about the U.S. that it wants to kno

    In [60]: rawtext[i+2]
    Out[60]: 'Star Trek is a science fiction series.\n'

    2684 raw text多打了一个.
    后边有几行，tokentext可能删了一部分，但是没有删完，有几行一个词的情况
    2685+ 这个看起来raw text更准，主要还是\n的问题

    raw:
    'Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.\n',
    '.\n',
    '\n',
    'As mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of daysSalauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decadesIn fact, Pakistan president Asif Ali Zardari sent an emissary to Sheikh Hasina, Pervez Ispahani, to persuade her to put off this trial as it could embarrass the Pak army considerably.\n',

    after tokenized:
    'Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.\n',
    'Trouble\n',
    'It\n',
    'In fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.\n',
    'Sources\n',
    'Behind As mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of days.ChowSalauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.TroubleItIn fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.SourcesBehind In fact, Pakistan president Asif Ali Zardari sent
    an emissary to Sheikh Hasina, Pervez Ispahani, to persuade her to put off this trial as it could embarrass the Pak army considerably.\n',

    原文：
    Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.
    Trouble continues to brew in Dhaka, where the army cadres, particularly mid-level officers, are spoiling for a fight with the Bangladesh Rifles (BDR) cadres.
    So far, the Bangladesh army leaders, led by army chief Moeen Ahmed, have kept the officers in check, which is making the present situation slightly different from 1975.
    According to the fire service operations chief, Sheikh Mohammad Shahjalal, 50 officers are still missing.
    "We have so far removed 10 dead bodies.
    They are badly decomposed and many are mutilated," he said.
    "They not only shot them dead but some bodies were badly mutilated with bayonets," Shahjalal said.
    It is increasingly clear that the chief targets are the army chief Moeen Ahmed and prime minister Sheikh Hasina who, reports say, has been moved to an army guest house for her personal safety.
    In fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.
    Sources are also pointing to the scale of the brutality of the murders, the mutilations, etc, which they say are tell-tale signs of the Islamist ideologies that have infiltrated the lower cadres of the BDR, thanks to their extensive Jamaat-e-Islami and Jamaat-ul-Mujahideen Bangladesh (JMB) connections.
    Behind the mutiny is the war crimes tribunal that Sheikh Hasina promised to set up for the trial of Pakistani collaborators or razakars from the independence war.
    This had created trouble inside Bangladesh and Pakistan as well.
    As mass graves continue to spew forth more bloody tales - 10 more bodies have been recovered, bringing the toll to 76 - what is emerging slowly is a larger design behind the apparently senseless killing over the past couple of days.The preliminary interrogation of some of the rebels has thrown up the name of Salauddin Qadeer Chowdhury, a well-known shipping magnate and reportedly very close to the Pakistan military-intelligence complex and the opposition BNP.
    According to sources monitoring the situation, about one crore taka has already changed hands to help the mutiny along.Chowdhury, a close associate of opposition BNP leader Begum Khaleda Zia, was closely connected to the Chittagong arms drop case of April 2004 - the arms were apparently intended for ULFA.
    The ships were caught carrying the arms.Salauddin Chowdhury, belonging to an old Chittagong family, has been close to Pakistan for decades.Trouble continues to brew in Dhaka, where the army cadres, particularly mid-level officers, are spoiling for a fight with the Bangladesh Rifles (BDR) cadres.
    So far, the Bangladesh army leaders, led by army chief Moeen Ahmed, have kept the officers in check, which is making the present situation slightly different from 1975.
    According to the fire service operations chief, Sheikh Mohammad Shahjalal, 50 officers are still missing.
    "We have so far removed 10 dead bodies.
    They are badly decomposed and many are mutilated," he said.
    "They not only shot them dead but some bodies were badly mutilated with bayonets," Shahjalal said.It is increasingly clear that the chief targets are the army chief Moeen Ahmed and prime minister Sheikh Hasina who, reports say, has been moved to an army guest house for her personal safety.In fact, a number of plots are surfacing, all intended to create confusion while the real targets would have been attacked.Sources are also pointing to the scale of the brutality of the murders, the mutilations, etc, which they say are tell-tale signs of the Islamist ideologies that have infiltrated the lower cadres of the BDR, thanks to their extensive Jamaat-e-Islami and Jamaat-ul-Mujahideen Bangladesh (JMB) connections.Behind the mutiny is the war crimes tribunal that Sheikh Hasina promised to set up for the trial of Pakistani collaborators or razakars from the independence war.

    总结起来感觉还是\n的缘故


需要排查：
    1. 是否因为是duplength的区别
        现在是raw text=100 bytes，token=200 bytes; 
        raw: 6.9G -> 6.6G
        token: 6.9G -> 6.8G
        token_dup50: 6.9 -> 6.5G
        这是合理的，因为预计200 bytes=100 token ids，考虑到一个token大约是4个bytes（gopher test with 4.3 bytes per token），
        所以等价的raw text应该至少是400.
        所以这里应该是除以2，但为什么他们说是乘以2？？？？

        不过有意思的是，这里只是删掉了100M的数据，质量直接直线下降。。（train loss不变，但是validation非常差）


    1.1. 我们先试下400 bytes的raw；或者50 bytes的tokenized。
    可以先改成50 bytes tokenized的id matching
    这时候的duplicated sentence是这样的：前三个差不多就是raw_100_bytes里的 1200,1886; 36299,36695; 36699,37099。这个range几本match上了。
        559 874
        15890 16096
        16100 16298
        98710 98768
        108054 108168
        123570 123666
        140427 140572
        140573 140684
        140685 140736
        140737 141036
        141037 141116
        141117 141168
        141169 141316
        141317 141410
        141497 142466
        145366 145452
    但是效果还是很差。
    
    2. 排查一下detokenize的时候，把\xff\xff被删掉的情况加回来。貌似还是不太行。

    2.1. 多加一个 blank before and after \n or \n\n to make the tokenize consistent