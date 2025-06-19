# fungal-repository
MSc thesis fungal repository holding fungal transcriptomic data for the analysis of gene expression under different climatic conditions

## Creating SQLite Database
To create the sqlite3 database, run the following in the root directory of this repository.
```sqlite3 database/repository.sqlite < database/repository.sql```

## Populating the SQLite Database

--> files must either be .txt or .csv

## Connecting the SQLite Database
Change the full path of `repository.sqlite` defined in `./app/global.R` to the full path on your local machine
