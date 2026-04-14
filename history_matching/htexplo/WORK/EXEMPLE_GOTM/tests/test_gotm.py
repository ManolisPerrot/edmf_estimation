import pytest
import subprocess

def test_gotm_exists():
    """Check that gotm exe exists."""
    cmd = ['gotm','-h']
    assert subprocess.run(cmd)
    