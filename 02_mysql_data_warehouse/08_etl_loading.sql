-- =============================================================================
-- ΚΕΦΑΛΑΙΟ 4.4: ΔΙΑΔΙΚΑΣΙΑ ETL ΚΑΙ ΜΑΖΙΚΗ ΦΟΡΤΩΣΗ
-- Database: playstore_dw
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- =============================================================================
USE playstore_dw;

-- Γέμισμα Πίνακα Διάστασης Συναισθήματος χειροκίνητα
INSERT INTO dim_sentiment_types (sentiment_name, polarity_range, sentiment_description)
VALUES
('Positive', '> +0.14', 'Θετική αξιολόγηση χρήστη'),
('Negative', '< -0.14', 'Αρνητική αξιολόγηση χρήστη'),
('Neutral', '[-0.14, +0.14]', 'Ουδέτερη ζώνη ανοχής / λειτουργικά σχόλια');

UPDATE dim_sentiment_types -- Μικρές διορθώσεις
SET polarity_range = CASE sentiment_type_key
    WHEN 1 THEN '> +0.14 to +1.00'
    WHEN 2 THEN '< -0.14 to -1.00'
    WHEN 3 THEN '[-0.14, +0.14]'
END
WHERE sentiment_type_key IN (1, 2, 3);

SELECT * FROM dim_sentiment_types; -- !!! Εκτύπωση τεστ για τον πίνακα dim_sentiment_types !!!

-- Φόρτωση Πίνακα Διάστασης Τοποθεσιών από δικό μας παραγώμενο CSV αρχείο μέσω R
LOAD DATA INFILE 'C:/Users/mitso/Desktop/Master_Thesis_BI_NLP/data_clean/locations.csv'
INTO TABLE dim_locations
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(country, continent);

SELECT * FROM dim_locations; -- !!! Εκτύπωση τεστ για τον πίνακα dim_locations !!!

-- Φόρτωση Πίνακα Διάστασης Εφαρμογών από πηγαίο (καθαρισμένο) CSV αρχείο
LOAD DATA INFILE 'C:/Users/mitso/Desktop/Master_Thesis_BI_NLP/data_clean/apps_clean.csv'
INTO TABLE dim_apps
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    app_name, 
    category, 
    @v_rating, 
    reviews_count, 
    @dummy_size, 
    installs, 
    type, 
    price, 
    content_rating, 
    genres, 
    @dummy_updated, 
    @dummy_cver, 
    @dummy_aver, 
    size_mb, 
    @v_size_imputed
)
SET 
    rating = CASE 
        WHEN @v_rating IN ('', 'NA', 'NaN') THEN NULL 
        ELSE CAST(@v_rating AS DECIMAL(2, 1)) 
    END,
    size_imputed = CASE 
        WHEN UPPER(@v_size_imputed) IN ('TRUE', '1') THEN 1 
        ELSE 0 
    END;

SELECT COUNT(*) AS total_apps FROM dim_apps; -- Έλεγχος πλήθους (πρέπει να επιστρέψει 9659)
SELECT * FROM dim_apps LIMIT 10;            -- Δειγματοληπτικός έλεγχος

-- ========================ΘΑ ΜΠΟΡΟΥΣΕ ΝΑ ΓΙΝΕΙ ΚΑΙ ΞΕΧΩΡΙΣΤΟ ΑΡΧΕΊΟ.sql========================
-- 4. ΔΙΑΔΙΚΑΣΙΑ STAGING & ΦΟΡΤΩΣΗ ΠΙΝΑΚΑ ΓΕΓΟΝΟΤΩΝ (fact_reviews)
-- =============================================================================================
USE playstore_dw;
-- 4.1 Δημιουργία προσωρινού staging πίνακα
DROP TABLE IF EXISTS staging_reviews;

CREATE TABLE staging_reviews (
    App VARCHAR(255),
    Translated_Review TEXT,
    Sentiment VARCHAR(15),
    Sentiment_Polarity DOUBLE,
    Sentiment_Subjectivity DOUBLE,
    Clean_Text TEXT,
    my_polarity_scaled DOUBLE,
    my_sentiment_type VARCHAR(15),
    my_subjectivity DOUBLE,
    my_pos_subjectivity DOUBLE,
    anger TINYINT,
    anticipation TINYINT,
    disgust TINYINT,
    fear TINYINT,
    joy TINYINT,
    sadness TINYINT,
    surprise TINYINT,
    trust TINYINT,
    negative TINYINT,
    positive TINYINT,
    Country VARCHAR(50),
    Continent VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4.2 Μαζική φόρτωση από το CSV (με απενεργοποίηση του backslash escape)
LOAD DATA INFILE 'C:/Users/mitso/Desktop/Master_Thesis_BI_NLP/data_clean/reviews_ready_for_sql.csv'
INTO TABLE staging_reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Έλεγχος πλήθους
SELECT COUNT(*) AS total_staging_reviews FROM staging_reviews;
SELECT * FROM staging_reviews LIMIT 5;

SET SQL_SAFE_UPDATES = 0; -- Απενεργοποιεί προσωρινά τη δικλείδα ασφαλείας («Safe Update Mode») της MySQL
DELETE FROM fact_reviews; -- Διαγράφει όλες τις γραμμές (τις 28.318 προηγούμενες εγγραφές) από τον πίνακα γεγονότων.
ALTER TABLE fact_reviews AUTO_INCREMENT = 1; -- Μηδενίζει τον εσωτερικό μετρητή του πρωτεύοντος κλειδιού (review_key). 
SET SQL_SAFE_UPDATES = 1; -- Επαναφέρει αμέσως τη δικλείδα ασφαλείας σε λειτουργία (ON), ώστε να είσαι απόλυτα προστατευμένος για τις επόμενες εργασίες.

-- 4.3 Αφαίρεση των διπλότυπων εφαρμογών από τον dim_apps που βρέθηκαν έπειτα
SET SQL_SAFE_UPDATES = 0;

DELETE FROM dim_apps -- πρέπει να επιστρέψει 22
WHERE app_key NOT IN (
    SELECT min_key FROM (
        SELECT MIN(app_key) AS min_key
        FROM dim_apps
        GROUP BY app_name
    ) AS keep_rows
);

SET SQL_SAFE_UPDATES = 1;

-- Έλεγχος επαλήθευσης: πρέπει να επιστρέψει 0 γραμμές!
SELECT app_name, COUNT(*) AS duplicate_count
FROM dim_apps
GROUP BY app_name
HAVING COUNT(*) > 1;

-- 4.4 Τελικό σωστό insert στον fact_reviews
INSERT INTO fact_reviews (
    app_key,
    location_key,
    sentiment_type_key,
    translated_review,
    sentiment_polarity,
    sentiment_subjectivity,
    my_polarity_scaled,
    my_subjectivity,
    my_pos_subjectivity,
    anger, anticipation, disgust, fear, joy, 
    sadness, surprise, trust, negative, positive
)
SELECT 
    a.app_key,
    l.location_key,
    s.sentiment_type_key,
    stg.Translated_Review,
    ROUND(stg.Sentiment_Polarity, 3),
    ROUND(stg.Sentiment_Subjectivity, 3),
    ROUND(stg.my_polarity_scaled, 3),
    ROUND(stg.my_subjectivity, 3),
    ROUND(stg.my_pos_subjectivity, 3),
    stg.anger,
    stg.anticipation,
    stg.disgust,
    stg.fear,
    stg.joy,
    stg.sadness,
    stg.surprise,
    stg.trust,
    stg.negative,
    stg.positive
FROM staging_reviews stg
JOIN dim_apps a 
    ON stg.App = a.app_name
JOIN dim_locations l 
    ON stg.Country = l.country AND stg.Continent = l.continent
JOIN dim_sentiment_types s 
    ON stg.my_sentiment_type = s.sentiment_name;

-- Τελικός έλεγχος πλήθους (πρέπει να επιστρέψει ακριβώς 28247)
SELECT COUNT(*) AS total_fact_reviews FROM fact_reviews;








-- 1. Έλεγχος των πρώτων γραμμών για οπτική επιβεβαίωση των Surrogate Keys
SELECT review_key, app_key, location_key, sentiment_type_key, sentiment_polarity, my_polarity_scaled 
FROM fact_reviews 
LIMIT 10;

-- 2. Έλεγχος ότι το εύρος των review_key είναι ακριβώς από 1 έως 28247
SELECT MIN(review_key) AS min_key, MAX(review_key) AS max_key 
FROM fact_reviews;

-- 3. Απομάκρυνση του προσωρινού staging πίνακα
DROP TABLE staging_reviews;