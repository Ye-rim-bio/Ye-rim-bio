% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/normalize_by_feature_property.R
\name{normalize_by_feature_property}
\alias{normalize_by_feature_property}
\alias{normalize_by_feature_property_partitioned}
\alias{evaluate_parameter_effect}
\title{Normalization of LC-MS/MS Data}
\usage{
normalize_by_feature_property(
  eset,
  property,
  method = c("lowess", "loess"),
  ...
)

normalize_by_feature_property_partitioned(
  eset,
  property,
  partition_by,
  method = c("lowess", "loess"),
  ...
)

evaluate_parameter_effect(
  eset,
  sample,
  property,
  partition_by,
  partition_value,
  ...
)
}
\arguments{
\item{eset}{ExpressionSet/MSnSet object}

\item{property}{character; the column in the fData that the relative
intensities regress against.}

\item{method}{character; either \code{"lowess"} or \code{"loess"}
at this point.}

\item{...}{passed to \code{lowess} or \code{loess}. We suggest to use span = 0.5 with loess.}

\item{partition_by}{character; column name in \code{fData}, according to
which features will be partitioned. This is when, for example,
normalizing by LC and there are multiple fractions per sample.}

\item{sample}{indices of rows used to fit the trend}

\item{partition_value}{one of the values in the \code{partition_by} column
used to subset `eset`.}
}
\description{
Fits a nonparametric trend into relative abundance data. Any significant
(at this point just any) trend is corrected. Converts one
ExpressionSet/MSnSet to another ExpressionSet/MSnSet.
}
\note{
So far the only property I have in mind is elution time in
     label-free LC-MS/MS data.
}
