/* 
1. Exploring data

Getting a sense of what is going on with the data in two tables I plan to use.
*/

-- 1.1 Games table
SELECT *
FROM SQLProject..games
/* 
This table has a list of board games and the year they were published, 
their ratings and ranks, player counts, playtime, and other relevant data.
*/

-- 1.2 Mechanisms table
SELECT *
FROM SQLProject.dbo.mechanisms
/*
This table has binary data indicating whether a game does or doesn't 
have a particular mechanism. Mechanisms are what you do in a 
game (eg. 'Dice Rolling').
*/

-- 1.3 Filtering to view only top 3000 games, by rank
SELECT *
FROM SQLProject..games
WHERE Rank_boardgame BETWEEN 1 AND 3001
ORDER BY Rank_boardgame

-- 1.4 Examining year published
SELECT YearPublished, COUNT(YearPublished) AS num_published
FROM SQLProject..games
GROUP BY YearPublished
ORDER BY YearPublished
/*
There appear to be quite a few games published in year 0 or before.
I want to ensure this isn't indicative of problems with the data.
*/

--    1.4.1 Checking games published before year 1 in the top 3000 games
SELECT Name, YearPublished
FROM SQLProject..games
WHERE YearPublished < 1 AND Rank_boardgame < 3001
ORDER BY Rank_boardgame
/*
Go, Carrom and Backgammon are traditional games. Some online research
showed that the years published for those games are indeed accurate. 
Next, I will isolate the other two games to explore them further.
*/

--    1.4.2 Pulling up the description and other information for the two rows of interest published in year 0
SELECT *
FROM SQLProject..games
WHERE Name = 'Unpublished Prototype' OR Name = 'Eat Poop You Cat'
/*
Examining the BoardGameGeek.com entry for 'Eat Poop You Cat' revealed
that it is not really a board game, it is a pencil-and-paper drawing game.
Examining the entry for 'Unpublished Prototype' revealed that it is 
a placeholder for games that do not have entires on the site. 
Neither of these are relevant to my project, and should be removed 
during data cleaning.
*/

-- 1.5 Examining rankings 
SELECT BGGId, Name, Rank_boardgame
	, Rank_abstracts, Rank_cgs, Rank_childrensgames
	, Rank_familygames, Rank_partygames, Rank_strategygames
	, Rank_thematic, Rank_wargames
FROM SQLProject..games
ORDER BY Rank_boardgame

--    1.5.1 Ensuring each rank is unique (each rank should only have one game)
SELECT Rank_boardgame, COUNT(Rank_boardgame) AS num_of_games
FROM SQLProject..games
GROUP BY Rank_boardgame
ORDER BY num_of_games DESC
/*
There are quite a few games ranked 21926. This seems to be an issue
since each rank should only have one game.
*/

--    1.5.2 Examining games with rank 21926
SELECT *
FROM SQLProject..games
WHERE Rank_boardgame = 21926

--    1.5.3 Looking into a specific game from that list to explore what the 21926 ranking could mean
SELECT YearPublished, Name, Rank_boardgame, Rank_familygames, Rank_strategygames
FROM SQLProject..games
WHERE Name LIKE 'FORMULA D%'
/*
Cross-referencing the BoardGameGeek.com entries for these games
revealed that games that are 'unranked' according to BoardGameGeek.com
are ranked 21926 in this dataset. This will be addressed during cleaning.
*/

-- 1.6 Examining games with duplicate names
WITH num_rows AS (
	SELECT * , ROW_NUMBER() 
		OVER (PARTITION BY Name
			ORDER BY YearPublished
		) AS row_num
	FROM SQLProject..games
)
SELECT DISTINCT games.Name, games.YearPublished
	, games.BGGId, games.Rank_boardgame
FROM num_rows AS duplicate
JOIN SQLProject..games AS games
	ON duplicate.Name = games.Name
WHERE row_num > 1 

--    1.6.1 Examining rows with duplicate game names in the top 3000 (and number of editions those duplicates have)
WITH num_rows AS (
	SELECT * , ROW_NUMBER() 
		OVER (PARTITION BY Name
			ORDER BY YearPublished
		) AS row_num
	FROM SQLProject..games
)
SELECT DISTINCT games.Name, games.YearPublished
	, games.BGGId, games.Rank_boardgame
	, MAX(row_num) OVER (PARTITION BY games.Name) AS num_editions
FROM num_rows AS duplicate
JOIN SQLProject..games AS games
	ON duplicate.Name = games.Name
WHERE duplicate.row_num > 1 
	AND games.Rank_boardgame BETWEEN 1 AND 3001
ORDER BY num_editions DESC, games.Name
/* 
There appear to be quite a few games that have the same name but different
BGGIds, rankings, and publishing years. This suggests that they are 
different editions of the same game. This issue will be addressed
during data cleaning. 
*/

-- 1.7 Examining game families 
SELECT BGGId, Name, Family
FROM SQLProject..games
/* 
Families of games are groups of games that are similar or 
related in some way. There appears to be quite a few NULL values
in the family column. This will be addressed during cleaning.
*/

--    1.7.1 Looking into how many games are contained in each family
SELECT BGGId, Name, Family
	, COUNT(Family) OVER (PARTITION BY Family) AS games_in_family
FROM SQLProject..games
WHERE Family IS NOT NULL
ORDER BY Family

--    1.7.2 Seeing which families have the most games
SELECT Family, COUNT(Family) AS games_in_family
FROM SQLProject..games
GROUP BY Family
ORDER BY games_in_family DESC

--    1.7.3 Further exploring games with NULL in the Family column
SELECT BGGId, Name, Family
FROM SQLProject..games
WHERE Family IS NULL
ORDER BY Rank_boardgame
/*
Games with NULL in the Family column appear to be games that are
not part of any family. The NULL represents 'no family'.
*/

/*
2. Data Cleaning and Structuring
*/

-- 2.1 Creating a new table for the cleaned data (keeping the original table intact)
DROP TABLE IF EXISTS SQLProject..GamesClean

SELECT *
INTO SQLProject..GamesClean
FROM SQLProject..games

-- 2.2 Checking for duplicates
WITH num_rows AS (
	SELECT *, ROW_NUMBER() 
		OVER (PARTITION BY BGGId,
			Name, YearPublished, Rank_boardgame
			ORDER BY Rank_boardgame
			) AS row_num
	FROM SQLProject..GamesClean
)
SELECT *
FROM num_rows
WHERE row_num > 1
/*
This code assigns row numbers to each group of rows with the same
values in the specified columns. If the combination of values is unique,
it is assigned row number 1. If not, it is assigned a number greater than 1.
A number greater than 1 would indicate a duplicate row. There do not appear
to be any duplicate rows in this dataset.
*/

-- 2.3 Removing irrelevant columns
ALTER TABLE SQLProject..GamesClean
DROP COLUMN BayesAvgRating, StdDev, MinPlayers
	, MaxPlayers, ComAgeRec, LanguageEase
	, NumOwned, NumWant, NumWish
	, NumWeightVotes, MfgPlaytime, MfgAgeRec
	, NumComments, NumAlternates
	, NumExpansions, NumImplementations, IsReimplementation
	, Kickstarted, Cat_Abstract, Cat_CGS, Cat_Childrens
	, Cat_Family, Cat_Party, Cat_Strategy, Cat_Thematic
	, Cat_War

-- 2.4 Adding edition numbers to games
DROP TABLE IF EXISTS #MultipleEditions

WITH num_rows AS (
	SELECT * , ROW_NUMBER() 
		OVER (PARTITION BY Name
			ORDER BY YearPublished
		) AS row_num
	FROM SQLProject..GamesClean
)
SELECT *, MAX(row_num) OVER (PARTITION BY Name) AS num_editions
INTO #MultipleEditions
FROM num_rows
ORDER BY Name, YearPublished

UPDATE SQLProject..GamesClean
SET Name = CASE
		WHEN eds.row_num = 1 THEN eds.Name
		WHEN eds.row_num = 2 THEN CONCAT(eds.Name, ' 2nd ed')
		WHEN eds.row_num = 3 THEN CONCAT(eds.Name, ' 3rd ed')
		WHEN eds.row_num = 4 THEN CONCAT(eds.Name, ' 4th ed')
		ELSE eds.Name
	END
FROM #MultipleEditions AS eds
JOIN SQLProject..GamesClean AS games
	ON eds.Name = games.Name AND eds.BGGId = games.BGGId
/* This code finds games with the same name and assigns them a number
based on which year they are published relative to other games with the same
name. Then the name in the GamesClean table is updated to reflect whether
the game with the repeated name is the original, 2nd, 3rd, or 4th edition.
*/

--    2.4.1 Making sure it worked by searching a game with  mutliple editions ('Cosmic Encounter')
SELECT * 
FROM SQLProject..GamesClean
WHERE Name LIKE 'Cosmic Encounter%'
ORDER BY YearPublished

-- 2.5 Changing rank of unranked games to 0 instead of 21926
UPDATE SQLProject..GamesClean 
SET Rank_abstracts = REPLACE(Rank_abstracts, 21926, 0)
	, Rank_boardgame = REPLACE(Rank_boardgame, 21926, 0)
	, Rank_cgs = REPLACE(Rank_cgs, 21926, 0)
	, Rank_childrensgames = REPLACE(Rank_childrensgames, 21926, 0)
	, Rank_familygames = REPLACE(Rank_familygames, 21926, 0)
	, Rank_partygames = REPLACE(Rank_partygames, 21926, 0)
	, Rank_strategygames = REPLACE(Rank_strategygames, 21926, 0)
	, Rank_thematic = REPLACE(Rank_thematic, 21926, 0)
	, Rank_wargames = REPLACE(Rank_wargames, 21926, 0)

-- 2.6 Filtering table for only the top 3000 games
DELETE
FROM SQLProject..GamesClean
WHERE Rank_boardgame < 1 OR Rank_boardgame > 3000

-- 2.7 Checking for missing rows in the top 3000 games
SELECT COUNT(DISTINCT Name) AS count_games
FROM SQLProject..GamesClean
/*
There are only 2998 rows in the table, suggesting that 2 games are missing.
*/

-- Locating the rank of the first missing game

WITH missing AS
	(SELECT Name, Rank_boardgame, ROW_NUMBER() OVER(ORDER BY Rank_boardgame)- Rank_boardgame AS row_num
	FROM SQLProject..GamesClean
	WHERE Rank_boardgame >1 AND Rank_boardgame < 3001
	) 
SELECT Name, Rank_boardgame, row_num
FROM missing
WHERE row_num <> -1

SELECT Name, Rank_boardgame
FROM SQLProject..GamesClean
WHERE Rank_boardgame >1940 AND Rank_boardgame < 1951
ORDER BY Rank_boardgame
/* 
The first missing game should be rank 1946. Normally, this information
would allow me to find that game on BoardGameGeek.com and add it to the
dataset manually. Unfortnuately, this data is a few years old so the rankings
have changed since the dataset was created. However, it may be useful to know
which ranks are missing.
*/

-- Locating the rank of the second missing game
WITH missing AS
	(SELECT Name, Rank_boardgame, ROW_NUMBER() OVER(ORDER BY Rank_boardgame)- Rank_boardgame AS row_num
	FROM SQLProject..GamesClean
	WHERE Rank_boardgame >1 AND Rank_boardgame < 3001
	) 
SELECT Name, Rank_boardgame, row_num
FROM missing
WHERE row_num < -2

SELECT Name, Rank_boardgame
FROM SQLProject..GamesClean
WHERE Rank_boardgame >2610 AND Rank_boardgame < 2621
ORDER BY Rank_boardgame
/*
The second missing game should be rank 2618.
*/

-- 2.8 Addressing games published in year 0
SELECT *
FROM SQLProject..GamesClean
WHERE Rank_boardgame >0 AND Rank_boardgame < 3001 AND YearPublished = 0 AND Name <> 'Carrom'
ORDER BY Rank_boardgame

DELETE
FROM SQLProject..GamesClean
WHERE Rank_boardgame >0 AND Rank_boardgame < 3001 AND YearPublished = 0 AND Name <> 'Carrom'

-- 2.9 Addressing the nulls in the Family column
UPDATE SQLProject..GamesClean
SET Family = ISNULL(Family, 'No Family')

-- 2.10 Extracting cover picture ID from image URL
SELECT ImagePath, BGGId, Name
	, SUBSTRING(ImagePath, CHARINDEX('pic', ImagePath), LEN(ImagePath) - CHARINDEX('pic', ImagePath) - 3) AS PicId
FROM SQLProject..GamesClean

ALTER TABLE SQLProject..GamesClean
ADD PicId nvarchar(150)

UPDATE SQLProject..GamesClean
SET PicId = 
	SUBSTRING(ImagePath, CHARINDEX('pic', ImagePath), LEN(ImagePath) - CHARINDEX('pic', ImagePath) - 3)
/* 
The image URL provided in this dataset contains the picture ID for the cover photo
used for each game listing on BoardGameGeek.com. The above code
extracts just the picture ID from the image URL.
*/

-- 2.11 Creating adjusted_weight column to allow the grouping of games by weight (1-5)
ALTER TABLE SQLProject..GamesClean
ADD adjusted_weight int

UPDATE SQLProject..GamesClean
SET adjusted_weight = 
	CASE
		WHEN GameWeight < 2 THEN 1
		WHEN GameWeight BETWEEN 2 AND 3 THEN 2
		WHEN GameWeight BETWEEN 3 AND 4 THEN 3
		ELSE 4
	END
FROM SQLProject..GamesClean
/*
BoardGameGeek.com gives games a weigth (complexity) rating out of 5
based on users' average weight ratings for that game. This code allows
the grouping of games by weight with any game rated between 1 and 2 being
rounded to 1, etc.
*/

-- 2.12 Creating a column for playtime range
ALTER TABLE SQLProject..GamesClean
ADD playtime_range nvarchar(50)

UPDATE SQLProject..GamesClean
SET playtime_range = 
	CASE
		WHEN ComMinPlaytime = ComMaxPlaytime THEN ComMinPlaytime
		ELSE CONCAT(ComMinPlaytime, ' - ', ComMaxPlaytime)
	END
/*
Play time was listed in two separate columns. The above code combines playtime
into one column that includes a range of playtimes (min playtime - max playtime).
*/

-- 2.13 Looking at data to validate data cleaning
SELECT *
FROM SQLProject..GamesClean
ORDER BY Rank_boardgame

/*
3. Joining
*/

-- 3.1 Joining the games table to the mechanisms table on BGGId
--    3.1.1 Changing the column name from the mechanisms table
ALTER TABLE SQLProject..mechanisms
ADD BGGId1 int

UPDATE SQLProject..mechanisms
SET BGGId1 = BGGId

ALTER TABLE SQLProject..mechanisms
DROP COLUMN BGGId

--    3.1.2 Joining the two tables into a temporary table for further exploration
DROP TABLE IF EXISTS #GamesMechanisms

SELECT *
INTO #GamesMechanisms
FROM SQLProject..GamesClean
JOIN SQLProject..mechanisms
	ON GamesClean.BGGId = mechanisms.BGGId1

ALTER TABLE #GamesMechanisms
DROP COLUMN BGGId1

/*
4. Analysis/Further Exploration
*/

-- 4.1 Examining the highest ranked game released from each year and how many games were published that year
WITH best_of_year AS
	(SELECT YearPublished
		, MIN(Rank_boardgame) AS best_rank
		, COUNT(YearPublished) AS games_from_year_in_top_3000
	FROM #GamesMechanisms
	GROUP BY YearPublished
	)
SELECT BGGId, Name, best_of_year.YearPublished
	, best_rank, AvgRating, games_from_year_in_top_3000
FROM best_of_year
JOIN #GamesMechanisms
	ON best_of_year.Best_rank = #GamesMechanisms.Rank_boardgame
ORDER BY best_of_year.YearPublished DESC
/* 
This table shows the highest ranked game published each year
as well as the number of games published that year that are in the top
3000 ranked games. It could be worth looking into Sleeping Gods, 
the highest ranked game of the 85 games to make the top 3000 released in 2021.
*/

-- 4.2 Examining game weight and ratings
--    4.2.1 Exploring the heaviest (most complex) games with at least 100 ratings
SELECT Name, Rank_boardgame, YearPublished, GameWeight, NumUserRatings
FROM #GamesMechanisms
WHERE NumUserRatings > 100
ORDER BY GameWeight DESC, Rank_boardgame

--    4.2.2 Looking at the average rating, the average rank, and the best rank for each weight group in the top 3000 games
SELECT adjusted_weight, AVG(AvgRating) AS mean_rating
	, AVG(Rank_boardgame) AS mean_rank
	, MIN(Rank_boardgame) AS best_rank
FROM #GamesMechanisms
GROUP BY adjusted_weight
ORDER BY adjusted_weight
/* 
It is often theorized by board gamers that higher-weight games rank higher 
and are rated more highly than lighter, less complex games. This table 
seems to support that presupposition. Games with higher weight are ranked 
and rated, on average, more highly than lighter games. 
*/

--    4.2.3 Discovering which game is the highest ranked for each weight group
WITH weight_groups AS
	(SELECT adjusted_weight, AVG(AvgRating) AS mean_rating
		, AVG(Rank_boardgame) AS mean_rank
		, MIN(Rank_boardgame) AS best_rank
	FROM #GamesMechanisms
	GROUP BY adjusted_weight
	)
SELECT weight.*, game.Name AS best_game_of_weight
FROM weight_groups AS weight
JOIN #GamesMechanisms AS game
	ON weight.best_rank = game.Rank_boardgame
ORDER BY adjusted_weight
/*
This table shows which game is the highest rated for each weight group.
If a game group wants to play a highly-ranked lighter game, The Crew seems
to be an excellent option.
*/

--    4.2.4 Looking at the highest ranked game that is best at 3, 4, and 5 players for each weight group
WITH weight_group_5p AS
	(SELECT BestPlayers, adjusted_weight, AVG(AvgRating) AS mean_rating
		, AVG(Rank_boardgame) AS mean_rank
		, MIN(Rank_boardgame) AS best_rank
	FROM #GamesMechanisms
	GROUP BY adjusted_weight, BestPlayers
	HAVING BestPlayers BETWEEN 3 AND 5
	)
SELECT weight.*, game.Name AS best_game_of_weight
FROM weight_group_5p AS weight
JOIN #GamesMechanisms AS game
	ON weight.best_rank = game.Rank_boardgame
ORDER BY BestPlayers, adjusted_weight
/* 
Different games are better at different number of players. 
This table illustrates the highest ranked game at each weight group
for 3 players, 4 players, and 5 players. If 4 players want to play a 
medium-weight game, they could try Pandemic Legacy or Scythe. 
*/

-- 4.3 Looking at the highest ranked games by playtime range
SELECT BGGId, Name, Rank_boardgame, GoodPlayers, BestPlayers, playtime_range
FROM #GamesMechanisms
ORDER BY playtime_range DESC, Rank_boardgame
/*
Sometimes the biggest factor in determining a game to play is how long
it will take. This table illustrates the highest ranked games in 
order of playtime. If you have 45 minutes,  you might want
to look into The Quacks of Quedlinburg. If you have 60-90 minutes,
Root or The Isle of Cats might be a good fit.
*/


-- 4.4 Examining families of games and their average rating and rank
SELECT Family, COUNT(Family) AS games_in_family
	, AVG(AvgRating) AS avg_rating
	, AVG(Rank_boardgame) AS avg_rank
FROM #GamesMechanisms
GROUP BY Family
HAVING Family <> 'No Family'
ORDER BY games_in_family DESC, avg_rank
/*
If I wanted to look into a specific family of games, the Kosmos
two-player games line has 24 games, and they have an average rating
of 6.84 out of 10. This could be worth looking into.
*/

-- 4.5 Looking into the highest rated games from one of my favorite genres - deck building
SELECT BGGId, Name, Rank_boardgame, AvgRating, GameWeight
FROM #GamesMechanisms
WHERE Deck_Bag_and_Pool_Building = 1
ORDER BY Rank_boardgame
/*
This table shows all games that include the mechanism of deck building.
Since I know I enjoy this mechanism, it is possible that many of these 
games would be a good fit for me.
*/

-- 4.6 Looking into mechanisms contained in our favorite games
--    4.6.1 Comparing mechanisms in the Azul trilogy of games
SELECT GamesClean.BGGId, Name, Rank_boardgame, YearPublished, mechanisms.*
FROM SQLProject..GamesClean
JOIN SQLProject..mechanisms
	ON GamesClean.BGGId = mechanisms.BGGId1
WHERE Name LIKE 'Azul%' 
ORDER BY Rank_boardgame
/*
This table shows the mechanisms in the Azul games, a series of games that
we enjoy. It is interesting to compare the different mechanisms between
each of the three games. They are similar but not identical.
*/

--    4.6.2 Examining mechanisms in some other favorites
SELECT *
FROM #GamesMechanisms
WHERE Name LIKE '%Spirit Island%'
	OR Name LIKE 'Lost Ruins of Arnak%'
	OR Name LIKE '%Century: Golem%'
	OR Name LIKE '%Aeon%s End%'
ORDER  BY Name
/* 
Identifying common mechanisms in these games that we enjoy
allowed me to create a temporary table, below, that onlly contains
games with our favorite mehcanisms.
*/
	
-- 4.7 Creating a temporary table with all games that contain our favorite mechanisms
DROP TABLE IF EXISTS #FavoriteMechanisms

SELECT BGGId, Name, YearPublished, GameWeight, AvgRating, Rank_boardgame
		, Variable_Player_Powers
		, Programmed_Movement
		, Cooperative_Game
		, Worker_Placement
		, Deck_Bag_and_Pool_Building
		, TableauBuilding
		, Drafting
		, Hand_Management
		, Simultaneous_Action_Selection
		, Variable_Set_up
INTO #FavoriteMechanisms
FROM #GamesMechanisms
WHERE 1 IN(Variable_Player_Powers
		, Programmed_Movement
		, Cooperative_Game
		, Worker_Placement
		, Deck_Bag_and_Pool_Building
		, TableauBuilding
		, Drafting
		, Hand_Management
		, Simultaneous_Action_Selection
		, Variable_Set_up
		)
/*
This temporary table contains only games that contain at least one of the 
mechanisms that we enjoy in games. It can be used to further explore
other games that might fit our tastes.
*/

-- 4.8 Exploring games with our favorite mechanisms
--    4.8.1 Checking for games with all 10 mechanisms
SELECT *
FROM #FavoriteMechanisms
WHERE NOT 0 IN (Variable_Player_Powers
		, Programmed_Movement
		, Cooperative_Game
		, Worker_Placement
		, Deck_Bag_and_Pool_Building
		, TableauBuilding
		, Drafting
		, Hand_Management
		, Simultaneous_Action_Selection
		, Variable_Set_up
		)
/*
Unfortunately there are no games in the top 3000 games that have all 10 
of our favorite mechnisms.
*/

--    4.8.2 Adding a column with a count of how many of our top 10 mechanisms each game contains
ALTER TABLE #FavoriteMechanisms
ADD good_fit int

UPDATE #FavoriteMechanisms
SET good_fit = CAST(Variable_Player_Powers AS int)
		+ CAST(Programmed_Movement AS int)
		+ CAST(Cooperative_Game AS int)
		+ CAST(Worker_Placement AS int)
		+ CAST(Deck_Bag_and_Pool_Building AS int)
		+ CAST(TableauBuilding AS int)
		+ CAST(Drafting AS int)
		+ CAST(Hand_Management AS int)
		+ CAST(Simultaneous_Action_Selection AS int)
		+ CAST(Variable_Set_up AS int)
/*
The above code adds a column to the favorite mechanisms table that contains
a score (out of 10) based on how many of our favorite mechanisms that game
contains. 
*/

--    4.8.3 Exploring games that should be a good match for us based on mechanisms
SELECT *
FROM #FavoriteMechanisms
ORDER BY good_fit DESC, Rank_boardgame
/* 
We already have and enjoy Aeon's End, but Mombasa might be a good fit because it 
contains 6 out of 10 of our favorite mechanisms. 
*/

--    4.8.4 Exploring games that contain worker placement and are a good fit for our preferred mechanisms and game weight
SELECT *
FROM #FavoriteMechanisms
WHERE Worker_Placement = 1 AND GameWeight BETWEEN 2 AND 3.5
ORDER BY good_fit DESC, Rank_boardgame
/*
This table filters the favorite mechanisms table for games that are the best fit
and contain the worker placement mechanism. This query suggests that we should 
check out Everdell. 
*/

/*
5. Creating Stored Procedures
*/

-- 5.1 Creating a stored procedure to search game descriptions for specific keywords of interest
DROP PROCEDURE IF EXISTS KeywordSearch	

CREATE PROCEDURE KeywordSearch
@keyword nvarchar(50)
AS
SELECT BGGId, Rank_boardgame
	, Name, Description
	, SUBSTRING(Description, CHARINDEX(@keyword, Description)-75, 150) AS Selected_segment
FROM #GamesMechanisms
WHERE Description LIKE '%'+' ' + @keyword +' ' +'%'
ORDER BY Rank_boardgame
/*
This procedure allows users to search the descriptions of games
in the clean dataset containing the top 3000 ranked games for 
specific keywords. This allowed us to search for some of our other
interests to see if there were games that contain those elements.
*/

--    5.1.1 Using the procedure to see the highest ranked games with descriptions containing specific keywords
EXEC KeywordSearch 
@keyword = 'battle'

EXEC KeywordSearch
@keyword = 'insect'

EXEC KeywordSearch
@keyword = 'cat'

EXEC KeywordSearch
@keyword = 'library'
/*
If we wanted to try a game about libraries, we could check out 
Biblios or Ex Libris
*/

-- 5.2 Creating a stored procedure to search for game recommendations based on player count and desired game weight
DROP PROCEDURE IF EXISTS GameRecommender

CREATE PROCEDURE GameRecommender
@num_players int,
@min_weight float,
@max_weight float
AS
SELECT BGGId, Rank_boardgame, Name, GameWeight, AvgRating, BestPlayers, GoodPlayers
	, CASE
		WHEN BestPlayers = @num_players THEN 'Best'
		ELSE 'Better at ' + CONVERT(nvarchar(50), BestPlayers)
		END AS Player_count_is_best
FROM #GamesMechanisms
WHERE GameWeight BETWEEN @min_weight AND @max_weight
	AND GoodPlayers LIKE CONCAT('%''', CAST(@num_players AS nvarchar(50)), '''%')
ORDER BY Player_count_is_best, Rank_boardgame
/*
This procedure allows users to input their desired number of players and
game weight range and returns games that fit those criteria, ordered by
the highest ranked game that is best at their player count or can at least
be played at that player count. If the current player count is not considered
the best player count, the Player_count_is_best column suggests which player 
count is considered better.
*/

--    5.2.1 Using procedure to see games that allow for (and/or are best at) our desired player count and weight, sorted by rank
EXEC GameRecommender
@num_players = 2,
@min_weight = 3.5,
@max_weight = 4

EXEC GameRecommender
@num_players = 6,
@min_weight = 1,
@max_weight = 3

EXEC GameRecommender
@num_players = 4,
@min_weight = 1.5,
@max_weight = 2.75
/*
If four players are looking to play a light-medium game that is best at
four, they could try Clank! or The Crew. This group could play any of
the games on this list, but some are rated better at other player counts.
Cosmic Encounter would work with 4, but is rated as best at 5.
*/