/* =====================================================================
   COHORT DEFINITION - SVT INDEX / SVT ABLATION ESCALATION
   (FALSIFICATION ARM for the DCCV -> AF ablation study)
   ---------------------------------------------------------------------
   One row per INDEX SPELL. Index = a patient's first EMERGENCY admission
   with SVT as PRIMARY diagnosis (I47.1; optionally I45.6 pre-excitation),
   among patients with no prior catheter ablation of any kind.

   Outcome = ELECTIVE SVT-type ablation (K57.1/K57.2/K57.4 with an SVT
   diagnosis) within 12 / 24 months of index admission.

   DESIGN LOGIC (mirror of the AF arm, differences marked *):
     1.* Entry is agency-free: an emergency SVT admission is not chosen.
         This is the point of the falsification arm - same referral chain,
         same geography, same deprivation-correlated frictions afterwards,
         but no plausible expectations channel.
     2.  Primary-position diagnosis anchors "admitted FOR SVT".
     3.  EXCLUDE patients with ANY prior catheter ablation (broad code set,
         any setting) - ablation-experienced patients follow redo logic.
     4.* EXCLUDE index spells containing an ablation in the same spell -
         these patients were ablated during the emergency admission and
         never faced the elective referral decision. COUNT THEM FIRST
         (QA block): if material, report alongside the model, because
         inpatient ablation availability could itself vary by site.
     5.  Outcome is ELECTIVE only (mirrors the AF-arm decision: escalation
         must be chosen). Exclusion remains all-setting.
     6.  730-day clean lookback; first index per patient; age >= 18.
     7.* K57.1 TRAP: AV-node ablation is also the "ablate and pace" rate-
         control procedure for AF. The outcome therefore REQUIRES an SVT
         diagnosis (I47.1/I45.6) on the ablation spell, so a later AF
         ablate-and-pace does not count as SVT escalation. For the same
         reason the outcome does NOT include K62.1 (PVI): a later AF
         ablation in a patient who also has AF is AF-pathway activity.

   VERIFIED CODES (from earlier sensitivity work):
     I47.1  Supraventricular tachycardia          (index diagnosis)
     I45.6  Pre-excitation syndrome / WPW         (optional index; flagged)
     K57.1  Ablation of atrioventricular node     (outcome; see trap above)
     K57.2  Ablation of conducting system NEC     (outcome)
     K57.4  Ablation of accessory pathway         (outcome; the WPW cure)
     Exclusion set additionally: K57.5/6/7, K62.1/2/3, K64.1, X50.1 n/a.

   ENVIRONMENT / TODOs:
     [ ] Confirm table and field names (identical to AF-arm assumptions).
     [ ] Confirm emergency Admission_Method values incl. '2A'/'2B'/'2D'.
     [ ] Discharge_Method = '4' assumed "died". Confirm.
     [ ] If your tool rejects DECLARE, paste literals inline.
   ===================================================================== */

DECLARE @data_start     DATE = '2008-04-01';
DECLARE @data_end       DATE = '2026-03-31';
DECLARE @lookback_days  INT  = 730;
DECLARE @followup_days  INT  = 730;

WITH

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
      AND (Der_Diagnosis_All LIKE '%I471%' OR Der_Diagnosis_All LIKE '%I456%')
      AND Admission_Method IN ('11','12','13')
),

/* -- 3. ALL SVT ADMISSIONS (for the recurrence-burden covariate) ------- */
svt_any AS (
    SELECT
        der_pseudo_nhs_number AS nhs_no,
        Admission_Date        AS svt_date
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
    WHERE Der_Diagnosis_All LIKE '||I471%'      /* primary position */
),

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
        s.Der_Procedure_All,
        /* WPW entry-route flag (0 = classic SVT I47.1 primary) */
        CASE WHEN s.Der_Diagnosis_All LIKE '||I456%' THEN 1 ELSE 0 END AS wpw_entry
    FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] AS s
    WHERE ( s.Der_Diagnosis_All LIKE '||I471%'
            /* toggle: comment the next line out to restrict entry to I47.1 */
            /*OR s.Der_Diagnosis_All LIKE '||I456%' */
          )
      AND s.Admission_Method IN ('21','22','23','24','25','28','2A','2B','2D')
      AND s.der_age_at_cds_activity_date >= 18
      AND s.der_age_at_cds_activity_date <= 112
      AND s.der_pseudo_nhs_number IS NOT NULL
      /* exclude same-spell ablation: never faced the elective decision */
      AND s.Der_Procedure_All NOT LIKE '%K57[124567]%'
      AND s.Der_Procedure_All NOT LIKE '%K62[123]%'
      AND s.Der_Procedure_All NOT LIKE '%K641%'
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
prior_svt AS (
    SELECT i.der_spell_id, COUNT(*) AS n_prior_svt
    FROM idx AS i
    INNER JOIN svt_any AS v
            ON v.nhs_no = i.nhs_no AND v.svt_date < i.Admission_Date
    GROUP BY i.der_spell_id
),

/* -- 8. OUTCOME: FIRST ELECTIVE SVT ABLATION AFTER INDEX --------------- */
next_abl AS (
    SELECT i.der_spell_id, MIN(a.abl_date) AS first_abl_after_date
    FROM idx AS i
    INNER JOIN abl_svt_elective AS a
            ON a.nhs_no = i.nhs_no AND a.abl_date > i.Admission_Date
    GROUP BY i.der_spell_id
)

/* -- 9. FINAL COHORT --------------------------------------------------- */
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
    i.wpw_entry,
    /* ---- OUTCOME ---- */
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

    /* ---- CENSORING / VALIDITY ---- */
    CASE WHEN i.Admission_Date <= DATEADD(day, -@followup_days, @data_end)
         THEN 1 ELSE 0 END AS has_24m_followup,
    CASE WHEN i.Admission_Date <= DATEADD(day, -365, @data_end)
         THEN 1 ELSE 0 END AS has_12m_followup,
    CASE WHEN i.Discharge_Method = '4' THEN 1 ELSE 0 END AS died_in_index_spell,

    /* ---- PATHWAY POSITION ---- */
    ISNULL(pv.n_prior_svt, 0) AS n_prior_svt,
    CASE WHEN ISNULL(pv.n_prior_svt, 0) > 0 THEN 1 ELSE 0 END AS recurrent_svt,

    /* ---- CO-CODED ARRHYTHMIA (sensitivity flags, not exclusions) ----
       Concurrent AF matters: these patients sit in BOTH pathways, and their
       later EP contact may be AF-driven. Primary analysis keeps them
       (outcome definition already walls off AF-pathway activity); a
       sensitivity excluding dx_af_any = 1 tests robustness. */
    CASE WHEN i.Der_Diagnosis_All LIKE '%I48%'  THEN 1 ELSE 0 END AS dx_af_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I47[02]%' THEN 1 ELSE 0 END AS dx_other_i47,

    /* ---- HEART FAILURE (kept for symmetry with the AF arm) ---- */
    CASE WHEN i.Der_Diagnosis_All LIKE '%I50%'  THEN 1 ELSE 0 END AS hf_any,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I509%' THEN 1 ELSE 0 END AS hf_unspecified,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I500%'
           OR i.Der_Diagnosis_All LIKE '%I501%' THEN 1 ELSE 0 END AS hf_specified,

    /* ---- COMORBIDITY (index spell; lookback versions via pipeline) ---- */
    CASE WHEN i.Der_Diagnosis_All LIKE '%I1[0-5]%' THEN 1 ELSE 0 END AS hypertension,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I2[0-5]%' THEN 1 ELSE 0 END AS ihd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I6[34]%'
           OR i.Der_Diagnosis_All LIKE '%G45%'     THEN 1 ELSE 0 END AS stroke_tia,
    CASE WHEN i.Der_Diagnosis_All LIKE '%E1[0-4]%' THEN 1 ELSE 0 END AS diabetes,
    CASE WHEN i.Der_Diagnosis_All LIKE '%J44%'     THEN 1 ELSE 0 END AS copd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%N18%'     THEN 1 ELSE 0 END AS ckd,
    CASE WHEN i.Der_Diagnosis_All LIKE '%I3[45]%'  THEN 1 ELSE 0 END AS valve_disease,
    CASE WHEN i.Der_Diagnosis_All LIKE '%E66%'     THEN 1 ELSE 0 END AS obesity,

    /* ---- CODING-DEPTH DIAGNOSTIC ---- */
    LEN(i.Der_Diagnosis_All)
      - LEN(REPLACE(i.Der_Diagnosis_All, ',', '')) + 1 AS n_diagnoses,
    LEN(i.Der_Diagnosis_All)                            AS len_diagnosis_string,

    /* ---- raw strings for the lookback pipeline ---- */
    i.Der_Diagnosis_All,
    i.Der_Procedure_All

FROM idx AS i
LEFT JOIN prior_abl AS pa ON pa.der_spell_id = i.der_spell_id
LEFT JOIN prior_svt AS pv ON pv.der_spell_id = i.der_spell_id
LEFT JOIN next_abl  AS na ON na.der_spell_id = i.der_spell_id

WHERE pa.first_prior_abl_date IS NULL
  AND i.Admission_Date >= DATEADD(day, @lookback_days, @data_start)
ORDER BY i.Admission_Date, i.der_spell_id;


/* =====================================================================
   QA BLOCK - run before modelling (as #svt_cohort):

   -- 1. The same-spell-ablation count the exclusion threw away:
   SELECT Der_Financial_Year, COUNT(*) AS n_inpatient_ablation
   FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot]
   WHERE Der_Diagnosis_All LIKE 'I471%'
     AND Admission_Method IN ('21','22','23','24','25','28','2A','2B','2D')
     AND (Der_Procedure_All LIKE '%K57[124]%')
   GROUP BY Der_Financial_Year ORDER BY Der_Financial_Year;
   -- If material or trending, report it: inpatient ablation availability
   -- could vary by site/era and interact with deprivation via admission
   -- routes. Small and flat = one methods sentence.

   -- 2. Cohort summary by year (mirror of the AF arm QA):
   SELECT fyear, COUNT(*) AS n_index,
          AVG(CAST(age AS FLOAT))              AS mean_age,
          AVG(CAST(n_diagnoses AS FLOAT))      AS mean_n_diagnoses,
          AVG(CAST(dx_af_any AS FLOAT))        AS pct_cocoded_af,
          AVG(CAST(wpw_entry AS FLOAT))        AS pct_wpw_entry,
          AVG(CAST(recurrent_svt AS FLOAT))    AS pct_recurrent,
          SUM(has_24m_followup)                AS n_with_24m_fu,
          AVG(CAST(ablation_24m AS FLOAT))     AS escalation_rate_24m
   FROM #svt_cohort GROUP BY fyear ORDER BY fyear;

   -- 3. Events by year x IMD decile after linkage - same sparsity gate
   --    as the AF arm. SVT is lower-volume than DCCV: if cells are thin,
   --    a coarser time parametrisation in the falsification model is fine
   --    (the arm needs a credible gradient estimate, not a full replica).
   ===================================================================== */

