library(tidyverse)
library(haven)

# anes_timeseries_cdf.sav is not provided in the repository and
# can be downloaded from https://electionstudies.org/data-center/ 

anes_full <- read_sav("data/anes_timeseries_cdf.sav")

anes_issues <- read_csv("data/anes_items.csv")

selected_issues <- anes_issues$anes_code %>% 
  str_replace("_.+", "") %>% 
  unique()

anes <- anes_full %>% 
  select(year = VCF0004,
         id = VCF0006a,
         mode = VCF0017,
         panel_st = VCF0016,
         wgt = VCF0009z,
         wgt_alt = VCF0011z,
         state = VCF0901b,
         polviews_full = VCF0803,
         polviews = VCF0804,
         party = VCF0301,
         age = VCF0101,
         gender = VCF0104,
         edu = VCF0110,
         edu_7 = VCF0140a,
         race = VCF0105b,
         polit_info = VCF0050b,
         discuss = VCF0732,
         discuss_lw = VCF0733,
         read_news = VCF9033,
         watch_news = VCF9035,
         one_of(selected_issues),
         VCF9020)

anes <- anes %>% 
  mutate_at(vars(polviews_full, polviews, gender, race, edu, edu_7, mode), as_factor) %>% 
  mutate(gender = fct_recode(gender, NULL = "3. Other (2016)")) %>% 
  mutate_if(is.labelled, zap_labels) %>% 
  mutate_at(vars(starts_with("VCF")), 
            ~ifelse(. %in% c(-9:-7, 0, 8:9), NA, .)) %>% 
  mutate_at(vars(VCF0816, VCF0834, VCF9037, VCF0878, VCF0830, 
                 VCF0877, VCF0823, VCF9043, VCF0867, VCF0876,
                 VCF9231, VCF9236, VCF9238),
            ~ifelse(. == 1, 1, 0)) %>% 
  mutate_at(vars(VCF0853, VCF0854, VCF9040),
             ~ case_when(
              . %in% 1:2 ~ 1, 
              . %in% 4:5 ~ 0,
              TRUE ~ NA_real_)) %>% 
  mutate(state = ifelse(state %in% c(0, 99), NA, state),
         VCF0829 = ifelse(VCF0829 == 2, 1, 0),
         VCF0814 = ifelse(VCF0814 == 3, 1, 0),
         VCF0838_str = ifelse(VCF0838 > 1, 1, 0),
         VCF0838_mid = ifelse(VCF0838 > 2, 1, 0),
         VCF0838_lib = ifelse(VCF0838 > 3, 1, 0),
         VCF9019 = ifelse(VCF9019 == 1|(VCF9020 == VCF9019 & VCF9019 == 2),
                       1, 
                       0), 
         VCF0616 = case_when(
           VCF0616 == 1 ~ 1, 
           VCF0616 == 2 ~ 0,
           VCF0616 == 3 ~ NA_real_
         ), 
         VCF9230 = case_when(
           VCF9230 == 1 ~ 1, 
           VCF9230 == 3 ~ 0,
           VCF9230 == 2 ~ NA_real_
         ), 
         VCF9232 = case_when(
           VCF9232 == 1 ~ 1, 
           VCF9232 == 3 ~ 0,
           VCF9232 == 2 ~ NA_real_
         ), 
         VCF0879 = ifelse(VCF0879 < 3, 1, 0),
         VCF0844 = ifelse(VCF0844 < 4, 1, 0))


anes_long <- anes %>% 
  select(-VCF0838, -VCF9020) %>% 
  gather(anes_code, opinion, starts_with("VCF")) %>% 
  drop_na(opinion)


anes_long <- anes_long %>% 
  mutate(wgt = ifelse(anes_code %in% c("VCF0814", "VCF0816"), wgt_alt, wgt)) %>% 
  select(-wgt_alt)

anes_long <- anes_long %>% 
  mutate(polviews_full = fct_recode(polviews_full,
                                    NULL = "9. DK; haven't thought much about it",
                                    NULL = "0. NA; no Post IW; form III,IV (1972); R not"),
         polviews = fct_recode(polviews,
                               NULL = "0. NA; no Post IW; form III,IV (1972)",
                               NULL = "9. DK; haven't thought much about it", 
                               Liberal = "1. Liberal", 
                               Moderate = "2. Moderate, middle of the road",
                               Conservative = "3. Conservative"),
         polviews = fct_rev(polviews),
         race = fct_recode(race,
                           white = "1. White non-Hispanic",
                           black = "2. Black non-Hispanic",
                           other = "3. Hispanic",
                           other = "4. Other or multiple races, non-Hispanic"),
         year_r = (year - 2000)/10, 
         discuss = 5 - discuss) 

write_rds(anes_long, "data/cleaned-anes.rds", compress = "gz")
