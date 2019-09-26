from ..dataframe_utils import (
    remove_genomic_transcripts,
    filter_startswith_prefix,
    calculate_abundances_aggregated_by_gene,
)
from pandas import DataFrame

DF = DataFrame(
    {
        "transcript_novelty": ["Genomic", "foo", "bar", "Genomic"],
        "annot_gene_id": ["FOOid1", "BARid2", "FOOid1", "BAZid4"],
        "numeric_values": [1, 2, 3, 4],
    }
)


def test_remove_genomic_transcripts():
    assert len(remove_genomic_transcripts(DF).index) == 2


def test_filter_startswith_prefix_nomatch():
    assert filter_startswith_prefix(DF, "not_matching_prefix").equals(DF)


def test_filter_startswith_prefix_match():
    filtered = filter_startswith_prefix(DF, "FOO")
    assert len(filtered.index) == 2


def test_calculate_abundances_aggregated_by_gene():
    aggregated = calculate_abundances_aggregated_by_gene(DF, "numeric_values")
    assert aggregated.FOOid1 == 4
    assert aggregated.BARid2 == 2
    assert aggregated.BAZid4 == 4
