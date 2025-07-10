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
parser.add_argument(
    '-g', '--go_term',
    help="indicates that the annotation file contains go terms in the second column and functional annotation in the 3rd column"
)
args = parser.parse_args()

# Connect to sqlite database
conn = sqlite3.connect(args.database)

# Define a set to store geneIDs
geneID = {}
geneFTS = set()


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
    queryGeneID = 'SELECT gene_id, go_term FROM GeneGo;'
    cursor.execute(queryGeneID)
    # Store the geneIDs in the dictionary. Go_terms are stored as a list associated with each 
    # geneID.update([row[0] for row in cursor.fetchall()])
    for gene_id, go_term in cursor.fetchall():
        if gene_id in geneID:
            geneID[gene_id].append(go_term)
        else:
            geneID[gene_id] = [go_term]

    ## Define and execute the query for the FTS table
    queryFTS = 'SELECT gene_id FROM GeneFunctions;'
    cursor.execute(queryFTS)
    geneFTS.update(row[0] for row in cursor.fetchall())

    ## If user indicates annotation file in format: gene_id | go_term | functional_annotation
    if args.go_term:

        ## Input the geneIDs and functions
        for row in reader:
            gene_id = row[0]
            go_term = row[1]
            if len(row) > 2:
                gene_function = row[2]

            try:
                if gene_id in geneID and go_term in geneID[gene_id]:
                    continue  # Skip this row, combo already exists

                cursor.execute(
                    'INSERT INTO GeneGo (gene_id, go_term) VALUES (?, ?)',
                    (gene_id, go_term)
                )
                # if gene_id not in geneFTS and gene_function is not None:
                # to check if gene_function exists and is not just whitespace
                if gene_id not in geneFTS and gene_function and gene_function.strip():
                    # TODO: need check to make sure not inserting empty/repetitive into FTS!!
                    cursor.execute(
                        'INSERT INTO GeneFunctions (gene_id, go_func, gene_function) VALUES (?, ?, ?)',
                        (gene_id, go_term, gene_function)
                    )
                    cursor.execute(
                        'INSERT INTO GeneFunctions_FTS (gene_id, go_func, gene_function) VALUES (?, ?, ?)',
                        (gene_id, go_term, gene_function)
                    )
                    geneFTS.add(gene_id)
                

                # Update the dictionary to avoid re-inserting
                if gene_id in geneID:
                    geneID[gene_id].append(go_term)
                else:
                    geneID[gene_id] = [go_term]

            except Exception as e:
                print(f"Error inserting {gene_id}, {go_term}: {e}")
    
    ## If user indicates annotation file in format of: gene_id | functional_annotation
    else:
        ## Input the geneIDs and functions
        for row in reader:
            gene_id = row[0]
            if len(row) > 1:
                gene_function = row[1]

            try:
                # if gene_id in geneID and go_term in geneID[gene_id]:
                #     continue  # Skip this row, combo already exists

                # cursor.execute(
                #     'INSERT INTO GeneGo (gene_id, go_term) VALUES (?, ?)',
                #     (gene_id, go_term)
                # )
                if gene_id not in geneFTS and gene_function and gene_function.strip():
                    # TODO: need check to make sure not inserting empty/repetitive into FTS!!
                    cursor.execute(
                        'INSERT INTO GeneFunctions (gene_id, gene_function) VALUES (?, ?)',
                        (gene_id, gene_function)
                    )
                    cursor.execute(
                        'INSERT INTO GeneFunctions_FTS (gene_id, gene_function) VALUES (?, ?)',
                        (gene_id, gene_function)
                    )
                    geneFTS.add(gene_id)
                

                # # Update the dictionary to avoid re-inserting
                # if gene_id in geneID:
                #     geneID[gene_id].append(go_term)
                # else:
                #     geneID[gene_id] = [go_term]

            except Exception as e:
                print(f"Error inserting {gene_id}: {e}")






#### ORIGINAL WORKING CODE ---------------------
# # Open and read the annotation file and populate the database
# with open(args.annotation_file, mode='r', encoding='utf-8') as file, \
#     sqlite3.connect(args.database) as db_connection:

#     ## Define what the delimiter should be based on the input file type
#     if args.annotation_file.endswith('.csv'):
#         delimeter = ','
#     elif args.annotation_file.endswith('.txt'):
#         delimeter = '\t'
#     else:
#         raise ValueError('Unsupported file type.')
    
#     ## Read the annotation file
#     reader = csv.reader(file, delimiter=delimeter)

#     ## Establish connection to the db
#     cursor = db_connection.cursor()

#     ## Define and execute the query
#     queryGeneID = 'SELECT gene_id, go_term FROM GeneFunctions;'
#     cursor.execute(queryGeneID)
#     # Store the geneIDs in the dictionary. Go_terms are stored as a list associated with each 
#     # geneID.update([row[0] for row in cursor.fetchall()])
#     for gene_id, go_term in cursor.fetchall():
#         if gene_id in geneID:
#             geneID[gene_id].append(go_term)
#         else:
#             geneID[gene_id] = [go_term]

#     ## Define and execute the query for the FTS table
#     queryFTS = 'SELECT gene_id FROM GeneFunctions_FTS;'
#     cursor.execute(queryFTS)
#     geneFTS.update(row[0] for row in cursor.fetchall())


#     ## Input the geneIDs and functions
#     for row in reader:
#         gene_id = row[0]
#         go_term = row[1]
#         if len(row) > 2:
#             gene_function = row[2]

#         try:
#             if gene_id in geneID and go_term in geneID[gene_id]:
#                 continue  # Skip this row, combo already exists

#             cursor.execute(
#                 'INSERT INTO GeneFunctions (gene_id, go_term, gene_function) VALUES (?, ?, ?)',
#                 (gene_id, go_term, gene_function)
#             )
#             if gene_id not in geneFTS and gene_function:
#                 # TODO: need check to make sure not inserting empty/repetitive into FTS!!
#                 cursor.execute(
#                     'INSERT INTO GeneFunctions_FTS (gene_id, gene_function) VALUES (?, ?)',
#                     (gene_id, gene_function)
#                 )
#                 geneFTS.add(gene_id)

#             # Update the dictionary to avoid re-inserting
#             if gene_id in geneID:
#                 geneID[gene_id].append(go_term)
#             else:
#                 geneID[gene_id] = [go_term]

#         except Exception as e:
#             print(f"Error inserting {gene_id}, {go_term}: {e}")

