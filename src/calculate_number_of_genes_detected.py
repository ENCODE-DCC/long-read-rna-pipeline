from qc_utils import QCMetric, QCMetricRecord
import argparse
import json
import pandas as pd


def main(args):
    abundance = pd.read_csv(args.abundance, sep='\t')
    not_genomic_transcript = abundance.genomic_transcript != 'genomic_transcript'
    not_starts_with_TALON = abundance['annot_gene_id'].apply(lambda x: not x.startswith('TALON'))
    not_genomic_not_TALON = not_genomic_transcript & not_starts_with_TALON
    gene_counts = abundance[not_genomic_not_TALON].groupby(['annot_gene_id'])[args.counts_colname].sum()
    number_of_genes = sum(gene_counts >= 1)
    number_of_genes_record = QCMetricRecord()
    number_of_genes_metric = QCMetric('number_of_genes_detected', {'number_of_genes_detected': number_of_genes})
    number_of_genes_record.add(number_of_genes_metric)
    with open(args.outfile, 'w') as fp:
        json.dump(number_of_genes_record.to_ordered_dict(), fp)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--abundance', type=str, help='abundance .tsv from create_abundance_file_from_database.py')
    parser.add_argument('--counts_colname', type=str, help='which column in the tsv contains counts')
    parser.add_argument('--outfile', type=str, help='output filename')
    args = parser.parse_args()
    main(args)
