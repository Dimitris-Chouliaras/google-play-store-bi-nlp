import json, re
import numpy as np, pandas as pd, tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences

test  = pd.read_csv("../data_clean/ml_splits/test.csv")
saved = pd.read_csv("models/bilstm_test_predictions.csv")
model = tf.keras.models.load_model("models/bilstm_sentiment_model.keras")
cfg = json.load(open("models/bilstm_tokenizer.json", encoding="utf-8"))
tokenizer_config = cfg

def clean_text(text):
    text = str(text).lower()
    text = re.sub(r'https?://\S+|www\.\S+', ' ', text)
    text = re.sub(r'[^a-z\s]', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()

def to_padded(texts):
    word_index = tokenizer_config["word_index"]
    oov_index  = tokenizer_config["oov_index"]
    vocab_size = tokenizer_config["vocab_size"]
    max_len    = tokenizer_config["max_len"]
    seqs = []
    for t in texts:
        seq = []
        for w in clean_text(t).split():
            idx = word_index.get(w, oov_index)
            seq.append(idx if idx < vocab_size else oov_index)
        seqs.append(seq)
    return pad_sequences(seqs, maxlen=max_len, padding='post', truncating='post')

probs = model.predict(to_padded(test["Clean_Text"]), verbose=0)
print(f"Ταύτιση με τις προβλέψεις του Colab: {(np.argmax(probs, axis=1) == saved['y_pred'].values).mean():.4%}")