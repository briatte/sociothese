
library(ggplot2)
library(slam) # simple triplet matrix representation
library(tm)   # document term matrix representation
library(topicmodels) # fit LDA models (VEMs, Gibbs, CTM)

data = unz("data/resumes.csv.zip", "sociothese-resumes.csv")
data = read.csv(data, sep = ";", stringsAsFactors = FALSE)$V2
length(data)

corpus = "^Pas de resume|^Non communique|NULL$"
corpus = data[!grepl(corpus, data)]
length(corpus)

## fraction of missing data
print(length(corpus) / length(data), digits = 2)

## set keyword to "" to run on whole corpus instead
if(nchar(keyword)) corpus = corpus[ grepl("relig", corpus) ]

## set training to subset to a small training set
if(training) corpus = sample(corpus, training)

corpus = Corpus(VectorSource(corpus, encoding = "UTF-8"))
corpus = tm_map(corpus, tolower)
corpus = tm_map(corpus, removeWords, stopwords("fr"))

corpus = DocumentTermMatrix(corpus,
  control = list(stemming = TRUE, stopwords = TRUE, minWordLength = 4,
  removeNumbers = TRUE, removePunctuation = TRUE))

## document term matrix (first dimension is number of docs)
dim(corpus)

## mean term frequency-inverse document frequency (tf-idf)
summary(col_sums(corpus))
term_tfidf =
  tapply(corpus$v/row_sums(corpus)[corpus$i], corpus$j, mean) *
  log2(nDocs(corpus)/col_sums(corpus > 0))

## use median to trim most frequent words from corpus
summary(term_tfidf)

corpus = corpus[, term_tfidf >= 0.05]
corpus = corpus[row_sums(corpus) > 0, ]
summary(col_sums(corpus))

## document-term matrix with a reduced vocabulary
dim(corpus)

## identify 100 topics using LDA estimators
TM =
  list(
    VEM = LDA(corpus, k = k, control = list(seed = SEED)),
    VEM_fixed = LDA(corpus, k = k,
      control = list(estimate.alpha = FALSE, seed = SEED)),
    Gibbs = LDA(corpus, k = k, method = "Gibbs",
      control = list(seed = SEED, burnin = 1000,
      thin = 100, iter = 1000))
  )

## compare estimated and fixed VEM
sapply(TM[1:2], slot, "alpha")

## mean entropy for each fitted model
Entropy = sapply(TM, function(x)
 mean(apply(posterior(x)$topics,
 1, function(z) - sum(z * log(z)))))
Entropy

## most likely topic for each document
Topic = topics(TM[["VEM"]], 1)
table(Topic)[order(table(Topic), decreasing = TRUE)]

## 15 most frequent terms in each topic
Terms = terms(TM[["VEM"]], 15)
Terms[, table(Topic) >= quantile(table(Topic), probs = .75)]

save.image(paste0("data/sociothese", 
           ifelse(nchar(keyword) > 0, paste0("_", keyword), ""), ".rda"))
