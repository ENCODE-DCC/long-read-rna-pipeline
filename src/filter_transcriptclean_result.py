# Filter SAM file to make sure there are no read ID duplicates, and that
# all junctions are either canonical or annotated non-canonical splice junctions.

from optparse import OptionParser
import os.path


def getOptions():
    parser = OptionParser()
    parser.add_option(
        "--f",
        dest="infile",
        help="SAM input file",
        metavar="FILE",
        type="string",
        default="",
    )
    parser.add_option(
        "--o",
        dest="outfile",
        help="output file",
        metavar="FILE",
        type="string",
        default=None,
    )
    (options, args) = parser.parse_args()
    return options


def main():
    options = getOptions()

    infile = options.infile

    # Filter the reads
    if options.outfile is None:
        outfile = os.path.abspath(infile).split(".sam")[0] + "_filtered.sam"

    else:
        outfile = options.outfile

    o = open(outfile, "w")
    reads_seen = {}

    with open(infile, "r") as f:
        for line in f:
            line = line.strip()
            if line.startswith("@"):
                o.write(line + "\n")
                continue

            entry = line.split("\t")
            index = [i for i, s in enumerate(entry) if "jM:B:c" in s]
            if len(index) == 0:
                raise ValueError("SAM entry does not have junction types tag")
            jn_index = index[0]

            read_ID = entry[0]
            jns = entry[jn_index].split(",")
            if "0" not in jns and read_ID not in reads_seen:
                o.write(line + "\n")
                reads_seen[read_ID] = 1

    o.close()


if __name__ == "__main__":
    main()
