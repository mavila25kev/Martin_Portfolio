
/* dropping slug, city, and control columns, slug is the non cleaned verision of the univeristy names
Dropping city because dditional table are on a state level so need to look at the specific city, 
Dropping control because we are looking at univerities as a whole and not classifying them into private/public
*/
ALTER TABLE collegesdata 
	DROP COLUMN slug,
	DROP COLUMN city,
    DROP COLUMN control;

/* Dropping several columns here, type distinguishes between private/public which will not be looking at,
We filtered for 4 year schools only already in Excel so we will drop this now,
Room_and_board, in_state_tuition and out_of_state_tuition all add up to the columns we are keeping with the total for each so we do not need these columns
*/
ALTER TABLE tuition_cost 
	DROP COLUMN type,
	DROP COLUMN degree_length,
    DROP COLUMN room_and_board,
    DROP COLUMN in_state_tuition,
	DROP COLUMN out_of_state_tuition;

-- cte to find average of salary by state for early and mid career
with average_salary_by_state as
(
	select 
		replace(state_name, '-', ' ') as state_name_clean,
        round(avg(early_career_pay),0) as avg_early_career_pay,
		round(avg(mid_career_pay),0) as avg_mid_career_pay
	from salary_potential
    group by state_name_clean
)
 -- cte to find average of tutiion by state for in-state and out of state
, average_tuition_by_state as
(
	select 
		state,
        state_code,
        round(avg(in_state_total*4),0) as avg_in_state_total,
		round(avg(out_of_state_total*4),0) as avg_out_of_state_total
	from tuition_cost
    where state not like 'NA'
    group by state, state_code
)
-- joining two tables to show avg tuition and salary
, salary_and_tuition_by_state as
( select
	ats.state as state, 
	ats.state_code as state_code, 
    av.avg_early_career_pay as avg_earnings_year_0_10_by_state,
    av.avg_mid_career_pay as avg_earnings_year_11_20_by_state,
    ats.avg_in_state_total as avg_state_cost_of_attendance_resident_usd,
    ats.avg_out_of_state_total as avg_state_cost_of_attendance_nonresident_usd
from average_tuition_by_state as ats
inner join average_salary_by_state as av on ats.state = av.state_name_clean
order by ats.state, ats.state_code
)

-- joining our colleges data with each colleges state statistics
,  colleges_final as (
select 
	cd.name,
    cd.state_name,
    cd.npv_30yr_resident_usd,
    cd.npv_30yr_nonresident_usd,
    cd.total_cost_of_attendance_usd,
    cd.total_cost_of_attendance_nonresident_usd,
    sts.avg_state_cost_of_attendance_resident_usd,
    sts.avg_state_cost_of_attendance_nonresident_usd,
    cd.median_earnings_10yr_usd,
    sts.avg_earnings_year_0_10_by_state,
    sts.avg_earnings_year_11_20_by_state,
    cd.breakeven_age,
    cd.freopp_program_coverage
from collegesdata as cd
left join salary_and_tuition_by_state as sts on cd.state = sts.state_code
)


select 
	name,
    state_name,
    npv_30yr_resident_usd,
    npv_30yr_nonresident_usd,
    median_earnings_10yr_usd,
    avg_earnings_year_0_10_by_state,
    median_earnings_10yr_usd - avg_earnings_year_0_10_by_state as difference_in_salary,
    breakeven_age,
    freopp_program_coverage
from colleges_final
where (npv_30yr_resident_usd > 500000) and (avg_earnings_year_0_10_by_state + 30000 < median_earnings_10yr_usd) and (median_earnings_10yr_usd >74000)
order by npv_30yr_resident_usd desc, difference_in_salary desc, breakeven_age desc
;

