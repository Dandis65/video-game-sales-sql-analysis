
SELECT 
    MAX(CHAR_LENGTH(TRIM(title)))     AS max_title_len,      -- výsledek ~130 -> VARCHAR(150)
    MAX(CHAR_LENGTH(TRIM(console)))   AS max_console_len,    -- výsledek ~6   -> VARCHAR(10)
    MAX(CHAR_LENGTH(TRIM(genre)))     AS max_genre_len,      -- výsledek ~16  -> VARCHAR(30)
    MAX(CHAR_LENGTH(TRIM(publisher))) AS max_publisher_len,  -- výsledek ~50  -> VARCHAR(100)
    MAX(CHAR_LENGTH(TRIM(developer))) AS max_developer_len   -- výsledek ~50  -> VARCHAR(100)
FROM games_raw;


DROP TABLE IF EXISTS games_clean;

CREATE TABLE games_clean (
    game_id      INT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(150) NOT NULL,
    console      VARCHAR(10)  NOT NULL,
    genre        VARCHAR(30),
    publisher    VARCHAR(100),
    developer    VARCHAR(100),
    critic_score DECIMAL(3, 1),
    total_sales  DECIMAL(6, 2),
    na_sales     DECIMAL(6, 2),
    jp_sales     DECIMAL(6, 2),
    pal_sales    DECIMAL(6, 2),
    other_sales  DECIMAL(6, 2),
    release_date DATE,
    
);


INSERT INTO games_clean (
    title,
    console,
    genre,
    publisher,
    developer,
    critic_score,
    total_sales,
    na_sales,
    jp_sales,
    pal_sales,
    other_sales,
    release_date
)
WITH staged_data AS (
    SELECT 
        TRIM(title)       AS title,
        TRIM(console)     AS console,
        NULLIF(TRIM(genre), '')     AS genre,
        NULLIF(TRIM(publisher), '') AS publisher,
        NULLIF(TRIM(developer), '') AS developer,
        CAST(NULLIF(TRIM(critic_score), '') AS DECIMAL(3, 1)) AS critic_score,
        CAST(NULLIF(TRIM(total_sales), '')  AS DECIMAL(6, 2)) AS total_sales,
        CAST(NULLIF(TRIM(na_sales), '')     AS DECIMAL(6, 2)) AS na_sales,
        CAST(NULLIF(TRIM(jp_sales), '')     AS DECIMAL(6, 2)) AS jp_sales,
        CAST(NULLIF(TRIM(pal_sales), '')    AS DECIMAL(6, 2)) AS pal_sales,
        CAST(NULLIF(TRIM(other_sales), '')  AS DECIMAL(6, 2)) AS other_sales,
        STR_TO_DATE(TRIM(release_date), '%Y-%m-%d')           AS release_date
    FROM games_raw
    WHERE NULLIF(TRIM(total_sales), '') IS NOT NULL
      AND TRIM(console) NOT IN ('All', 'PSN', 'XBL')
),
deduplicated_data AS (
    SELECT 
        *,
        -- Při výskytu duplicit zachováme záznam s nejvyššími evidovanými prodeji
        ROW_NUMBER() OVER (
            PARTITION BY title, console 
            ORDER BY total_sales DESC
        ) AS rn
    FROM staged_data
)
SELECT 
    title,
    console,
    genre,
    publisher,
    developer,
    critic_score,
    total_sales,
    na_sales,
    jp_sales,
    pal_sales,
    other_sales,
    release_date
FROM deduplicated_data
WHERE rn = 1;