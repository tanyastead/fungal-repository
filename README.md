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

### A. Populating the database from the command line
1. To populate the SQLite database from the command line, first run `populate_genes.py` in one of the following formats:
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -e path/to/experiment_data`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year -t "Experiment description/title" -k keyword -k "keyword 2"`
    - `python database/populate_genes.py -g path/to/gene_expression_data -s "Fungal species" -a author -y year`
        - This option can be run if experiment information has already been entered into the database

2. To add gene functional information, run `populate_annot.py`. This only file only needs to be run once per experiment
    - `python database/populate_annot.py -a path/to/gene_annotation_data`

### B. Populating the database from the frontend interface
To populate the database from the frontend inteface, navigate to the `Upload` tab. The user must first add differential expression data by filling out author, year, fungal species, keywords, description, choosing the file containing differential expression data and clicking `Upload`.

Once upload is complete, the user can add functional annotation data for the study by choosing the appropriate file, selecting the type of data in column 2 and clickung `Upload`.

## Initialising the repository
The Fungal Transcriptomic Database is a local application that is hosted and run only on the local machine. To start the application, open app.R and click on `Run App` in the top right corner. This will open a popup window containing the repository. Click on `open in browser` to open the reposioty in a browser window to access GO term hyperlinks. 

## Running the repository
### A. Searching the database
After initialising the repository, the user is presented with the main 'Search' tab where they can query the database. Here, the user can switch between searching by `Gene (Name or Function)`, e.g. `FG1G19350` or `toxin`, or experimental `Condition`, e.g. `temperature`. Clicking the `Search` button will query the database and automatically navigate the user to the 'Results' tab where the output from the search query is displayed.

### B. Exploring the output from the search
Once the user can clicked on the `Search` button on the main page, they are automatically navigated to the 'Results' tab, which displays the output from the search query. 

If the user selected `Gene (Name or Function)`, they are presented with a table containing 6 columns: `Gene`, which lists gene ID; `Functional Annotation`, displaying gene description, if available, with text hyperlinked to the corresponding GO web page when GO terms are present in the input file; `Contrasts`, listing all experimental contrasts investigated in the study where the gene was identified; `Author`, displaying the author(s) associated with the study, `Year`, indicating the year the study was conducted; and `Description`, which displays either the study title or is a short description of the study.

If the user selected `Condition`, they are presented with a table containing only 4 columns: `Contrasts`, `Author`, `Year`, and `Descriptioin`.

In both views, to the left of the table is a sidepanel where the user can refine the data presented in the table. They can select the fungal species involved in the study and refine the displayed studies based on associated experimental condition. Clicking on the `down arrow` button displays the search logic functionality when refining by experimental condition, allowing the user to switch between AND and OR logic. Lastly, the user can refine by the year when the study was conducted.

The `Clear` button at the bottom of the side panel clears all the inputs and returns the table to its original view based on the query, and the `Export table` button downloads the table in its current view.

### C. Visualising DEGs for a specific contrast
To visualise DE data, the user can click an experimental contrast, which will bring the user to the 'Experiments' tab. This tab displays all DEGs identified in that contrast. The 'Experiments' tab contains 3 subtabs, displaying the data in 3 formats:
    - 1. `Data Table` - a table with 6 columns displaying DEGs. The columns are: `Gene`, displaying gene ID; `Functional Annotation`, showing gene description, with text hyperlinked to the corresponding GO web page when GO terms are present in the input file; `Log2-fold change`, showing the log<sub>2</sub>-fold change value to 3 decimal places; `Log-Fold change standard error`, showing the log<sub>2</sub>-fold change standard error to 3 decimal places; `P-Value`, showing the p-value of the log<sub>2</sub>-fold change to 3 decimal places; `P-Adjusted`, showing the p-adjusted value of the log<sub>2</sub>-fold change to 3 decimal places.
   - 2. `Volcano Plot` - an interactive volcano plot of log<sub>2</sub>-fold change against p-value. Hovering over a point will display gene ID and functional annotation, if available, and clicking on a point will navigate the user to the 'Gene Info' tab, which displays the functional annotation and GO terms associated with that gene.
   - 3. `Expression Heatmap` - an interactive heatmap showing differential expression of up to 30 genes across all contrasts associated with the study. Hovering over a tile will display gene ID, log<sub>2</sub>-fold change and functional annotation, if available, and clicking on a point will navigate the user to the 'Gene Info' tab, which displays the functional annotation and GO terms associated with that gene.