# populate_genes.py script to import gene expression data into sqlite3 database

# import necessary packages
import argparse
import csv 
import sqlite3 

# Define the argparse arguments
parser = argparse.ArgumentParser(
    description="""Populate database with gene expression data"""
)
parser.add_argument(
    '-d', '--database',  nargs='?',
    help="path to repository.sqlite database",
    default="./database/repository.sqlite"
)
parser.add_argument(
    '-g', '--genes_file', help="full path to file containing gene differential expression data"
)
parser.add_argument(
    '-s', '--species', help="fungal species"
)



parser.add_argument(
    '-e', '--experiment_file', 
    help="A csv or txt file containing experiment information, including author, year, description, and keywords"
)
parser.add_argument(
    '-a', '--author',
    help='author of the study'
)
parser.add_argument(
    '-y', '--year', help="year the study was conducted"
)
parser.add_argument(
    '-t', '--description', help="Description or title of the study. Should be enclosed in quotation marks"
)
parser.add_argument(
    '-k', '--keyword', type=str, action='append',
    help="enter key terms relevant to the study, e.g. heat"
)


""" NOTE: at the moment have separate files for gene expression/molecular function
Both kinds of files need to be inputted into the database - have separate arguments/functions for if this is the case?
Can also include separate optional arguments to include fungal species and abiotic conditions?
"""

args = parser.parse_args()

# connect to database
conn = sqlite3.connect(args.database) # connect to sqlite3 

# Define dictionaries and sets to keep track of database input
known_gene_ids = set()
exp_id = ""
contrast = ""


# Create a function to insert gene_id and fungal species into the Genes table
def insert_species(db_cursor, gene_id):
    if gene_id not in known_gene_ids:
        db_cursor.execute(
            'INSERT INTO Genes (gene_id, species) VALUES (?,?);', (gene_id, args.species)
            )
        known_gene_ids.add(gene_id)

# Create a function to check if experiment recorded in Experiments table. If yes, return experimentID, if no, populate table and create experiment ID
def insert_experiment(db_cursor, author, year, description, keywords):
    # generate the experiment id for this experiment
    exp_id = author + "_" + year
    # define and execute query
    query = 'SELECT experiment_id FROM Experiments;'
    db_cursor.execute(query)
    stored_exp_id = [row[0] for row in db_cursor.fetchall()]
    # check if exp_id recorded in table, and save experiment if not
    if exp_id not in stored_exp_id:
        db_cursor.execute(
            'INSERT INTO Experiments VALUES (?,?,?,?);',
            (exp_id, author, year, description)
        )
        # also populate the ExpKeywords table
        for word in keywords:
            db_cursor.execute(
                'INERT INTO ExpKeywords VALUES (?,?)',
                (exp_id, word)
            )
    
# Create a function to create the contrast from condition 1 and condition 2
def write_contrast(condition1, condition2):
    contrast = condition1 + "_vs_" + condition2
    return contrast

# Populate ExpContrasts table
def insert_exp_contrast(db_cursor, author, year, contrast):
    exp_id = author + "_" + year
    db_cursor.execute(
        'INSERT INTO ExpContrasts VALUES (?,?);',
        (exp_id, contrast)
    )

# Populate GeneConstrasts  and DEG table
def insert_gene_contrasts_DEG(db_cursor, gene_id, contrast, lFC, lfcSE, pval, padj):
    # create gene_contrast
    gene_contrast = gene_id + "_" + contrast
    # populate GeneContrasts table
    db_cursor.execute(
        'INSERT INTO GeneContrasts VALUES (?,?,?);',
        (gene_contrast, gene_id, contrast)
    )
    # populate DEG table
    db_cursor.execute(
        'INSERT INTO DEG VALUES (?,?,?,?,?);',
        (gene_contrast, lFC, lfcSE, pval, padj)
    )


if args.experiment_file:
    # read file and execute functions
    print("hello")
elif (args.author and args.year and args.description and args.keyword):
    # use tags to populate DB
    print("hel")
elif (args.author and args.year):
    with open(args.genes_file, mode='r', encoding='utf-8') as file, \
    sqlite3.connect(args.database) as db_connection:
        ## Define what the delimiter should be based on the input file type
        if args.genes_file.endswith('.csv'):
            delimeter = ','
        elif args.genes_file.endswith('.txt'):
            delimeter = '\t'
        else:
            raise ValueError('Unsupported file type.')
        
        ## Read the annotation file
        reader = csv.reader(file, delimiter=delimeter)

        ## Establish connection to the db
        cursor = db_connection.cursor()

        # Skip the header row
        next(reader)
        

        for row in reader:
            try:
                insert_species(cursor, row[0])
            except Exception as e:
                print(f"Error inserting function insert_species: {e}")
                exit('Error: Data import failed')
            try:
                write_contrast(row[1], row[2])
            except Exception as e:
                print(f"Error inserting function write_contrast: {e}")
                exit('Error: Data import failed')
            
            try:
                insert_gene_contrasts_DEG(cursor, row[0], contrast, row[6], row[7], row[9], row[10])
            except Exception as e:
                print(f"Error inserting function insert_gene_contrasts_DEG: {e}")
                exit('Error: Data import failed')
        
        try:
            insert_exp_contrast(cursor, args.author, args.year, contrast)
        except Exception as e:
            print(f"Error inserting function insert_exp_contrast: {e}")
            exit('Error: Data import failed')
else:
    print("error message")





### if -csv selected, do this; else if tags selected, do that
