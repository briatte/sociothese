## let's go

rm(list = ls())
options(verbose = TRUE)

#
# quick example (needs two hours to run)
#
dir.create("figs_relig")

keyword = "relig" # subset corpus to grep match
training = FALSE  # subset to a smaller training set
k = 50            # number of topics to model
SEED = 3740       # random seed for LDA estimation

source("1.estimate.r")

threshold = 0.002 # threshold for network plot

source("2.visualize.r")

n = 100           # diagnose topics from 1 to n

source("3.diagnose.r")
source("4.validate.r") # 10-fold cross-validation

copy = dir(pattern = "figs_")
file.copy(copy, paste0("figs_", keyword, "/", copy), overwrite = TRUE)

#
# full sample (needs a full day to run)
#
dir.create("figs_full")

keyword = ""
k = 100 # topics
n = 200 # diagnostics

source("1.estimate.r")
source("2.visualize.r")
source("3.diagnose.r")
source("4.validate.r") # 10-fold cross-validation

file.copy(copy, paste0("figs_full/", copy), overwrite = TRUE)

#
# clean up
#

file.remove(dir(pattern = "fig_|Rplot"))
clear(list = ls())

## kthxbye
