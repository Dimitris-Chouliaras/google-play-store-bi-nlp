# ==============================================================================
# Μεταπτυχιακή Διπλωματική Εργασία: Google Play Store Analytics
# Στάδιο 3.1: Διαγνωστική Οπτικοποίηση Συναισθημάτων (ggplot2)
# Συγγραφέας: Δημήτριος Χουλιάρας
# ==============================================================================
# 1. ΒΙΒΛΙΟΘΗΚΕΣ & ΑΝΑΓΝΩΣΗ ΔΕΔΟΜΕΝΩΝ
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)

# 1. Φόρτωση του τελικού επεξεργασμένου συνόλου NLP
reviews_clean_final <- read_csv("data_clean/reviews_nlp_clean.csv")

# ------------------------------------------------------------------------------
# Γράφημα 1: Κατανομή της Συνεχούς Πολικότητας (Syuzhet tanh) ανά Κατηγορία
# ------------------------------------------------------------------------------
# Σκοπός: Οπτικός έλεγχος του τρόπου με τον οποίο κατανέμεται το συνεχές σκορ 
# και πώς λειτούργησε η ζώνη ουδετερότητας [-0.14, +0.14].

ggplot(reviews_clean_final, aes(x = my_polarity_scaled, fill = my_sentiment_type)) +
  geom_histogram(binwidth = 0.05, color = "white", alpha = 0.85) +
  geom_vline(xintercept = c(-0.14, 0.14), linetype = "dashed", color = "black", linewidth = 0.8) +
  scale_fill_manual(values = c("Negative" = "#d9534f", "Neutral" = "#f0ad4e", "Positive" = "#5cb85c")) +
  scale_x_continuous(breaks = seq(-1, 1, 0.2)) +
  labs(
    title = "Διαγνωστική Κατανομή Πολικότητας (Syuzhet tanh)",
    subtitle = "Διακεκομμένες γραμμές: Όρια Ζώνης Ουδετερότητας [-0.14, +0.14]",
    x = "Κανονικοποιημένη Πολικότητα (my_polarity_scaled)",
    y = "Πλήθος Κριτικών",
    fill = "Κατηγορία"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  )

# ------------------------------------------------------------------------------
# Γράφημα 2: Προφίλ των 8 Βασικών Συναισθημάτων Plutchik (NRC Emotion Profile)
# ------------------------------------------------------------------------------
# Σκοπός: Συγκεντρωτική καταμέτρηση των λέξεων ανά συναίσθημα για να φανεί 
# ποια συναισθηματικά μοτίβα κυριαρχούν στις 28.247 κριτικές.

# Προετοιμασία αθροισμάτων για τα 8 συναισθήματα
emotion_summary <- reviews_clean_final %>%
  select(anger, anticipation, disgust, fear, joy, sadness, surprise, trust) %>%
  summarise(across(everything(), sum)) %>%
  pivot_longer(cols = everything(), names_to = "Emotion", values_to = "Word_Count") %>%
  arrange(desc(Word_Count))

ggplot(emotion_summary, aes(x = reorder(Emotion, Word_Count), y = Word_Count, fill = Word_Count)) +
  geom_col(show.legend = FALSE, width = 0.7) +
  coord_flip() + # Οριζόντιες μπάρες για ευκολότερη ανάγνωση
  scale_fill_gradient(low = "#9ecae1", high = "#08519c") +
  labs(
    title = "Συνολική Ένταση των 8 Συναισθημάτων NRC (Plutchik)",
    subtitle = "Άθροισμα λέξεων ανά συναίσθημα στο σύνολο των 28.247 κριτικών",
    x = "Συναίσθημα",
    y = "Συνολικό Πλήθος Λέξεων"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text = element_text(size = 11)
  )