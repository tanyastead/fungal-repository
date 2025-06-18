# populate_repository.py script to import gene expression data into sqlite3 database

# import necessary packages
import argparse
import csv 
import sqlite3 

# Define the argparse arguments
parser = argparse.ArgumentParser(
    description="""Populate empty transcriptomics gene expression database"""
)

parser.add_argument(
    'gene_exp_db', type=str, nargs='?',
    help="empty sqlite database (it should have the schema from repository.sql)",
    default='./repository.sqlite'
)
parser.add_argument(
    'input_csv_path', type=str,
    help="input CSV file containing gene expression data"
)
parser.add_argument(
    '-a', '--annotation_file',
    help="specify the database will be loaded with an annotation file"
)

""" NOTE: at the moment have separate files for gene expression/molecular function
Both kinds of files need to be inputted into the database - have separate arguments/functions for if this is the case?
Can also include separate optional arguments to include fungal species and abiotic conditions?
"""

args = parser.parse_args()

# connect to database
conn = sqlite3.connect(args.micro_db) # connect to sqlite3 ###NOTE: need to change path in args!!

# Define dictionaries and sets to keep track of database input
gene_id = set()
conditions = set()
