import argparse
import json


def main(args):
    outputs = {
        "inputs": {},
        "talon.py": {},
        "create_abundance_file_from_database.py": {},
    }
    outputs["inputs"]["annotation_name"] = args.annotation_name
    outputs["inputs"]["ref_genome_name"] = args.genome
    outputs["talon.py"]["--build"] = args.genome
    outputs["create_abundance_file_from_database.py"]["-a"] = args.annotation_name
    with open(args.outfile, "w") as fp:
        json.dump(outputs, fp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--annotation_name", type=str)
    parser.add_argument("--genome", type=str)
    parser.add_argument("--outfile", type=str)
    args = parser.parse_args()
    main(args)
