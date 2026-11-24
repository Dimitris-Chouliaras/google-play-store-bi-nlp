# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 3: Ανάλυση συναισθήματος
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΦΟΡΤΩΣΗ/ΑΝΑΓΝΩΣΗ/ΠΡΟΕΠΙΣΚΟΠΗΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr) # Γρήγορο διάβασμα/γράψιμο αρχείων CSV - σωστοί τύποι δεδομένων/UTF-8
library(dplyr) # Παρέχει εντολές επεξεργασίας δεδομένων (filter, mutate, arrange, distinct, group_by) - τελεστή διοχέτευσης %>%
library(stringr) # Επεξεργασία κειμένων/συμβολοσειρών
library(syuzhet) # H μηχανή του Sentiment Analysis
library(ggplot2) #Οπτικό έλεγχο των συναισθημάτων στο τέλος 

# 1. ΦΟΡΤΩΣΗ ΚΑΘΑΡΙΣΜΕΝΩΝ ΔΕΔΟΜΕΝΩΝ ΚΡΙΤΙΚΩΝ ΚΑΙ ΜΕΡΙΚΗ ΠΡΟΕΠΙΣΚΟΠΗΣΗ
reviews_sentiment <- read_csv("data_clean/reviews_clean.csv")

# Έλεγχος διαστάσεων
cat("Συνολικές κριτικές:", nrow(reviews_sentiment), "\n")
cat("Συνολικές στήλες:", ncol(reviews_sentiment), "\n")

# Προεπισκόπηση πρώτων εγγραφών
head(reviews_sentiment, 3)

# 2. Δημιουργία νέας στήλης στο υπάρχων αρχείο
reviews_sentiment <- reviews_sentiment %>% mutate(Clean_Text = Translated_Review)

# 3. Προεπεξεργασία κειμένου
# i Μετατροπή σε πεζά
reviews_sentiment <- reviews_sentiment %>% mutate(Clean_Text = str_to_lower(Clean_Text))
head(reviews_sentiment$Clean_Text, 3)

# ii Αφαίρεση Url
reviews_sentiment <- reviews_sentiment %>% mutate(Clean_Text = str_replace_all(Clean_Text, "https?://\\S+|www\\.\\S+", " ")) # str_replace_all(string, pattern, replacement)
head(reviews_sentiment$Clean_Text, 3)

# iii Αφαίρεση αριθμών, σημείων στίξης και ειδικών συμβόλων
reviews_sentiment <- reviews_sentiment %>% mutate(Clean_Text = str_replace_all(Clean_Text, "[^a-z\\s]", " "))
head(reviews_sentiment$Clean_Text, 3)

# iv Κανονικοποίηση κενών διαστημάτων
reviews_sentiment <- reviews_sentiment %>% mutate(Clean_Text = str_squish(Clean_Text))
head(reviews_sentiment$Clean_Text, 3)

# Εμφάνιση γραμμών όπου το Clean_Text είναι κενό ("") ή NA
reviews_sentiment %>% filter(Clean_Text == "" | is.na(Clean_Text))

# 4. Αφαίρεση κενών κριτικών μετά την προεπεξεργασία (NLP Pruning)
reviews_sentiment <- reviews_sentiment %>% filter(Clean_Text != "" & !is.na(Clean_Text))

# Επιβεβαίωση νέων διαστάσεων (αναμένουμε 28.247 γραμμές)
cat("Ενεργές κριτικές για NLP:", nrow(reviews_sentiment), "\n")

# 5. Υπολογισμός των 8 συναισθημάτων και των 2 πολικοτήτων του NRC
nrc_scores <- get_nrc_sentiment(reviews_sentiment$Clean_Text) # Έτρεξε περίπου 3 με 4 λεπτά
head(nrc_scores, 5) # Εμφανίζει τις μετρήσεις των πρώτων 5 κριτικών.
nrow(nrc_scores) # Επιβεβαιώνει ότι ο πίνακας έχει ακριβώς 28.247 γραμμές (συμβαδίζει απόλυτα με το reviews_sentiment).
reviews_sentiment$Clean_Text[1:5] # Τυπώνει το πλήρες κείμενο των πρώτων 5 κριτικών για να συγκρίνουμε λέξη-λέξη γιατί μπήκαν τα συγκεκριμένα σκορ.
colSums(nrc_scores) # Αθροίζει κάθε στήλη σε ολόκληρο το dataset, αποκαλύπτοντας τη γενική τάση.

# 6 Υπολογισμός του συνεχούς σκορ πολικότητας με τη μέθοδο Syuzhet
syuzhet_vector <- get_sentiment(reviews_sentiment$Clean_Text, method = "syuzhet")
length(syuzhet_vector) # Επιβεβαιώνει μέγεθος ακριβώς 28.247 τιμών.
syuzhet_vector[1:5] # Δείχνει τα πρώτα 5 σκορ.
summary(syuzhet_vector) # Δίνει τα όρια της κατανομής.
my_polarity_scaled <- tanh(syuzhet_vector) # το σκορ συμπιεσμένο αυστηρά στο διάστημα [-1.0, +1.0], με κέντρο το 0.

# 7. Κατηγοριοποίηση πολικότητας με ζώνη ουδετερότητας [-0.14, +0.14]
my_sentiment_type <- case_when(
  my_polarity_scaled > 0.14  ~ "Positive",
  my_polarity_scaled < -0.14 ~ "Negative",
  TRUE                       ~ "Neutral"
)

my_sentiment_type <- factor(my_sentiment_type, levels = c("Negative", "Neutral", "Positive")) # Μετατροπή σε factor με καθορισμένη σειρά επιπέδων

table(my_sentiment_type) # Έλεγχος κατανομής των νέων κατηγοριών

# 8. Υπολογισμός Υποκειμενικότητας (Lexicon-based Subjectivity)
word_count <- str_count(reviews_sentiment$Clean_Text, "\\w+") # i. Συνολικός αριθμός λέξεων ανά κριτική

emotional_words <- nrc_scores$positive + nrc_scores$negative # ii. Άθροισμα συναισθηματικά φορτισμένων λέξεων από το NRC

my_subjectivity <- ifelse(word_count > 0, emotional_words / word_count, 0) # iii. Υπολογισμός δείκτη υποκειμενικότητας στο διάστημα [0.0, 1.0]
my_subjectivity <- pmin(my_subjectivity, 1.0) # εξασφαλίζει ότι το μέγιστο είναι αυστηρά 1.0

summary(my_subjectivity) # iv. Έλεγχος στατιστικής κατανομής

# ==============================================================================
# Βήμα 8 (Εναλλακτική Προσέγγιση): Υπολογισμός Υποκειμενικότητας μέσω POS Tagging (udpipe)
# ==============================================================================

# i. Εγκατάσταση και φόρτωση του πακέτου udpipe
if (!require(udpipe)) install.packages("udpipe")
library(udpipe)
library(dplyr)

# ii. Λήψη και φόρτωση του προ-εκπαιδευμένου αγγλικού μοντέλου (αν δεν υπάρχει τοπικά) - (Η λήψη γίνεται μία φορά στον τρέχοντα φάκελο εργασίας)
model_file <- list.files(pattern = "^english-ewt-ud-.*\\.udpipe$")
if (length(model_file) == 0) {
  model_info <- udpipe_download_model(language = "english")
  ud_model <- udpipe_load_model(model_info$file_model)
} else {
  ud_model <- udpipe_load_model(model_file[1])
}

# iii. Εκτέλεση συντακτικού/γραμματικού σχολιασμού (POS Annotation) - 5 έως 10 λεπτά
message("Έναρξη POS Tagging για 28.247 κριτικές. Παρακαλώ περιμένετε...")
start_time <- Sys.time()

annotated_all <- udpipe_annotate( # Διαβάζει και τις 28.247 κριτικές μία προς μία και αναλύει γραμματικά κάθε λέξη.
  ud_model, 
  x = reviews_sentiment$Clean_Text, 
  doc_id = 1:nrow(reviews_sentiment)
)

end_time <- Sys.time()
print(end_time - start_time) # Χρειάστηκε 5,88 λεπτά

# iv. Μετατροπή των αποτελεσμάτων σε Data Frame για να μπορούμε να το επεξεργαστούμε με την dplyr
annotated_df <- as.data.frame(annotated_all)

# v. Υπολογισμός δείκτη υποκειμενικότητας: Subjectivity = (Επίθετα + Επιρρήματα) / Συνολικές Λέξεις
pos_subjectivity_df <- annotated_df %>%
  group_by(doc_id = as.integer(doc_id)) %>% # Μαζεύει τις λέξεις ανά κριτική
  summarise(
    total_tokens = n(), # Μετράει πόσες λέξεις έχει η κριτική
    opinion_tokens = sum(upos %in% c("ADJ", "ADV")), # Μετράει πόσα επίθετα (ADJ) και επιρρήματα (ADV) υπάρχουν.
    pos_subjectivity = opinion_tokens / total_tokens,
    .groups = "drop"
  )

# vi. Διασφάλιση αντιστοίχισης με όλες τις γραμμές (πλήρης ευθυγράμμιση 28.247 εγγραφών)
pos_summary_table <- tibble(doc_id = 1:nrow(reviews_sentiment)) %>%
  left_join(pos_subjectivity_df, by = "doc_id") %>%
  mutate(pos_subjectivity = coalesce(pos_subjectivity, 0))

my_pos_subjectivity <- pos_summary_table$pos_subjectivity # Εξαγωγή του καθαρού διανύσματος 28.247 τιμών

# vii. Στατιστική επισκόπηση και σύγκριση
summary(my_pos_subjectivity) # Έλεγχος στατιστικής κατανομής
summary(my_subjectivity) # Έλεγχος στατιστικής κατανομής

cor(my_pos_subjectivity, my_subjectivity, use = "complete.obs") # Συντελεστής γραμμικής συσχέτισης μεταξύ POS-based (udpipe) και Lexicon-based (NRC).

cor(my_pos_subjectivity, reviews_sentiment$Sentiment_Subjectivity, use = "complete.obs") # Συντελεστής γραμμικής συσχέτισης μεταξύ POS-based (udpipe) και με τον αρχικό δείκτη TextBlob (Sentiment_Subjectivity).

# 9. Ενοποίηση Πινάκων & Διανυσμάτων (bind_cols)
# Δημιουργία του τελικού ενιαίου dataframe με συγκεκριμένη διάταξη στηλών
reviews_clean_final <- bind_cols(
  reviews_sentiment, # Περιλαμβάνει: App, Translated_Review, Clean_Text, Sentiment, Sentiment_Polarity, Sentiment_Subjectivity
  my_polarity_scaled = my_polarity_scaled,
  my_sentiment_type   = my_sentiment_type,
  my_subjectivity     = my_subjectivity,
  my_pos_subjectivity = my_pos_subjectivity,
  nrc_scores          # Προσθέτει τις 10 στήλες: anger, anticipation, disgust, fear, joy, sadness, surprise, trust, negative, positive
)

# Προαιρετικός έλεγχος διαστάσεων και ονομάτων στηλών
dim(reviews_clean_final) # Πρέπει να εμφανίσει: 28247 20
colnames(reviews_clean_final)

# Εξαγωγή του τελικού αρχείου
write_csv(reviews_clean_final, "data_clean/reviews_nlp_clean.csv")