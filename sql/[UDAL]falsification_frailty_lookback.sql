/* =====================================================================
   LOOKBACK EXTRACTION - HFRS + COMORBIDITY - SVT ESCALATION COHORT
   ---------------------------------------------------------------------
   Adapts the TAVI HFRS lookback to the SVT -> ablation cohort. One output
   row per (index spell x prior spell in window); scoring happens in R.

   DESIGN DECISIONS CARRIED OVER (see TAVI pipeline discussion):
     - Lookback covers ALL prior admissions (elective included) - in the
       HFRS methodology "emergency" describes Gilbert's derivation cohort,
       not the accrual window.
     - STRICTLY PRIOR: the index spell's own diagnoses are excluded. For
       this cohort the argument is even simpler than for TAVI - covariates
       should be as-at the escalation decision, and the index DCCV spell
       is thin-coded anyway.
     - Window: prior spell's DISCHARGE within 730 days before index
       ADMISSION (the NHP join logic).
     - Prior spells discharged ON the index admission date are excluded
       (probable transfers into the index event - superspell logic).
       One-character change marked below if you disagree.
     - De-duplication to distinct 3-char codes happens in R, so it is safe
       to run this against an episode-level table if that is what you have;
       you just pull more rows.

   ===================================================================== */
   
DECLARE @data_start     DATE = '2008-04-01';
DECLARE @data_end       DATE = '2026-03-31';
DECLARE @lookback_days  INT  = 730;
DECLARE @followup_days  INT  = 730;

WITH
   
/* =====================================================================
   COHORT DEFINITION
   --------------------------------------------------------------------- */
   
/* -- 1. ALL CATHETER ABLATIONS, ANY TYPE (for the EXCLUSION) ----------- */
abl_any AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS abl_date
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE Der_Procedure_All LIKE '%K57[124567]%'
       OR Der_Procedure_All LIKE '%K62[123]%'
       OR Der_Procedure_All LIKE '%K641%'
),

/* -- 2. ELECTIVE SVT ABLATIONS (for the OUTCOME) ----------------------- */
abl_svt_elective AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS abl_date
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE Der_Procedure_All LIKE '%K57[124]%'
      AND (Der_Diagnosis_All LIKE '%I471%'
      /* OR Der_Diagnosis_All LIKE '%I456%' */
      )
      AND Admission_Method IN ('11','12','13')
),

/* -- 3. ALL SVT ADMISSIONS (for the recurrence-burden covariate) ------- */
/*svt_any AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS svt_date
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE Der_Diagnosis_All LIKE '||I471%'    
),
*/
/* -- 4. CANDIDATE INDEX SPELLS ----------------------------------------- */
cand AS (
    SELECT
        s.Der_Financial_Year                AS fyear,
        s.Der_Activity_Month                AS month,
        s.der_spell_id,
        s.der_pseudo_nhs_number             AS nhs_no,
        s.Admission_Date,
        s.Admission_Time,
        s.Discharge_Date,
        s.Discharge_Time,
        s.Sex,
        s.der_age_at_cds_activity_date      AS age,
        s.ethnic_group,
        s.der_postcode_lsoa_2011_code       AS lsoa11code,
        s.der_postcode_lsoa_2021_code       AS lsoa21code,
        s.Der_Provider_Site_Code,
        s.Admission_Method,
        s.Der_Management_Type,
        s.Discharge_Method,
        s.Der_Diagnosis_All,
        s.Der_Procedure_All
        /* WPW entry-route flag (0 = classic SVT I47.1 primary) */
        /*CASE WHEN s.Der_Diagnosis_All LIKE '||I456%' THEN 1 ELSE 0 END AS wpw_entry*/
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] AS s
    WHERE ( s.Der_Diagnosis_All LIKE '||I471%'
            /* toggle: comment the next line out to restrict entry to I47.1 */
            /* OR s.Der_Diagnosis_All LIKE '||I456%' */
          )
      AND s.Admission_Method IN ('21','22','23','24','25','28','2A','2B','2D')
      AND s.der_age_at_cds_activity_date >= 18
      AND s.der_age_at_cds_activity_date <= 112
      AND s.der_pseudo_nhs_number IS NOT NULL
      /* exclude same-spell ablation: never faced the elective decision */
      AND (
               s.Der_Procedure_All NOT LIKE '%K57[124567]%' 
           AND s.Der_Procedure_All NOT LIKE '%K62[123]%'
           AND s.Der_Procedure_All NOT LIKE '%K641%'
           /* NULLs are coded as "" pre 2018/19 and NULL thereafter
              which causes problems unless the line below is included
              */
           OR  s.Der_Procedure_All IS NULL
           )
),

/* -- 5. FIRST CANDIDATE PER PATIENT ------------------------------------ */
ranked AS (
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c.nhs_no
                              ORDER BY c.Admission_Date, c.der_spell_id) AS seq
    FROM cand AS c
),
idx AS (
    SELECT * FROM ranked WHERE seq = 1
),

/* -- 6. PRIOR ABLATION (exclusion) ------------------------------------- */
prior_abl AS (
    SELECT i.der_spell_id, MIN(a.abl_date) AS first_prior_abl_date
    FROM idx AS i
    INNER JOIN abl_any AS a
            ON a.nhs_no = i.nhs_no AND a.abl_date < i.Admission_Date
    GROUP BY i.der_spell_id
),

/* -- 7. PRIOR SVT ADMISSIONS (recurrence burden - covariate) ----------- */
/*prior_svt AS (
    SELECT i.der_spell_id, COUNT(*) AS n_prior_svt
    FROM idx AS i
    INNER JOIN svt_any AS v
            ON v.nhs_no = i.nhs_no AND v.svt_date < i.Admission_Date
    GROUP BY i.der_spell_id
),
*/
/* -- 8. OUTCOME: FIRST ELECTIVE SVT ABLATION AFTER INDEX --------------- */
next_abl AS (
    SELECT i.der_spell_id, MIN(a.abl_date) AS first_abl_after_date
    FROM idx AS i
    INNER JOIN abl_svt_elective AS a
            ON a.nhs_no = i.nhs_no AND a.abl_date > i.Admission_Date
    GROUP BY i.der_spell_id
),

/* -- 9. FINAL COHORT --------------------------------------------------- */
cohort AS (
SELECT
    i.fyear, 
    i.month, 
    i.der_spell_id,
    i.nhs_no,
    i.Admission_Date,
    i.Admission_Time,
    i.Discharge_Date,
    i.Discharge_Time,
    i.Sex,
    i.age,
    i.ethnic_group,
    i.lsoa11code,
    i.lsoa21code,
    i.Der_Provider_Site_Code,
    i.Admission_Method,
    i.Der_Management_Type,
    /*i.wpw_entry,*/
    /* ---- OUTCOME ---- */
    na.first_abl_after_date,
    /*
    CASE WHEN na.first_abl_after_date IS NOT NULL
         THEN DATEDIFF(day, i.Admission_Date, na.first_abl_after_date)
    END AS days_to_ablation,
    CASE WHEN na.first_abl_after_date IS NOT NULL
          AND na.first_abl_after_date <= DATEADD(month, 12, i.Admission_Date)
         THEN 1 ELSE 0 END AS ablation_12m,
        */ 
    CASE WHEN na.first_abl_after_date IS NOT NULL
          AND na.first_abl_after_date <= DATEADD(month, 24, i.Admission_Date)
         THEN 1 ELSE 0 END AS ablation_24m,

    /* ---- CENSORING / VALIDITY ----
    CASE WHEN i.Admission_Date <= DATEADD(day, -@followup_days, @data_end)
         THEN 1 ELSE 0 END AS has_24m_followup,
    CASE WHEN i.Admission_Date <= DATEADD(day, -365, @data_end)
         THEN 1 ELSE 0 END AS has_12m_followup,
    CASE WHEN i.Discharge_Method = '4' THEN 1 ELSE 0 END AS died_in_index_spell,
 */
    /* ---- PATHWAY POSITION ---- 
    ISNULL(pv.n_prior_svt, 0) AS n_prior_svt,
    CASE WHEN ISNULL(pv.n_prior_svt, 0) > 0 THEN 1 ELSE 0 END AS recurrent_svt,
*/
    /* ---- CO-CODED ARRHYTHMIA (sensitivity flags, not exclusions) ----
       Concurrent AF matters: these patients sit in BOTH pathways, and their
       later EP contact may be AF-driven. Primary analysis keeps them
       (outcome definition already walls off AF-pathway activity); a
       sensitivity excluding dx_af_any = 1 tests robustness. 
    CASE WHEN i.Der_Diagnosis_All LIKE '%I48%'  THEN 1 ELSE 0 END AS dx_af_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I47[02]%' THEN 1 ELSE 0 END AS dx_other_i47,
*/
    /* ---- HEART FAILURE (kept for symmetry with the AF arm) ----
    CASE WHEN i.Der_Diagnosis_All LIKE '%I50%'  THEN 1 ELSE 0 END AS hf_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I509%' THEN 1 ELSE 0 END AS hf_unspecified,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I500%'
           OR i.Der_Diagnosis_All LIKE '%I501%' THEN 1 ELSE 0 END AS hf_specified,
 */
    /* ---- COMORBIDITY (index spell; lookback versions via pipeline) ---- 
    CASE WHEN i.Der_Diagnosis_All LIKE '%I1[0-5]%' THEN 1 ELSE 0 END AS hypertension,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I2[0-5]%' THEN 1 ELSE 0 END AS ihd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I6[34]%'
           OR i.Der_Diagnosis_All LIKE '%G45%'     THEN 1 ELSE 0 END AS stroke_tia,
    CASE WHEN i.Der_Diagnosis_All LIKE '%E1[0-4]%' THEN 1 ELSE 0 END AS diabetes,
    CASE WHEN i.Der_Diagnosis_All LIKE '%J44%'     THEN 1 ELSE 0 END AS copd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%N18%'     THEN 1 ELSE 0 END AS ckd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I3[45]%'  THEN 1 ELSE 0 END AS valve_disease,
    CASE WHEN i.Der_Diagnosis_All LIKE '%E66%'     THEN 1 ELSE 0 END AS obesity,
*/
    /* ---- CODING-DEPTH DIAGNOSTIC ---- 
    LEN(i.Der_Diagnosis_All)
      - LEN(REPLACE(i.Der_Diagnosis_All, ',', '')) + 1 AS n_diagnoses,
    LEN(i.Der_Diagnosis_All)                            AS len_diagnosis_string,
*/
    /* ---- raw strings for the lookback pipeline ---- */
    i.Der_Diagnosis_All,
    i.Der_Procedure_All

FROM idx AS i
LEFT JOIN prior_abl AS pa ON pa.der_spell_id = i.der_spell_id
/* LEFT JOIN prior_svt AS pv ON pv.der_spell_id = i.der_spell_id */
LEFT JOIN next_abl  AS na ON na.der_spell_id = i.der_spell_id

WHERE pa.first_prior_abl_date IS NULL
  AND i.Admission_Date >= DATEADD(day, @lookback_days, @data_start)


   )
   

/* =====================================================================
   LOOKBACK EXTRACTION - HFRS + COMORBIDITY - SVT ESCALATION COHORT
   --------------------------------------------------------------------- */

SELECT
    j.der_spell_id,                        /* index spell key */
    j.nhs_no,
    j.Admission_Date       AS index_admission_date,
    q.Discharge_Date       AS prior_discharge_date,
    q.Der_Diagnosis_All    AS prior_diagnosis_all
FROM cohort AS j
INNER JOIN [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] AS q
        ON q.der_pseudo_nhs_number = j.nhs_no
       AND q.Discharge_Date >= DATEADD(day, -730, j.Admission_Date)
       AND q.Discharge_Date <  j.Admission_Date
           /* '<' excludes same-day transfers into the index event.
              Use '<=' to include them (not recommended). */
WHERE q.Der_Diagnosis_All IS NOT NULL
ORDER BY j.der_spell_id, q.Discharge_Date

/* Patients with NO rows here are zero-filled in R (any_prior_admission=0),
   so do not inner-join this output back to the cohort as a filter. */







