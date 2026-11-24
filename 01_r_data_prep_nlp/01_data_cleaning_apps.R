# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 1: Exploratory Data Analysis (EDA) & Καθαρισμός Εφαρμογών (Apps Dataset)
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΑΝΑΓΝΩΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr) # Γρήγορο διάβασμα/γράψιμο αρχείων CSV - σωστοί τύπου δεδομένων/κωδικοποίηση UTF-8
library(dplyr) # Παρέχει εντολές επεξεργασίας δεδομένων (filter, mutate, arrange, distinct, group_by) - τελεστή διοχέτευσης %>%
library(stringr) # Επεξεργασία κειμένων/συμβολοσειρών

apps_raw <- read_csv("data_raw/googleplaystore.csv") # Ανάγνωση του αρχικού dataset από τον σχετικό φάκελο data_raw

cat("=== ΑΡΧΙΚΗ ΕΙΚΟΝΑ APPS DATASET ===\n")
cat("Συνολικές αρχικές γραμμές:", nrow(apps_raw), "\n") # Number of rows
cat("Συνολικές στήλες:", ncol(apps_raw), "\n\n") # Number of columns

# 2. ΕΝΤΟΠΙΣΜΟΣ ΑΝΩΜΑΛΙΩΝ (EXPLORATORY DATA ANALYSIS)
# Τρόπος 1: Έλεγχος Ακραίων Τιμών (Sanity Check) στο Rating [1.0 - 5.0]
cat("=== ΤΡΟΠΟΣ 1: ΕΛΕΓΧΟΣ ΟΡΙΩΝ RATING ===\n")
invalid_rating_apps <- apps_raw %>% # invalid_rating_apps: Ο προσωρινός πίνακας που κρατάει το αποτέλεσμα + %>% (Pipe): «Πάρε το apps_raw και μετά...».
  filter(Rating > 5.0 | Rating < 1.0)
print(invalid_rating_apps %>% select(App, Category, Rating, Reviews))
cat("\n")
# Τρόπος 2: Έλεγχος Μοναδικών Τιμών στο Category (Frequency Check)
cat("=== ΤΡΟΠΟΣ 2: ΣΥΧΝΟΤΗΤΑ ΚΑΤΗΓΟΡΙΩΝ ===\n")
category_freq <- table(apps_raw$Category) # Το σύμβολο $ στην R απομονώνει μία μεμονωμένη στήλη από έναν πίνακα ως διάνυσμα
print(category_freq[category_freq == 1]) # Δείξε μου ΜΟΝΟ όσες εμφανίζονται ακριβώς 1 φορά
cat("\n")

# 3. ΔΙΑΣΤΑΥΡΟΥΜΕΝΟΣ ΕΛΕΓΧΟΣ ΜΕ ΤΑ REVIEWS
cat("=== ΔΙΑΣΤΑΥΡΟΥΜΕΝΟΣ ΕΛΕΓΧΟΣ ΜΕ ΤΑ REVIEWS ===\n")
reviews_temp <- read_csv("data_raw/googleplaystore_user_reviews.csv", col_types = cols_only(App = col_character()))
has_reviews <- "Life Made WI-Fi Touchscreen Photo Frame" %in% reviews_temp$App
cat("Έχει κριτικές η προβληματική εφαρμογή στο reviews dataset;", has_reviews, "\n\n")

# 4. ΑΦΑΙΡΕΣΗ ΕΛΑΤΤΩΜΑΤΙΚΗΣ ΕΓΓΡΑΦΗΣ
apps_clean <- apps_raw %>% # Δημιουργούμε νέο πίνακα (apps_clean) για να μην πειράξουμε τον αρχικό (apps_raw)
  filter(Category != "1.9")

cat("Γραμμές μετά την αφαίρεση της προβληματικής εγγραφής:", nrow(apps_clean), "\n")


# 5. ΚΑΘΑΡΙΣΜΟΣ ΣΥΜΒΟΛΩΝ & ΜΕΤΑΤΡΟΠΕΣ ΤΥΠΩΝ (DATA TYPE CONVERSION) ---
cat("=== ΜΕΤΑΤΡΟΠΗ ΣΤΗΛΩΝ ΣΕ ΑΡΙΘΜΗΤΙΚΟΥΣ ΤΥΠΟΥΣ ===\n")

apps_clean <- apps_clean %>%
  # 1. Μετατροπή των Reviews σε ακέραιο αριθμό
  mutate(Reviews = as.numeric(Reviews)) %>% # Η συνάρτηση του dplyr που τροποποιεί υπάρχουσες στήλες ή φτιάχνει καινούργιες - Μετατρέπει μια τιμή σε πραγματικό αριθμό
  
  # 2. Καθαρισμός Installs: αφαιρούμε το '+' και το ',' και μετατρέπουμε σε numeric
  # Το '[+,]' σημαίνει: βρες είτε το '+' είτε το ',' και αντικατάστησέ το με τίποτα ("")
  mutate(Installs = str_replace_all(Installs, "[+,]", ""),
         Installs = as.numeric(Installs)) %>%
  
  # 3. Καθαρισμός Price: αφαιρούμε το '$' και μετατρέπουμε σε numeric
  # Βάζουμε '\\$' επειδή το σκέτο '$' στη γλώσσα των regex σημαίνει 'τέλος γραμμής' - χρειάζεται διπλό backslash για να διαβαστεί ως κανονικό δολάριο και όχι ως σύμβολο τέλους γραμμής
  mutate(Price = str_replace_all(Price, "\\$", ""),
         Price = as.numeric(Price))

# Επαλήθευση: Εμφάνιση των πρώτων τιμών μετά τον καθαρισμό
cat("Δείγμα καθαρών τιμών:\n")
apps_clean %>% 
  select(App, Reviews, Installs, Price) %>% 
  head(5) %>% # Επιστρέφει μόνο τις πρώτες 5 γραμμές του πίνακα για οπτικό έλεγχο.
  print()

# 6. ΚΑΘΑΡΙΣΜΟΣ & ΣΤΑΤΙΣΤΙΚΟΣ ΚΑΤΑΛΟΓΙΣΜΟΣ ΜΕΓΕΘΟΥΣ (SIZE IMPUTATION) ---
cat("=== ΜΕΤΑΤΡΟΠΗ ΜΕΓΕΘΟΥΣ ΚΑΙ IMPUTATION ΔΙΑΜΕΣΟΥ ===\n")
# Σημείωση: Το Warning "NAs introduced by coercion" κατά την εκτέλεση είναι απολύτως φυσιολογικό, καθώς το κείμενο 'Varies with device' μετατρέπεται σκόπιμα σε NA
apps_clean <- apps_clean %>%
  # i. Αρχική μετατροπή σε MB και ορισμός NA για το 'Varies with device'
  mutate(
    Size_MB = case_when(
      str_detect(Size, "M$") ~ as.numeric(str_replace(Size, "M", "")),
      str_detect(Size, "k$") ~ as.numeric(str_replace(Size, "k", "")) / 1024,
      TRUE ~ NA_real_
    ),
    # Κρατάμε ένδειξη (flag) για το αν η τιμή έλειπε αρχικά
    Size_Imputed = is.na(Size_MB)
  ) %>%
  # ii. Ομαδοποίηση ανά κατηγορία
  group_by(Category) %>%
  #iii. Αντικατάσταση των NA με τη διάμεσο της συγκεκριμένης κατηγορίας
  mutate(
    Size_MB = ifelse(is.na(Size_MB), round(median(Size_MB, na.rm = TRUE), 2), round(Size_MB, 2))
  ) %>%
  # iv. Αποδέσμευση της ομαδοποίησης
  ungroup()

# Επαλήθευση: Έλεγχος ότι δεν υπάρχουν πλέον NA στη στήλη Size_MB
cat("Πλήθος κενών τιμών (NA) στο Size_MB μετά τον καταλογισμό:", sum(is.na(apps_clean$Size_MB)), "\n")
cat("Πλήθος εφαρμογών με καταλογισμένο μέγεθος (Imputed):", sum(apps_clean$Size_Imputed), "\n\n") # Μετράει πόσα TRUE υπάρχουν, δηλαδή σε πόσες γραμμές μπήκε η διάμεσος

# Εμφάνιση δείγματος
apps_clean %>%
  select(App, Category, Size, Size_MB, Size_Imputed) %>%
  head(6) %>%
  print()

# 7. ΕΝΤΟΠΙΣΜΟΣ & ΔΙΑΧΕΙΡΙΣΗ ΔΙΠΛΟΤΥΠΩΝ (DUPLICATES HANDLING) ---
cat("=== ΕΛΕΓΧΟΣ ΔΙΠΛΟΤΥΠΩΝ ΕΦΑΡΜΟΓΩΝ ===\n")

# i. Υπολογισμός και εκτύπωση των μετρικών
total_rows_before <- nrow(apps_clean)
unique_apps_count <- n_distinct(apps_clean$App) # Επιστρέφει το πλήθος των διαφορετικών (distinct) ονομάτων
duplicate_count   <- sum(duplicated(apps_clean$App)) # Επιστρέφει TRUE για κάθε γραμμή της οποίας το όνομα έχει ήδη εμφανιστεί προηγουμένως στον πίνακα, και FALSE για την πρώτη εμφάνιση. Το sum(...) προσθέτει όλα τα TRUE

cat("Συνολικές εγγραφές πριν την εκκαθάριση:", total_rows_before, "\n")
cat("Μοναδικά ονόματα εφαρμογών:", unique_apps_count, "\n")
cat("Πλήθος διπλότυπων εγγραφών προς αφαίρεση:", duplicate_count, "\n\n")

# ii. Αφαίρεση διπλοτύπων:
# Πρώτα ταξινομούμε με φθίνουσα σειρά reviews (ώστε η πιο ενημερωμένη να είναι πρώτη) και μετά με τη distinct() κρατάμε μόνο την πρώτη εμφάνιση κάθε εφαρμογής
apps_clean <- apps_clean %>%
  arrange(App, desc(Reviews)) %>% # Ταξινομεί αλφαβητικά ανά εφαρμογή και, για την ίδια εφαρμογή, βάζει πρώτη τη γραμμή με τα περισσότερα reviews
  distinct(App, .keep_all = TRUE)

# iii. Επαλήθευση
cat("Συνολικές γραμμές μετά την αφαίρεση των διπλοτύπων:", nrow(apps_clean), "\n")
cat("Απομένουν διπλότυπα;", any(duplicated(apps_clean$App)), "\n") # Ελέγχει αν υπάρχει έστω και ένα διπλότυπο ακόμα

# 8. ΕΞΑΓΩΓΗ ΚΑΘΑΡΙΣΜΕΝΩΝ ΔΕΔΟΜΕΝΩΝ (DATA EXPORT) ---
cat("=== ΑΠΟΘΗΚΕΥΣΗ ΚΑΘΑΡΟΥ DATASET ΕΦΑΡΜΟΓΩΝ ===\n")

output_path <- "data_clean/apps_clean.csv" # 1. Ορισμός διαδρομής εξαγωγής

write_csv(apps_clean, output_path) # 2. Εξαγωγή του πίνακα apps_clean σε CSV - Χρησιμοποιούμε τη write_csv() η οποία αποθηκεύει τα δεδομένα με κωδικοποίηση UTF-8

if (file.exists(output_path)) { # 3. Έλεγχος επαλήθευσης ύπαρξης αρχείου στον δίσκο
  cat("Το αρχείο αποθηκεύτηκε επιτυχώς στο:", output_path, "\n")
  cat("Συνολικές αποθηκευμένες γραμμές:", nrow(apps_clean), "\n")
  cat("Συνολικές στήλες:", ncol(apps_clean), "\n")
} else {
  cat("Προσοχή: Η αποθήκευση του αρχείου απέτυχε!\n")
}