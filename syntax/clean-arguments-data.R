library(tidyverse)


# ANES issues -------------------------------------------------------------

anes_full_arguments <- read_csv("data/anes-argument-data.csv")

sample <- anes_full_arguments %>% 
  distinct(batch, id, mturk_prescreening, sex, age)

write_rds(sample, "data/anes-arguments-sample.rds")


mf_measures <- anes_full_arguments %>%
  filter(mf %in% c("harm", "fair", "lib", "viol")) %>% 
  group_by(anes_code, issue, type) %>% 
  summarise(mean = mean(value, na.rm = TRUE)) %>% 
  spread(type, mean) %>% 
  transmute(hvfl = pro - against) %>% 
  ungroup()

# add standard errors

mf_measures_se <- anes_full_arguments %>% 
  filter(mf %in% c("harm", "fair", "lib", "viol")) %>%
  group_by(anes_code, id, type) %>% 
  summarise(mean = mean(value, na.rm = TRUE)) %>% 
  spread(type, mean) %>% 
  transmute(hvfl_individual = pro - against) %>% 
  group_by(anes_code) %>% 
  summarise(n = n(),
            hvfl_sd = sd(hvfl_individual, na.rm = TRUE)) %>% 
  mutate(hvfl_se = hvfl_sd/sqrt(n)) 


mf_measures <- left_join(mf_measures, mf_measures_se) %>% 
  ungroup()

write_rds(mf_measures, "data/anes-mf-measures.rds")

# GSS issues --------------------------------------------------------------

gss_full_arguments <- read_csv("data/gss-argument-data.csv")

mf_data <- gss_full_arguments %>%
  filter(mf %in% c("Harm", "Fairness", "Liberty", "Violence")) %>% 
  group_by(issue, type) %>% 
  summarise(mean = mean(value, na.rm = TRUE)) %>% 
  spread(type, mean) %>% 
  transmute(hvfl = pro - against) %>% 
  ungroup()

write_rds(mf_data, "data/gss-mf-measures.rds")
