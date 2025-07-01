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
stored_contrasts = set()
stored_gene_contrasts = set()


# Create a function to insert gene_id and fungal species into the Genes table
def insert_species(db_cursor, gene_id):
    if gene_id not in known_gene_ids:
        db_cursor.execute(
            'INSERT INTO Genes (gene_id, species) VALUES (?,?);', (gene_id, args.species)
            )
        known_gene_ids.append(gene_id)

# Create a function to check if experiment recorded in Experiments table. If yes, return experimentID, if no, populate table and create experiment ID
def insert_experiment(db_cursor, author, year, description, species, keywords):
    # generate the experiment id for this experiment
    exp_id = author + "_" + year

    if exp_id not in stored_exp_id:
        db_cursor.execute(
            'INSERT INTO Experiments VALUES (?,?,?,?,?);',
            (exp_id, author, year, description, species)
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
def insert_gene_contrasts_DEG(db_cursor, gene_id, contrast, lFC, lfcSE, pval, padj, exp_id):
    # create gene_contrast
    gene_contrast = gene_id + "_" + contrast
    # populate GeneContrasts table
    db_cursor.execute(
        'INSERT INTO GeneContrasts VALUES (?,?,?,?);',
        (gene_contrast, gene_id, contrast, exp_id)
    )
    # populate DEG table
    db_cursor.execute(
        'INSERT INTO DEG VALUES (?,?,?,?,?);',
        (gene_contrast, lFC, lfcSE, pval, padj)
    )

# Safely insert float values or none when an NA value is encountered
def safe_float(value):
    try:
        return float(value)
    except:
        return None

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
        query_gene_id = 'SELECT gene_id FROM Genes;'
        cursor.execute(query_gene_id)
        known_gene_ids.extend([row[0] for row in cursor.fetchall()])

        # ## Insert genes data
        # for i, row in enumerate(reader):
        #     try:
        #         if i == 0:
        #             contrast = write_contrast(row[1], row[2])
        #         insert_species(cursor, row[0])
        #         insert_gene_contrasts_DEG(cursor, row[0], contrast, row[6], row[7], row[9], row[10])
        #     except Exception as e:
        #         exit(f'Error: could not enter gene expression data: {e}')
    
        ## Determine which experiments are populated in the DB
        query_exp_id = 'SELECT experiment_id FROM Experiments;'
        cursor.execute(query_exp_id)
        stored_exp_id.extend([row[0] for row in cursor.fetchall()])

        ## Determine which gene_contrasts are populated in the DB
        query_gene_contrast = "SELECT gene_contrast FROM DEG;"
        cursor.execute(query_gene_contrast)
        stored_gene_contrasts.update([row[0] for row in cursor.fetchall()])
        
        ## Perform different arguments depending on the input files
        if args.experiment_file:
            with open(args.experiment_file, mode='r', encoding='utf-8') as exp_file:
                if args.experiment_file.endswith('.csv'):
                    delimeter2 = ','
                elif args.experiment_file.endswith('.txt'):
                    delimeter2 = '\t'
                else:
                    raise ValueError('Unsupported file type.')
                
                ## Read and extract information from the exp file
                exp_reader = csv.reader(exp_file, delimiter=delimeter2) # read the exp file
                next(exp_reader) # skip the header row
                keys = []
                author = ""
                year = ""
                description = ""

                for exp_row in exp_reader:
                    keys = [key.strip() for key in exp_row[3].split(',')]
                    author = exp_row[0]
                    year = exp_row[1]
                    description = exp_row[2]
            # with open(args.experiment_file, mode='r', encoding='utf-8') as exp_file:
            #     reader = csv.DictReader(exp_file)
            #     for row in reader:
            #         if not row.get("keywords"):
            #             continue
            #         keys = [k.strip() for k in row["keywords"].split(",")]
            #         author = row["author"]
            #         year = row["year"]
            #         description = row["description"]

                ## Insert genes data
                exp_id = author + "_" + year
                for i, row in enumerate(reader):
                    try:
                        if i == 0:
                            contrast = write_contrast(row[1], row[2])
                        insert_species(cursor, row[0])
                        gene_contrast = row[0] + "_" + contrast
                        if gene_contrast not in stored_gene_contrasts:
                            insert_gene_contrasts_DEG(cursor, 
                                                      row[0], 
                                                      contrast, 
                                                      safe_float(row[6]), 
                                                      safe_float(row[7]),
                                                      safe_float(row[9]), 
                                                      safe_float(row[10]), 
                                                      exp_id)
                    except Exception as e:
                        exit(f'Error: could not enter gene expression data: {e}')

                ## Check what contrasts are stored in the DB
                contrast_query = f"SELECT contrast FROM ExpContrasts WHERE experiment_id = '{exp_id}';"
                cursor.execute(contrast_query)
                stored_contrasts.update([row[0] for row in cursor.fetchall()])

                ## Insert the experiment data
                try:
                    insert_experiment(cursor, author, year, description, args.species, keys)
                    if contrast not in stored_contrasts:
                        insert_exp_contrast(cursor, author, year, contrast)
                except Exception as e:
                    exit(f"Error: could not enter experiment data: {e}")
                # for exp_row in exp_reader:
                #     keys = [key.strip() for key in exp_row[3].split(',')]
                #     try:
                #         insert_experiment(cursor, exp_row[0], exp_row[1], exp_row[2], args.species, keys)
                #         insert_exp_contrast(cursor, exp_row[0], exp_row[1], contrast)
                #     except Exception as e:
                #         exit(f"Error: could not enter experiment data: {e}")
                

        elif (args.author and args.year and args.description and args.keyword):
            exp_id = args.author + "_" + args.year
            ## Insert genes data
            for i, row in enumerate(reader):
                try:
                    if i == 0:
                        contrast = write_contrast(row[1], row[2])
                    insert_species(cursor, row[0])
                    gene_contrast = row[0] + "_" + contrast
                    if gene_contrast not in stored_gene_contrasts:
                        insert_gene_contrasts_DEG(cursor, row[0], contrast, row[6], row[7], row[9], row[10], exp_id)
                except Exception as e:
                    exit(f'Error: could not enter gene expression data: {e}')
            
            contrast_query = f"SELECT contrast FROM ExpContrasts WHERE experiment_id = '{exp_id}';"
            cursor.execute(contrast_query)
            stored_contrasts.update([row[0] for row in cursor.fetchall()])

            try:
                insert_experiment(cursor, args.author, args.year, args.description, args.species, args.keyword)
                if contrast not in stored_contrasts:
                    insert_exp_contrast(cursor, args.author, args.year, contrast)   
            except Exception as e:
                exit(f"Error: could not enter experiment data: {e}")


        elif (args.author and args.year):
            exp_id = args.author + "_" + args.year
            ## Insert genes data
            for i, row in enumerate(reader):
                try:
                    if i == 0:
                        contrast = write_contrast(row[1], row[2])
                    insert_species(cursor, row[0])
                    gene_contrast = row[0] + "_" + contrast
                    if gene_contrast not in stored_gene_contrasts:
                        insert_gene_contrasts_DEG(cursor, row[0], contrast, row[6], row[7], row[9], row[10], exp_id)
                except Exception as e:
                    exit(f'Error: could not enter gene expression data: {e}')

            contrast_query = f"SELECT contrast FROM ExpContrasts WHERE experiment_id = '{exp_id}';"
            cursor.execute(contrast_query)
            stored_contrasts.update([row[0] for row in cursor.fetchall()])

            try:
                if contrast not in stored_contrasts:
                    insert_exp_contrast(cursor, args.author, args.year, contrast)
            except Exception as e:
                exit(f"Error: could not enter experiment data: {e}")

