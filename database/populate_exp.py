# populate_exp.py script to populate repository with experiment metadata

# import necessary packages
import argparse
import csv 
import sqlite3 

# Define the argparse arguments
parser = argparse.ArgumentParser(
    description="""Populate database with experiment metadata"""
)