% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/list_objects.R
\name{lsos}
\alias{lsos}
\title{Improved list of objects}
\usage{
lsos(..., n = 10)
}
\arguments{
\item{...}{arguments passed to \code{.ls.objects}.}

\item{n}{maximum number of rows to output. Default is 10.}
}
\value{
\code{data.frame}
\describe{
  \item{\code{Type}}{the object class}
  \item{\code{Size}}{the object size (in bytes)}
  \item{\code{Rows}}{the number of rows, if applicable}
  \item{\code{Columns}}{the number of columns, if applicable}
}
}
\description{
Create a \code{data.frame} containing information about objects in the global
environment.
}
