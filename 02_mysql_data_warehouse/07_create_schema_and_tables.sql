-- =============================================================================
-- ΚΕΦΑΛΑΙΟ 4.3: DDL SCRIPT ΔΗΜΙΟΥΡΓΙΑΣ ΒΑΣΗΣ & STAR SCHEMA
-- Database: playstore_dw
-- Engine: InnoDB | Charset: utf8mb4 | Collation: utf8mb4_unicode_ci
-- =============================================================================

-- 1. Δημιουργία της Βάσης Δεδομένων
CREATE DATABASE playstore_dw
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE playstore_dw;

-- 2. Δημιουργία Πίνακα Διάστασης: dim_locations
CREATE TABLE dim_locations (
    location_key INT AUTO_INCREMENT PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    continent VARCHAR(50) NOT NULL,
    CONSTRAINT uq_location UNIQUE (country, continent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Δημιουργία Πίνακα Διάστασης: dim_sentiment_types (Lookup Dimension)
CREATE TABLE dim_sentiment_types (
    sentiment_type_key TINYINT AUTO_INCREMENT PRIMARY KEY,
    sentiment_name VARCHAR(15) NOT NULL,
    polarity_range VARCHAR(30) NOT NULL,
    sentiment_description VARCHAR(100) NULL,
    CONSTRAINT uq_sentiment_name UNIQUE (sentiment_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Δημιουργία Πίνακα Διάστασης: dim_apps
CREATE TABLE dim_apps (
    app_key INT AUTO_INCREMENT PRIMARY KEY,
    app_name VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL,
    rating DECIMAL(2, 1) NULL,
    reviews_count INT NOT NULL,
    installs BIGINT NOT NULL,
    type VARCHAR(10) NOT NULL,
    price DECIMAL(6, 2) NOT NULL,
    content_rating VARCHAR(50) NOT NULL,
    genres VARCHAR(100) NOT NULL,
    size_mb DECIMAL(6, 2) NOT NULL,
    size_imputed TINYINT(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Δημιουργία Κεντρικού Πίνακα Γεγονότων: fact_reviews
CREATE TABLE fact_reviews (
    review_key INT AUTO_INCREMENT PRIMARY KEY,
    app_key INT NOT NULL,
    location_key INT NOT NULL,
    sentiment_type_key TINYINT NOT NULL,
    translated_review TEXT NULL,
    sentiment_polarity DECIMAL(4, 3) NOT NULL,
    sentiment_subjectivity DECIMAL(4, 3) NOT NULL,
    my_polarity_scaled DECIMAL(4, 3) NOT NULL,
    my_subjectivity DECIMAL(4, 3) NOT NULL,
    my_pos_subjectivity DECIMAL(4, 3) NOT NULL,
    anger TINYINT NOT NULL,
    anticipation TINYINT NOT NULL,
    disgust TINYINT NOT NULL,
    fear TINYINT NOT NULL,
    joy TINYINT NOT NULL,
    sadness TINYINT NOT NULL,
    surprise TINYINT NOT NULL,
    trust TINYINT NOT NULL,
    negative TINYINT NOT NULL,
    positive TINYINT NOT NULL,
    
    -- Foreign Key Constraints (Αναφορική Ακεραιότητα 1:N)
    CONSTRAINT fk_reviews_apps 
        FOREIGN KEY (app_key) REFERENCES dim_apps (app_key)
        ON DELETE RESTRICT ON UPDATE CASCADE,
        
    CONSTRAINT fk_reviews_locations 
        FOREIGN KEY (location_key) REFERENCES dim_locations (location_key)
        ON DELETE RESTRICT ON UPDATE CASCADE,
        
    CONSTRAINT fk_reviews_sentiment_types 
        FOREIGN KEY (sentiment_type_key) REFERENCES dim_sentiment_types (sentiment_type_key)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;