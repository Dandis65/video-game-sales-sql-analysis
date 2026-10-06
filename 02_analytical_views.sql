-- 1. TOP 20 nejprodávanějších her historie
WITH `sales_worldwide` AS (
    SELECT 
        `games_clean`.`title` AS `title`,
        SUM(`games_clean`.`total_sales`) AS `sales_ww` 
    FROM `games_clean` 
    WHERE (`games_clean`.`total_sales` IS NOT NULL) 
    GROUP BY `games_clean`.`title`
) 
SELECT 
    `sales_worldwide`.`title` AS `title`,
    `sales_worldwide`.`sales_ww` AS `sales_ww`,
    ROW_NUMBER() OVER (ORDER BY `sales_worldwide`.`sales_ww` DESC) AS `rank` 
FROM `sales_worldwide` 
ORDER BY `sales_worldwide`.`sales_ww` DESC 
LIMIT 20;

-- 2. Kohortové prodeje podle roků vydání
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `top_sales_by_year` AS 
SELECT 
    YEAR(`games_raw`.`release_date`) AS `year`,
    ROUND(SUM(`games_raw`.`total_sales`), 2) AS `total_sales_by_year`,
    ROW_NUMBER() OVER (ORDER BY SUM(`games_raw`.`total_sales`) DESC) AS `rank` 
FROM `games_raw` 
GROUP BY YEAR(`games_raw`.`release_date`) 
ORDER BY `total_sales_by_year` DESC;


-- 3. Zastoupení žánrů na konzolích
WITH `genre_count_rank` AS (
    SELECT 
        `games_clean`.`console` AS `console`,
        `games_clean`.`genre` AS `genre`,
        COUNT(`games_clean`.`genre`) AS `genre_count`,
        ROW_NUMBER() OVER (PARTITION BY `games_clean`.`console` ORDER BY COUNT(`games_clean`.`genre`) DESC) AS `ranking` 
    FROM `games_clean` 
    GROUP BY `games_clean`.`console`, `games_clean`.`genre` 
    ORDER BY `genre_count` DESC
) 
SELECT 
    `genre_count_rank`.`console` AS `console`,
    `genre_count_rank`.`genre` AS `genre`,
    `genre_count_rank`.`genre_count` AS `genre_count` 
FROM `genre_count_rank` 
WHERE (`genre_count_rank`.`ranking` BETWEEN 0 AND 3) 
ORDER BY `genre_count_rank`.`console`, `genre_count_rank`.`genre_count` DESC;




-- 4. Srovnání trhů NA vs. JP (Kulturní anomálie)
WITH `total_sales_region` AS (
    SELECT 
        `games_clean`.`title` AS `title`,
        SUM(`games_clean`.`na_sales`) AS `na_sales`,
        SUM(`games_clean`.`jp_sales`) AS `jp_sales`,
        CAST(ROW_NUMBER() OVER (ORDER BY SUM(`games_clean`.`na_sales`) DESC) AS SIGNED) AS `na_sales_ranked`,
        CAST(ROW_NUMBER() OVER (ORDER BY SUM(`games_clean`.`jp_sales`) DESC) AS SIGNED) AS `jp_sales_ranked` 
    FROM `games_clean` 
    WHERE (
        (`games_clean`.`na_sales` IS NOT NULL) 
        AND (`games_clean`.`jp_sales` IS NOT NULL)
    ) 
    GROUP BY `games_clean`.`title` 
    ORDER BY `na_sales` DESC
) 
SELECT 
    `total_sales_region`.`title` AS `title`,
    `total_sales_region`.`na_sales` AS `na_sales`,
    `total_sales_region`.`jp_sales` AS `jp_sales`,
    `total_sales_region`.`na_sales_ranked` AS `na_sales_ranked`,
    `total_sales_region`.`jp_sales_ranked` AS `jp_sales_ranked`,
    (`total_sales_region`.`na_sales_ranked` - `total_sales_region`.`jp_sales_ranked`) AS `rank_diff` 
FROM `total_sales_region` 
ORDER BY (`total_sales_region`.`na_sales_ranked` - `total_sales_region`.`jp_sales_ranked`) DESC;




-- 5. Recenze vs. Prodeje 
WITH `game_aggregated` AS (
    SELECT 
        `games_clean`.`title` AS `title`,
        ROUND(AVG(`games_clean`.`critic_score`), 1) AS `avg_score`,
        ROUND(SUM(`games_clean`.`total_sales`), 2) AS `total_sales_all_platforms`,
        COUNT(DISTINCT `games_clean`.`console`) AS `platform_count` 
    FROM `games_clean` 
    WHERE (
        (`games_clean`.`critic_score` IS NOT NULL) 
        AND (`games_clean`.`total_sales` IS NOT NULL)
    ) 
    GROUP BY `games_clean`.`title`
), 
`ranked_games` AS (
    SELECT 
        `game_aggregated`.`title` AS `title`,
        `game_aggregated`.`avg_score` AS `avg_score`,
        `game_aggregated`.`total_sales_all_platforms` AS `total_sales_all_platforms`,
        `game_aggregated`.`platform_count` AS `platform_count`,
        DENSE_RANK() OVER (ORDER BY `game_aggregated`.`avg_score` DESC) AS `score_rank`,
        DENSE_RANK() OVER (ORDER BY `game_aggregated`.`total_sales_all_platforms` DESC) AS `sales_rank` 
    FROM `game_aggregated`
) 
SELECT 
    `ranked_games`.`title` AS `title`,
    `ranked_games`.`avg_score` AS `avg_score`,
    `ranked_games`.`total_sales_all_platforms` AS `total_sales_all_platforms`,
    `ranked_games`.`platform_count` AS `platform_count`,
    `ranked_games`.`score_rank` AS `score_rank`,
    `ranked_games`.`sales_rank` AS `sales_rank`,
    (CAST(`ranked_games`.`sales_rank` AS SIGNED) - CAST(`ranked_games`.`score_rank` AS SIGNED)) AS `rank_gap` 
FROM `ranked_games` 
ORDER BY `rank_gap` DESC 
LIMIT 20;




