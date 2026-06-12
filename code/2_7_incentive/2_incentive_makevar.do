	
    use "$temp/incentive_record_stand_clean" , clear

    keep if treatment == 0
        
    collapse 	(mean) amount_payed_mean=amount_payed amount_allotted_mean=amount_allotted ///
                (sum) amount_payed_sum=amount_payed amount_allotted_sum = amount_allotted, by(pid)
            
    
    foreach i of varlist amount_payed_mean-amount_payed_sum {
        replace `i' = 0 if mi(`i') // 4 instances of is_paid_mean with all missing
    }
    
    more_or_less amount_payed_mean 	, prefix(higher) varlab("Higher Incentive Paid")
    more_or_less amount_payed_sum 	, prefix(higher) 	varlab("Higher Incentive Paid")
    more_or_less amount_allotted_mean 	, prefix(higher) 	varlab("Higher Incentive Allocated") vallab(0 "Lower than Median" 1 "Higher than Median")
    more_or_less amount_payed_sum 	, prefix(higher) 	varlab("Higher Incentive Paid")
    more_or_less amount_allotted_mean 	, prefix(higher) 	varlab("Higher Incentive Allocated") vallab(0 "Lower than Median" 1 "Higher than Median")
    more_or_less amount_allotted_sum 	, prefix(higher) 	varlab("Higher Incentive Allocated")
    
    keep pid higher* amount_payed_mean amount_allotted_mean amount_payed_sum amount_allotted_sum

    save "$temp/control_payment_higher_lower.dta" , replace