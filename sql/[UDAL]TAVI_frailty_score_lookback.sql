/*
================================================================================
 HFRS STEP 1 -- EXTRACT 2-YEAR LOOKBACK ADMISSIONS FOR THE TAVI/SAVR COHORT
================================================================================
 PURPOSE
   For every index valve spell (from the principal TAVI query), pull ALL
   admissions (elective AND emergency) for the same patient whose discharge
   date falls within the 730 days BEFORE the index admission date.
   Diagnoses from these prior spells feed the Hospital Frailty Risk Score
   (Gilbert et al. 2018, Lancet), computed in hfrs_02_scoring.R.

 KEY METHOD DECISIONS (see accompanying notes)
   - Lookback includes ALL admission methods (HFRS accrual is not
     emergency-only; "emergency" describes Gilbert's index cohort only).
   - Index-spell diagnoses are EXCLUDED (strictly prior accrual, so the
     covariate is fixed as-at the treatment decision). This deviates
     deliberately from Gilbert, who included index-admission codes.
   - Window: prior_spell.Discharge_Date in
       [index.Admission_Date - 730 days, index.Admission_Date)
     i.e. strictly before the index admission.

 !! PLACEHOLDERS TO CHECK -- SEARCH FOR "TODO" !!
================================================================================
*/

SET DATEFIRST 1


/*------------------------------------------------------------------------------
 STEP 1c: EXPORT for the R workflow.
 One row per (index spell x prior spell). Patients with NO prior admissions
 simply won't appear here -- the R script re-attaches them with score 0 and
 sets any_prior_admission = 0 (keep that marker in the model, per the
 utilisation-dependence point).
------------------------------------------------------------------------------*/
SELECT
    index_spell_id,
    nhs_no,
    index_admission_date,
    prior_spell_id,
    prior_admission_date,
    prior_discharge_date,
    prior_diagnosis_all
FROM (

/*------------------------------------------------------------------------------
 STEP 1b: LOOKBACK SPELLS -- all prior admissions in the 730-day window.

 NOTE on the window bounds: using Discharge_Date < index_admission_date
   excludes spells still open at (or discharged on the day of) the index
   admission. A prior spell discharged the SAME DAY the index spell opens
   is most likely a transfer into the index spell (the superspell issue) --
   its diagnoses arguably belong to the index event, so excluding them is
   consistent with Decision 2. If you'd rather include same-day discharges,
   change < to <=.
------------------------------------------------------------------------------*/

SELECT
    i.[der_spell_id]            AS index_spell_id,
    i.nhs_no,
    i.index_admission_date,
    p.[der_spell_id]            AS prior_spell_id,     
    p.[Admission_Date]          AS prior_admission_date,
    p.[Discharge_Date]          AS prior_discharge_date,
    p.[Der_Diagnosis_All]       AS prior_diagnosis_all
FROM (
/*------------------------------------------------------------------------------
 STEP 1a: INDEX SPELLS -- one row per spell, from the principal cohort query.
 Your principal query is EPISODE-level (APCE); HFRS is computed per index
 SPELL, so collapse to spell level here. Re-uses your WHERE logic verbatim.
------------------------------------------------------------------------------*/

SELECT
    [der_pseudo_nhs_number]                          AS nhs_no,
    [der_spell_id],
    MIN([Admission_Date])                            AS index_admission_date
    /* MIN() is belt-and-braces: admission date should be constant within
       a spell, but episode rows occasionally disagree. */
FROM [Reporting_MESH_APC].[APCE_Core_Monthly_Snapshot]
WHERE 1=1
    AND [Der_Diagnosis_ALL]  LIKE '%I350%'
    AND [Der_Procedure_All]  LIKE '%K26%'
    AND YEAR([Admission_Date]) >= 2010
    AND [Der_Financial_Year] <> '2009/10'
    AND [Der_Financial_Year] <> '2026/27'
    AND [Deleted] = 0
    AND [der_age_at_cds_activity_date] <= 112
    AND [der_pseudo_nhs_number] IS NOT NULL   /* can't look back without an ID */
GROUP BY
    [der_pseudo_nhs_number],
    [der_spell_id]

) i
INNER JOIN [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] p  
    ON  p.[der_pseudo_nhs_number] = i.nhs_no
    AND p.[Discharge_Date] >= DATEADD(DAY, -730, i.index_admission_date)
    AND p.[Discharge_Date] <  i.index_admission_date
WHERE
    p.[Deleted] = 0
    AND p.[der_spell_id] <> i.[der_spell_id]   /* never score the index spell itself */

) p

