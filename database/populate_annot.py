# populate_annot.py script to populate repository with gene annotation data

# import necessary packages
import argparse
import csv 
import sqlite3 

# Define the argparse arguments
parser = argparse.ArgumentParser(
    description="""Populate database with gene annotation data"""
)
parser.add_argument(
    '-a', '--annotation_file', 
    help="full path to annotation file containing geneIDs, GO terms and molecular functions"
)
parser.add_argument(
    '-d', '--database',  nargs='?',
    help="path to repository.sqlite database",
    default="./database/repository.sqlite"
)

args = parser.parse_args()

# Connect to sqlite database
conn = sqlite3.connect(args.database)

# Define a set to store geneIDs
geneID = []


# Open and read the annotation file and populate the database
with open(args.annotation_file, mode='r', encoding='utf-8') as file, \
    sqlite3.connect(args.database) as db_connection:

    ## Define what the delimiter should be based on the input file type
    if args.annotation_file.endswith('.csv'):
        delimeter = ','
    elif args.annotation_file.endswith('.txt'):
        delimeter = '\t'
    else:
        raise ValueError('Unsupported file type.')
    
    ## Read the annotation file
    reader = csv.reader(file, delimiter=delimeter)

    ## Establish connection to the db
    cursor = db_connection.cursor()

    ## Define and execute the query
    queryGeneID = 'SELECT gene_id FROM GeneFunctions;'
    cursor.execute(queryGeneID)
    # Store the geneIDs
    geneID.extend([row[0] for row in cursor.fetchall()])

    ## Input the geneIDs and functions
    for row in reader:
        try:
            if row[0] not in geneID:
                cursor.execute(f'INSERT INTO GeneFunctions VALUES ("{row[0]}", "{row[2]}");')
                geneID.append(row[0])
        except Exception as e:
            exit(f'Error inserting row {row}: {e}')

