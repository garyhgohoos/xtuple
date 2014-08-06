-- 4.4.1 and 4.5.0 fix - synchronize flcol_report_id
do $$
begin
if fetchMetricText('ServerVersion') < '4.6.0' then

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonth'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('Month', 'Current')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('Month, YTD', 'Current Period, YTD')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='Month, QTD'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='QTD'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('Current, Budget', 'Month, Budget')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarterBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='QTD, Budget'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorMonth'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('Current, Prior Period', 'Current, Prior Month', 'Current, Year Ago', 'Month, Prior Month', 'Month, Prior Year Month')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportQuarterPriorQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('QTD, Prior Year Quarter', 'Current Quarter, Prior Year Quarter', 'QTD, Prior Quarter')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='YTD'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYearBudget'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='YTD, Budget'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportYearPriorYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_name IN ('YTD, Prior Year YTD', 'YTD, Prior Full Year')
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorYear'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='Current, Prior Year'
;

update flcol set flcol_report_id = (select report_id from report
                                    where report_name = 'FinancialReportMonthPriorQuarter'
                                    order by report_grade desc
                                    limit 1)
where flcol_name='Current, Prior Quarter'
;

end if;
end$$;