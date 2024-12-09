# Corporate Decision-Making and Quantitative Analysis Winter 2024/25 - Assignment I

## Audit market concentration in the EU

This repository contains the code and data for the first assignment of the Corporate Decision-Making and Quantitative Analysis Winter 2024/25. It is implemented in [R](https://www.r-project.org/) and [quarto](https://quarto.org/).


### How Do I create the output?

Assuming that you have R, [Rtools](https://cran.r-project.org/bin/windows/Rtools/rtools40.html) (if on windows) and quarto installed, you need to: 

1. Install the required packages. You can run the following code in R to install the required packages:

```R
# Code to install packages to your system
install_package_if_missing <- function(pkg) {
  if (! pkg %in% installed.packages()[, "Package"]) install.packages(pkg)
}
install_package_if_missing("RPostgres")
install_package_if_missing("DBI")
install_package_if_missing("dplyr")
install_package_if_missing("readr")
install_package_if_missing("lubridate")
install_package_if_missing("ggplot2")
install_package_if_missing("tidyr")
install_package_if_missing("knitr")
install_package_if_missing("kableExtra")
```

2. Copy the file _config.csv to config.csv in the project main directory. Edit it by adding your WRDS credentials.

3. Run `make all` either via the console or by identifying the 'Build All' button in the 'Build' tab (normally in the upper right quadrant of the RStudio screen). This will create the paper in the `output` directory.

```
This repository was built based on the ['treat' template for reproducible research](https://github.com/trr266/treat).
```