When I first heard about [magenta](https://magenta.tensorflow.org/) and machine learning for musical generation I was very excited. Soon after I realized that if I wanted to train my own model I was going to have to get a better computer and plan on doing a lot of web scraping of midi files...

Then I found out they have pre-trained models that we can play with. OK... not as cool as training your own but still interesting. So I thought I would git it a try:

First we need to run these commands to set up the environment:

```bash
sudo apt-get install build-essential libasound2-dev libjack-dev portaudio19-dev
virtualenv magenta
source magenta/bin/activate
pip3 install magenta
```

Ok now that we have our environment set up we can generate some melodies right? No! We need to [download some pre-trained models](https://github.com/tensorflow/magenta/tree/master/magenta/models/melody_rnn) from magenta. I got the basic_rnn, the loockback_rnn and the attention_rnn. Download the ones you want to use.

Now you can generate some basic melodies. Try the following:

```bash
melody_rnn_generate --config=basic_rnn --bundle_file=basic_rnn.mag --output_dir=/path/to/output/dir --num_outputs=10 --num_steps=128 --primer_melody="[60]"
```

This primes magenta with the midi note 60 which is middle C. This is not meant to be a complete guide so play with the other parameters and check the [Docs](https://github.com/tensorflow/magenta) for more info. This should at least get you started though. You can read more about RNN (Reccurent Neural Nets) [here](https://towardsdatascience.com/recurrent-neural-networks-d4642c9bc7ce) and [here](https://elham-khanche.github.io/blog/RNNs_and_LSTM/)

The lookback model sounds a little better in my opinion:

```bash
melody_rnn_generate --config=lookback_rnn --bundle_file=lookback_rnn.mag --output_dir=~/Documents/magentaTutorial/generated --num_outputs=10 --num_steps=128 --primer_melody="[60]"
```

But the attention model sounds the best:

```bash
melody_rnn_generate --config=attention_rnn --bundle_file=attention_rnn.mag --output_dir=~/Documents/magentaTutorial/generated --num_outputs=10 --num_steps=128 --primer_melody="[60]"
```

You can also feed it a midi file for priming:

```bash
melody_rnn_generate --config=attention_rnn --bundle_file=attention_rnn.mag --output_dir=~/Documents/magentaTutorial/generated --num_outputs=10 --num_steps=128 --primer_midi=/path/to/midifile.mid
```

You can also check out my git hub repo with all the pretrained models and sample commands [here](https://github.com/karangejo/magenta-melody-gen)
