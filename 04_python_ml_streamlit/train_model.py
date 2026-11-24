import os # Μας βοηθάει να φτιάχνουμε φακέλους και να ενώνουμε μονοπάτια αρχείων
import pandas as pd # Η βιβλιοθήκη για τους πίνακες (DataFrames)
import joblib # Η βιβλιοθήκη που κάνει "Save" το εκπαιδευμένο μοντέλο στον σκληρό δίσκο.
import matplotlib.pyplot as plt # Η βιβλιοθήκη για τα γραφήματα.
# Φορτώνουμε εργαλεία Μηχανικής Μάθησης
from sklearn.model_selection import train_test_split, GridSearchCV, StratifiedKFold
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, confusion_matrix

# 1. Φόρτωση δεδομένων
file_path = os.path.join('..', 'data_clean', 'reviews_nlp_clean.csv')
df = pd.read_csv(file_path)

# 2. Καθαρισμός & TRAIN/TEST SPLIT
df = df.dropna(subset=['Clean_Text', 'my_sentiment_type', 'Sentiment']) # Αφαίρεση NaN τιμών
df = df[df['Clean_Text'].astype(str).str.strip().str.len() > 0] # Αφαίρεση κενών κειμένων (π.χ. "" ή "   ")

initial_len = len(df)
df = df.drop_duplicates(subset=['Clean_Text']).copy() # Αφαίρεση διπλότυπων κριτικών (κρατάμε μόνο την 1η εμφάνιση)
removed_duplicates = initial_len - len(df)

print(f"Αφαιρέθηκαν {removed_duplicates} διπλότυπες κριτικές.")
print(f"Καθαρό δείγμα για ML: {len(df)} μοναδικές κριτικές.")

X = df['Clean_Text'] # series type
y_syuzhet = df['my_sentiment_type'] # series type Πείραμα 1: Syuzhet (Κύριος Στόχος)
y_blob = df['Sentiment'] # series type Πείραμα 2: TextBlob (Συγκριτικός Στόχος)

# Χωρίζουμε τα δεδομένα: 80% για εκπαίδευση (train) και 20% για έλεγχο (test)
X_train, X_test, y_train_syuzhet, y_test_syuzhet, y_train_blob, y_test_blob = train_test_split(
    X, y_syuzhet, y_blob, test_size=0.2, random_state=42, stratify=y_syuzhet
)

print("\n=== ΔΙΑΧΩΡΙΣΜΟΣ ΔΕΔΟΜΕΝΩΝ ===")
print(f"Training Set: {len(X_train)} κριτικές")
print(f"Test Set:     {len(X_test)} κριτικές\n")



# Αποθηκεύουμε ακριβώς τα ίδια σύνολα, ώστε το νευρωνικό δίκτυο να εκπαιδευτεί και να αξιολογηθεί στα ίδια δεδομένα με το baseline (δίκαιη σύγκριση).
split_dir = os.path.join('..', 'data_clean', 'ml_splits')
os.makedirs(split_dir, exist_ok=True) # Δημιουργία φακέλου αν δεν υπάρχει ήδη

cols = ['App', 'Clean_Text', 'my_sentiment_type', 'Sentiment']
train_df = df.loc[X_train.index, cols]   # οι ίδιες γραμμές με το X_train
test_df = df.loc[X_test.index, cols]     # οι ίδιες γραμμές με το X_test

# index_label='row_id': κρατάμε τον αρχικό αριθμό γραμμής για ανάλυση λαθών αργότερα
train_df.to_csv(os.path.join(split_dir, 'train.csv'), index=True, index_label='row_id', encoding='utf-8')
test_df.to_csv(os.path.join(split_dir, 'test.csv'), index=True, index_label='row_id', encoding='utf-8')

print(f"Αποθηκεύτηκαν: train.csv ({len(train_df)} γραμμές) και test.csv ({len(test_df)} γραμμές) στον φάκελο {split_dir}\n")



# 3. Pipeline: TF-IDF + Logistic Regression
pipeline = Pipeline([
    ('tfidf', TfidfVectorizer(min_df=2, sublinear_tf=True)), # Minimum Document Frequency και εφαρμογή λογαριθμικής κλίμακας
    ('clf', LogisticRegression(random_state=42, max_iter=2000)) # "Τυχαιότητα" και αρκετά βήματα
])

# 4. GRID SEARCH CROSS-VALIDATION
param_grid = {
    'tfidf__ngram_range': [(1, 1), (1, 2)],
    'tfidf__max_features': [5000, None],
    'clf__C': [2, 5, 10, 20, 50],
    'clf__class_weight': [None, 'balanced']
}

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

targets = {
    'Syuzhet (my_sentiment_type)': (y_train_syuzhet, y_test_syuzhet),
    'TextBlob (Sentiment)': (y_train_blob, y_test_blob),
}
labels = ['Negative', 'Neutral', 'Positive']

# Δημιουργία φακέλου models αν δεν υπάρχει
os.makedirs(os.path.join('..', 'models'), exist_ok=True)

all_results = {}   # εδώ κρατάμε τα αποτελέσματα του grid search για το γράφημα

# 5. Εκτέλεση πειραμάτων
for name, (y_tr, y_te) in targets.items():
    print(f"{'=' * 60}\nΠΕΙΡΑΜΑ: {name}\n{'=' * 60}")

    grid_search = GridSearchCV(
        estimator=pipeline, # Η γραμμή παραγωγής
        param_grid=param_grid, # Το μενού με τις ρυθμίσεις
        cv=cv, # 5-Fold Cross Validation
        scoring='f1_macro', # με βάση το F1-Score
        n_jobs=-1,
        verbose=1
    )
    
    grid_search.fit(X_train, y_tr) # Εκπαίδευση (αναζήτηση στο Train)
    all_results[name] = (pd.DataFrame(grid_search.cv_results_), grid_search.best_params_)
    
    print("\n--- Αποτελέσματα Cross-Validation ---")
    print("Καλύτερες ρυθμίσεις:", grid_search.best_params_)
    print(f"Macro-F1 (CV): {grid_search.best_score_:.4f}")

    # Αξιολόγηση στο κρυφό Test Set (Μία φορά)
    best_model = grid_search.best_estimator_
    y_pred = best_model.predict(X_test)

    print("\n--- Αξιολόγηση στο Test Set ---")
    print(classification_report(y_te, y_pred, digits=3))
    print("Confusion Matrix (γραμμές = πραγματικό, στήλες = πρόβλεψη):")
    print(pd.DataFrame(confusion_matrix(y_te, y_pred, labels=labels), index=labels, columns=labels))
    print("\n")

    # Αποθήκευση του νικητήριου μοντέλου
    short = 'syuzhet' if name.startswith('Syuzhet') else 'textblob'
    joblib.dump(best_model, os.path.join('..', 'models', f'tfidf_logreg_{short}.joblib'))

print("Όλα τα πειράματα ολοκληρώθηκαν και τα μοντέλα αποθηκεύτηκαν!")

# 6. ΓΡΑΦΗΜΑ: ανάλυση ευαισθησίας ως προς το C
fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
for ax, (name, (res, best)) in zip(axes, all_results.items()):
    # Κρατάμε μόνο τις γραμμές όπου οι ΑΛΛΕΣ παράμετροι είναι ίδιες με τις βέλτιστες
    mask = pd.Series(True, index=res.index)
    for p, v in best.items():
        if p != 'clf__C':
            col = res[f'param_{p}']
            if v is None:
                mask &= col.isna() | (col.astype(str) == 'None')   # το None εμφανίζεται ως NaN
            else:
                mask &= col.astype(str) == str(v)

    sub = res[mask].sort_values('param_clf__C')
    C_vals = sub['param_clf__C'].astype(float)
    mean = sub['mean_test_score']
    std = sub['std_test_score']

    ax.plot(C_vals, mean, marker='o', label='Μέσο macro-F1 (5-fold CV)')
    ax.fill_between(C_vals, mean - std, mean + std, alpha=0.2, label='± 1 τυπική απόκλιση')
    ax.axvline(best['clf__C'], linestyle='--', color='gray', label=f"Βέλτιστο C = {best['clf__C']}")
    ax.set_xscale('log')
    ax.set_xticks(C_vals)
    ax.set_xticklabels([str(int(c)) for c in C_vals])
    ax.minorticks_off()
    ax.set_xlabel('C (λογαριθμική κλίμακα)')
    ax.set_ylabel('Macro-F1 (CV)')
    ax.set_title(name)
    ax.grid(alpha=0.3)
    ax.legend(fontsize=8)

fig.tight_layout()
os.makedirs(os.path.join('..', 'figures'), exist_ok=True)
fig.savefig(os.path.join('..', 'figures', 'c_sensitivity.png'), dpi=300, bbox_inches='tight')
plt.show()   # ανοίγει παράθυρο