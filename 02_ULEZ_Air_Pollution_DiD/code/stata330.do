
clear all
set python_exec "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3"

python:
import pandas as pd
import csv

file_name = "AirQualityDataStatistics.csv"
output_name = "clean_by_python.csv"

try:
    
    rows = []
    with open(file_name, 'r', encoding='utf-8', errors='ignore') as f:
        reader = csv.reader(f)
        for row in reader:
            rows.append(row)

    
    site_names = rows[3][1::2]
    site_types = rows[6][1::2]
    local_auths = rows[9][1::2]

    
    all_records = []
    for r in range(11, len(rows)):
        current_row = rows[r]
        if not current_row or len(current_row) < 2: continue
        
        date_val = current_row[0]
        
        for i in range(len(site_names)):
            val_idx = 1 + i*2
            if val_idx < len(current_row):
                val = current_row[val_idx]
                
                all_records.append({
                    'date': date_val,
                    'no2_ugm3': val,
                    'site_name': site_names[i],
                    'site_type': site_types[i],
                    'local_authority': local_auths[i]
                })

    
    df = pd.DataFrame(all_records)

    
    df['no2_ugm3'] = df['no2_ugm3'].str.extract('(\d+\.?\d*)').astype(float)
    
  
    df['date'] = pd.to_datetime(df['date'], errors='coerce')
    df = df.dropna(subset=['date', 'no2_ugm3'])

    
    df.to_csv(output_name, index=False)
    print("Success")

except Exception as e:
    print(f"Error")
end


capture confirm file "clean_by_python.csv"
if _rc == 0 {
    import delimited "clean_by_python.csv", clear
    gen s_date = date(date, "YMD")
    format s_date %td
    drop date
    rename s_date date
    
    order date site_name site_type local_authority no2_ugm3
    sort date site_name
    list in 1/20
    di "Success"
}
else {
    di as error "Failed"
}

cap confirm numeric variable date
if _rc {
    gen date_numeric = date(date, "YMD")
    format date_numeric %td
}
else {
    gen date_numeric = date
}

*Define Post Variable (2023-08-29) 
gen byte post = (date_numeric >= td(29aug2023))
label define postlbl 0 "Before Expansion" 1 "After Expansion"
label values post postlbl

*Define Treatment Group (London)
gen byte treat = 0
gen temp_la = lower(trim(local_authority))

local ldn1 "barking barnet bexley brent bromley camden croydon ealing enfield"
local ldn2 "greenwich hackney hammersmith fulham haringey harrow havering"
local ldn3 "hillingdon hounslow islington kensington chelsea kingston"
local ldn4 "lambeth lewisham merton newham redbridge richmond"
local ldn5 "southwark sutton tower hamlets waltham wandsworth westminster"

foreach list in ldn1 ldn2 ldn3 ldn4 ldn5 {
    foreach b in ``list'' {
        quietly replace treat = 1 if strpos(temp_la, "`b'") > 0
    }
}

replace treat = 1 if strpos(temp_la, "london") > 0
replace treat = 0 if strpos(temp_la, "hull") > 0

label define treatlbl 0 "Control" 1 "London"
label values treat treatlbl

* Generate Panel ID 
encode site_name, gen(station_id)

* Final Data Verification
di "Review: London Boroughs (Treated)"
tab local_authority if treat == 1

di "Review: Outside London (Control)"
tab local_authority if treat == 0

drop temp_la

* Data Quality Check and Summary Statistics
*------------------------------------------------------------------------------
* Remove observations with missing NO2 values to ensure a clean sample
drop if missing(no2_ugm3)

* Declare the dataset as a panel (Station ID and Numeric Date)
xtset station_id date_numeric

count

label var no2_ugm3 "NO2 concentration (ug/m3)"
label var treat "Treated station"
label var post "Post-policy period"

tabstat no2_ugm3 treat post, statistics(mean sd min max n) columns(statistics)

cap ssc install estout

estpost summarize no2_ugm3 treat post, detail

esttab using "Summary_Table.tex", ///
    cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0)) count(fmt(0))") ///
    label replace nonumber title("Summary Statistics")

* Step-wise DID and Placebo Test
*------------------------------------------------------------------------------

cap drop placebo_post
cap drop pre_policy_sample

* Step-wise DID Regression

* Model 1: Simple OLS 
eststo m1: reg no2_ugm3 i.treat##i.post, vce(cluster station_id)

* Model 2: Adding Time Fixed Effects
eststo m2: reghdfe no2_ugm3 i.treat##i.post, absorb(date) vce(cluster station_id)

* Model 3: Full Baseline (Station + Time Fixed Effects)
eststo m3: reghdfe no2_ugm3 i.treat##i.post, absorb(station_id date) vce(cluster station_id)

*  Placebo Test
gen placebo_post = (date_numeric >= td(29aug2022) & date_numeric < td(29aug2023)) 

gen pre_policy_sample = (date_numeric < td(29aug2023)) 

eststo m4: reghdfe no2_ugm3 i.treat##i.placebo_post if pre_policy_sample == 1, ///
    absorb(station_id date_numeric) vce(cluster station_id)

esttab m1 m2 m3 m4 using "results_table.tex", replace ///
    b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) ///
    booktabs alignment(c) ///
    keep(1.treat#1.post 1.treat#1.placebo_post) ///
    title("Impact of ULEZ Expansion on NO2 Concentrations") ///
    mtitle("OLS" "Time FE" "Full FE" "Placebo") ///
    addnotes("Note: Columns 2-4 include Fixed Effects.")
	

*Event Study and Dynamic Effects (Figure4)
*------------------------------------------------------------------------------
clear all
set more off
capture matrix drop resmat 

import delimited "clean_by_python.csv", clear 

gen date_n = date(date, "YMD")
gen treat = 0
foreach area in "Camden" "Westminster" "Southwark" "Tower Hamlets" "Haringey" "Bexley" "Greenwich" "Hillingdon" "Kensington" {
    replace treat = 1 if local_authority == "`area'"
}
gen weeks = floor((date_n - td(29aug2023)) / 7)
keep if weeks >= -8 & weeks <= 8
gen t_idx = weeks + 9

tempname resmat
matrix `resmat' = J(17, 3, .) 
local row = 1
forvalues w = -8/8 {
    if `w' == -1 {
        matrix `resmat'[`row', 1] = `w'
        matrix `resmat'[`row', 2] = 0
        matrix `resmat'[`row', 3] = 0
    }
    else {
        tempvar temp_int
        gen `temp_int' = treat * (weeks == `w')
        quietly reg no2_ugm3 treat i.t_idx `temp_int', vce(robust)
        matrix `resmat'[`row', 1] = `w'
        matrix `resmat'[`row', 2] = _b[`temp_int']
        matrix `resmat'[`row', 3] = _se[`temp_int']
    }
    local row = `row' + 1
}


drop _all
svmat `resmat', names(col)
rename (c1 c2 c3) (week coef stderr)
gen ci_hi = coef + 1.96 * stderr
gen ci_lo = coef - 1.96 * stderr


twoway ///
    (scatteri . . . ., recast(line) lpattern(dash) lcolor(red) lwidth(medium)) ///  
    (rcap ci_hi ci_lo week, lcolor(gs10) lwidth(medium)) ///                       
    (connected coef week, lcolor(navy) mcolor(white) mlcolor(navy) msize(small) lwidth(medium)), /// 
    yline(0, lcolor(black) lwidth(thin)) ///
    xline(-0.5, lcolor(red) lpattern(dash) lwidth(medium)) ///
    ylabel(-10(2.5)10, angle(0) nogrid) /// 
    xlabel(-8(1)8, nogrid) ///              
    title("Dynamic Impact of ULEZ Expansion (±8 Weeks)", size(medium)) ///
    ytitle("Change in NO2 Concentration (ug/m3)") ///
    xtitle("Weeks Relative to Expansion (August 29, 2023)") ///
    graphregion(color(white)) ///
    legend(order(1 "Policy Expansion Date" 3 "Weekly Estimate (95% CI)") pos(6) region(lstyle(none)))


graph export "Figure4.pdf", replace

* ULEZ Placebo Test (Figure5)
*------------------------------------------------------------------------------

clear all
set more off

import delimited "clean_by_python.csv", clear 
gen date_n = date(date, "YMD")
gen weeks = floor((date_n - td(29aug2023)) / 7)
keep if weeks >= -8 & weeks <= 8
encode local_authority, gen(area_id)   
gen week_idx = weeks + 9               
gen post = (weeks >= 0)


gen real_treat = 0
local areas `" "Camden" "Westminster" "Southwark" "Tower Hamlets" "Haringey" "Bexley" "Greenwich" "Hillingdon" "Kensington" "'
foreach a in `areas' {
    replace real_treat = 1 if local_authority == "`a'"
}
gen real_did = real_treat * post

quietly reg no2_ugm3 i.area_id i.week_idx real_did, vce(robust)


capture program drop placebo_sim
program placebo_sim, rclass
    preserve
    tempvar area_rand rank fake_treat fake_did
    bysort area_id: gen `area_rand' = runiform() if _n==1
    bysort area_id: replace `area_rand' = `area_rand'[1]
    egen `rank' = group(`area_rand')
    gen `fake_treat' = (`rank' <= 9)
    gen `fake_did' = `fake_treat' * post
    quietly reg no2_ugm3 i.area_id i.week_idx `fake_did', vce(robust)
    return scalar b_did = _b[`fake_did']
    return scalar p_did = 2 * ttail(e(df_r), abs(_b[`fake_did']/_se[`fake_did']))
    restore
end
set seed 123456
simulate coeff = r(b_did) pvalue = r(p_did), reps(500): placebo_sim

local true_beta_val = 0.116 

twoway ///
    (kdensity coeff, lcolor(navy) lwidth(medium) yaxis(1)) ///           
    (scatter pvalue coeff, msymbol(oh) msize(vsmall) mcolor(gs12) yaxis(2)), /// 
    xline(`true_beta_val', lcolor(red) lpattern(dash) lwidth(medium)) ///  
    xline(0, lcolor(black) lwidth(thin)) ///                             
    yline(0.05, axis(2) lcolor(red) lpattern(shortdash)) ///             
    title("Placebo Test: 500 Permutations", size(medium)) ///
    xtitle("Estimated Coefficients") ///
    ytitle("Kernel Density", axis(1)) ///
    ytitle("p-value", axis(2)) ///
    xlabel(-5(1)5) ///                                                   
    ylabel(0(0.2)1, axis(2)) ///                                         
    legend(order(1 "Kernel Density" 2 "p-values") pos(6) region(lstyle(none))) ///
    graphregion(color(white)) ///
    note("Note: The red dashed vertical line indicates the actual estimate (0.116) from Table 2.", size(vsmall))

graph export "Figure5.pdf", replace

* Identification Strategy (Figure 1)
* ------------------------------------------------------------------------------
clear all
set more off

import delimited "clean_by_python.csv", clear 

describe

capture confirm numeric variable date
if _rc {
    gen date2 = daily(date, "YMD")
    format date2 %td
    drop date
    rename date2 date
}

gen treat = inlist(local_authority, ///
    "Camden","Westminster","Kensington","Greenwich","Haringey","Hillingdon", ///
    "Tower Hamlets","Southwark","Bexley")

gen mdate = mofd(date)
format mdate %tm

preserve
collapse (mean) no2_ugm3, by(mdate treat)

local pm = tm(2023m8)


summ no2_ugm3
local ymax = r(max)


twoway ///
 (line no2_ugm3 mdate if treat==1, lcolor(black) lwidth(medthick)) ///
 (line no2_ugm3 mdate if treat==0, lcolor(black) lpattern(dash) lwidth(medthick)) ///
 (scatter no2_ugm3 mdate if treat==1, msymbol(O)  mcolor(none) mlcolor(black) msize(small)) ///
 (scatter no2_ugm3 mdate if treat==0, msymbol(Oh) mcolor(none) mlcolor(black) msize(small)), ///
 legend(order(1 "Treated" 2 "Control") ring(0) pos(11)) ///
 xline(`pm', lcolor(black) lwidth(medthick)) ///
 text(`=0.98*`ymax'' `pm' "ULEZ expansion", place(e) size(small)) ///
 xtitle("Month") ytitle("Mean NO2 (ug/m3)") ///
 title("NO2 Trends: Treated vs Control") ///
 graphregion(color(white)) plotregion(color(white))

graph export "Figure1.pdf", replace

restore
