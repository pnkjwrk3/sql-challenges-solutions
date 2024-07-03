-- Source: https://dataford.io/sql/The-Most-Equipped-City

-- The Most Equipped City - Airbnb
-- You're provided with a dataset of Airbnb property searches, where each search result represents a unique host. 
-- Your task is to find the city with the most amenities across all their properties.

-- Output the name of the city.

-- airbnb_search_details table:
-- Column Name	Description
-- id	                Identifier of property
-- price	                Price of property
-- property_type	        Property type
-- room_type	            Room type
-- amenities	            Amenities
-- accommodates	            Number of accommodates
-- bathrooms	            Number of bathrooms
-- bed_type	                Bed type
-- cancellation_policy	    Cancellation policy
-- cleaning_fee	            Cleaning fee
-- city	                    City name
-- host_identity_verified	Host verified
-- host_response_rate	    Host response rate
-- host_since	            Host since date
-- neighbourhood	        Neighbourhood name
-- number_of_reviews	    Number of reviews
-- review_scores_rating	    Scores rating
-- zipcode	                Zipcode
-- bedrooms	                Number of bedrooms
-- beds	                    Number of beds

-- Example output:
-- city
-- NYC



with city_amenity_cnt as (select 
   city,
  unnest(string_to_array(replace(replace(amenities,'{',''),'}',''), ',')) as amenities_n,
  count(1) as cnt
from airbnb_search_details fp
group by
  city,amenities_n)
  
  select 
    city, sum(cnt) as total_amenities
  from
    city_amenity_cnt
  group by
    city
  order by
    total_amenities desc
  limit 1;