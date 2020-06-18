import pytest

from pathlib import Path


@pytest.fixture
def test_data_dir():
    return Path("test_data")
