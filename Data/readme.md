# Analysis recipe

## Dependencies

- Python (2.7 or 3.4)
- numpy
- scipy
- [python-datamatrix]()
- [python-eyelinkparser]()

## Running the Analysis

Convert the `.edf` files to `.asc` with `edf2asc`, and place the `.asc` files in a subfolder called data.

To run the analysis:

	python analyze.py

Some files are cached during the analysis. To clear the cache, run:

	python analyze.py --clear-cache
