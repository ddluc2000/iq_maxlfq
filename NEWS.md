## Version 1.9.6

- add support for multiple quantitative values per table cell, for examples fragment intensities separated by ';' in DIA-NN output.

- add oneliner function 'process_long_format' for end-to-end processing with default values for DIA-NN.

- add oneliner function 'process_wide_format' for end-to-end processing to collapse multiple rows with same id, such as multiple entries for a gene.

- fix NOTE due to Rcpp

- fix memory reallocation problem

- better exception handling

## Version 1.9.3

- Use RcppEigen

## Version 1.9.1

- Revise code (change order of header files) to support OpenMP in clang 13.0.0.

- fix typo: medpolish to median_polish

## Version 1.9

- rchk: fix protection stack imbalance.

## Version 1.8

- Revise code to get rid of rchk complaints.

## Version 1.7

- Remove the R_ToplevelExec declaration to fix a compilation problem on Solaris.

## Version 1.6

- Use _OPENMP to safeguard against MacOS lack of OpenMP support.

## Version 1.5

- Speedup with C++ implementation

## Version 1.4

- Add references.
- Add size of pdf of QC.
- Fix error of missing median `m` when `pdf_out = NULL`

## Ver 1.3

- Filter out NaN values in the quantitative column in the function `preprocess()`.

- Update the median normalization step in the function `preprocess()`.

## Ver 1.2

- Update the function `preprocess()`.

## Ver 1.0

First release.
