-- Source: https://platform.stratascratch.com/coding/10364-fridays-likes-count

-- You have access to Facebook's database, containing tables related to user posts, friendships, and likes. 
-- Your goal is to calculate the total number of likes made on posts by friends specifically on Fridays.

-- user_posts table:
-- column Name    Description
-- post_id        Identifier of post
-- user_name      Username
-- date_posted    Date posted

-- friendships table:
-- column Name    Description
-- user_name1     Friend 1
-- user_name2     Friend 2

-- likes table:
-- column Name    Description
-- user_name      Username
-- post_id        Identifier of post
-- date_liked     Date liked

-- Example output:
-- date_liked  count
-- 2024-01-05  3
-- 2020-01-12  7
-- 2024-01-19  1

select l.date_liked, count(1) 
from user_posts up
join friendships f 
    on (up.user_name = f.user_name1 or up.user_name = f.user_name2)
join likes l 
    on (up.post_id = l.post_id)
where 
    extract(isodow from l.date_liked) = 5 
    AND
    (f.user_name1 = l.user_name OR f.user_name2 = l.user_name)
group by l.date_liked;


