1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT COUNT(post_type_id)
FROM stackoverflow.posts
WHERE post_type_id IN (1)
    AND (score >300 OR favorites_count >=100)

2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

WITH q AS (SELECT COUNT(post_type_id) OVER (PARTITION BY creation_date::date) AS cnt
FROM stackoverflow.posts
WHERE post_type_id IN (1)
    AND DATE_TRUNC('day', creation_date)::date BETWEEN '2008-11-01' AND '2008-11-18')

SELECT ROUND(AVG(DISTINCT cnt))
FROM q

3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT (DISTINCT u.id)
FROM stackoverflow.badges b
JOIN stackoverflow.users u ON b.user_id=u.id
WHERE DATE_TRUNC('day', u.creation_date) :: date = DATE_TRUNC('day', b.creation_date) :: date;

4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.users as u
JOIN stackoverflow.posts as p ON u.id = p.user_id
JOIN stackoverflow.votes AS v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn'

5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id.

SELECT *,
     RANK() OVER (ORDER BY id DESC)
FROM stackoverflow.vote_types
ORDER BY id

6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT user_id AS id,
       COUNT(vote_type_id) AS vote
FROM stackoverflow.votes
WHERE vote_type_id IN (6)
GROUP BY user_id
ORDER BY vote DESC, id DESC
LIMIT 10 

7.Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT user_id,
       COUNT(id),       
       DENSE_RANK () OVER (ORDER BY COUNT(id) DESC)
FROM stackoverflow.badges
WHERE creation_date BETWEEN '2008-11-15' AND '2008-12-16'
GROUP BY user_id
ORDER BY COUNT(id) DESC, user_id
LIMIT 10 

8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
заголовок поста;
идентификатор пользователя;
число очков поста;
среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.

SELECT p.title,
      p.user_id,
      p.score,
      ROUND(AVG(p.score) OVER (PARTITION BY p.user_id)) 
FROM stackoverflow.posts AS p
WHERE title IS NOT NULL AND score <> 0

9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список.

WITH one AS (SELECT user_id AS user,
       COUNT(id) AS badges
FROM stackoverflow.badges
GROUP BY user_id)

SELECT p.title
FROM stackoverflow.posts p
JOIN one o ON p.user_id=o.user
WHERE p.title IS NOT NULL AND o.badges>1000

10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). 
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.

SELECT DISTINCT id,
    views,
CASE
    WHEN views >= 350 THEN 1
    WHEN views >= 100 AND  views < 350 THEN 2
    WHEN views < 100 THEN 3
END AS user_group
FROM stackoverflow.users
WHERE views != 0 AND LOCATION LIKE ('%United States%')

11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH view_group AS
(SELECT DISTINCT id,
    views,
CASE
    WHEN views >= 350 THEN 1
    WHEN views >= 100 AND  views < 350 THEN 2
    WHEN views < 100 THEN 3
END AS user_group
FROM stackoverflow.users
WHERE views != 0 AND LOCATION LIKE ('%United States%'))

SELECT id,
    views,
    user_group
FROM
(SELECT *,
    DENSE_RANK() OVER (PARTITION BY user_group ORDER BY views DESC)
FROM view_group
ORDER BY 3 ASC, 2 DESC) AS rating
WHERE
    (user_group = 1 AND dense_rank = 1)
    OR (user_group = 2 AND dense_rank = 1)
    OR (user_group = 3 AND dense_rank = 1)
ORDER BY 2 DESC, 1 ASC

12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
- номер дня;
- число пользователей, зарегистрированных в этот день;
- сумму пользователей с накоплением.

SELECT EXTRACT(DAY FROM creation_date),
    COUNT(id),
    SUM(COUNT(id)) OVER (ORDER BY EXTRACT(DAY FROM creation_date)) as total
FROM stackoverflow.users
WHERE creation_date BETWEEN '2008-11-1' AND '2008-12-1'
GROUP BY EXTRACT(DAY FROM creation_date)

13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
- идентификатор пользователя;
- разницу во времени между регистрацией и первым постом.

WITH one AS (SELECT user_id,
      creation_date AS date,
      ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY creation_date) AS rn
FROM stackoverflow.posts),

two AS (SELECT user_id AS id,
       date
FROM one
WHERE rn=1)

SELECT u.id,
       t.date -u.creation_date
FROM stackoverflow.users u
JOIN two t ON u.id=t.id

14. Выведите общую сумму просмотров постов за каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров.

SELECT SUM(views_count),
       DATE_TRUNC('month', creation_date)::date
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date) = 2008
GROUP BY DATE_TRUNC('month', creation_date)
ORDER BY SUM(views_count) DESC

15. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке.

SELECT display_name,
    COUNT(DISTINCT user_id) AS cnt
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON u.id=p.user_id
LEFT JOIN stackoverflow.post_types pt ON p.post_type_id=pt.id
WHERE type='Answer'
    AND p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date:: date + INTERVAL '1 month')
GROUP BY display_name
HAVING COUNT(user_id) > 100
ORDER BY display_name

16. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию.

WITH dp AS (SELECT user_id AS december_id
FROM stackoverflow.posts
WHERE creation_date BETWEEN '2008-12-01' AND '2009-01-01')

SELECT COUNT(DISTINCT p.id),
       DATE_TRUNC('month', p.creation_date)::date AS month
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id=u.id
JOIN dp dp ON p.user_id=dp.december_id
WHERE EXTRACT(YEAR FROM p.creation_date) = 2008
    AND u.creation_date BETWEEN '2008-09-01' AND '2008-10-01'
GROUP BY DATE_TRUNC('month', p.creation_date)
ORDER BY month DESC

17. Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT user_id,
    creation_date,
    views_count,
    SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY user_id, creation_date

18. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат.

WITH one AS (select user_id,
             COUNT(id),
       count(creation_date::date) AS date
from stackoverflow.posts
WHERE creation_date BETWEEN '2008-12-01' AND '2008-12-7'
group by user_id)

SELECT ROUND(AVG(date))
FROM one

19. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
номер месяца; количество постов за месяц; процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.

WITH posts_monthly AS
(SELECT EXTRACT(MONTH FROM creation_date::DATE) AS MONTH,
    COUNT(id) AS cnt
FROM stackoverflow.posts
WHERE creation_date::DATE BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY 1)
 
SELECT *,
    ROUND((cnt - LAG(cnt, 1) OVER(ORDER BY MONTH)) * 100.0 / LAG(cnt) OVER(ORDER BY MONTH), 2)
FROM posts_monthly

20. Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. 
Выведите данные за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе.

with data as (SELECT user_id,
             COUNT(id) AS count
             FROM stackoverflow.posts
             GROUP BY user_id
             ORDER BY count DESC
             LIMIT 1)
SELECT DISTINCT EXTRACT (WEEK FROM creation_date) AS week,
       MAX (creation_date) OVER (ORDER BY EXTRACT (WEEK FROM creation_date) )
FROM stackoverflow.posts
WHERE user_id IN (SELECT user_id FROM data)
AND DATE_TRUNC('day', creation_date) BETWEEN '2008-10-01' AND '2008-10-31'
