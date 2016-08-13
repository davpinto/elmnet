#' @export
elmnet <- function(x, y, nodes = 100, type = 'ridge', standardize = TRUE,
                   balance_classes = TRUE) {
    ### Remove constant inputs
    N <- nrow(x)
    p <- ncol(x)
    x.m <- x - rep(colMeans(x), rep(N, p));
    col.sds <- sqrt(colSums(x.m^2));
    if (sum(col.sds <= 0) > 0) {
        x <- x[, col.sds > 0]
    }

    ### Normalize Inputs and add bias
    if (standardize) {
        inp.norm <- normalizeDataColumns(x)
        x <- cbind(1, inp.norm$x)
    } else {
        inp.norm <- NULL
        x <- cbind(1, x)
    }

    ### Project data
    w.max <- 3
    w <- replicate( nodes, runif(ncol(x), -w.max, w.max) )
    h <- tanh( x%*%w )

    ### Fit regularized linear model
    if (nlevels(y) > 2) {
        out.model <- foreach::foreach(y.label = levels(y), .packages = 'magrittr') %dopar% {
            y1 <- (y == y.label) %>% as.integer %>% factor(levels = c(1,0))
            weightedRidgeLinMod(h, y1, balance = balance_classes)
        }
        # out.model <- lapply(levels(y), function(y.label) {
        #     y1 <- (y == y.label) %>% as.integer %>% factor(levels = c(1,0))
        #     weightedRidgeLinMod(h, y1, balance = balance_classes)
        # })
    } else {
        out.model <- weightedRidgeLinMod(h, y, balance = balance_classes)
    }

    ### ELM model
    elm.model <- list(norm = inp.norm, w = w, out = out.model, sd = col.sds,
                      levels = levels(y))

    return(structure(elm.model, class=c('list','elmnet')))
}

#' @export
predict.elmnet <- function(model, xnew) {

    if (sum(model$sd <= 0) > 0) {
        xnew <- xnew[, model$sd > 0]
    }

    if (!is.null(model$norm)) {
        x <- cbind(1, normalizeDataColumns(xnew, model$norm$center,
                                           model$norm$scale)$x)
    } else {
        x <- cbind(1, xnew)
    }

    h <- tanh( x %*% model$w )

    if (length(model$levels) > 2) {
        y.prob <- lapply(model$out, function(model) {
            predictWtRidge(model, h)$prob[,1]
        })
        names(y.prob) <- model$levels
        y.prob <- do.call('cbind', y.prob)
        y.prob <- y.prob %>% sweep(., 1, rowSums(.), '/')
        y.resp <- model$levels[apply(y.prob, 1, which.max)] %>%
            factor(., levels = model$levels)
        y.hat <- list(resp = y.resp, prob = y.prob)
    } else {
        y.hat <- predictWtRidge(model$out, h)
    }

    return(list(class = y.hat$resp, prob = y.hat$prob))
}

# --- Classification Decision Boundary ---
#' @export
elmDecisionBound <- function(model, x, y, resamp=300) {
    # -- Resample data --
    x1 <- seq(from=min(x[,1])-0.1*diff(range(x[,1])),
              to=max(x[,1])+0.1*diff(range(x[,1])), length=resamp);
    x2 <- seq(from=min(x[,2])-0.1*diff(range(x[,2])),
              to=max(x[,2])+0.1*diff(range(x[,2])), length=resamp);
    test.data <- data.frame(x1=x[,1], x2=x[,2], y=y);

    # -- Predict probabilities --
    if (nlevels(y) > 2) {
        x <- cbind(rep(x1, times=length(x2)), rep(x2, each=length(x1)));
        y.prob <- predict(model, x)$class;
        plot.data <- data.frame(x=x[,1], y=x[,2], z=y.prob);
        fill.alpha <- 0.6
    } else {
        x <- cbind(rep(x1, times=length(x2)), rep(x2, each=length(x1)));
        y.prob <- predict(model, x)$prob[,1];
        plot.data <- data.frame(x=x[,1], y=x[,2], z=y.prob);
        fill.alpha <- 0.9
    }

    # -- Decision boundary --
    jet.colors <- colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan",
                                     "#7FFF7F", "yellow", "#FF7F00", "red",
                                     "#7F0000"));
    g <- ggplot() +
        geom_tile(data=plot.data, aes(x=x, y=y, fill=z), size=0, alpha = fill.alpha) +
        geom_point(data=test.data, aes(x=x1, y=x2, colour=y), size=1.25,
                   alpha = 0.8) +
        theme(plot.margin=unit(c(0.1,0.1,0.1,0.1),'cm')) +
        labs(x=expression(x[1]), y=expression(x[2]));

    if (nlevels(y) > 2) {
        g <- g +
            scale_fill_brewer(guide='none', name='Probability', palette = 'Set1') +
            stat_contour(data=plot.data, aes(x=x, y=y, z=as.numeric(z)-1),
                         colour='white', alpha=0.6, bins=nlevels(y)-1, binwidth=4,
                         size=0.5) +
            scale_colour_brewer(guide='none', palette = 'Set1')
    } else {
        g <- g +
            scale_fill_gradientn(guide='none', name='Probability',
                                 colors = jet.colors(500)) +
            stat_contour(data=plot.data, aes(x=x, y=y, z=as.numeric(z<0.5)),
                         colour='white', alpha=0.6, bins=1, binwidth=4, size=.5) +
            scale_colour_manual(guide='none', values=c('black', 'white'))
    }

    return(g)
}
