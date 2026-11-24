import streamlit as st
import joblib
import json
import re
import numpy as np
import io
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models"
import tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences
# import nltk
# import cleantext
# nltk.download('stopwords')

# --- 1. ΡΥΘΜΙΣΕΙΣ ΣΕΛΙΔΑΣ ---
st.set_page_config(
    page_title="Sentiment Analysis | Master Thesis",
    page_icon="🧠",
    layout="wide"
)

# Προαιρετικό CSS για πιο καθαρό, μοντέρνο look
st.markdown("""
    <style>
    .footer {
        position: fixed;
        left: 0;
        bottom: 0;
        width: 100%;
        background-color: transparent;
        color: #888888;
        text-align: center;
        padding: 10px;
        font-size: 13px;
    }
    </style>
""", unsafe_allow_html=True)

# --- 2. ΦΟΡΤΩΣΗ ΜΟΝΤΕΛΩΝ (ΜΕ CACHE) ---
@st.cache_resource
def load_models():
    lr_syuzhet = joblib.load(MODELS_DIR / "tfidf_logreg_syuzhet.joblib")
    lr_textblob = joblib.load(MODELS_DIR / "tfidf_logreg_textblob.joblib")
    bilstm = tf.keras.models.load_model(MODELS_DIR / "bilstm_sentiment_model.keras")
    with open(MODELS_DIR / "bilstm_tokenizer.json", "r", encoding="utf-8") as f:
        tokenizer = json.load(f)

    return lr_syuzhet, lr_textblob, bilstm, tokenizer

with st.spinner("Φόρτωση Μοντέλων..."):
    lr_syuzhet, lr_textblob, bilstm_model, tokenizer_config = load_models()


# --- ΠΡΟΕΠΕΞΕΡΓΑΣΙΑ (ίδια με τον καθαρισμό της R) ---
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


# --- 3. ΠΛΑΪΝΗ ΜΠΑΡΑ (SIDEBAR) ---

logo_path = BASE_DIR.parent / "assets" / "UTH-logo-english.png"
if logo_path.exists():
    st.sidebar.image(str(logo_path), width=200)
st.sidebar.markdown("---")
st.sidebar.title("Ρυθμίσεις Ανάλυσης")

selected_model = st.sidebar.radio(
    "Επιλογή Μοντέλου:",
    (
        "Logistic Regression (Syuzhet Target)", 
        "Logistic Regression (TextBlob Target)", 
        "BiLSTM (Deep Learning)"
    )
)

st.sidebar.markdown("---")
# Στοιχεία Δημιουργού & Social Links (LinkedIn & GitHub)
st.sidebar.markdown(
    """
    <div style="background-color: rgba(128, 128, 128, 0.1); padding: 15px; border-radius: 10px;">
        <p style="margin-bottom: 5px; font-size: 14px;"><b>Developed by:</b> Chouliaras Dimitrios</p>
        <p style="margin-bottom: 12px; font-size: 13px; color: #888;">🎓 UTH Thessaly</p>
        <p style="margin-bottom: 12px; font-size: 13px; color: #888;">Master Thesis Project<br>Data Engineering & NLP</p>
        <div style="display: flex; gap: 10px;">
            <a href="https://www.linkedin.com/in/dimitrios-chouliaras/" target="_blank" style="text-decoration: none; display: inline-flex; align-items: center; background-color: #0077B5; color: white; padding: 6px 12px; border-radius: 6px; font-size: 13px; font-weight: bold;">
                <svg xmlns="http://w3.org" width="16" height="16" fill="white" viewBox="0 0 24 24" style="margin-right: 6px;">
                    <path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/>
                </svg>
                LinkedIn
            </a>
            <a href="https://github.com/Dimitris-Chouliaras" target="_blank" style="text-decoration: none; display: inline-flex; align-items: center; background-color: #24292e; color: white; padding: 6px 12px; border-radius: 6px; font-size: 13px; font-weight: bold;">
                <svg xmlns="http://w3.org" width="16" height="16" fill="white" viewBox="0 0 24 24" style="margin-right: 6px;">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                </svg>
                GitHub
            </a>
        </div>
    </div>
    """,
    unsafe_allow_html=True
)

# --- 4. ΚΥΡΙΩΣ ΟΘΟΝΗ (MAIN PAGE) ---
st.title("Google Play Store Reviews Sentiment Analysis")
st.markdown(f"**Ενεργό Μοντέλο:** `{selected_model}`")

tab1, tab2 = st.tabs(["✍️ Γρήγορη Δοκιμή", "📁 Μαζική Ανάλυση (CSV)"])

# ----- ΚΑΡΤΕΛΑ 1: ΓΡΗΓΟΡΗ ΔΟΚΙΜΗ -----
with tab1:
    st.subheader("Ανάλυση Μεμονωμένου Κειμένου")
    user_input = st.text_area("Πληκτρολόγησε μια κριτική στα Αγγλικά (π.χ. 'I do not like this app'):", height=120)
    
    if "analyze_clicked" not in st.session_state:
        st.session_state.analyze_clicked = False

    def on_analyze_click():
        st.session_state.analyze_clicked = True

    st.button("Ανάλυση Συναισθήματος", type="primary", on_click=on_analyze_click)
    
    if st.session_state.analyze_clicked:
        if user_input and clean_text(user_input):

            text_prep = clean_text(user_input)

            # 1. Πρόβλεψη Συναισθήματος
            if selected_model == "Logistic Regression (Syuzhet Target)":
                prediction = lr_syuzhet.predict([text_prep])[0]
                probabilities = lr_syuzhet.predict_proba([text_prep])[0]
                classes = lr_syuzhet.classes_

            elif selected_model == "Logistic Regression (TextBlob Target)":
                prediction = lr_textblob.predict([text_prep])[0]
                probabilities = lr_textblob.predict_proba([text_prep])[0]
                classes = lr_textblob.classes_

            else:
                probs = bilstm_model.predict(to_padded([text_prep]), verbose=0)[0]
                classes = tokenizer_config["classes"]
                prediction = classes[int(np.argmax(probs))]
                probabilities = probs
            
            # Εμφάνιση Αποτελεσμάτων
            if prediction == "Positive":
                st.success(f"### Τελικό Συναίσθημα: **{prediction}** 😃")
            elif prediction == "Negative":
                st.error(f"### Τελικό Συναίσθημα: **{prediction}** 😡")
            else:
                st.warning(f"### Τελικό Συναίσθημα: **{prediction}** 😐")
            
            st.markdown("#### Πιθανότητες Εμπιστοσύνης (Confidence):")
            for i, class_name in enumerate(classes):
                prob = float(probabilities[i])
                st.write(f"**{class_name}**: {prob*100:.1f}%")
                st.progress(prob)
                
            # 2. Εμφάνιση του Καθαρισμένου Κειμένου με τη βιβλιοθήκη cleantext
            st.markdown("---")
            st.subheader("🧹 Καθαρισμός Κειμένου (Clean Text)")
            # cleaned_output = cleantext.clean(
            #     user_input, 
            #     clean_all=False, 
            #     extra_spaces=True, 
            #     # stopwords=True,
            #     lowercase=True, 
            #     numbers=True, 
            #     punct=True
            # )
            # st.info(cleaned_output)
            # st.write(':red[Removing unnecessary words which have zero impact from the text given]')
            st.info(text_prep)
            st.caption("Το κείμενο όπως το επεξεργάζεται το μοντέλο: πεζά γράμματα, χωρίς αριθμούς και σημεία στίξης.")    
        
        else:
            st.warning("Παρακαλώ, πληκτρολόγησε κείμενο με γράμματα πρώτα.")

# ----- ΚΑΡΤΕΛΑ 2: ΜΑΖΙΚΗ ΑΝΑΛΥΣΗ (CSV) -----
with tab2:
    st.subheader("Μαζική Ανάλυση Αρχείου")
    uploaded_file = st.file_uploader("Ανέβασε ένα αρχείο .csv ή .xlsx", type=["csv", "xlsx"])
    
    if uploaded_file is not None:
        import pandas as pd
        if uploaded_file.name.endswith('.csv'):
            dataframe = pd.read_csv(uploaded_file)
        else:
            dataframe = pd.read_excel(uploaded_file)
            
        columns = dataframe.columns.tolist()
        columns.insert(0, "Select Column")
        selected_column = st.selectbox('Select Column for Analysis:', columns)
        
        if selected_column != "Select Column":
            if st.button("Έναρξη Μαζικής Ανάλυσης", type="primary"):
                with st.spinner("Η ανάλυση είναι σε εξέλιξη..."):
                    texts = [clean_text(t) for t in dataframe[selected_column].fillna('').astype(str)]
                    
                    if selected_model == "Logistic Regression (Syuzhet Target)":
                        predictions = lr_syuzhet.predict(texts)
                        probs = lr_syuzhet.predict_proba(texts)
                        dataframe['Predicted_Sentiment'] = predictions
                        dataframe['Confidence_Max'] = np.max(probs, axis=1)
                        
                    elif selected_model == "Logistic Regression (TextBlob Target)":
                        predictions = lr_textblob.predict(texts)
                        probs = lr_textblob.predict_proba(texts)
                        dataframe['Predicted_Sentiment'] = predictions
                        dataframe['Confidence_Max'] = np.max(probs, axis=1)
                        
                    else:
                        #word_index = tokenizer_config["word_index"]
                        #max_len = tokenizer_config["max_len"]
                        #oov_index = tokenizer_config["oov_index"]
                        #classes = tokenizer_config["classes"]
                        
                        # seqs = []
                        # for t in texts:
                        #     t = str(t).lower()
                        #     t = re.sub(r'[^\w\s]', '', t)
                        #     seq = [word_index.get(word, oov_index) for word in t.split()]
                        #     seqs.append(seq)
                            
                        #padded_texts = pad_sequences(seqs, maxlen=max_len, padding='post', truncating='post')
                        classes = tokenizer_config["classes"]
                        padded_texts = to_padded(texts)
                        batch_probs = bilstm_model.predict(padded_texts, verbose=0)
                        pred_indices = np.argmax(batch_probs, axis=1)
                        
                        dataframe['Predicted_Sentiment'] = [classes[i] for i in pred_indices]
                        dataframe['Confidence_Max'] = np.max(batch_probs, axis=1)

                    empty = np.array([t == '' for t in texts])
                    dataframe.loc[empty, ['Predicted_Sentiment', 'Confidence_Max']] = None
                    st.success("Η μαζική ανάλυση ολοκληρώθηκε επιτυχώς!")
                    st.dataframe(dataframe[[selected_column, 'Predicted_Sentiment', 'Confidence_Max']].head(10))
                    
                    excel_buffer = io.BytesIO()
                    with pd.ExcelWriter(excel_buffer, engine='xlsxwriter') as writer:
                        dataframe.to_excel(writer, index=False, sheet_name='Sheet1')
                    excel_data = excel_buffer.getvalue()
                    
                    st.download_button(
                        label="📥 Download data as Excel",
                        data=excel_data,
                        file_name='analyzed_data.xlsx',
                        mime='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                    )
        else:
            st.dataframe(dataframe)
