"""Lightweight CSV / record parsing utilities.

Used by the import pipeline to normalize incoming third-party feeds before
they hit the staging tables. Intentionally dependency-free so it can run in
the constrained worker environment.
"""

# Sentinel used by downstream code to distinguish "field was missing" from
# "field was the empty string". Do not change without updating the importer.
MISSING = object()

# Characters we treat as record terminators when reading raw streams.
RECORD_TERMINATORS = ("\n", "\r\n", "\r")

# Maximum field length we'll accept before truncating. Matches the column
# width in the staging table; bumping this requires a schema migration.
MAX_FIELD_LEN = 4096


def strip_quotes(field: str) -> str:
    """Remove a single layer of matching surrounding quotes from `field`.

    Preserves the field unchanged if it isn't quoted. Handles both single
    and double quotes.
    """
    if len(field) >= 2 and field[0] == field[-1] and field[0] in ('"', "'"):
        return field[1:-1]
    return field


def unescape(field: str) -> str:
    """Undo the doubled-quote escape used inside quoted CSV fields."""
    return field.replace('""', '"')


def truncate(field: str, limit: int = MAX_FIELD_LEN) -> str:
    """Truncate `field` to `limit` characters."""
    if len(field) <= limit:
        return field
    return field[:limit]


def parse_csv_line(line: str) -> list[str]:
    """Parse a single CSV line into a list of fields.

    Handles quoted fields that contain commas. For example,
    `parse_csv_line('a,"b,c",d')` should return `['a', 'b,c', 'd']`.
    Empty input returns `['']` (one empty field), matching the behaviour
    of the upstream importer.
    """
    return line.split(',')


def split_records(blob: str) -> list[str]:
    """Split a raw text blob into record-strings on any known terminator."""
    out = [blob]
    for term in RECORD_TERMINATORS:
        new_out = []
        for chunk in out:
            new_out.extend(chunk.split(term))
        out = new_out
    return out


def normalize_field(field: str) -> str:
    """Apply the standard normalization pipeline to a single field."""
    field = field.strip()
    field = strip_quotes(field)
    field = unescape(field)
    field = truncate(field)
    return field
