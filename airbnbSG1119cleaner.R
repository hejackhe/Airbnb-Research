library(tidyverse)
library(lubridate)
library(NCmisc)
df<-read_csv("listings1119.csv")
df <- df[,-c(1:19,21,22)]
df <- df[,-c(3,4,7,9,10,16,17)]
df <- df[,-c(11,14,15,17,18,19,20)]
df <- df[,-c(7,16,25,41,42,47,50)]
df <- df[,-c(52,53,54,56,58,59,63)]
df <- df[,-c(4,6,9,44)]
df[, 23:24][is.na(df[, 23:24])] <- "$0.00" # replace NA in security deposit and cleaning fees to $0
df <- df[,-c(21,22)] # remove weekly and monthly price columns

# Count number of verifications host has performed
df$host_verifications <- as.list(strsplit(df$host_verifications, ","))
df$host_verifications <- as.numeric(lapply(df$host_verifications, length))

# Count number of amenities per listing
df$amenities <- as.list(strsplit(df$amenities, ","))
df$amenities <- as.numeric(lapply(df$amenities, length))
df <- na.omit(df) # dimension is now (4459,34)

# remove $ signs and convert to numeric for prices
df$price <- as.numeric(gsub('[$,]', '', df$price))
df$security_deposit <- as.numeric(gsub('[$,]', '', df$security_deposit))
df$cleaning_fee <- as.numeric(gsub('[$,]', '', df$cleaning_fee))
df$extra_people <- as.numeric(gsub('[$,]', '', df$extra_people))


df <- df %>% 
  mutate(occupancy_est_total = minimum_nights*number_of_reviews,
         occupancy_est_ltm = minimum_nights*number_of_reviews_ltm,
         revenue_est_total = occupancy_est_total*price,
         revenue_est_ltm = occupancy_est_ltm*price,
         # composite ratings from scale 1 - 8
         comp_ratings = (((review_scores_rating+review_scores_accuracy+review_scores_cleanliness
                          +review_scores_checkin+review_scores_communication+review_scores_location
                          +review_scores_value)/160)*7)+1,
         # numbers of days person has been a host
         days_as_host = as.numeric(ymd("2019-11-26")-ymd(host_since)))

# Remove outliers more than 3 sd from mean
df <- df[-which.outlier(df$price, thr = 3, method = "sd", high = TRUE),]
df <- df[-which.outlier(df$minimum_nights, thr = 3, method = "sd", high = TRUE),]
df <- df[-which.outlier(df$occupancy_est_total, thr = 3, method = "sd", high = TRUE),]
df <- df[-which.outlier(df$occupancy_est_ltm, thr = 3, method = "sd", high = TRUE),]
df <- df[-which.outlier(df$bedrooms, thr = 3, method = "sd", high = TRUE),]

quantile(df$revenue_est_total, probs = c(0.10, 0.5, 0.9))

quantiles <- function(x) { 
  if(x < 3015) y <- "Low" # <50%
  if(x >= 3015 & x <= 15120) y <- "Medium" # 50% <= x <= 80%
  if(x > 15120) y <- "High" # >80%
  return(y)
}
df$success <- sapply(df$revenue_est_total,quantiles)
df$success <- factor(df$success, levels=c("Low","Medium","High"))

quantiles_ltm <- function(x) { 
  if(x < 1160) y <- "Low" # <50%
  if(x >= 1160 & x <= 6240) y <- "Medium" # 50% <= x <= 80%
  if(x > 6240) y <- "High" # >80%
  return(y)
}
df$success_ltm <- sapply(df$revenue_est_ltm,quantiles_ltm)
df$success_ltm <- factor(df$success_ltm, levels=c("Low","Medium","High"))

df$host_is_superhost <- as.factor(df$host_is_superhost)
df$instant_bookable <- as.factor(df$instant_bookable)
df$cancellation_policy <- as.factor(df$cancellation_policy)

df <- df[,-(27:36)]
write_csv(df, "airbnbSG1119v2.csv")
