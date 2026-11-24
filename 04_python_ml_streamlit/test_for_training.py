import pandas as pd
import os

# Ορίζουμε τη διαδρομή για να βρούμε το καθαρό αρχείο κριτικών - Ανεβαίνουμε έναν φάκελο πάνω ('..') και μπαίνουμε στο data_clean/reviews_nlp_clean.csv
file_path = os.path.join('..', 'data_clean', 'reviews_nlp_clean.csv')

print("Φόρτωση δεδομένων από:", file_path)
df = pd.read_csv(file_path) # df = DataFrame (πίνακας δεδομένων)

# Εκτύπωση βασικών πληροφοριών
print("\n=== ΕΠΙΤΥΧΗΣ ΦΟΡΤΩΣΗ ===")
print(f"Συνολικό πλήθος γραμμών (κριτικών): {df.shape[0]}") # Η ιδιότητα .shape επιστρέφει τις διαστάσεις του πίνακα.
print(f"Συνολικό πλήθος στηλών: {df.shape[1]}") # Το shape[0] δίνει τις γραμμές και το shape[1] δίνει τις στήλες.

print("\nΔιαθέσιμες στήλες στο αρχείο:")
print(df.columns.tolist())

print("\nΚατανομή των 3 κλάσεων συναισθήματος (my_sentiment_type):")
print(df['my_sentiment_type'].value_counts())