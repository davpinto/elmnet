.onLoad <- function(libname, pkgname) {
    cl <- parallel::makeCluster(parallel::detectCores(), type="SOCK")
    doSNOW::registerDoSNOW(cl)
    op <- options()
    op.elmnet <- list(

    )
    toset <- !(names(op.elmnet) %in% names(op))
    if (any(toset))
        options(op.elmnet[toset])

    invisible()
}

.onAttach <- function(libname, pkgname) {
    packageStartupMessage("ELMnet version 0.9.1")
}
