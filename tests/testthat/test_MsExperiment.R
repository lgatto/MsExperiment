test_that("linkSampleData,MsExperiment works", {
    res <- linkSampleData(mse)
    expect_true(length(res@sampleDataLinks) == 0)

    expect_error(linkSampleData(mse, with = "experimentFile.fls"),
                 "unsupported")
    expect_error(
        linkSampleData(mse, with = "experimentFiles.mzML_file", withIndex = 1),
        "Length")
    expect_error(linkSampleData(
        mse, with = "experimentFile.mzML_file", withIndex = c(2, 1)), "No slot")
    expect_error(linkSampleData(
        mse, with = "experimentFiles.mzML_files", withIndex = c(2, 1)), "empty")

    res <- linkSampleData(mse, with = "experimentFiles.mzML_file",
                          withIndex = c(2, 1))
    expect_true(length(res@sampleDataLinks) == 1)
    expect_equal(res@sampleDataLinks[["experimentFiles.mzML_file"]],
                 cbind(1:2, 2:1))
    expect_warning(linkSampleData(
        res, with = "experimentFiles.mzML_file", withIndex = 1:2),
        "Overwriting")

    ## link all sample to one file.
    res <- linkSampleData(mse, with = "experimentFiles.mzML_file",
                          withIndex = c(1, 1))
    expect_equal(res@sampleDataLinks[["experimentFiles.mzML_file"]],
                 cbind(1:2, c(1L, 1L)))

    ## link one sample to one file.
    res <- linkSampleData(mse, with = "experimentFiles.mzML_file",
                          sampleIndex = 1L, withIndex = 2L)
    expect_equal(res@sampleDataLinks[["experimentFiles.mzML_file"]],
                 cbind(1L, 2L))

    ## link using a SQL-like expression
    expect_error(linkSampleData(mse, with = "bla.blu = ble.blo"),
                 "one of the slot")

    sampleData(mse)$orgfile <- unique(spectra(mse)$dataOrigin)
    res <- linkSampleData(mse, with = "sampleData.orgfile = spectra.dataOrigin")
    res2 <- linkSampleData(mse, with = "spectra.dataOrigin = sampleData.orgfile")
    expect_equal(res@sampleDataLinks[[1L]], res2@sampleDataLinks[[1L]])

    res3 <- linkSampleData(
        mse, with = "spectra",
        sampleIndex = match(basename(spectra(mse)$dataOrigin),
                            sampleData(mse)$mzML_file),
        withIndex = seq_along(spectra(mse)))
    expect_equal(unname(res@sampleDataLinks[[1L]]),
                 unname(res3@sampleDataLinks[[1L]]))
})

test_that("[,LinkedMsExperiment works", {
    tmp <- mse
    expect_error(res <- tmp[4], "out-of-bound")
    expect_error(res <- tmp[1, 2], "is supported")
    expect_error(res <- tmp[c(TRUE, FALSE, TRUE)], "number of")
    expect_warning(tmp[c("b")], "rownames")

    res <- tmp[c(TRUE, FALSE)]
    expect_equal(sampleData(res), sampleData(tmp)[1, ])

    ## Subset including qdata
    library(SummarizedExperiment)
    sd <- DataFrame(sample = c("QC1", "QC2", "QC3"), idx = c(1, 3, 5))
    se <- SummarizedExperiment(colData = sd, assay = cbind(1:10, 11:20, 21:30))

    mse2 <- mse
    qdata(mse2) <- se

    res <- mse2[2]
    expect_equal(length(res), 1L)
    expect_equal(sampleData(res), sampleData(mse2)[2, ])
    expect_equal(spectra(res), spectra(mse2))
    expect_equal(qdata(res), qdata(mse2))

    ## Link spectra
    spectra(mse2)$mzML_file <- basename(spectra(mse2)$dataOrigin)
    mse2 <- linkSampleData(
        mse2, with = "sampleData.mzML_file = spectra.mzML_file")
    res <- mse2[2]
    expect_equal(
        spectra(res),
        spectra(mse2)[spectra(mse2)$mzML_file == "20171016_POOL_POS_3_105-134.mzML"])
    res <- mse2[1]
    expect_equal(
        spectra(res),
        spectra(mse2)[spectra(mse2)$mzML_file == "20171016_POOL_POS_1_105-134.mzML"])

    ## Link experiment files
    mse2 <- linkSampleData(mse2, with = "experimentFiles.mzML_file",
                           sampleIndex = c(1, 2), withIndex = c(1, 2))
    res <- mse2[2]
    expect_equal(experimentFiles(res)[["mzML_file"]],
                 experimentFiles(mse2)[["mzML_file"]][2L])
    res <- mse2[1]
    expect_equal(experimentFiles(res)[["mzML_file"]],
                 experimentFiles(mse2)[["mzML_file"]][1L])

    ## Link qdata
    mse2 <- linkSampleData(mse2, with = "sampleData.sample = qdata.sample")
    res <- mse2[2]
    expect_equal(qdata(res), qdata(mse2)[, 2L])
    res <- mse2[1]
    expect_equal(qdata(res), qdata(mse2)[, 1L])

    ##
    qdata(mse2) <- se[, 1:2]
    res <- mse2[1:2]
    expect_equal(res, mse2)
})

test_that("MsExperiment works", {
    m <- MsExperiment()
    expect_s4_class(m, "MsExperiment")
})

test_that("show,MsExperiment works", {
    expect_output(show(MsExperiment()), "MsExperiment")
    expect_output(show(mse), "Experiment data")
    expect_output(show(MsExperiment()), "Empty object")
})

test_that("metadata<-,metadata,MsExperiment works", {
    m <- MsExperiment()
    metadata(m) <- list(version = "1.2", data = "1900")
    res <- metadata(m)
    expect_equal(res$version, "1.2")
    expect_equal(res$data, "1900")
})

test_that("spectra<-,spectra,MsExperiment works", {
    m <- MsExperiment()
    expect_null(spectra(m))

    res <- spectra(mse)
    expect_s4_class(res, "Spectra")
    expect_true(length(res) > 0)

    spectra(m) <- res
    expect_equal(spectra(m), res)

    expect_error(spectra(m) <- "b")
})
