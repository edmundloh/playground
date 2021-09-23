/*The table has 4 fields: date, event_name, video_id and user_id. Write a query that will return the
number of users who viewed at least one video in a given day and the number of those users
who returned the next day to view at least one video. The video_play event signifies that a video
was played by a user. Imagine the actual data set is much larger than shown in the sample
data.

date event_name video_id user_id
2018-01-01 video_play 51651561651 989189198
2018-01-01 video_play 98121651656 561884864
2018-01-01 video_play 78918918918 561884864
2018-01-01 create_video 32156541355 153215651
2018-01-01 create_video 87351531311 232135135
2018-01-02 create_video 51651561651 489846581
2018-01-02 video_play 12315315352 561884864
2018-01-02 create_video 32156541355 321351351
2018-01-02 create_video 87351531311 231513515
2018-01-02 video_play 98191891894 615616516

The output should have one row per day. Each row should have 3 columns, date,
users_view_videos and users_view_next_day.
- users_view_videos is the number of users who viewed at least one video in the given
date
- users_view_next_day is the subset number of users from user_view_videos who also
view a video on the next day
From the sample data provided above this should be the output:

date users_view_videos users_view_next_day
2018-01-01 2 1
2018-01-02 2 0
*/

--METHOD 1 - Without using the computation heavy count(distinct) function

--Setting parameters for the query
SET (start_date_var,end_date_var,event_name_var) = ('2018-01-01',current_date-1,'video_play');

--Finding unique users by date (assuming base table name is EVENTS_TABLE)
WITH users_day as
(
SELECT  date,
        user_id
FROM EVENTS_TABLE
WHERE event_name= $event_name_var
AND   date between $start_date_var and $end_date_var
GROUP BY 1,2
),

--counting unqiue users by date
users_day_count as
(
SELECT  date,
        count(user_id) as users_view_videos
FROM users_day
),

--counting unqiue users who view next day.  Joining table onto itself on user_id and dates are 1 day apart.
users_next_day_count as
(
SELECT  a.date as current_date,
        b.date as next_date,
        count(a.user_id) as users_view_next_day
FROM users_day a
INNER JOIN users_day b
  ON a.date = b.date-1
  AND a.user_id=b.user_id
GROUP BY 1,2
)

--merging users_view_video count and users_view_next_day count in one table.  
--Remove last date since there would be no data for users_view_next_day
select a.date,
       a.users_view_videos,
       b.users_view_next_day
FROM users_day_count a
LEFT JOIN users_next_day_count b
  ON a.date=b.current_date
WHERE a.date <> $end_date_var;


--METHOD 2 - Using count(distinct) and no sub-queries

--Setting parameters for the query
SET (start_date_var,end_date_var,event_name_var) = ('2018-01-01',current_date-1,'video_play');

SELECT a.date,
       count(distinct a.user_id) as users_view_videos,
       count(distinct b.user_id) as users_view_next_day
FROM EVENTS_TABLE a
LEFT OUTER JOIN EVENTS_TABLE b
  ON a.user_id=b.user_id and a.date=b.date-1
WHERE a.date between $start_date_var and $end_date_var
  and b.date between $start_date_var and $end_date_var
  and a.event_name= $event_name_var
  and b.event_name= $event_name_var
GROUP BY 1
HAVING a.date <> $end_date_var;
