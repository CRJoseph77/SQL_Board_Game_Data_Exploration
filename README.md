# Exploring Board Game Recommendations Using SQL
Cleaning and exploring board game data from BoardGameGeek.com using SQL.

## Project Overview
Collecting and playing board games with others is one of my favorite hobbies. I enjoy sharing fun experiences around the table with friends and family. 

Another element of the board game hobby is discovering and exploring new games to share with others. With the ever-increasing amount of board games published each year, it can be difficult to find games that fit the tastes and preferences of my game group. This project aims to use data from boardgamegeek.com to find game recommendations based on a variety of different factors (game complexity, player count, category, etc.). 

The boardgamegeek.com data was explored, cleaned, structured, and manipulated to discover highly ranked games that might be a good fit for me and the people I play games with. 

## Code and Resources Used
Editor Used: This project was created using Microsoft’s SQL Server Management Studio 19.

## Data
1. Source data: The data originally comes from a popular board game reference site, boardgamegeek.com. The two relevant datasets for this project are the [games.csv](games.csv) dataset and the [mechanics.csv](mechanics.csv)

2. Acquisition: The boardgamegeek.com data used for this project was downloaded from Kaggle (https://www.kaggle.com/datasets/threnjen/board-games-database-from-boardgamegeek).
  
3. Preprocessing: No preprocessing was performed prior to importing the CSV files into Microsoft SQL Server Management Studio. During the process of importing, column data types were automatically detected. A few of them had to be inspected to ensure that numbers were being treated as integers or floats and that strings were being interpreted properly as strings. 

## Results
An exploration of the BoardGameGeek.com data allowed me to successfully identify multiple games that may be a good fit for my group based on multiple different metrics such as year published, player count, play time, game weight, and other factors. I also was able to gain insight into how games are ranked and rated based on their complexity, with higher-weight games generally being ranked and rated more favorably. I was also able to identify which games might be a good fit for me based on the mechanisms I enjoy. Finally, I was able to create stored procedures that return game recommendations based on specified keywords in the game description or player count and game weight. 

## References
Kaggle Data: https://www.kaggle.com/datasets/threnjen/board-games-database-from-boardgamegeek.
Sources: BoardGameGeek: https://boardgamegeek.com/.

All data was sourced and shared in accordance with the XML API Terms of Use: https://boardgamegeek.com/wiki/page/XML_API_Terms_of_Use.

## License
The license associated with the data used for this project is CC BY-SA 3.0.
