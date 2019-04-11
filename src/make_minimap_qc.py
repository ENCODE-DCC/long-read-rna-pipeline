from qc_utils import QCMetric, QCMetricRecord
import argparse
import json


def main(args):
    with open(args.flnc, 'r') as fp:
        flnc = int(fp.readline())
    with open(args.mapped, 'r') as fp:
        mapped = int(fp.readline())
    mapping_rate = flnc / mapped
    qc_record = QCMetricRecord()
    # FLNC = Full-length nonchimeric reads
    flnc_metric = QCMetric('full_length_non_chimeric_reads', {'flnc': flnc})
    mapped_metric = QCMetric('number_of_mapped_reads', {'mapped': mapped})
    mapping_rate_metric = QCMetric('mapping_rate', {'mapping_rate': mapping_rate})
    qc_record.add_all([flnc_metric, mapped_metric, mapping_rate_metric])
    with open(args.outfile, 'w') as fp:
        json.dump(qc_record.to_ordered_dict(), fp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--flnc', type=str, help='file that contains the number of full length non chimeric reads')
    parser.add_argument('--mapped', type=str, help='file that contains the mapped reads number')
    parser.add_argument('--outfile', type=str, help='output filename')
    args = parser.parse_args()
    main(args)
