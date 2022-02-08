# Raw GSS data used in this script is not provided in the repository 
# and has to be downloaded from http://gss.norc.org/get-the-data/spss

library(tidyverse)
library(haven)

# source("rscripts/auxiliary_functions.R")

gss_full <- read_sav("data/GSS7218_R2.sav")
gss_items <- read_csv("data/gss-items-98v.csv")

gss <- gss_full %>%
  rename_all(tolower) %>% 
  filter(year %in% c(1985, 1987, 2000, 2014)) %>% 
  # combine two different wordings of the same issues
  mutate(hubbywk1 = coalesce(hubbywk1, hubbywrk),
         twoincs1 = coalesce(twoincs1, twoincs)) %>% 
  select(id, year, wtssall, oversamp, sample, 
         polviews, wordsum, educ, sex, age, race, news,
         talkpol, talkpol1, talkpol2, talkpol3, discpol, poldisgn,
         one_of(gss_items$issue))

gss <- gss %>% 
  mutate_at(vars(id, wtssall, oversamp, age, educ, year, polviews, wordsum,
                 talkpol, talkpol1, talkpol2, talkpol3, discpol, poldisgn), 
            zap_labels) %>% 
  mutate_if(is.labelled, ~fct_relabel(as_factor(.), tolower)) %>% 
  mutate(# rescale polviews bw 0 (Extremely conservative) and 6 (Extremely liberal),
         polviews_cont = 7 - polviews,
         polviews = cut(polviews, c(0, 3, 4, 7), 
                        labels = c("Liberal", "Moderate", "Conservative")),
         polviews = fct_rev(polviews),
         time = (year - 1972)/10,
         wgt = wtssall*oversamp)

gss <- gss %>% 
  mutate(talkpol_close = pmap_dbl(list(talkpol1, talkpol2, talkpol3), min)) %>% 
  mutate_at(vars(talkpol, talkpol_close, discpol),
            ~ max(., na.rm = TRUE) - .)


# recode neutral levels that are not in the middle of factor levels to NA
gss <- gss %>% 
  mutate(homosex = fct_recode(homosex, NULL = "other"),
         racchng = fct_recode(racchng, NULL = "wdnt belong"),
         racopen = fct_recode(racopen, NULL = "neither"),
         sexeduc = fct_recode(sexeduc, NULL = "depends")) 

#Excluding years where racial questions were asked of non-blacks only 
for(i in c("racmar","racpush", "racopen","racdin")) {
  gss[gss$year %in% 1972:1977,i] <- NA
}

gss <- gss %>% droplevels()

# recode issues to binary with 1 indicating agreement to the default position 
# if relevant, the neutral middle category is omited

dichotomize <- function(var){
  # for already binary items recode "yes" (1st level) to 1 and "no" to 0
  if(nlevels(var) == 2){
    return(2 - as.numeric(var))
  }
  # if item has even number of levels recode first half of levels as 1, and second as 0
  if(nlevels(var)%%2 == 0){
    return(ifelse(as.numeric(var) > nlevels(var)/2, 0, 1))
  } else {
    # if item has odd number of levels recode the middle level to NA, first half of levels as 1, and second as 0
    middle <- ceiling(nlevels(var)/2)
    return(case_when(
      as.numeric(var) == middle ~ NA_real_,
      as.numeric(var) < middle ~ 1,
      as.numeric(var) > middle ~ 0,
      TRUE ~ NA_real_)
    )
  }
}

gss_bin <- gss %>% 
  mutate(pornlaw = ifelse(pornlaw == "legal", 0 , 1)) %>% 
  mutate_at(gss_items$issue[gss_items$issue != "pornlaw"], dichotomize)

gss_long <- gss_bin %>%
  gather(issue, opinion, one_of(gss_issues$issue))  %>% 
  drop_na(opinion) 

write_rds(gss_long, "data/cleaned-gss.rds", compress = "gz")



