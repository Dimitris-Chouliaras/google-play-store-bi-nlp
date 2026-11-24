-- ΚΕΦΑΛΑΙΟ 4.5: ΒΕΛΤΙΣΤΟΠΟΙΗΣΗ ΑΠΟΘΗΚΗΣ ΔΕΔΟΜΕΝΩΝ & Δημιουργία Ευρετηρίων (Indexing)
-- Database: playstore_dw
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- ============================================================================
USE playstore_dw;

-- 1. ΕΥΡΕΤΗΡΙΑ ΞΕΝΩΝ ΚΛΕΙΔΙΩΝ (Foreign Key Indexes για γρήγορα JOINs) - Επιταχύνουν δραστικά τις συνενώσεις του Star Schema με τους 3 πίνακες διαστάσεων
CREATE INDEX idx_fact_app_key 
    ON fact_reviews(app_key);

CREATE INDEX idx_fact_location_key 
    ON fact_reviews(location_key);

CREATE INDEX idx_fact_sentiment_type_key 
    ON fact_reviews(sentiment_type_key);

-- 2. ΣΥΝΘΕΤΑ ΕΥΡΕΤΗΡΙΑ ΓΙΑ ΣΥΧΝΑ ΑΝΑΛΥΤΙΚΑ ΕΡΩΤΗΜΑΤΑ (Composite Indexes)
-- Επιταχύνει ερωτήματα που αναλύουν το συναίσθημα ανά συγκεκριμένη εφαρμογή (π.χ. Dashboards στο Power BI)
CREATE INDEX idx_app_sentiment 
    ON fact_reviews(app_key, sentiment_type_key);

-- Επιταχύνει γεωγραφικές αναλύσεις συναισθήματος (Country/Continent vs Sentiment)
CREATE INDEX idx_location_sentiment 
    ON fact_reviews(location_key, sentiment_type_key);

-- 3. ΕΠΙΚΑΙΡΟΠΟΙΗΣΗ ΣΤΑΤΙΣΤΙΚΩΝ ΒΕΛΤΙΣΤΟΠΟΙΗΤΗ (Optimizer Statistics) - Ενημερώνει τον Cost-Based Optimizer της InnoDB για την κατανομή των κλειδιών
ANALYZE TABLE fact_reviews;
ANALYZE TABLE dim_apps;
ANALYZE TABLE dim_locations;
ANALYZE TABLE dim_sentiment_types;

-- 4. ΕΠΑΛΗΘΕΥΣΗ ΠΛΑΝΟΥ ΕΚΤΕΛΕΣΗΣ (Query Execution Plan via EXPLAIN) - Έλεγχος ότι τα JOINs και τα φίλτρα αξιοποιούν τα νέα B-Tree ευρετήρια (τύπος ref αντί για ALL)
EXPLAIN 
SELECT 
    a.app_name,
    l.country,
    s.sentiment_name,
    COUNT(f.review_key) AS total_reviews,
    AVG(f.my_polarity_scaled) AS avg_polarity
FROM fact_reviews f
JOIN dim_apps a ON f.app_key = a.app_key
JOIN dim_locations l ON f.location_key = l.location_key
JOIN dim_sentiment_types s ON f.sentiment_type_key = s.sentiment_type_key
WHERE a.app_name = 'Facebook'
GROUP BY a.app_name, l.country, s.sentiment_name;





-- Έλεγχος ότι όλες οι κριτικές έχουν έγκυρο και υπαρκτό app_key στον dim_apps
SELECT COUNT(*) AS orphan_reviews
FROM fact_reviews f
LEFT JOIN dim_apps a ON f.app_key = a.app_key
WHERE a.app_key IS NULL;