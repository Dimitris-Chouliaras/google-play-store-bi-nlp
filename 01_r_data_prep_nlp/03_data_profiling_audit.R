# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 2.5: Έλεγχοι Ολοκλήρωσης Δεδομένων & Κατανομής (Data Profiling Audit)
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΑΝΑΓΝΩΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr)
library(dplyr)
library(stringr)

cat("=== ΑΝΑΓΝΩΣΗ ΚΑΘΑΡΙΣΜΕΝΩΝ ΣΥΝΟΛΩΝ ΔΕΔΟΜΕΝΩΝ ===\n")
apps    <- read_csv("data_clean/apps_clean.csv")
reviews <- read_csv("data_clean/reviews_clean.csv")

cat("Συνολικές μοναδικές εφαρμογές (apps_clean):", nrow(apps), "\n")
cat("Συνολικές καθαρές κριτικές (reviews_clean):", nrow(reviews), "\n\n")

# 2. ΕΛΕΓΧΟΣ ΚΑΛΥΨΗΣ ΕΦΑΡΜΟΓΩΝ (COVERAGE METRICS) ---
cat("=== 1. ΕΛΕΓΧΟΣ ΚΑΛΥΨΗΣ ΕΦΑΡΜΟΓΩΝ (COVERAGE) ===\n")

apps_with_reviews <- n_distinct(reviews$App)
coverage_pct      <- round((apps_with_reviews / nrow(apps)) * 100, 2)

cat("Εφαρμογές με τουλάχιστον μία κριτική:", apps_with_reviews, "\n")
cat("Εφαρμογές χωρίς καμία καταγεγραμμένη κριτική:", nrow(apps) - apps_with_reviews, "\n")
cat("Ποσοστό κάλυψης εφαρμογών στο reviews dataset:", coverage_pct, "%\n\n")

# 3. ΚΑΤΑΝΟΜΗ ΠΛΗΘΟΥΣ ΚΡΙΤΙΚΩΝ ΑΝΑ ΕΦΑΡΜΟΓΗ ---
cat("=== 2. ΣΤΑΤΙΣΤΙΚΑ ΚΑΤΑΝΟΜΗΣ ΚΡΙΤΙΚΩΝ ΑΝΑ ΕΦΑΡΜΟΓΗ ===\n")

# Υπολογισμός πλήθους κριτικών ανά εφαρμογή
reviews_per_app <- reviews %>%
  group_by(App) %>%
  summarise(
    Review_Count = n(),
    Avg_Polarity = mean(Sentiment_Polarity, na.rm = TRUE),
    Avg_Subjectivity = mean(Sentiment_Subjectivity, na.rm = TRUE)
  ) %>%
  arrange(desc(Review_Count))

# Βασικά στατιστικά μεγέθη (Descriptive Statistics)
summary_stats <- summary(reviews_per_app$Review_Count)
print(summary_stats)
cat("\n")

cat("Τυπική απόκλιση κριτικών ανά app:", round(sd(reviews_per_app$Review_Count), 2), "\n\n")

# 4. TOP 10 ΕΦΑΡΜΟΓΕΣ ΜΕ ΤΙΣ ΠΕΡΙΣΣΟΤΕΡΕΣ ΚΡΙΤΙΚΕΣ ---
cat("=== 3. TOP 10 ΕΦΑΡΜΟΓΕΣ ΜΕ ΤΟΝ ΜΕΓΑΛΥΤΕΡΟ ΟΓΚΟ ΣΧΟΛΙΩΝ ===\n")
print(head(reviews_per_app, 10))
cat("\n")

# 5. ΚΑΤΑΝΟΜΗ ΑΡΧΙΚΟΥ ΣΥΝΑΙΣΘΗΜΑΤΟΣ (BASELINE SENTIMENT BREAKDOWN) ---
cat("=== 4. ΚΑΤΑΝΟΜΗ ΑΡΧΙΚΩΝ ΚΑΤΗΓΟΡΙΩΝ ΣΥΝΑΙΣΘΗΜΑΤΟΣ (BENCHMARK) ===\n")

sentiment_dist <- reviews %>%
  count(Sentiment) %>%
  mutate(Percentage = round((n / sum(n)) * 100, 2))

print(sentiment_dist)

# 6. ΚΑΤΑΝΟΜΗ ΚΡΙΤΙΚΩΝ ΑΝΑ ΚΑΤΗΓΟΡΙΑ ΕΦΑΡΜΟΓΗΣ (CATEGORY AUDIT) ---
cat("=== 5. ΚΑΤΑΝΟΜΗ ΚΡΙΤΙΚΩΝ ΑΝΑ ΚΑΤΗΓΟΡΙΑ (CATEGORY PROFILING) ===\n")

# Σύνδεση των reviews με τα apps για να ανακτήσουμε το Category
reviews_with_category <- reviews %>%
  inner_join(apps %>% select(App, Category), by = "App")

# Συγκεντρωτικός πίνακας ανά Category
category_reviews_summary <- reviews_with_category %>%
  group_by(Category) %>%
  summarise(
    Total_Reviews    = n(),
    Unique_Apps      = n_distinct(App),
    Avg_Reviews_App  = round(n() / n_distinct(App), 1),
    Avg_Polarity     = round(mean(Sentiment_Polarity, na.rm = TRUE), 3),
    Avg_Subjectivity = round(mean(Sentiment_Subjectivity, na.rm = TRUE), 3),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Reviews)) %>%
  mutate(Review_Pct = round((Total_Reviews / sum(Total_Reviews)) * 100, 2))

cat("Συνολικές κατηγορίες με εκπροσώπηση στα reviews:", nrow(category_reviews_summary), "\n\n")

# Εμφάνιση Top 10 Κατηγοριών με τον μεγαλύτερο όγκο σχολίων
cat("--- TOP 10 ΚΑΤΗΓΟΡΙΕΣ ΜΕ ΤΙΣ ΠΕΡΙΣΣΟΤΕΡΕΣ ΚΡΙΤΙΚΕΣ ---\n")
print(head(category_reviews_summary, 10))
cat("\n")

# Εμφάνιση των 5 κατηγοριών με τις λιγότερες κριτικές (Tail categories)
cat("--- 5 ΚΑΤΗΓΟΡΙΕΣ ΜΕ ΤΙΣ ΛΙΓΟΤΕΡΕΣ ΚΡΙΤΙΚΕΣ ---\n")
print(tail(category_reviews_summary, 5))