/* =====================================================================
   LOOKBACK EXTRACTION - HFRS + COMORBIDITY - DCCV ESCALATION COHORT
   ---------------------------------------------------------------------
   Adapts the TAVI HFRS lookback to the DCCV->ablation cohort. One output
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

   ASSUMES: #cohort (or a view) holds the final cohort from
   dccv_ablation_cohort.sql with der_spell_id, nhs_no, Admission_Date.

   TODOs:
     [ ] Table name for the lookback source (spell-level snapshot preferred).
     [ ] Confirm Der_Diagnosis_All delimiter (R regex tolerates , ; |).
     [ ] Check history depth: index spells in your first eligible year need
         lookback reaching 2 years earlier. The cohort SQL's clean-lookback
         filter should guarantee this - the R diagnostic verifies.
   ===================================================================== */
   
   
/* =====================================================================
   COHORT DEFINITION
   --------------------------------------------------------------------- */

DECLARE @data_start     DATE = '2008-04-01';   /* first date in snapshot*/
DECLARE @data_end       DATE = '2026-03-31';   /* last date in snapshot*/
DECLARE @lookback_days  INT  = 730;            /* clean history required before index*/
DECLARE @followup_days  INT  = 730;            /* 24m outcome window*/

WITH

/* -- 1. ALL AF ABLATION EVENTS ------------------------------------------
   Used both for the prior-ablation EXCLUSION and for the OUTCOME.
   Broad definition (d3 from the earlier sensitivity file). For a
   K62.1-only sensitivity, delete the two K575 / K641 lines - but note
   those codes arrive later in the window, so the broad definition is
   itself mildly time-dependent. Worth running both. 
   Includes emergency ablation (which only account for ~2pc of ablations
   annually) as outcome is ablation escalation.
   */
abl AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS abl_date,
        CASE WHEN Admission_Method IN ('21','22','23','24','25','28','2A','2B','2D') 
             THEN 1 ELSE 0 END AS em_abl
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE (   Der_Procedure_All LIKE '%K621%'
           /*OR Der_Procedure_All LIKE '%K575%'
           OR Der_Procedure_All LIKE '%K641%' */
           )
      AND Der_Diagnosis_All LIKE '%I48%'
),

/* -- 2. ALL DCCV EVENTS, ANY POSITION / ANY ADMISSION METHOD ------------
   Not for cohort entry - only to count prior cardioversions, which is a
   useful marker of how far down the rhythm-control road a patient already
   is at index. Repeat DCCV is itself a recognised trigger for ablation
   referral, so this is a substantively meaningful covariate. */
/*dccv_any AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS dccv_date
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE Der_Procedure_All LIKE '%X501%'
      AND Der_Diagnosis_All LIKE '%I48%'
),*/

/* -- 3. CANDIDATE INDEX SPELLS ----------------------------------------- */
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
        u.site_name,
        u.trust_name,
        s.Admission_Method,
        s.Der_Management_Type,
        s.Discharge_Method,
        s.Der_Diagnosis_All,
        s.Der_Procedure_All
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] AS s
    LEFT JOIN (
        SELECT [site_code],
               [site_name],
               [trust_name]
        FROM Reporting_UKHD_ODS.Provider_Site
    ) u 
    ON s.der_provider_site_code = u.site_code
    WHERE s.Der_Procedure_All  LIKE '||X501%'            /* PRIMARY position */
      AND s.Der_Diagnosis_All  LIKE '%I48%'
      AND s.Admission_Method   IN ('11','12','13')       /* elective */
      AND s.der_age_at_cds_activity_date >= 18
      AND s.der_age_at_cds_activity_date <= 112
      AND s.der_pseudo_nhs_number IS NOT NULL            /* need ID to link */
      /* exclude same-spell ablation: DCCV here is part of the ablation */
      AND s.Der_Procedure_All NOT LIKE '%K621%'
      /*AND s.Der_Procedure_All NOT LIKE '%K575%'
      AND s.Der_Procedure_All NOT LIKE '%K641%' */
      AND s.Deleted = 0
),

/* -- 4. FIRST CANDIDATE PER PATIENT ------------------------------------ */
ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.nhs_no
                           ORDER BY c.Admission_Date, c.der_spell_id) AS seq
    FROM cand AS c
),
idx AS (
    SELECT * FROM ranked WHERE seq = 1
),

/* -- 5. PRIOR ABLATION (exclusion) ------------------------------------- */
prior_abl AS (
    SELECT
        i.der_spell_id,
        MIN(a.abl_date) AS first_prior_abl_date
    FROM idx AS i
    INNER JOIN abl AS a
            ON a.nhs_no   = i.nhs_no
           AND a.abl_date < i.Admission_Date
    GROUP BY i.der_spell_id
),

/* -- 6. PRIOR DCCV COUNT (covariate) ----------------------------------- */
/*prior_dccv AS (
    SELECT
        i.der_spell_id,
        COUNT(*) AS n_prior_dccv
    FROM idx AS i
    INNER JOIN dccv_any AS d
            ON d.nhs_no    = i.nhs_no
           AND d.dccv_date < i.Admission_Date
    GROUP BY i.der_spell_id
),*/

/* -- 7. OUTCOME: FIRST ABLATION AFTER INDEX ---------------------------- */
next_abl AS (
    SELECT
        i.der_spell_id, 
        a.em_abl,
        MIN(a.abl_date) AS first_abl_after_date
    FROM idx AS i
    INNER JOIN abl AS a
            ON a.nhs_no   = i.nhs_no
           AND a.abl_date > i.Admission_Date
    GROUP BY i.der_spell_id, a.em_abl
),

/* -- 8. FINAL COHORT --------------------------------------------------- */
cohort AS (
    SELECT
    /* ---- requested identifiers and characteristics ---- */
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
    i.site_name,
    i.trust_name,
    /*
    i.Admission_Method,
    i.Der_Management_Type,
    */

    /* ---- OUTCOME ---- */
    /*na.em_abl,
    na.first_abl_after_date,
    CASE WHEN na.first_abl_after_date IS NOT NULL
         THEN DATEDIFF(day, i.Admission_Date, na.first_abl_after_date)
    END AS days_to_ablation,
    CASE WHEN na.first_abl_after_date IS NOT NULL
          AND na.first_abl_after_date <= DATEADD(month, 12, i.Admission_Date)
         THEN 1 ELSE 0 END AS ablation_12m,
    CASE WHEN na.first_abl_after_date IS NOT NULL
          AND na.first_abl_after_date <= DATEADD(month, 24, i.Admission_Date)
         THEN 1 ELSE 0 END AS ablation_24m,
*/
    /* ---- CENSORING / VALIDITY FLAGS ---- */
    /*
    CASE WHEN i.Admission_Date <= DATEADD(day, -@followup_days, @data_end)
         THEN 1 ELSE 0 END AS has_24m_buffer,
    CASE WHEN i.Admission_Date <= DATEADD(day, -365, @data_end)
         THEN 1 ELSE 0 END AS has_12m_buffer,
    CASE WHEN i.Discharge_Method = '4' THEN 1 ELSE 0 END AS died_in_index_spell,
*/
    /* ---- PATHWAY POSITION ---- */
    /*
    ISNULL(pd.n_prior_dccv, 0) AS n_prior_dccv,
    CASE WHEN ISNULL(pd.n_prior_dccv, 0) > 0 THEN 1 ELSE 0 END AS repeat_dccv,
*/
    /* ---- AF SUBTYPE ----
       NOTE: the I48 four-character subdivisions were not always populated
       in England's earlier ICD-10 editions - early records may carry only
       I48X. Check af_subtype_known by year before using these in any model
       that includes a time trend; if the subtype only becomes available
       mid-window, treating it as a covariate imports a coding artefact. */
    /*
    CASE WHEN i.Der_Diagnosis_All LIKE '%I480%' THEN 1 ELSE 0 END AS af_paroxysmal,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I481%' THEN 1 ELSE 0 END AS af_persistent,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I482%' THEN 1 ELSE 0 END AS af_chronic,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I48X%'
           OR i.Der_Diagnosis_All LIKE '%I489%' THEN 1 ELSE 0 END AS af_unspecified,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I483%'
           OR i.Der_Diagnosis_All LIKE '%I484%' THEN 1 ELSE 0 END AS flutter_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I480%'
           OR i.Der_Diagnosis_All LIKE '%I481%'
           OR i.Der_Diagnosis_All LIKE '%I482%'
           OR i.Der_Diagnosis_All LIKE '%I483%'
           OR i.Der_Diagnosis_All LIKE '%I484%'
           OR i.Der_Diagnosis_All LIKE '%I489%'
         THEN 1 ELSE 0 END AS af_subtype_known,
    CASE WHEN i.Der_Diagnosis_All LIKE '||I48%' THEN 1 ELSE 0 END AS af_primary_dx,
*/
    /* ---- HEART FAILURE (the C3 finding) ----
       Split specified vs unspecified: a rise concentrated in I50.9 points to
       coding-depth inflation; a rise in I50.0/I50.1 is likelier to be real
       case-mix change. hf_any is the one to interact with a post-2018 era
       term, since that is where the survival indication (CASTLE-AF and
       successors) mutes the preference channel. */
       /*
    CASE WHEN i.Der_Diagnosis_All LIKE '%I50%' THEN 1 ELSE 0 END AS hf_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I509%' THEN 1 ELSE 0 END AS hf_unspecified,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I500%'
           OR i.Der_Diagnosis_All LIKE '%I501%' THEN 1 ELSE 0 END AS hf_specified,
*/
    /* ---- COMORBIDITY (index spell only - see caveat below) ---- */
   
   /*
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
       Mean diagnosis count per record rose materially across the 2010s, so
       EVERY secondary-diagnosis flag above trends upward mechanically.
       Tabulate these by year FIRST. If hf_any tracks n_diagnoses, most of
       the C3 rise is artefact. len_diagnosis_string is the delimiter-
       agnostic fallback if the comma assumption is wrong. */
 /*
 
    LEN(i.Der_Diagnosis_All)
      - LEN(REPLACE(i.Der_Diagnosis_All, ',', '')) + 1 AS n_diagnoses,
    LEN(i.Der_Diagnosis_All)                            AS len_diagnosis_string,
*/
    /* ---- raw strings: keep for HFRS lookback join and audit.
            Comment out if the extract is too wide. ---- */
    i.Der_Diagnosis_All,
    i.Der_Procedure_All

FROM idx AS i
LEFT JOIN prior_abl  AS pa ON pa.der_spell_id = i.der_spell_id
/*LEFT JOIN prior_dccv AS pd ON pd.der_spell_id = i.der_spell_id*/
LEFT JOIN next_abl   AS na ON na.der_spell_id = i.der_spell_id

WHERE pa.first_prior_abl_date IS NULL                    /* no prior ablation */
  AND i.Admission_Date >= DATEADD(day, @lookback_days, @data_start)  /* clean lookback */
  /* flutter-only exclusion. Comment out this block to keep them and use
     the flutter_any / af_* flags instead. */
  /* AND NOT ( (i.Der_Diagnosis_All LIKE '%I483%' OR i.Der_Diagnosis_All LIKE '%I484%')
        AND  i.Der_Diagnosis_All NOT LIKE '%I480%'
        AND  i.Der_Diagnosis_All NOT LIKE '%I481%'
        AND  i.Der_Diagnosis_All NOT LIKE '%I482%'
        AND  i.Der_Diagnosis_All NOT LIKE '%I489%'
        AND  i.Der_Diagnosis_All NOT LIKE '%I48X%' ) */
)


/* =====================================================================
   LOOKBACK EXTRACTION - HFRS + COMORBIDITY - DCCV ESCALATION COHORT
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







