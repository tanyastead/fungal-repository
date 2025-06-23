PRAGMA foreign_keys = true;

/* Drop tables in reverse order of creating them */
DROP TABLE IF EXISTS DEG;
DROP TABLE IF EXISTS ExpContrasts;
DROP TABLE IF EXISTS GeneContrasts;
DROP TABLE IF EXISTS ExpKeywords;
DROP TABLE IF EXISTS Experiments;
DROP TABLE IF EXISTS GeneFunctions;
DROP TABLE IF EXISTS Genes;

/* Create the Genes table */
CREATE TABLE IF NOT EXISTS Genes (
    gene_id TEXT,
    species TEXT,
    PRIMARY KEY (gene_id)
);

/* Create the GeneFunctions table */
CREATE TABLE IF NOT EXISTS GeneFunctions (
    gene_id TEXT,
    function TEXT,
    PRIMARY KEY (gene_id),
    FOREIGN KEY (gene_id) REFERENCES Genes (gene_id)
);

/* Create the Experiments table */
CREATE TABLE IF NOT EXISTS Experiments (
    experiment_id TEXT,
    author TEXT,
    year INTEGER,
    description TEXT,
    PRIMARY KEY (experiment_id)
);

/* Create the ExpKeywords table */
CREATE TABLE IF NOT EXISTS ExpKeywords (
    experiment_id TEXT,
    keyword TEXT,
    PRIMARY KEY (experiment_id, keyword),
    FOREIGN KEY (experiment_id) REFERENCES Experiments (experiment_id)
);

/* Create the GeneContrasts table */
CREATE TABLE IF NOT EXISTS GeneContrasts (
    gene_contrast TEXT NOT NULL,
    gene_id TEXT,
    contrast TEXT,
    PRIMARY KEY (gene_contrast),
    FOREIGN KEY (gene_id) REFERENCES Genes (gene_id)
);

/* Create the ExpContrasts table*/
CREATE TABLE IF NOT EXISTS ExpContrasts (
    experiment_id TEXT,
    contrast TEXT,
    PRIMARY KEY (experiment_id, contrast),
    FOREIGN KEY (experiment_id) REFERENCES Experiments (experiment_id),
    FOREIGN KEY (contrast) REFERENCES GeneContrasts (contrast)
);



/* Create the DEG table */
CREATE TABLE IF NOT EXISTS DEG (
    gene_contrast TEXT,
    log2FC REAL,
    lfcSE REAL,
    pval REAL,
    padj REAL,
    PRIMARY KEY (gene_contrast),
    FOREIGN KEY (gene_contrast) REFERENCES GeneContrasts (gene_contrast)
);