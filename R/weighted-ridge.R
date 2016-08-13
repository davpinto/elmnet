##---------------------------------------------
### Weighted Cross-Product between two matrices
##---------------------------------------------
wtCrossProd <- function(x, y, w) {
    ## Normalize weights
    if (!sum(w)==1) {
        w <- w/sum(w);
    }

    ## Weighted Cross-Product
    N <- nrow(x);
    p <- ncol(x);
    if (missing(y)) {
        x <- x*sqrt(w);
        wt.cprod <- crossprod(x);
    } else {
        x <- x*w;
        wt.cprod <- crossprod(x, y);
    }

    return(wt.cprod)
}

##--------------------
### Encode data labels
##--------------------
oneHotEncoding <- function(y, codes) {
    ## Convert to factor
    if (!is.factor(y)) {
        y <- as.factor(y);
    }
    y.levels <- levels(y);
    y.codes <- y.levels[order(table(y))];

    ## Encode to binary matrix
    N <- length(y);
    y <- as.data.frame.matrix(table(1:N, y));

    ## Choose '1' as minoritary class label
    y <- y[, which.min(apply(y, 2, function(y.col) sum(y.col == 1)))];

    ## Transform to specified codes
    if (!missing(codes)) {
        zeros.idx <- which(y==0);
        ones.idx <- which(y==1);
        y[zeros.idx] <- codes[1];
        y[ones.idx] <- codes[2];
    }

    return(list(y=y, y.minor = y.codes[1], y.major = y.codes[2], levels = y.levels))
}

##----------------------
### Data Standardization
##----------------------
normalizeDataColumns <- function(x, col.center, col.scale) {
    ## Columnwise statistics
    if (missing(col.center)) {
        col.center <- colMeans(x);
    }
    if (missing(col.scale)) {
        col.scale <- matrixStats::colSds(x);
    }

    ## Center and scale
    N <- nrow(x);
    p <- ncol(x);
    x <- x - rep(col.center, rep(N,p));
    x <- x / rep(col.scale, rep(N,p));

    return(list(x = x, center = col.center, scale = col.scale))
}

##------------------------------
### Generalized Cross-Validation
##------------------------------
wtLeaveOneOutGCV <- function(x, y, w, lambda) {
    ## Data Dimension
    N <- nrow(x);
    p <- ncol(x);

    ## Center response to avoid intercept penalization
    y <- y - mean(y);

    ## Weight data instances
    x <- x*sqrt(w);

    ## Weighted SVD decomposition
    wt.svd <- svd(x);

    ## Trace of the Hat Matrix
    hat.tr <- sapply(lambda, function(l, d) {
        sum(d^2/(d^2 + l)) + 1
    }, d = wt.svd$d);

    ## Residual sum of squares
    rss <- sapply(lambda, function(l, d, u) {
        k <- length(d);
        n <- nrow(u);
        d <- sqrt(d^2/(d^2 + l));
        u <- u*rep(d, rep(n, k));
        sum( (y - u%*%crossprod(u, y))^2 )
    }, d = wt.svd$d, u = wt.svd$u);

    ## GCV error
    gcv <- rss/(N*(1 - hat.tr/N)^2);

    return(list(
        gcv = gcv,
        lambda = lambda,
        best.lambda = lambda[which.min(gcv)]
    ))
}

##-------------------------------
### Fit Weighted Ridge Regression
##-------------------------------
fitWtRidge <- function(x, y, w, lambda) {
    ## Data Dimension
    N <- nrow(x);
    p <- ncol(x);

    ## Estimate coefficients using least squares
    x <- cbind(1,x);
    xtx <- wtCrossProd(x, w=w);
    diag(xtx) <- diag(xtx) + c(0, rep(lambda, p));
    xty <- wtCrossProd(x, y, w);
    if (N > p) { # Use Cholesky decomposition
        xtx.chol <- chol(xtx);
        alpha <- forwardsolve(t(xtx.chol), xty);
        B <- backsolve(xtx.chol, alpha);
    } else { # Use SVD decomposition
        ## TODO
        xtx.chol <- chol(xtx);
        alpha <- forwardsolve(t(xtx.chol), xty);
        B <- backsolve(xtx.chol, alpha);
    }

    ## Store model
    model <- list(beta=B, lambda=lambda, w=w);

    return(structure(model, class=c('list','wtridge')))
}

#' Weighted Ridge Linear Model
#'
#' Fit weighted ridge regression on inbalanced data.
#'
#' @param x design matrix.
#' @param y \code{factor} with class labels.
#' @param w sample weights (default: \code{rep(1/N, N)}).
#' @param lambda optional. L2 penalty parameter.
#' @param balance use the inverse of the class frequencies as weights (default: \code{TRUE}).
#'
#' @return object of class \code{wt_ridge}.
#'
#' @export
weightedRidgeLinMod <- function(x, y, w, lambda, balance = TRUE) {
    ## Data dimension
    N <- nrow(x);
    p <- ncol(x);

    ## Encode response
    y.code <- oneHotEncoding(y, codes = c(-1,1));
    y <- y.code$y;

    ## Normalize data: "Linear Regression" (Grob 2003)
    x.center <- colMeans(x);
    x <- x - rep(x.center, rep(N, p));
    x.scale <- sqrt(colSums(x^2));
    x <- x / rep(x.scale, rep(N, p));

    ## Remove constant variables
    rm.col <- (x.scale <= 0);
    if (sum(rm.col) > 0) {
        x <- x[, -which(rm.col)];
        x.scale[rm.col] <- 1; # To avoid NAs on normalizing new instances
    }

    ## Assign sample weights according to class frequencies
    if (balance) {
        if (missing(w)) {
            w <- ifelse(y==-1, 1/sum(y==-1), 1/sum(y==1));
            w <- w/sum(w);
        } else {
            w <- w/sum(w);
        }
    } else {
        if (missing(w)) {
            w <- rep(1/N, N);
        } else {
            w <- w/sum(w);
        }
    }

    ## Best penalty parameter
    if (missing(lambda)) {
        lambda.path <- 2^seq(-15, 15, len = 20);
        lambda <- wtLeaveOneOutGCV(x, y, w, lambda.path)$best.lambda;
    }

    ## Fit model
    model <- fitWtRidge(x, y, w, lambda);

    ## Replace missing coefficient with zero
    if (sum(rm.col) > 0) {
        # Temporary array
        B <- numeric(length(x.scale));

        # Store values on temporary array
        B[!rm.col] <- as.numeric(model$beta[-1]);

        # Replace missing
        model$beta <- as.matrix(c(model$beta[1], B));
    }

    ## Scale coefficients
    model$beta[-1] <- model$beta[-1]/x.scale;
    model$xc <- x.center;
    model$xs <- x.scale;

    ## Save response encoding
    model$decode <- list(codes = c(y.code$y.minor, y.code$y.major),
                         levels = y.code$levels);

    return(model)
}

#' Predict Weighted Ridge Linear Model
#'
#' Predict response for new data instances.
#'
#' @param model object of class \code{wt_ridge}.
#' @param x matrix containing new data instances.
#'
#' @return class labels and membership probabilities.
#'
#' @export
predictWtRidge <- function(model, x) {
    ## Center data
    x <- x - rep(model$xc, rep(nrow(x), ncol(x)));

    ## Add intercept
    x <- cbind(1, x);

    ## Predict response
    y.hat <- as.numeric(x%*%model$beta);

    ## Predict class probabilities
    y.prob <- zapsmall(1/(1+exp(-y.hat)))
    y.prob <- cbind(y.prob, 1-y.prob)
    colnames(y.prob) <- model$decode$codes
    y.prob <- y.prob[, model$decode$levels]

    ## Decode response
    y.hat <- sign(y.hat);
    y.resp <- character(length(y.hat));
    y.resp[y.hat==1] <- model$decode$codes[1];
    y.resp[y.hat==-1] <- model$decode$codes[2];
    y.resp <- factor(y.resp, levels = model$decode$levels);

    return(list(resp = y.resp, prob = y.prob))
}
