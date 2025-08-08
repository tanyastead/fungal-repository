# Fungal Transcriptomic Database
MSc thesis fungal repository holding fungal transcriptomic data for the analysis of gene expression under different climatic conditions

## Creating SQLite Database
To create the SQLite database, run the following in the root directory of this repository.
```sqlite3 database/repository.sqlite < database/repository.sql```

## Connecting the SQLite Database
Before initiating the repository, set the working directory at line 26 in `global.R` to the `fungal-repository` root directory.

## Populating the SQLite Database
The SQLite database can either be populated through the command line or via the `Upload` tab in the frontend interface.

Populating the database requires the following data:
- gene expression data (in `.txt` or `.csv` format). The data should be organised in the following columns, with the first row as the header:
    - geneID | conditionA | conditionB | baseMeanA | baseMeanB | LFC | lfcSE | stat | pval | padj
    - The number of columns must be 10, however only the following columns must contain data: geneID, conditionA, conditionB, LFC, pval and padj
- gene function data (in `.txt` or `.csv` format). The data should be organised in the either of the following formats. The file should not contain a header.
    - geneID | GO terms | gene description
    - geneID | gene description
- experiment data (in `.txt` or `.csv` format, or can be entered manually as arguments)
    - If a `txt` or `csv` file is supplied, the file should be structure in the following format, with the first row as the header
    author | year | description | keywords (separated by commas)

### Populating the database from the command line
1. To populate the SQLite database from the command line, first run `populate_genes.py` in one of the following formats:
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -e path/to/experiment_data`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year -t "Experiment description/title" -k keyword -k "keyword 2"`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year`
        - This option can be run if experiment information has already been entered into the database

2. To add gene functional information, run `populate_annot.py`. This only file only needs to be run once per experiment
    - `python database/populate_annot.py -a path/to/gene_annotation_data`

### Populating the database from the frontend interface
To populate the database from the frontend inteface, navigate to the `Upload` tab. The user must first add differential expression data by filling out author, year, fungal species, keywords, description, choosing the file containing differential expression data and clicking `Upload`.

Once upload is complete, the user can add functional annotation data for the study by choosing the appropriate file, selecting the type of data in column 2 and clickung `Upload`.

## Running the repository
The Fungal Transcriptomic Database is a local application that is hosted and run only on the local machine. To start the application, open app.R and click on `Run App` in the top right corner. This will open a popup window containing the repository. Click on `open in browser` to open the reposioty in a browser window to access GO term hyperlinks. 
