/*
# README
List number of ablations for AFib by site, by year. Used in R workflow
to identify Electrophysiology (EP) centres. 
*/


SELECT
  s.Der_Financial_Year                AS fyear,
  s.der_provider_site_code,
  u.site_name,
  u.trust_name,
  COUNT(*)                            AS n_abl
FROM [Reporting_MESH_APC].[APCS_Core_Monthly_Snapshot] s
    LEFT JOIN (
        SELECT [site_code],
               [site_name],
               [trust_name]
        FROM Reporting_UKHD_ODS.Provider_Site
    ) u 
    ON s.der_provider_site_code = u.site_code
    WHERE (
           Der_Procedure_All LIKE '%K621%'
           )
      AND Der_Diagnosis_All LIKE '%I48%'
GROUP BY 
  s.Der_Financial_Year,
  s.der_provider_site_code,
  u.site_name,
  u.trust_name
  