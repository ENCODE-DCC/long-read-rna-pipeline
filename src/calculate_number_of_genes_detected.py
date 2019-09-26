from qc_utils import QCMetric, QCMetricRecord
import argparse
import json
import pandas as pd
from dataframe_utils import (
    remove_genomic_transcripts,
    filter_startswith_prefix,
    calculate_abundances_aggregated_by_gene,
)


def main(args):
    abundance = pd.read_csv(args.abundance, sep="\t")
    abundance_filtered = filter_startswith_prefix(
        remove_genomic_transcripts(abundance), args.idprefix
    )
    gene_counts = calculate_abundances_aggregated_by_gene(
        abundance_filtered, args.counts_colname
    )
    number_of_genes_detected = sum(gene_counts >= 1)
    number_of_genes_record = QCMetricRecord()
    number_of_genes_metric = QCMetric(
        "number_of_genes_detected",
        {"number_of_genes_detected": number_of_genes_detected},
    )
    number_of_genes_record.add(number_of_genes_metric)
    with open(args.outfile, "w") as fp:
        json.dump(number_of_genes_record.to_ordered_dict(), fp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--abundance",
        type=str,
        help="abundance .tsv from create_abundance_file_from_database.py",
    )
    parser.add_argument(
        "--counts_colname", type=str, help="which column in the tsv contains counts"
    )
    parser.add_argument("--outfile", type=str, help="output filename")
    parser.add_argument("--idprefix", type=str, help="prefix for novel geneIDs")
    args = parser.parse_args()
    main(args)
