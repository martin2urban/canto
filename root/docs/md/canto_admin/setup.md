# Configuring Canto and loading data

After the software is installed some configuration is needed.

## Creating users

To manage sessions and users from the web interface there needs to be at least
one "admin" user.  Users can be added with the `canto_add.pl` script:

    ./script/canto_add.pl --person "Kim Rutherford" kim@pombase.org secret_password admin

## Loading data

You will need to load at least one organisms, a list of genes and one or more
ontologies before using Canto.

### Organisms

Add an organism using this command in the `canto` directory:

    ./script/canto_load.pl --organism "<genus> <species> <taxon_id>"

At least one organism is needed in the Canto database before genes can be
loaded.

### Gene data

Load genes with:

    ./script/canto_load.pl --genes genes_file.tsv --for-taxon 4896

All genes in an input file must be from one organism.  Use the `--for-taxon`
argument with an NCBI taxon ID to specify the organism, which needs to have
been loaded with the --organism option (see above).

#### gene data format

A gene data file consists of four tab separated columns with no header line.
The columns are:

- systematic identifier
- gene primary name
- synonyms (comma separated)
- gene product or description

There is a small example file in the test directory:

    ./script/canto_load.pl --genes t/data/pombe_genes.txt --for-taxon 4896

### Ontology terms

OBO format ontology data can be imported or updated with:

    ./script/canto_load.pl --ontology ontology_file.obo

Multiple ontology files can be imported at once:

    ./script/canto_load.pl --ontology ontology_file.obo \
       --ontology another_ontology_file.obo

The OBO file can also be given by URL.  eg.

    ./script/canto_load.pl --ontology \
       http://purl.obolibrary.org/obo/go/go-basic.obo

The ontology must be configured in the [annotation_type_list](#annotation_type_list) section of the
`canto.yaml` file.