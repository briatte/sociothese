
library(ggplot2)
library(topicmodels)

load(paste0("data/sociothese", 
     ifelse(nchar(keyword) > 0, paste0("_", keyword), ""), ".rda"))

topics = 10 * c(1:5, 10, 20)
D = nrow(corpus)
folding = sample(rep(seq_len(10), ceiling(D))[seq_len(D)])

## 10-fold cross-validation (Grün and Hornik appendix code)

dir.create("results")

for (k in topics) {
  cat("k = ", k, "\n")
  
  for (chain in seq_len(10)) {
    cat("  chain = ", chain, "\n")

    FILE = paste("VEM_", k, "_", chain, ".rda", sep = "")
    training = LDA(corpus[folding != chain,], k = k,
                    control = list(seed = SEED))
    testing = LDA(corpus[folding == chain,], model = training,
                   control = list(estimate.beta = FALSE, seed = SEED))
    save(training, testing, file = file.path("results", FILE))

    FILE = paste("VEM_fixed_", k, "_", chain, ".rda", sep = "")
    training = LDA(corpus[folding != chain,], k = k,
                    control = list(seed = SEED, estimate.alpha = FALSE))
    testing = LDA(corpus[folding == chain,], model = training,
                   control = list(estimate.beta = FALSE, seed = SEED))
    save(training, testing, file = file.path("results", FILE))

    FILE = paste("Gibbs_", k, "_", chain, ".rda", sep = "")
    training = LDA(AssociatedPress[folding != chain,], k = k,
                    control = list(seed = SEED, burnin = 1000, thin = 100,
                    iter = 1000, best = FALSE), method = "Gibbs")
    best_training = training@fitted[[which.max(logLik(training))]]
    testing = LDA(AssociatedPress[folding == chain,],
                   model = best_training, control = list(estimate.beta = FALSE,
                   seed = SEED, burnin = 1000, thin = 100, iter = 1000, best = FALSE))
    save(training, testing, file = file.path("results", FILE))
  }
}

## plot perplexities of training data for VEM and VEM fixed

setwd("results")

sims = dir(pattern = "VEM")
sims = sapply(sims, function(x) {
  load(x)
  c(
    ifelse(grepl("VEM_fixed", x), "VEM fixed", "VEM"),
    unlist(strsplit(gsub("(.*)_([0-9]+)_([0-9]+).rda", "\\2;\\3", x), ";")),
    perplexity(testing), perplexity(training)
    )
})

setwd("..")

sims = data.frame(t(sims), stringsAsFactors = FALSE)
sims = cbind(sims[1], sapply(sims[, -1], as.numeric))
names(sims) = c("model", "topics", "fold", "testing", "training")

p = qplot(data = sims, x = topics, y = training, group = factor(fold)) +
  geom_line(alpha = .5) + facet_wrap(~ model)

ggsave("fig_crossvalidation.png", p, width = 7, height = 5)
ggsave("fig_crossvalidation.pdf", p, width = 7, height = 5)

## done
