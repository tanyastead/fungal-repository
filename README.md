# fungal-repository
MSc thesis fungal repository holding fungal transcriptomic data for the analysis of gene expression under different climatic conditions

## Creating SQLite Database
To create the SQLite database, run the following in the root directory of this repository.
```sqlite3 database/repository.sqlite < database/repository.sql```

## Populating the SQLite Database
Populating the database requires the following data:
- gene expression data (in `.txt` or `.csv` format)
- gene function data (in `.txt` or `.csv` format)
- experiment data (in `.txt` or `.csv` format, or can be entered manually as arguments)
    - If a `txt` or `csv` file is supplied, the file should be structure in the following format, with the first row as the header
    author | year | description | keywords (separated by commas)

1. To populate the SQLite database, first run `populate_genes.py` in one of the following formats:
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -e path/to/experiment_data`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year -t "Experiment description/title" -k keyword -k "keyword 2"`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year`
        - This option can be run if experiment information has already been entered into the database

2. To add gene functional information, run `populate_annot.py`. This only file only needs to be run once per experiment
    - `python database/populate_annot.py -a path/to/gene_annotation_data`



--> files must either be .txt or .csv
--> experiment file - keywords in col 4 seperated by comma

## Connecting the SQLite Database
Change the full path of `repository.sqlite` defined in `./app/global.R` to the full path on your local machine

## Running the app
