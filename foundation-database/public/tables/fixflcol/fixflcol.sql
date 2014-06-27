-- 4.4.1 and 4.5.0 fix - synchronize flcol_report_id
update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReport'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=285
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonth'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=375
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=376
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthDbCr'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=387
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorMonth'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=377
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=386
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=378
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=379
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=374
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=380
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarterBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=381
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarterPriorQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=382
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=383
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYearBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=384
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYearPriorYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=385
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialTrend'
                                    order by report_grade desc
                                    limit 1)
where flcol_report_id=388
and flcol_id in (
  select flcol_id
  from flcol left join report on flcol_report_id = report_id
  where report_id is null)
;

