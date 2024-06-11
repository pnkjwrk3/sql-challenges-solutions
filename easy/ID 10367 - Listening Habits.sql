-- Source: https://platform.stratascratch.com/coding/10367-aggregate-listening-data
-- Source: https://dataford.io/sql/Listening-habits

-- Simple aggregation query

select user_id, 
  sum(listen_duration) as total_listen_duration, 
  count(distinct song_id) as unique_song_count 
from listening_habits
group by user_id