# populate_genes.py script to import gene expression data into sqlite3 database

# import necessary packages
import argparse
import csv 
import sqlite3 

# Define the argparse arguments
## Mandatory arguments
parser = argparse.ArgumentParser(
    description="""Populate database with gene expression data"""
)
parser.add_argument(
    '-d', '--database',  nargs='?',
    help="path to repository.sqlite database",
    default="./database/repository.sqlite"
)
parser.add_argument(
    '-g', '--genes_file', help="full path to file containing gene differential expression data",
    required=True
)
parser.add_argument(
    '-s', '--species', help="fungal species", required=True
)

## Optional arguments
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
    help="""enter key terms relevant to the study, e.g. heat. 
    If adding several terms, pass each term individually with their own argument, 
    e.g. -k heat -k temperature -k "water activity" 
    """
)

args = parser.parse_args()

# connect to database
conn = sqlite3.connect(args.database) # connect to sqlite3 


# Define dictionaries and sets to keep track of database input
known_gene_ids = []
exp_id = ""
contrast = ""
stored_exp_id = []


# Create a function to insert gene_id and fungal species into the Genes table
def insert_species(db_cursor, gene_id):
    if gene_id not in known_gene_ids:
        db_cursor.execute(
            'INSERT INTO Genes (gene_id, species) VALUES (?,?);', (gene_id, args.species)
            )
        known_gene_ids.append(gene_id)

# Create a function to check if experiment recorded in Experiments table. If yes, return experimentID, if no, populate table and create experiment ID
def insert_experiment(db_cursor, author, year, description, keywords):
    # generate the experiment id for this experiment
    exp_id = author + "_" + year

    if exp_id not in stored_exp_id:
        db_cursor.execute(
            'INSERT INTO Experiments VALUES (?,?,?,?);',
            (exp_id, author, year, description)
        )
        # also populate the ExpKeywords table
        for word in keywords:
            db_cursor.execute(
                'INSERT INTO ExpKeywords VALUES (?,?)',
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



with open(args.genes_file, mode='r', encoding='utf-8') as file, \
    sqlite3.connect(args.database) as db_connection:
        ## Define what the delimiter should be based on the input file type
        if args.genes_file.endswith('.csv'):
            delimeter = ','
        elif args.genes_file.endswith('.txt'):
            delimeter = '\t'
        else:
            raise ValueError('Unsupported file type.')

        ## Set-up the files
        reader = csv.reader(file, delimiter=delimeter) ## Read the genes file
        cursor = db_connection.cursor() ## Establish connection to the db
        next(reader) # Skip the header row

        ## Determine which genes are populated in the DB
        query = 'SELECT gene_id FROM Genes;'
        cursor.execute(query)
        known_gene_ids.extend([row[0] for row in cursor.fetchall()])

        ## Insert genes data
        for i, row in enumerate(reader):
            try:
                if i == 0:
                    contrast = write_contrast(row[1], row[2])
                insert_species(cursor, row[0])
                insert_gene_contrasts_DEG(cursor, row[0], contrast, row[6], row[7], row[9], row[10])
            except Exception as e:
                exit(f'Error: could not enter gene expression data: {e}')
    
        ## Determine which experiments are populated in the DB
        query = 'SELECT experiment_id FROM Experiments;'
        cursor.execute(query)
        stored_exp_id.extend([row[0] for row in cursor.fetchall()])
        
        ## Perform different arguments depending on the input files
        if args.experiment_file:
            with open(args.experiment_file, mode='r', encoding='utf-8') as exp_file:
                if args.genes_file.endswith('.csv'):
                    delimeter2 = ','
                elif args.genes_file.endswith('.txt'):
                    delimeter2 = '\t'
                else:
                    raise ValueError('Unsupported file type.')
                
                exp_reader = csv.reader(exp_file, delimiter=delimeter2) # read the exp file
                next(exp_reader) # skip the header row

                ## Insert the experiment data
                for exp_row in exp_reader:
                    keys = [key.strip() for key in exp_row[3].split(',')]
                    try:
                        insert_experiment(cursor, exp_row[0], exp_row[1], exp_row[2], keys)
                        insert_exp_contrast(cursor, exp_row[0], exp_row[1], contrast)
                    except Exception as e:
                        exit(f"Error: could not enter experiment data: {e}")
                

        elif (args.author and args.year and args.description and args.keyword):
            try:
                insert_experiment(cursor, args.author, args.year, args.description, args.keyword)
                insert_exp_contrast(cursor, args.author, args.year, contrast)   
            except Exception as e:
                exit(f"Error: could not enter experiment data: {e}")


        elif (args.author and args.year):
            try:
                insert_exp_contrast(cursor, args.author, args.year, contrast)
            except Exception as e:
                exit(f"Error: could not enter experiment data: {e}")

