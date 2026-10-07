-- ============================================================
-- SOCIAL MEDIA ANALYTICS PROJECT
-- SQL Analysis Script
-- ============================================================
-- Purpose:
--   1. Create the database and raw table
--   2. Perform data quality checks
--   3. Create an analysis-ready clean table
--   4. Perform business-focused SQL analysis
-- ============================================================

CREATE DATABASE IF NOT EXISTS social_media_analytics;
USE social_media_analytics;

CREATE TABLE IF NOT EXISTS social_media_raw (
    Post_ID VARCHAR(50),
    Timestamp DATETIME,
    Platform VARCHAR(50),
    Content_Type VARCHAR(50),
    Category VARCHAR(100),
    Likes INT,
    Comments INT,
    Shares INT,
    Views INT,
    Saves INT,
    Follower_Count INT,
    Engagement_Rate DECIMAL(10,4),
    Hour_of_Day INT,
    Day_of_Week VARCHAR(20),
    Hashtag_Count INT,
    Content_Length INT,
    Sentiment VARCHAR(20),
    Influencer_Tier VARCHAR(20),
    Has_Media VARCHAR(10),
    Is_Verified VARCHAR(10)
);

-- Step 1 Data Quality Audit

-- Check Total Number of Records
SELECT COUNT(*) as total_records
FROM social_media_raw;

-- Check Table Structure
DESCRIBE social_media_raw;

-- View Sample Records
SELECT * 
FROM social_media_raw
LIMIT 10 ;

-- Check Missing Values in All Columns
SELECT
    SUM(Post_ID IS NULL) AS missing_post_id,
    SUM(Timestamp IS NULL) AS missing_timestamp,
    SUM(Platform IS NULL) AS missing_platform,
    SUM(Content_Type IS NULL) AS missing_content_type,
    SUM(Category IS NULL) AS missing_category,
    SUM(Likes IS NULL) AS missing_likes,
    SUM(Comments IS NULL) AS missing_comments,
    SUM(Shares IS NULL) AS missing_shares,
    SUM(Views IS NULL) AS missing_views,
    SUM(Saves IS NULL) AS missing_saves,
    SUM(Follower_Count IS NULL) AS missing_followers,
    SUM(Engagement_Rate IS NULL) AS missing_engagement_rate,
    SUM(Hour_of_Day IS NULL) AS missing_hour,
    SUM(Day_of_Week IS NULL) AS missing_day,
    SUM(Hashtag_Count IS NULL) AS missing_hashtags,
    SUM(Content_Length IS NULL) AS missing_content_length,
    SUM(Sentiment IS NULL) AS missing_sentiment,
    SUM(Influencer_Tier IS NULL) AS missing_influencer_tier,
    SUM(Has_Media IS NULL) AS missing_media,
    SUM(Is_Verified IS NULL) AS missing_verified
FROM social_media_raw;

-- Check for Duplicate Post IDs
SELECT Post_ID, COUNT(*) AS duplicate_count
FROM social_media_raw
GROUP BY Post_ID
HAVING COUNT(*) > 1;

-- Check Date Range
SELECT
    MIN(Timestamp) AS earliest_date,
    MAX(Timestamp) AS latest_date
FROM social_media_raw;

-- Check Unique Platform Values
SELECT DISTINCT Platform
FROM social_media_raw;

-- Check Unique Content Types
SELECT DISTINCT Content_Type
FROM social_media_raw;

-- Check Unique Category Values
SELECT DISTINCT Category
FROM social_media_raw;

-- Check Negative Engagement Values
SELECT COUNT(*) AS invalid_records
FROM social_media_raw
WHERE Likes < 0
   OR Comments < 0
   OR Shares < 0
   OR Views < 0
   OR Saves < 0
   OR Follower_Count < 0;
   
   -- Calculate Engagement Rate for One Record
SELECT
    Post_ID,
    Likes,
    Comments,
    Shares,
    Follower_Count,
    Engagement_Rate,
    ROUND(
        (Likes + Comments + Shares) / Follower_Count * 100,
        4
    ) AS calculated_rate
FROM social_media_raw
LIMIT 1;

-- Check Engagement Rate Differences
SELECT COUNT(*) AS different_rates
FROM social_media_raw
WHERE ABS(
    Engagement_Rate -
    ((Likes + Comments + Shares) / NULLIF(Follower_Count, 0) * 100)
) > 0.01;

-- Engagement Rate values are consistent with the underlying engagement metrics within an acceptable rounding tolerance.

-- Check Invalid Hours
SELECT COUNT(*) AS invalid_hours
FROM social_media_raw
WHERE Hour_of_Day < 0
   OR Hour_of_Day > 23;
   
-- Check Invalid Hashtag Counts
SELECT COUNT(*) AS invalid_hashtags
FROM social_media_raw
WHERE Hashtag_Count < 0;

-- Check Invalid Content Length
SELECT COUNT(*) AS invalid_content_length
FROM social_media_raw
WHERE Content_Length < 0;

-- Check Valid Day Names
SELECT DISTINCT Day_of_Week
FROM social_media_raw;

-- Check Unique Sentiment Values
SELECT DISTINCT Sentiment
FROM social_media_raw;

-- Check Unique Influencer Tiers
SELECT DISTINCT Influencer_Tier
FROM social_media_raw;

-- Check Has_Media Values
SELECT DISTINCT Has_Media
FROM social_media_raw;

-- Check Is_Verified Values
SELECT DISTINCT Is_Verified
FROM social_media_raw;

-- Check Timestamp vs Hour_of_Day
SELECT COUNT(*) AS mismatched_hours
FROM social_media_raw
WHERE HOUR(Timestamp) <> Hour_of_Day;

-- Check Timestamp vs Day_of_Week
SELECT COUNT(*) AS mismatched_days
FROM social_media_raw
WHERE DAYNAME(Timestamp) <> Day_of_Week;

-- End of Data Quality Audit

-- Step 2 - Clean / Prepare Data

-- Create Analysis-Ready Table
CREATE TABLE social_media_clean AS
SELECT *
FROM social_media_raw;

select count(*) as total_values
from social_media_clean;

-- Verify Clean Table Structure
DESCRIBE social_media_clean;

-- Check Boolean Values in Clean Table
SELECT
    Has_Media,
    Is_Verified,
    COUNT(*) AS record_count
FROM social_media_clean
GROUP BY Has_Media, Is_Verified;

-- Check Leading/Trailing Spaces
SELECT COUNT(*) AS records_with_spaces
FROM social_media_clean
WHERE Platform <> TRIM(Platform)
   OR Content_Type <> TRIM(Content_Type)
   OR Category <> TRIM(Category)
   OR Sentiment <> TRIM(Sentiment)
   OR Influencer_Tier <> TRIM(Influencer_Tier)
   OR Day_of_Week <> TRIM(Day_of_Week);
   
-- Check Blank Text Values
SELECT COUNT(*) AS blank_records
FROM social_media_clean
WHERE Platform = ''
   OR Content_Type = ''
   OR Category = ''
   OR Sentiment = ''
   OR Influencer_Tier = ''
   OR Day_of_Week = '';
   
-- Check Zero Follower Counts
SELECT COUNT(*) AS zero_followers
FROM social_media_clean
WHERE Follower_Count = 0;

-- Check Highest Engagement Rates
SELECT
    Post_ID,
    Platform,
    Likes,
    Comments,
    Shares,
    Follower_Count,
    Engagement_Rate
FROM social_media_clean
ORDER BY Engagement_Rate DESC
LIMIT 10;
/* Finding: Some posts have exceptionally high engagement rates, but these values are mathematically consistent with their likes, 
comments, shares, and follower counts. They should be retained and potentially investigated as an analytical insight
rather than treated as a data-quality error.
*/

-- Check Lowest Engagement Rates
SELECT
    Post_ID,
    Platform,
    Likes,
    Comments,
    Shares,
    Follower_Count,
    Engagement_Rate
FROM social_media_clean
ORDER BY Engagement_Rate ASC
LIMIT 10;


-- Final Clean Table Record Count
SELECT COUNT(*) AS total_clean_records
FROM social_media_clean;

-- Compare Raw and Clean Table
SELECT
    (SELECT COUNT(*) FROM social_media_raw) AS raw_records,
    (SELECT COUNT(*) FROM social_media_clean) AS clean_records;
    

 /* "The dataset was audited for missing values, duplicates, invalid numeric values, inconsistent categorical values, 
 formatting issues, and logical inconsistencies. No significant data-quality issues were identified.Therefore, the 
 original values were retained, and a separate analysis-ready table was created for further analysis."
 */
 
 -- End of Clean / Prepare Data
 
 
 
 -- ============================================================
-- STEP 3: BUSINESS ANALYSIS
-- ============================================================

 
 -- 1. Average Engagement Rate by Platform
SELECT
    Platform,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_engagement_rate DESC;

-- 2. Total Engagement by Platform
SELECT
    Platform,
    SUM(Likes + Comments + Shares) AS total_engagement
FROM social_media_clean
GROUP BY Platform
ORDER BY total_engagement DESC;

-- 3. Average Engagement Rate by Content Type
SELECT
    Content_Type,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Content_Type
ORDER BY avg_engagement_rate DESC;

-- 4. Content Type Volume and Total Engagement
SELECT
    Content_Type,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Content_Type
ORDER BY total_engagement DESC;

-- 5. Category Volume and Engagement Performance
SELECT
    Category,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Category
ORDER BY total_engagement DESC;

-- 6. Engagement Performance by Day of Week
SELECT
    Day_of_Week,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Day_of_Week
ORDER BY avg_engagement_rate DESC;

-- 7. Engagement Performance by Hour of Day
SELECT
    Hour_of_Day,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Hour_of_Day
ORDER BY avg_engagement_rate DESC;

-- 8. Total Views by Platform
SELECT
    Platform,
    SUM(Views) AS total_views
FROM social_media_clean
GROUP BY Platform
ORDER BY total_views DESC;


-- 9. Average Views per Post by Platform
SELECT
    Platform,
    COUNT(*) AS post_count,
    ROUND(AVG(Views), 0) AS avg_views
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_views DESC;

-- 10. Average Likes per Post by Platform
SELECT
    Platform,
    ROUND(AVG(Likes), 0) AS avg_likes
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_likes DESC;

-- 11. Average Comments per Post by Platform
SELECT
    Platform,
    ROUND(AVG(Comments), 0) AS avg_comments
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_comments DESC;

-- 12. Average Shares per Post by Platform
SELECT
    Platform,
    ROUND(AVG(Shares), 0) AS avg_shares
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_shares DESC;

-- 13. Number of Posts by Platform
SELECT
    Platform,
    COUNT(*) AS post_count
FROM social_media_clean
GROUP BY Platform
ORDER BY post_count DESC;

-- 14. Engagement-to-View Ratio by Platform
SELECT
    Platform,
    SUM(Likes + Comments + Shares) AS total_engagement,
    SUM(Views) AS total_views,
    ROUND(
        SUM(Likes + Comments + Shares) / SUM(Views) * 100,
        2
    ) AS engagement_to_view_rate
FROM social_media_clean
GROUP BY Platform
ORDER BY engagement_to_view_rate DESC;

-- 15. Total Views by Category
SELECT
    Category,
    SUM(Views) AS total_views
FROM social_media_clean
GROUP BY Category
ORDER BY total_views DESC;

-- 16. Average Views per Post by Category
SELECT
    Category,
    COUNT(*) AS post_count,
    ROUND(AVG(Views), 0) AS avg_views
FROM social_media_clean
GROUP BY Category
ORDER BY avg_views DESC;

-- 17. Views Performance by Content Type
SELECT
    Content_Type,
    COUNT(*) AS post_count,
    SUM(Views) AS total_views,
    ROUND(AVG(Views), 0) AS avg_views
FROM social_media_clean
GROUP BY Content_Type
ORDER BY total_views DESC;

-- 18. Total Engagement by Content Type
SELECT
    Content_Type,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement
FROM social_media_clean
GROUP BY Content_Type
ORDER BY total_engagement DESC;

-- 19. Engagement by Platform and Content Type
SELECT
    Platform,
    Content_Type,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Platform, Content_Type
ORDER BY Platform, avg_engagement_rate DESC;

-- 20. Average Followers by Platform
SELECT
    Platform,
    ROUND(AVG(Follower_Count), 0) AS avg_followers
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_followers DESC;

-- 21. Followers vs Engagement Rate by Platform
SELECT
    Platform,
    ROUND(AVG(Follower_Count), 0) AS avg_followers,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Platform
ORDER BY avg_engagement_rate DESC;

-- 22. Engagement Rate by Verification Status
SELECT
    Is_Verified,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Is_Verified
ORDER BY avg_engagement_rate DESC;

-- 23. Engagement Rate by Media Presence
SELECT
    Has_Media,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Has_Media
ORDER BY avg_engagement_rate DESC;

-- 24. Engagement Rate by Influencer Tier
SELECT
    Influencer_Tier,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Influencer_Tier
ORDER BY avg_engagement_rate DESC;

-- 25. Top Nano Influencer Posts by Engagement Rate
SELECT
    Post_ID,
    Platform,
    Follower_Count,
    Likes,
    Comments,
    Shares,
    Engagement_Rate
FROM social_media_clean
WHERE Influencer_Tier = 'Nano'
ORDER BY Engagement_Rate DESC
LIMIT 10;

-- 26. Follower Count by Influencer Tier
SELECT
    Influencer_Tier,
    COUNT(*) AS post_count,
    ROUND(AVG(Follower_Count), 0) AS avg_followers,
    MIN(Follower_Count) AS min_followers,
    MAX(Follower_Count) AS max_followers
FROM social_media_clean
GROUP BY Influencer_Tier
ORDER BY avg_followers DESC;

-- 27. Average Engagement per Post by Influencer Tier
SELECT
    Influencer_Tier,
    COUNT(*) AS post_count,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement
FROM social_media_clean
GROUP BY Influencer_Tier
ORDER BY avg_engagement DESC;

-- 28. Total Engagement by Influencer Tier
SELECT
    Influencer_Tier,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement
FROM social_media_clean
GROUP BY Influencer_Tier
ORDER BY total_engagement DESC;

-- 29. Engagement Rate by Sentiment
SELECT
    Sentiment,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Sentiment
ORDER BY avg_engagement_rate DESC;

-- 30. Total Engagement by Sentiment
SELECT
    Sentiment,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement
FROM social_media_clean
GROUP BY Sentiment
ORDER BY total_engagement DESC;

-- 31. Engagement Rate by Hashtag Count
SELECT
    Hashtag_Count,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Hashtag_Count
ORDER BY Hashtag_Count;

-- 32. Engagement Rate by Hashtag Range
SELECT
    CASE
        WHEN Hashtag_Count BETWEEN 0 AND 4 THEN '0-4'
        WHEN Hashtag_Count BETWEEN 5 AND 9 THEN '5-9'
        WHEN Hashtag_Count BETWEEN 10 AND 14 THEN '10-14'
        WHEN Hashtag_Count BETWEEN 15 AND 19 THEN '15-19'
        WHEN Hashtag_Count BETWEEN 20 AND 24 THEN '20-24'
        WHEN Hashtag_Count BETWEEN 25 AND 29 THEN '25-29'
    END AS hashtag_range,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY hashtag_range
ORDER BY hashtag_range;

-- 33. Check Content Length Range
SELECT
    MIN(Content_Length) AS min_content_length,
    MAX(Content_Length) AS max_content_length
FROM social_media_clean;

-- 34. Engagement Rate by Content Length Range
SELECT
    CASE
        WHEN Content_Length BETWEEN 15 AND 499 THEN '15-499'
        WHEN Content_Length BETWEEN 500 AND 999 THEN '500-999'
        WHEN Content_Length BETWEEN 1000 AND 1499 THEN '1000-1499'
        WHEN Content_Length BETWEEN 1500 AND 1999 THEN '1500-1999'
    END AS content_length_range,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY content_length_range
ORDER BY MIN(Content_Length);

-- 35. Average Views by Content Length Range
SELECT
    CASE
        WHEN Content_Length BETWEEN 15 AND 499 THEN '15-499'
        WHEN Content_Length BETWEEN 500 AND 999 THEN '500-999'
        WHEN Content_Length BETWEEN 1000 AND 1499 THEN '1000-1499'
        WHEN Content_Length BETWEEN 1500 AND 1999 THEN '1500-1999'
    END AS content_length_range,
    COUNT(*) AS post_count,
    ROUND(AVG(Views), 0) AS avg_views
FROM social_media_clean
GROUP BY content_length_range
ORDER BY MIN(Content_Length);

-- 36. Engagement Rate by Platform and Day
SELECT
    Platform,
    Day_of_Week,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Platform, Day_of_Week
ORDER BY Platform, avg_engagement_rate DESC;

-- 37. Engagement Rate by Platform, Content Type and Day
SELECT
    Platform,
    Content_Type,
    Day_of_Week,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate
FROM social_media_clean
GROUP BY Platform, Content_Type, Day_of_Week
HAVING COUNT(*) >= 10
ORDER BY avg_engagement_rate DESC;

-- 38. Total Engagement by Platform, Content Type and Day
SELECT
    Platform,
    Content_Type,
    Day_of_Week,
    COUNT(*) AS post_count,
    SUM(Likes + Comments + Shares) AS total_engagement,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement
FROM social_media_clean
GROUP BY Platform, Content_Type, Day_of_Week
HAVING COUNT(*) >= 10
ORDER BY total_engagement DESC;

-- 39. Top 10 Posts by Total Engagement
SELECT
    Post_ID,
    Platform,
    Content_Type,
    Likes,
    Comments,
    Shares,
    (Likes + Comments + Shares) AS total_engagement,
    Engagement_Rate
FROM social_media_clean
ORDER BY total_engagement DESC
LIMIT 10;

-- 40. Posts with Very High Total Engagement
SELECT
    Platform,
    COUNT(*) AS high_engagement_posts
FROM social_media_clean
WHERE (Likes + Comments + Shares) >= 40000
GROUP BY Platform
ORDER BY high_engagement_posts DESC;

-- 41. Verified vs Unverified Performance
SELECT
    Is_Verified,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement
FROM social_media_clean
GROUP BY Is_Verified
ORDER BY avg_engagement_rate DESC;

-- 42. Media vs Non-Media Performance
SELECT
    Has_Media,
    COUNT(*) AS post_count,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate,
    ROUND(AVG(Views), 0) AS avg_views,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement
FROM social_media_clean
GROUP BY Has_Media
ORDER BY avg_engagement_rate DESC;

-- 43. Overall Social Media Performance Summary
SELECT
    COUNT(*) AS total_posts,
    COUNT(DISTINCT Platform) AS total_platforms,
    COUNT(DISTINCT Category) AS total_categories,
    COUNT(DISTINCT Content_Type) AS total_content_types,
    ROUND(AVG(Engagement_Rate), 2) AS avg_engagement_rate,
    ROUND(AVG(Views), 0) AS avg_views,
    ROUND(AVG(Likes + Comments + Shares), 0) AS avg_engagement,
    SUM(Likes + Comments + Shares) AS total_engagement,
    SUM(Views) AS total_views
FROM social_media_clean;

-- End of data analysis

-- ============================================================
-- END OF SQL ANALYSIS SCRIPT
-- ============================================================
