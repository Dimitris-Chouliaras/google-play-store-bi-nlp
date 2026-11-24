# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 3.9: Προσομοίωση Γεωγραφικών Δεδομένων Χρηστών (Location Simulation)
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΑΝΑΓΝΩΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr)
library(dplyr)
library(tibble)

reviews_nlp <- read_csv("data_clean/reviews_nlp_clean.csv") #  Φόρτωση του NLP αρχείου (28.247 εγγραφές x 20 στήλες)

# 2. Λίστα των 24 χωρών, της ηπείρου τους και του ποσοστού πιθανότητας (Βάρος)
geo_lookup <- tribble(
  ~Country,          ~Continent,       ~Weight,
  "United States",   "North America",  0.190,
  "Canada",          "North America",  0.035,
  "Mexico",          "North America",  0.025,
  "United Kingdom",  "Europe",         0.080,
  "Germany",         "Europe",         0.050,
  "France",          "Europe",         0.040,
  "Spain",           "Europe",         0.030,
  "Italy",           "Europe",         0.030,
  "Russia",          "Europe",         0.030,
  "Greece",          "Europe",         0.025,
  "Netherlands",     "Europe",         0.020,
  "India",           "Asia",           0.150,
  "Indonesia",       "Asia",           0.050,
  "Japan",           "Asia",           0.030,
  "Turkey",          "Asia",           0.025,
  "South Korea",     "Asia",           0.020,
  "Philippines",     "Asia",           0.020,
  "Brazil",          "South America",  0.055,
  "Argentina",       "South America",  0.020,
  "Colombia",        "South America",  0.010,
  "Australia",       "Oceania",        0.030,
  "New Zealand",     "Oceania",        0.005,
  "Nigeria",         "Africa",         0.015,
  "South Africa",    "Africa",         0.015
)

# 3. Τυχαία ανάθεση χώρας σε κάθε κριτική βάσει των πιθανοτήτων
set.seed(42) # Σταθερός σπόρος για να βγάζει πάντα τα ίδια αποτελέσματα

simulated_countries <- sample(
  x       = geo_lookup$Country,
  size    = nrow(reviews_nlp),
  replace = TRUE,
  prob    = geo_lookup$Weight
)

# 4. Προσθήκη Χώρας και αντιστοίχιση της Ηπείρου
reviews_ready_for_sql <- reviews_nlp %>%
  mutate(Country = simulated_countries) %>%
  left_join(geo_lookup %>% select(Country, Continent), by = "Country")

# 5. Έλεγχος κατανομής ανά ήπειρο
cat("=== ΚΑΤΑΝΟΜΗ ΚΡΙΤΙΚΩΝ ΑΝΑ ΗΠΕΙΡΟ ===\n")
print(count(reviews_ready_for_sql, Continent, sort = TRUE))

# 6. Εξαγωγή του τελικού αρχείου (28.247 γραμμές x 22 στήλες)
write_csv(reviews_ready_for_sql, "data_clean/reviews_ready_for_sql.csv")
cat("\nΤο αρχείο data_clean/reviews_ready_for_sql.csv δημιουργήθηκε επιτυχώς!\n")