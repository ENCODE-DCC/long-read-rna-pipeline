def remove_genomic_transcripts(dataframe):
    """Remove rows where value on the column 'transcript_novelty' equals to 'Genomic'
    Args:
        dataframe: pandas DataFrame
    Returns:
        pandas DataFrame
    """
    not_genomic_transcript = dataframe['transcript_novelty'] != 'Genomic'
    return dataframe[not_genomic_transcript]


def remove_startswith_TALON(dataframe):
    """Remove rows where 'annot_gene_id' column value starts with string 'TALON'.
    Args:
        dataframe: pandas DataFrame
    Returns:
        pandas DataFrame
    """
    not_starts_with_TALON = dataframe['annot_gene_id'].apply(lambda x: not x.startswith('TALON'))
    return dataframe[not_starts_with_TALON]


def calculate_abundances_aggregated_by_gene(dataframe, colname):
    """Calculate abundance per gene.
    Args:
        dataframe: pandas DataFrame
        colname: String column that contains the abundances
    Returns:
        pandas DataFrame with abundances on gene resolution
    """
    return dataframe.groupby(['annot_gene_id'])[colname].sum()
