-- Source: https://dataford.io/sql/Keyword-Views

-- Keyword Views - Meta
-- Generate a report indicating the number of views for each keyword. 
-- Output includes the keyword and the total views, 
-- with records ordered in descending order based on the highest view count.

-- facebook_posts table:
-- Column Name	Description
-- post_id	        Identifier of post
-- poster	        Poster number
-- post_text	    Text of the post
-- post_keywords	Keywords
-- post_date	    Date of post


-- facebook_post_views table:
-- Column Name	Description
-- post_id	    Identifier of post
-- viewer_id	Identifier of viewer

-- Example output:
-- keyword	total_views
-- spam	        6
-- spaghetti	3

with p_views as (select 
  post_id, count(1) as cnt_views
from
  facebook_post_views
group by
  post_id)
select 
  -- fp.post_id,
  unnest(string_to_array(replace(replace(post_keywords,'[',''),']',''), ',')) as post_keywords_n,
  sum(pv.cnt_views)
from facebook_posts fp
inner join p_views pv
  on fp.post_id = pv.post_id
group by
  post_keywords
order by sum(pv.cnt_views) desc
;