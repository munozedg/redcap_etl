# 00_main_redcap_etl.R

# required packages
library(here)          # relative reference to project sub-folders etc
library(REDCapR)       # many useful REDCap API functions
library(tidyREDCap)    # just to get better/tidy data frames from REDCap
library(stringi)       # handling strings
library(lubridate)     # handling dates
library(rio)           # export data frames to SAS, Excel, etc
rio::install_formats() # required by rio package



# function tm_stamp for filenames
tm_stamp <- function(filename, extension) {
  paste0(
    stringi::stri_datetime_format(lubridate::now(), format = "yyyyMMdd-HHmm"),
    "-",
    filename,
    ".",
    extension
  )
}



# load your REDCap credentials from the local tokens folder
path_cred <- "tokens/redcap_tokens.csv"
if (file.exists(path_cred)) {
  redcap_creds <-
    REDCapR::retrieve_credential_local(
      path_credential = path_cred,
      project_id = 8349
    )
} else {
  stop("Please configure your REDCap API key for the project\n")
}



# export all the data from the REDCap project and
# produce one R data frame for each instrument
tidyREDCap::import_instruments(
  url = redcap_creds$redcap_uri,
  token = redcap_creds$token 
)


# Note: If you are doing your analyses in R (not SAS), you can stop here


# Example 1 - SAS 
SAS_demog_t1 <- demographic_ses_and_medical_factors_domain
names(SAS_demog_t1) <- substr(names(SAS_demog_t1), 1, 32)
SAS_demog_t1 <- SAS_demog_t1 %>% janitor::clean_names(case="snake")

SAS_demog_t1_fn <<- here("data", tm_stamp("DemographicsT1","sas7bdat"))

haven::write_sas(
  data = SAS_demog_t1 ,
  path = SAS_demog_t1_fn
)

SAS_demog_t1_test <- haven::read_sas(SAS_demog_t1_fn)
identical(SAS_demog_t1, SAS_demog_t1_test)
janitor::compare_df_cols(SAS_demog_t1, SAS_demog_t1_test, return = "mismatch")



# Example 2 - SAS
# here is an example exporting data from a REDCap report
# then exporting the results into a SAS data set
SAS_data <- REDCapR::redcap_report(
    redcap_uri = redcap_creds$redcap_uri,
    token      = redcap_creds$token,
    report_id  = 12715L,
    raw_or_label = "label",
    raw_or_label_headers = "raw"
  )$data

names(SAS_data) <- substr(names(SAS_data), 1, 32)
SAS_data <- SAS_data %>% janitor::clean_names(case="snake")

SAS_data_fn <<- here("data", tm_stamp("Avz-Screening","sas7bdat"))

haven::write_sas(
  data = SAS_data,
  path = SAS_data_fn
)

SAS_data_test <- haven::read_sas(SAS_data_fn)
identical(SAS_data, SAS_data_test)
janitor::compare_df_cols(SAS_data, SAS_data_test, return = "mismatch")
