
library(GGally) # plot network with ggplot2
library(ggplot2)
library(network)
library(topicmodels) # extract LDA posterior distribution

load(paste0("data/sociothese", 
     ifelse(nchar(keyword) > 0, paste0("_", keyword), ""), ".rda"))

#
# network method (topic.graph function by github.com/qxde01)
#
topic.graph = function(x) {
  v2g = function(x) {
    nr = length(x) - 1
    g = c()
    nr = 1:nr
    for(i in nr) {
      g0 = cbind(x[i], x[i + 1])
      g = rbind(g, g0)
    }
    g
  }
  ###
  gg = c()
  if(class(x) == "matrix") {
    nc = 1:ncol(x)
    for(i in nc) {
      gg0 = v2g(x[, i])
      gg0 = cbind(gg0, rep(i, nrow(gg0)))
      gg = rbind(gg, gg0)
    }
  }
  if(class(x) == "list") {
    nc = 1:length(x)
    for(i in nc) {   
      gg0 = v2g(x[[i]])
      gg0 = cbind(gg0, rep(i, nrow(gg0)))
      gg = rbind(gg, gg0)
    }
  }
  colnames(gg) = c("source", "target", "type")
  return(gg)
}

model = TM[[1]]
top_terms = terms(model, k = 5, threshold = threshold)
dim(top_terms)

g = topic.graph(top_terms)
g = network(g[, 1:2])

p = ggnet(g, label = TRUE, subset = 2, size = 0)

ggsave("fig_network.pdf", p, scale = .5)
ggsave("fig_network.png", p, scale = .5)

# over and out
