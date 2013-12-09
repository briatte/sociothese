
library(ggplot2)
library(topicmodels) # extract LDA posterior distribution

load(paste0("data/sociothese", 
     ifelse(nchar(keyword) > 0, paste0("_", keyword), ""), ".rda"))

dim(corpus)

#
# posterior distributions (probabilities of assignment to most likely topic)
#
methods = c("VEM", "VEM_fixed", "Gibbs")
DF = data.frame(posterior = unlist(lapply(TM,
  function(x) apply(posterior(x)$topics, 1, max))),
  method = factor(rep(methods, each = nrow(posterior(TM$VEM)$topics)), methods))

p = ggplot(DF, aes(x = posterior, color = method, fill = method)) +
  geom_density(alpha = .75) +
  facet_wrap(~ method, nrow = 1) +
  scale_x_continuous(breaks = 0:5/5) +
  labs(y = "Frequency\n",
       x = "\nProbability of assignment to the most likely topic") +
  theme_grey(12) +
  theme(legend.position = "none")

ggsave("fig_posteriors.pdf", p, width = 12, height = 5)
ggsave("fig_posteriors.png", p, width = 12, height = 5)

#
# create corpus and LDA simulation function
#

## test set ~ 1/6th of corpus
test_corpus = corpus[ sample(1:dim(corpus)[1], dim(corpus)[1] %/% 7) ]
dim(test_corpus)

## training set ~ 1/3th of corpus
train_corpus = corpus[ sample(1:dim(corpus)[1], dim(corpus)[1] %/% 5) ]
dim(train_corpus)

## simulation function for LDA (slow)
lda.rep = function(train, test = NULL, n = 5, method = "VEM") {
  model = vector("list")
  train_perp = test_perp = c()
  loglik = c()
  n = 2:n
  for(i in n) {
    cat(".. k = ", i, "\n")
    model[[i-1]] = LDA(train, control = list(verbose = 0),method, k = i)
    train_perp[i] = perplexity(model[[i-1]])
    if(!is.null(test)){
      test_perp[i] = perplexity(model[[i-1]], newdata = test)
    }
    
    loglik[i] = logLik(model[[i-1]])[1]
  }
  return(list(model = model,
              train_perp = train_perp,
              test_perp = test_perp,
              loglik = loglik))
}

#
# simulate LDA models with n = 2:50 topics
#

ldas = lda.rep(train = train_corpus, test = test_corpus, n = n, method = "VEM")
## str(ldas)

train_perp = ldas$train_perp
test_perp = ldas$test_perp
loglik = ldas$loglik
est = data.frame(x = c(1:n,1:n),
                 y = c(test_perp,train_perp),
                 type = c(rep("test_perplexity", n),
                          rep("train_perplexity", n)
                         )
                )

#
# plots
#

ggdiag = function(data, x) { # where x is the diagnostic name
  ggplot(data, aes(x, y, color = type)) + 
    geom_line() + 
    geom_point() + 
    facet_wrap(~ type) +
    labs(x = "number of topics", y = x) +
    theme(legend.position = "none")
  }

p = ggdiag(est, "perplexity")

ggsave("fig_set_perplexity.pdf", p, width = 7, height = 5)
ggsave("fig_set_perplexity.png", p, width = 7, height = 5)

## get alpha and entropy
alpha = sapply(ldas[[1]], slot, "alpha")
entropy = sapply(ldas[[1]], 
  function(x) {
    mean(apply(posterior(x)$topics, 1, function(z) - sum(z * log(z))))
    })
ae = data.frame(x = c(1:(n - 1), 1:(n - 1)),
                y = c(alpha, entropy),
                type = c(
                         rep( "alpha",   (n - 1) ), 
                         rep( "entropy", (n - 1) )
                        )
                )

p = ggdiag(ae, "alpha and entropy")

ggsave("fig_alpha_entropy.pdf", p, width = 7, height = 5)
ggsave("fig_alpha_entropy.png", p, width = 7, height = 5)

save(ldas, file = paste0("data/diagnostics", 
                         ifelse(nchar(keyword) > 0, 
                                paste0("_", keyword), 
                                ""), ".rda"))
