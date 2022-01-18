## Test environments
* ubuntu 20.04 (local), R 4.0.5
* ubuntu 20.04 (GitHub Actions), R release and devel
* macos (GitHub Actions), R release
* windows (win-builder), R release and devel

## R CMD check results

0 errors | 0 warnings | 0 notes

I have fixed the CRAN package check notes from previous version
* 'magrittr' removed from Imports (no longer used)
* 'iNZightTools' moved to Suggests

## Downstream dependencies

There are currently no downstream dependencies for this package.

## CRAN check results

There are ERRORs for windows r-devel and r-oldrel:
* one complaining about missing 'car' package (though it's there)
* three failing running tests, but no information to ascertain what's going wrong
