PRAGMA foreign_keys = true;

/* Drop tables in reverse order of creating them */
DROP TABLE IF EXISTS DifferentialExpression;
DROP TABLE IF EXISTS AbioticConditions;
DROP TABLE IF EXISTS Factors;
DROP TABLE IF EXISTS Conditions;
DROP TABLE IF EXISTS GeneFunctions;
DROP TABLE IF EXISTS GeneAnnotations;
DROP TABLE IF EXISTS Functions;
DROP TABLE IF EXISTS Annotations;
DROP TABLE IF EXISTS Genes;

/* Create the Genes table */
CREATE TABLE IF NOT EXISTS Genes (
    gene_id TEXT,
    PRIMARY KEY (gene_id)
);

/* Create the Annotations table */
CREATE TABLE IF NOT EXISTS Annotations (
    annotation_id TEXT,
    PRIMARY KEY (annotation_id)
);

/* Create the Functions table */
CREATE TABLE IF NOT EXISTS Functions (
    molecular_function TEXT,
    PRIMARY KEY (molecular_function)
);

/* Create the GeneAnnotations table */
CREATE TABLE IF NOT EXISTS GeneAnnotations (
    gene_id TEXT,
    annotation_id TEXT,
    PRIMARY KEY (gene_id, annotation_id),
    FOREIGN KEY (gene_id) REFERENCES Genes (gene_id),
    FOREIGN KEY (annotation_id) REFERENCES Annotations (annotation_id)
);

/* Create the GeneFunctions table */
CREATE TABLE IF NOT EXISTS GeneFunctions (
    gene_id TEXT,
    molecular_function TEXT,
    PRIMARY KEY (gene_id, molecular_function),
    FOREIGN KEY (gene_id) REFERENCES Genes (gene_id),
    FOREIGN KEY (molecular_function) REFERENCES Functions (molecular_function)
);

/* Create the Conditions table */
CREATE TABLE IF NOT EXISTS Conditions (
    condition TEXT,
    PRIMARY KEY (condition)
); /* holds the temp-aw-co2 condition */

/* Create the Factors table */
CREATE TABLE IF NOT EXISTS Factors (
    factor TEXT, /* holds the factor that changes e.g. temp, aw, co2, temp-aw, etc*/
    PRIMARY KEY (factor)
);

/* Create the AbioticConditions table */
CREATE TABLE IF NOT EXISTS AbioticConditions (
    abiotic_ID INTEGER,
    condition TEXT,
    temperature INTEGER,
    waterActivity INTEGER,
    co2 INTEGER,
    PRIMARY KEY (abiotic_ID),
    FOREIGN KEY (condition) REFERENCES Conditions (condition)
); /* holds the condition (temp-aw-co2) as well as the exact temp, aw and co2 values for that condition */

/* Create the DifferentialExpression table */
CREATE TABLE IF NOT EXISTS DifferentialExpression (
    gene_id TEXT,
    sampleA TEXT,
    sampleB TEXT,
    factor TEXT,
    baseMeanA INTEGER,
    baseMeanB INTEGER,
    baseMean INTEGER,
    log2CF INTEGER,
    lfcSE INTEGER,
    stat INTEGER,
    pval INTEGER,
    padj INTEGER,
    PRIMARY KEY (gene_id, sampleA, sampleB),
    FOREIGN KEY (gene_id) REFERENCES Genes (gene_id),
    FOREIGN KEY (sampleA) REFERENCES Conditions (condition),
    FOREIGN KEY (sampleB) REFERENCES Conditions (condition),
    FOREIGN KEY (factor) REFERENCES Factors (factor)
);