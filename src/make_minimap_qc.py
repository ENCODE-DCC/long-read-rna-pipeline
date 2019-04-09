from qc_utils import QCMetric, QCMetricRecord
import argparse
import json


def main(args):
    with open(args.fnlc, 'r') as fp:
        fnlc = int(fp.readline())
    with open(args.mapped, 'r') as fp:
        mapped = int(fp.readline())
    mapping_rate = fnlc / mapped
    qc_record = QCMetricRecord()
    # FNLC = Full-length nonchimeric reads
    fnlc_metric = QCMetric('fnlc', {'fnlc': fnlc})
    mapped_metric = QCMetric('mapped', {'mapped': mapped})
    mapping_rate_metric = QCMetric('mapping_rate', {'mapping_rate': mapping_rate})
    qc_record.add_all([fnlc_metric, mapped_metric, mapping_rate_metric])
    with open(args.outfile, 'w') as fp:
        json.dump(qc_record.to_ordered_dict(), fp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--fnlc', type=str, help='file that contains the fnlc number')
    parser.add_argument('--mapped', type=str, help='file that contains the mapped reads number')
    parser.add_argument('--outfile', type=str, help='output filename')
    args = parser.parse_args()
    main(args)
