% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dDHMM.R
\name{dDHMM}
\alias{dDHMM}
\alias{dDHMMo}
\alias{rDHMM}
\alias{rDHMMo}
\title{Dynamic Hidden Markov Model distribution for use in NIMBLE models}
\usage{
dDHMM(x, init, probObs, probTrans, len, log = 0)

dDHMMo(x, init, probObs, probTrans, len, log = 0)

rDHMM(n, init, probObs, probTrans, len)

rDHMMo(n, init, probObs, probTrans, len)
}
\arguments{
\item{x}{vector of observations, each one a positive integer
corresponding to an observation state
(one value of which could can correspond to "not observed", and
another value of which can correspond to "dead" or
"removed from system").}

\item{init}{vector of initial state probabilities. Must sum to 1}

\item{probObs}{time-independent matrix (\code{dDHMM} and
\code{rHMM}) or time-dependent 3D array (\code{dDHMMo} and
\code{rHMMo}) of observation probabilities.
First two dimensions of \code{probObs} are of size x (number of possible
system states) x (number of possible observation classes). \code{dDHMMo}
and \code{rHMMo} expects an additional third dimension of size (number of
observation times)}

\item{probTrans}{time-dependent array of system state transition
probabilities. Dimension of \code{probTrans} is (number of possible
system states) x  (number of possible system states)
x (number of observation times)}

\item{len}{length of observations (needed for rDHMM)}

\item{log}{TRUE or 1 to return log probability. FALSE or 0 to return probability}

\item{n}{number of random draws, each returning a vector of length
\code{len}. Currently only \code{n = 1} is supported, but the
argument exists for standardization of "\code{r}" functions}
}
\value{
For \code{dDHMM} and \code{dDHMMo}: the probability (or likelihood) or log
probability of observation vector \code{x}.
For \code{rDHMM} and \code{rDHMMo}: a simulated detection history, \code{x}.
}
\description{
\code{dDHMM} and \code{dDHMMo} provide Dynamic hidden Markov model
distributions for NIMBLE models.
}
\details{
These nimbleFunctions provide distributions that can be used directly in R or
in \code{nimble} hierarchical models (via \code{\link[nimble]{nimbleCode}}
and \code{\link[nimble]{nimbleModel}}).

The probability (or likelihood) of observation \code{x[t, o]} depends on
the previous true latent state, the time-dependent probability of
transitioning to a new state \code{probTrans}, and the probability of
observation states given the true latent state \code{probObs}.

The distribution has two forms, \code{dDHMM} and \code{dDHMMo}. \code{dDHMM}
takes a time-independent observation probability matrix with dimension
S x O, while \code{dDHMMo} expects a three-dimensional array of time-dependent
observation probabilities with dimension S x O x T, where O is the number of
possible occupancy states, S is the number of true latent states, and T is
the number of time intervals.

\code{probTrans} has dimension S x S x (T - 1). \code{probTrans}[i, j, t] is
the probability that an individual in state \code{i} at time \code{t} takes on
state \code{j} at time \code{t+1}.

\code{initStates} has length S. \code{initStates[i]} is the
probability of being in state \code{i} at the first observation time.

For more explanation, see
\href{../doc/Introduction_to_nimbleEcology.html}{package vignette} (or
\code{vignette("Introduction_to_nimbleEcology")}).

Compared to writing \code{nimble} models with a discrete true latent state
and a separate scalar datum for each observation, use
of these distributions allows one to directly sum (marginalize) over the
discrete latent state and calculate the probability of all observations from
one site jointly.

These are \code{nimbleFunction}s written in the format of user-defined
distributions for NIMBLE's extension of the BUGS model language. More
information can be found in the NIMBLE User Manual at
\href{https://r-nimble.org}{https://r-nimble.org}.

When using these distributions in a \code{nimble} model, the left-hand side
will be used as \code{x}, and the user should not provide the \code{log}
argument.

For example, in a NIMBLE model,

\code{observedStates[1:T] ~ dDHMM(initStates[1:S],
observationProbs[1:S, 1:O],
transitionProbs[1:S, 1:S, 1:(T-1)], T)}

declares that the \code{observedStates[1:T]} vector follows a dynamic hidden
Markov model distribution with parameters as indicated, assuming all the
parameters have been declared elsewhere in the model. In this case, \code{S}
is the number of system states, \code{O} is the number of observation
classes, and \code{T} is the number of observation occasions.This
will invoke (something like) the following call to \code{dDHMM} when
\code{nimble} uses the model such as for MCMC:

\code{rDHMM(observedStates[1:T], initStates[1:S],
observationProbs[1:S, 1:O],
transitionProbs[1:S, 1:S, 1:(T-1)], T, log = TRUE)}

If an algorithm using a \code{nimble} model with this declaration
needs to generate a random draw for \code{observedStates[1:T]}, it
will make a similar invocation of \code{rDHMM}, with \code{n = 1}.

If the observation probabilities are time-dependent, one would use:

\code{observedStates[1:T] ~
dDHMMo(initStates[1:S], observationProbs[1:S, 1:O, 1:(T-1)],
transitionProbs[1:S, 1:S, 1:(T-1)], T)}
}
\examples{
\donttest{
# Set up constants and initial values for defining the model
dat <- c(1,2,1,1) # A vector of observations
init <- c(0.4, 0.2, 0.4) # A vector of initial state probabilities
probObs <- t(array( # A matrix of observation probabilities
       c(1, 0,
         0, 1,
         0.8, 0.2), c(2, 3)))

probTrans <- array(rep(0.5, 27), # A matrix of time-indexed transition probabilities
            c(3,3,3))

# Define code for a nimbleModel
 nc <- nimbleCode({
   x[1:4] ~ dDHMM(init[1:3], probObs = probObs[1:3, 1:2],
                  probTrans = probTrans[1:3, 1:3, 1:4], len = 4)

   for (i in 1:3) {
     init[i] ~ dunif(0,1)

     for (j in 1:3) {
       for (t in 1:4) {
         probTrans[i,j,t] ~ dunif(0,1)
       }
     }

     probObs[i, 1] ~ dunif(0,1)
     probObs[i, 2] <- 1 - probObs[1,i]
   }
 })

# Build the model, providing data and initial values
DHMM_model <- nimbleModel(nc,
                          data = list(x = dat),
                          inits = list(init = init,
                                       probObs = probObs,
                                       probTrans = probTrans))
# Calculate log probability of x from the model
DHMM_model$calculate()
# Use the model for a variety of other purposes...
}
}
\references{
D. Turek, P. de Valpine and C. J. Paciorek. 2016. Efficient Markov chain Monte
Carlo sampling for hierarchical hidden Markov models. Environmental and Ecological Statistics
23:549–564. DOI 10.1007/s10651-016-0353-z
}
\seealso{
For hidden Markov models with time-independent transitions,
see \link{dHMM} and \link{dHMMo}.
For simple capture-recapture, see \link{dCJS}.
}
\author{
Perry de Valpine, Daniel Turek, and Ben Goldstein
}
