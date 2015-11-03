![elmnet R package](elmnet_logo.png)
======================================================================
> Fast Regularized and Pruned Extreme Learning Machines for Regression and Classification

## How To Install?
```r
library('devtools')
install_github(repo = "davidnexer/elmnet")
```

## Regularization Methods
* Lasso
* Ridge Regression
* Elastic-net

## Pruning Methods
* Fast Pruned ELM (P-ELM) [1]
* Optimally Pruned ELM (OP-ELM) [2]
* Double-Regularized ELM (TROP-ELM) [3]

### References
[1] Rong, Hai-Jun, Yew-Soon Ong, Ah-Hwee Tan, and Zexuan Zhu. "A fast pruned-extreme learning machine for classification problem." Neurocomputing 72, no. 1 (2008): 359-366.

[2] Miche, Yoan, Antti Sorjamaa, Patrick Bas, Olli Simula, Christian Jutten, and Amaury Lendasse. "OP-ELM: optimally pruned extreme learning machine." Neural Networks, IEEE Transactions on 21, no. 1 (2010): 158-162.

[3] Miche, Yoan, Mark Van Heeswijk, Patrick Bas, Olli Simula, and Amaury Lendasse. "TROP-ELM: a double-regularized ELM using LARS and Tikhonov regularization." Neurocomputing 74, no. 16 (2011): 2413-2421.
