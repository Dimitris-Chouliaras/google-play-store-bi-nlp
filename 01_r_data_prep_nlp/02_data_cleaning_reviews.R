# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 2: EDA & Καθαρισμός Κριτικών Χρηστών (User Reviews Dataset)
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΑΝΑΓΝΩΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr)   # Γρήγορο διάβασμα/γράψιμο αρχείων CSV - σωστοί τύποι δεδομένων/UTF-8
library(dplyr)   # Επεξεργασία δεδομένων (filter, mutate, arrange, distinct) - pipe %>%
library(stringr) # Επεξεργασία κειμένων/συμβολοσειρών

# Ανάγνωση του raw αρχείου, ορίζοντας ρητά ότι και το "nan" είναι κενή τιμή (NA)
reviews_raw <- read_csv("data_raw/googleplaystore_user_reviews.csv", 
                        na = c("", "NA", "nan"))

cat("=== ΑΡΧΙΚΗ ΕΙΚΟΝΑ REVIEWS DATASET ===\n")
cat("Συνολικές αρχικές κριτικές:", nrow(reviews_raw), "\n")
cat("Συνολικές στήλες:", ncol(reviews_raw), "\n\n")

# 2. ΕΝΤΟΠΙΣΜΟΣ ΕΛΛΙΠΩΝ ΤΙΜΩΝ (MISSING VALUES AUDIT)
cat("=== ΕΛΕΓΧΟΣ ΚΕΝΩΝ ΤΙΜΩΝ (NAs) ΑΝΑ ΣΤΗΛΗ ===\n")
col_na_counts <- colSums(is.na(reviews_raw)) # Μετράει τα κενά (NA) ανά στήλη
print(col_na_counts)
cat("\n")

# Ποσοστό και πλήθος κενών κριτικών
missing_reviews_count <- sum(is.na(reviews_raw$Translated_Review))
missing_reviews_pct   <- round((missing_reviews_count / nrow(reviews_raw)) * 100, 2)

cat("Πλήθος κενών κριτικών:", missing_reviews_count, "\n")
cat("Ποσοστό κριτικών χωρίς κείμενο:", missing_reviews_pct, "%\n")

# 3. ΑΦΑΙΡΕΣΗ ΚΕΝΩΝ ΚΡΙΤΙΚΩΝ (MISSING VALUES REMOVAL) ---
cat("=== ΑΦΑΙΡΕΣΗ ΚΕΝΩΝ ΕΓΓΡΑΦΩΝ ===\n")

# Φιλτράρισμα: κρατάμε μόνο όσες γραμμές έχουν μη κενό κείμενο κριτικής
reviews_clean <- reviews_raw %>%
  filter(!is.na(Translated_Review))

# Επαλήθευση αποτελεσμάτων
cat("Αρχικές εγγραφές:", nrow(reviews_raw), "\n")
cat("Εγγραφές μετά τον καθαρισμό:", nrow(reviews_clean), "\n")
cat("Γραμμές που αφαιρέθηκαν:", nrow(reviews_raw) - nrow(reviews_clean), "\n\n")

# Έλεγχος ότι δεν απέμεινε κανένα NA στη στήλη κειμένου
cat("Υπολειπόμενα κενά στο Translated_Review:", sum(is.na(reviews_clean$Translated_Review)), "\n")

# 4. ΕΝΤΟΠΙΣΜΟΣ & ΔΙΑΧΕΙΡΙΣΗ ΔΙΠΛΟΤΥΠΩΝ ΚΡΙΤΙΚΩΝ ---
cat("=== ΕΛΕΓΧΟΣ ΔΙΠΛΟΤΥΠΩΝ ΚΡΙΤΙΚΩΝ ===\n")

# i. Υπολογισμός διπλοτύπων με βάση την εφαρμογή και το κείμενο της κριτικής
total_reviews_before <- nrow(reviews_clean)
duplicate_reviews_count <- sum(duplicated(reviews_clean %>% select(App, Translated_Review))) # Απομονώνει προσωρινά μόνο τα δύο πεδία-κλειδιά για τον έλεγχο, ώστε ακόμα κι αν υπάρχει ανεπαίσθητη διαφορά δεκαδικών σε κάποια στήλη, να εντοπιστεί ότι πρόκειται για την ίδια κριτική - Επιστρέφει TRUE για κάθε γραμμή της οποίας το ζεύγος (App, Translated_Review) έχει ξαναεμφανιστεί νωρίτερα.

cat("Συνολικές κριτικές με κείμενο:", total_reviews_before, "\n")
cat("Πλήθος διπλότυπων κριτικών (ίδιο App & Review):", duplicate_reviews_count, "\n")
cat("Ποσοστό διπλότυπων:", round((duplicate_reviews_count / total_reviews_before) * 100, 2), "%\n\n")

# ii. Αφαίρεση διπλοτύπων: κρατάμε την πρώτη εμφάνιση κάθε διακριτού ζεύγους (App, Translated_Review)
reviews_clean <- reviews_clean %>%
  distinct(App, Translated_Review, .keep_all = TRUE) # Κρατάει μόνο τη μία διακριτή εκδοχή της κριτικής και διατηρεί όλες τις υπόλοιπες στήλες

# iii. Επαλήθευση
cat("Κριτικές μετά την αφαίρεση των διπλοτύπων:", nrow(reviews_clean), "\n")
cat("Απομένουν διπλότυπα;", any(duplicated(reviews_clean %>% select(App, Translated_Review))), "\n")

# 5. ΕΛΕΓΧΟΣ ΑΝΑΦΟΡΙΚΗΣ ΑΚΕΡΑΙΟΤΗΤΑΣ (REFERENTIAL INTEGRITY AUDIT) ---
cat("=== ΕΛΕΓΧΟΣ ΑΝΑΦΟΡΙΚΗΣ ΑΚΕΡΑΙΟΤΗΤΑΣ ΜΕ ΤΟ APPS_CLEAN ===\n")

# i. Φόρτωση των μοναδικών ονομάτων εφαρμογών από το καθαρισμένο dataset
apps_clean_names <- read_csv("data_clean/apps_clean.csv", col_types = cols_only(App = col_character()))$App

# ii. Εντοπισμός κριτικών που αναφέρονται σε ανύπαρκτες εφαρμογές (ορφανές εγγραφές)
orphan_reviews_mask <- !reviews_clean$App %in% apps_clean_names
orphan_count <- sum(orphan_reviews_mask)

cat("Συνολικές διακριτές εφαρμογές στο apps_clean.csv:", length(apps_clean_names), "\n")
cat("Πλήθος μοναδικών εφαρμογών στα reviews:", n_distinct(reviews_clean$App), "\n")
cat("Πλήθος ορφανών κριτικών προς αφαίρεση:", orphan_count, "\n\n")

# iii. Αν υπάρχουν ορφανές κριτικές, προβολή δείγματος και φιλτράρισμα
if (orphan_count > 0) {
  orphan_apps_sample <- unique(reviews_clean$App[orphan_reviews_mask])
  cat("Δείγμα εφαρμογών στα reviews που λείπουν από το apps_clean:\n")
  print(head(orphan_apps_sample, 5))
  cat("\n")
  
  # Αφαίρεση ορφανών κριτικών
  reviews_clean <- reviews_clean %>%
    filter(App %in% apps_clean_names)
  
  cat("Κριτικές μετά την επιβολή αναφορικής ακεραιότητας:", nrow(reviews_clean), "\n")
} else {
  cat("Όλες οι κριτικές συνδέονται απόλυτα με το apps_clean.csv (0 ορφανές εγγραφές)!\n")
}

# iv. Τελική επαλήθευση
cat("Υπάρχουν πλέον ορφανές κριτικές;", any(!reviews_clean$App %in% apps_clean_names), "\n")