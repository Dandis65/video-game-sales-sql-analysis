# Video Game Sales & Market Performance Analysis (SQL)

End-to-end data analytics projekt zaměřený na profilování, čištění a analytické zpracování databáze videoherních prodejů (VGChartz). Projekt demonstruje transformaci nestrukturovaných dat do produkčního schématu a tvorbu analytických pohledů (Views) připravených pro reportingovou vrstvu v Power BI.

---

## Použité technologie & Zdroj dat
- **Databázový systém:** MySQL 8.0 (CTEs, okenní funkce `ROW_NUMBER()` a `DENSE_RANK()`, DDL a DML operace, optimalizace typů).
- **Vývojové prostředí:** MySQL Workbench.
- **Zdroj dat:** [Kaggle – VGChartz Video Games Sales dataset.](https://mavenanalytics.io/data-playground/video-game-sales)

---

## Struktura repozitáře
- `01_data_cleaning.sql` – profilování délek textů, explicitní DDL definice `games_clean` ošetření `NULL` a deduplikace.
- `02_analytical_views.sql` – sada analytických SQL pohledů (Views) řešících klíčové byznysové otázky trhu.
- `README.md` – technická a metodická dokumentace projektu.
- *(Plánováno)* `reports/` – soubor `.pbix` a interaktivní vizualizace z Power BI.

---

## Datová architektura (Medallion Architecture)

Data jsou organizována ve třech vrstvách:
* **`games_raw`**: Zdrojová tabulka s původními daty.
* **`games_clean`**: Očištěná produkční tabulka se správnými datovými typy (`DECIMAL`, `DATE`), ošetřenými `NULL` hodnotami a odstraněnými duplicitami přes `ROW_NUMBER()`.
* **Analytická Views**:
  * `20_ww_sales_ranked`: Globální žebříček nejprodávanějších her historie.
  * `comparison_na_x_jp`: Srovnání popularity a rozdílů v umístění (Rank Gap) mezi Severní Amerikou a Japonskem.
  * `genre_count_by_console`: Zastoupení žánrů na jednotlivých herních platformách.
  * `top_sales_by_year`: Ročníkový objem celoživotních prodejů.
  * `games_x_sales_ranked`: Vztah mezi hodnocením kritiků a reálným komerčním úspěchem.
   - `games_x_sales_ranked` – korelace hodnocení recenzentů a komerčního úspěchu[cite: 6].

---

## 🔍 Příklad zjištění: Regionální propast (Severní Amerika vs. Japonsko)

Porovnáním pořadí prodejů v Severní Americe (`na_sales_ranked`) a Japonsku (`jp_sales_ranked`) byly odhaleny výrazné kulturní preference[cite: 3]:
- **Japonské bestsellery:** Hry jako *Pro Evolution Soccer 2014* (0,51 mil. ks) nebo *Samurai Warriors 2* (0,57 mil. ks) obsadily v Japonsku přední příčky prodejnosti (Top 100), zatímco na americkém trhu zapadly do průměru (propad o více než 1 600 příček)[cite: 3].
- **Měřítko trhu:** Protože je americký trh 4–5× větší, představuje 0,5 milionu prodaných kusů v Japonsku komerční hit, zatímco v USA jde o střední třídu.

### SQL dotaz pro výpočet rozdílu pozic:
```sql
WITH total_sales_region AS (
    SELECT 
        title,
        SUM(na_sales) AS na_sales,
        SUM(jp_sales) AS jp_sales,
        CAST(ROW_NUMBER() OVER (ORDER BY SUM(na_sales) DESC) AS SIGNED) AS na_sales_ranked,
        CAST(ROW_NUMBER() OVER (ORDER BY SUM(jp_sales) DESC) AS SIGNED) AS jp_sales_ranked
    FROM games_clean
    WHERE na_sales IS NOT NULL AND jp_sales IS NOT NULL
    GROUP BY title
)
SELECT 
    title,
    na_sales,
    jp_sales,
    na_sales_ranked,
    jp_sales_ranked,
    (na_sales_ranked - jp_sales_ranked) AS rank_diff
FROM total_sales_region
ORDER BY rank_diff DESC
LIMIT 5;
```

<img width="1180" height="371" alt="image" src="https://github.com/user-attachments/assets/42434f6d-2920-47a7-8e8a-9dd95d0c0a00" />
