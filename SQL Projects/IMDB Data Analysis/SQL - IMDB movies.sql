show databases;
-- https://relational.fit.cvut.cz/dataset/IMDb
use imdb_ijs;

show tables;
-- Let's see the tables first:
select * from actors;
select * from directors;
select * from directors_genres;
select * from movies;
select * from movies_directors;
select * from movies_genres;
select * from roles;

-- Q1: Let's find out the top rated movies, with their Actor name, director's name and genre of the movie:
SELECT DISTINCT m.name AS MovieTitle, a.first_name as ActorName, d.first_name AS DirectorName, mg.genre AS MovieGenre, AVG(m.rank) AS AvgRank
FROM movies m
INNER JOIN actors a on m.id = a.id
INNER JOIN movies_directors md ON m.id = md.movie_id
INNER JOIN directors d ON md.director_id = d.id
LEFT JOIN movies_genres mg ON m.id = mg.movie_id
GROUP BY m.name, a.first_name, d.first_name, mg.genre
ORDER BY AvgRank DESC
LIMIT 10;

-- The same code can be done using SubQuery or CTE. Lets see:
WITH MovieActorDirector AS (
    SELECT DISTINCT m.id, m.name AS MovieTitle, a.first_name AS ActorName, d.first_name AS DirectorName, mg.genre AS MovieGenre, m.rank AS MovieRank
    FROM movies m
    INNER JOIN actors a ON m.id = a.id
    INNER JOIN movies_directors md ON m.id = md.movie_id
    INNER JOIN directors d ON md.director_id = d.id
    LEFT JOIN movies_genres mg ON m.id = mg.movie_id
),
RankedMovies AS (
    SELECT MovieTitle, ActorName, DirectorName, MovieGenre, AVG(MovieRank) AS AvgRank
    FROM MovieActorDirector
    GROUP BY MovieTitle, ActorName, DirectorName, MovieGenre
)
SELECT MovieTitle, ActorName, DirectorName, MovieGenre, AvgRank
FROM RankedMovies
ORDER BY AvgRank DESC
LIMIT 10;

-- Q2: Number of Movies by Genre: How many movies are there in each genre?
SELECT mg.genre AS MovieGenre, COUNT(*) AS MovieCount
FROM movies_genres mg
GROUP BY mg.genre
ORDER BY MovieCount DESC;
-- Output shows that: "Short" movie genre has the highest number of movies.

-- Q3: Finding the directors who has made highest number of movies in the winner of Q2:
SELECT d.first_name AS DirectorFirstName, d.last_name AS DirectorLastName, COUNT(*) AS MovieCount
FROM directors d
JOIN movies_directors md ON d.id = md.director_id
JOIN movies_genres mg ON md.movie_id = mg.movie_id
WHERE mg.genre = 'Short'
GROUP BY d.first_name, d.last_name
ORDER BY MovieCount DESC
LIMIT 5;
-- Output: 	Dave Fleischer has made highest number of "Short" movies with 604 movies.

-- The same code can be written using Subquery also:
SELECT d.first_name AS DirectorFirstName, d.last_name AS DirectorLastName, COUNT(*) AS MovieCount
FROM directors d
JOIN movies_directors md ON d.id = md.director_id
WHERE md.movie_id IN (
    SELECT movie_id
    FROM movies_genres
    WHERE genre = 'Short'
)
GROUP BY d.first_name, d.last_name
ORDER BY MovieCount DESC
LIMIT 5;

-- Q3: Actors in Most Movies: Which actors (top 10) have appeared in the most movies?
SELECT a.first_name AS ActorFirstName, a.last_name AS ActorLastName, COUNT(*) AS MovieCount
FROM actors a
JOIN movies m ON a.id = m.id
GROUP BY a.first_name, a.last_name
ORDER BY MovieCount DESC
LIMIT 10;

-- Q4: Movies with Highest and Lowest Rank: What are the highest-ranked and lowest-ranked movies in the database?
SELECT name AS MovieTitle, rank AS MovieRank
FROM movies
ORDER BY MovieRank DESC
LIMIT 1;
-- Output: "Atunci i-am condamnat pe toti la moarte" with rank-9.9

SELECT name AS MovieTitle, rank AS MovieRank
FROM movies
ORDER BY MovieRank ASC
LIMIT 1;
-- Output: "sterreich" with "Null" rating.

-- Q5: Movies Released in a Specific Year: List all movies released in a specific year.
SELECT name AS MovieTitle, year AS ReleaseYear
FROM movies
WHERE year = '1996';
-- Output: 1000 rows

-- Q6: Actors and Their Movie Count and Director and Their Movie Count:
SELECT 'Actor' AS Role, a.first_name AS FirstName, a.last_name AS LastName, COUNT(r.movie_id) AS MovieCount
FROM actors a
LEFT JOIN roles r ON a.id = r.actor_id
GROUP BY a.first_name, a.last_name
UNION
SELECT 'Director' AS Role, d.first_name AS FirstName, d.last_name AS LastName, COUNT(md.movie_id) AS MovieCount
FROM directors d
LEFT JOIN movies_directors md ON d.id = md.director_id
GROUP BY d.first_name, d.last_name
ORDER BY Role, MovieCount DESC, FirstName, LastName;

-- The same can be done using subqueries as well:
SELECT Role, FirstName, LastName, MovieCount
FROM (
    SELECT 'Actor' AS Role, a.first_name AS FirstName, a.last_name AS LastName,
        (SELECT COUNT(*) FROM roles r WHERE r.actor_id = a.id) AS MovieCount
    FROM actors a
    UNION
    SELECT 'Director' AS Role, d.first_name AS FirstName, d.last_name AS LastName,
        (SELECT COUNT(*) FROM movies_directors md WHERE md.director_id = d.id) AS MovieCount
    FROM directors d
) AS Subquery
ORDER BY Role, MovieCount DESC, FirstName, LastName;

-- Q7. Actors Who Appeared in Top-Ranked Movies: List actors who appeared in top-ranked movies.
SELECT a.first_name AS ActorFirstName, a.last_name AS ActorLastName, m.name AS MovieTitle, m.rank AS MovieRank
FROM actors a
JOIN roles r ON a.id = r.actor_id
JOIN movies m ON r.movie_id = m.id
WHERE m.rank = (SELECT MAX(rank) FROM movies)
ORDER BY MovieRank DESC, MovieTitle, ActorLastName, ActorFirstName;