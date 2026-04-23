bys pid: egen num_launchset = nvals(launchset)
br stand pid date interviewer batch launchset if num_launchset > 1
sort pid date


br stand pid date interviewer batch launchset if pid == 655


keep if pid == 102
gen date_diff = date - date[_n - 1]



keep if pid == 1834

br pid date phase week_in work_recall_mode work_recall_mode_any1 recall_length grid_recall_anyinwk work1_wkly2 work1_wkly3