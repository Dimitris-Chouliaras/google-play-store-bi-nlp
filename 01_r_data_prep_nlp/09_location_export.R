library(dplyr)
library(readr)

# 1. Φόρτωση των δεδομένων που περιέχουν τη γεωγραφία
reviews_data <- read_csv("data_clean/reviews_ready_for_sql.csv")

# 2. Απομόνωση των μοναδικών συνδυασμών Country και Continent
dim_locations_df <- reviews_data %>%
  select(Country, Continent) %>%
  distinct() %>%
  arrange(Continent, Country)

# 3. Έλεγχος ότι έχουμε όντως ακριβώς 24 γραμμές
print(nrow(dim_locations_df))
print(dim_locations_df)

# 4. Εξαγωγή σε καθαρό CSV αρχείο
write_csv(dim_locations_df, "data_clean/locations.csv")