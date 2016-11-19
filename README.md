![elmnet R package](elmnet_logo.png "fig:")
================

> Nonlinear Regression and Classification with Regularized and Pruned Extreme Learning Machines

***This is a BETA release and for now it works only for classification problems.***

The `elmnet` function implements a tuning free regularized learner based on Extreme Learning Machines (ELMs) (Huang, Wang, and Lan 2011). It uses **Generalized Cross Validation** (GCV), a fast and efficient leave-one-out approach, to automatically define the best regularization parameter.

So, `elmnet` is a fast and easy to use nonlinear learner. Moreover, it uses a **softmax** function on the output layer to predict **calibrated probabilities**.

### How To Install?

``` r
library('devtools')
install_github(repo = "davpinto/elmnet")
```

### Required Packages

The following packages are required to make `emlnet` work properly. All of them will be automatically instaled when you install `elmnet`.

-   `magrittr` to use the pipe operator `%>%`,
-   `matrixStats` for fast row-wise and column-wise matrix operations,
-   `doSNOW` and `foreach` to train multiclass models in parallel. The `elmnet` package uses **all available cores** by default,
-   `ggplot2` to plot classification decision boundaries.

Regularization Methods
----------------------

-   Lasso (*in development*)
-   Ridge Regression
-   Elastic-net (*in development*)

Pruning Methods
---------------

-   Fast Pruned ELM (P-ELM) (Rong et al. 2008) (*in development*)
-   Optimally Pruned ELM (OP-ELM) (Miche et al. 2010) (*in development*)
-   Double-Regularized ELM (TROP-ELM) (Miche et al. 2011) (*in development*)

Toy Examples
------------

Classification decision boudary for nonlinear problems.

``` r
# Load packages
library('elmnet')
library('caTools')
```

### Two-class example

``` r
# Load toy data
data('spirals', package = 'elmnet')
x <- spirals$x
y <- spirals$y

# Split data
set.seed(111)
tr.idx <- caTools::sample.split(y, SplitRatio = 0.7)
x.tr <- x[tr.idx,]
x.te <- x[!tr.idx,]
y.tr <- y[tr.idx]
y.te <- y[!tr.idx]

# Fit ELM model
set.seed(111)
elm.model <- elmnet(x.tr, y.tr, nodes = 300, standardize = TRUE)

# Draw classification decision boudary
elmDecisionBound(elm.model, x.te, y.te, resamp = 150)
```

<img src="README_files/figure-markdown_github/unnamed-chunk-3-1.png" style="display: block; margin: auto;" />

### Multi-class example

``` r
# Load toy data
data('multi_spirals', package = 'elmnet')
x <- multi_spirals$x
y <- multi_spirals$y

# Split data
set.seed(222)
tr.idx <- caTools::sample.split(y, SplitRatio = 0.7)
x.tr <- x[tr.idx,]
x.te <- x[!tr.idx,]
y.tr <- y[tr.idx]
y.te <- y[!tr.idx]

# Fit ELM model
set.seed(222)
elm.model <- elmnet(x.tr, y.tr, nodes = 300, standardize = TRUE)

# Draw classification decision boudary
elmDecisionBound(elm.model, x.te, y.te, resamp = 150)
```

<img src="README_files/figure-markdown_github/unnamed-chunk-4-1.png" style="display: block; margin: auto;" />

------------------------------------------------------------------------

References
==========

Huang, Guang-Bin, Dian Hui Wang, and Yuan Lan. 2011. “Extreme Learning Machines: A Survey.” *International Journal of Machine Learning and Cybernetics* 2 (2). Springer: 107–22.

Miche, Yoan, Antti Sorjamaa, Patrick Bas, Olli Simula, Christian Jutten, and Amaury Lendasse. 2010. “OP-ELM: Optimally Pruned Extreme Learning Machine.” *IEEE Transactions on Neural Networks* 21 (1). IEEE: 158–62.

Miche, Yoan, Mark Van Heeswijk, Patrick Bas, Olli Simula, and Amaury Lendasse. 2011. “TROP-ELM: A Double-Regularized ELM Using LARS and Tikhonov Regularization.” *Neurocomputing* 74 (16). Elsevier: 2413–21.

Rong, Hai-Jun, Yew-Soon Ong, Ah-Hwee Tan, and Zexuan Zhu. 2008. “A Fast Pruned-Extreme Learning Machine for Classification Problem.” *Neurocomputing* 72 (1). Elsevier: 359–66.
