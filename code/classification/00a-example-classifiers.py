# -*- coding: utf-8 -*-
"""
Created on Tue Mar 29 14:34:11 2016

@author: PB (edited by RBM)
"""

import datetime, os, re, string
print datetime.datetime.now()
os.chdir('C:\\Users\\rbm166\\Dropbox\\Econvote_Media\\methods-analysis')

########################
# reading training data
#######################
import csv
import numpy as np
from pprint import pprint

f = open('temp\\training-data.csv', 'rb')
#f = open('temp/training-data.csv', 'rb')

reader = csv.reader(f)
reader.next()
text = []
labels = []
for row in reader:
    labels.append(int(row[0])) 
    if len(row) == 3:
        text.append(row[2] + " " + row[1])
    if len(row) == 2:
        text.append(row[1])

y = np.array(labels)

# removing punctuation and digits
text = [t.replace("</br></br>", " ") for t in text]
text = [re.sub(r'[^\x00-\x7F]+', ' ', t) for t in text]
text = [t.translate(None, string.punctuation + string.digits) for t in text]


########################
# reading test data
#######################

f = open('temp/test-data.csv', 'rb')
reader = csv.reader(f)
reader.next()
new_text = []
labels = []
for row in reader:
    labels.append(int(row[0])) 
    new_text.append(row[2] + " " + row[1])

new_y = labels
new_text = [t.replace("</br></br>", " ") for t in new_text]
new_text = [re.sub(r'[^\x00-\x7F]+', ' ', t) for t in new_text]
new_text = [t.translate(None, string.punctuation + string.digits) for t in new_text]

#######################
# preparing DFM
######################

from nltk.stem.porter import PorterStemmer
from sklearn.feature_extraction.text import CountVectorizer
from nltk.corpus import stopwords
from sklearn import cross_validation
from sklearn.linear_model import LogisticRegression

stop = stopwords.words('english')
porter = PorterStemmer()

def tokenizer_porter(text):
    return[porter.stem(word) for word in text.split()]

vectorizer = CountVectorizer(stop_words=None, tokenizer=tokenizer_porter, 
    max_features=75000, ngram_range=(1,3), 
    min_df=1, max_df=.80)

X = vectorizer.fit_transform(text)
Xnew = vectorizer.transform(new_text)

print(str(X.shape[1]) + " features")

#######################
# baseline classifier
######################

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]
val = alphas[0]
max_score = 0

for a in alphas:
    classifier = LogisticRegression(penalty="l2", C=a)
    classifier.fit(X, y)
    scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = LogisticRegression(penalty="l2", C=val)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.647 (+-0.02)
# Prec = 0.628 (+- 0.27)

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.744
# Prec = 0.833

#######################
# Ridge - SGD 
#######################

from sklearn.linear_model import SGDClassifier

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]
val = alphas[0]
max_score = 0

for a in alphas:
    classifier = SGDClassifier(penalty="l2", alpha=a, loss="log", 
                               random_state=0, n_iter=50)
    classifier.fit(X, y)
    scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = SGDClassifier(penalty="l2", alpha=val, loss="log", 
                           random_state=0, n_iter=50)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.642 (+/- 0.03)
# Prec = 0.577 (+/- 0.26)

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.768
# Prec = 0.818

#######################
# Lasso - not SGD
######################

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1]
val = alphas[0]
max_score = 0

for a in alphas:
    classifier = classifier = LogisticRegression(penalty="l1", C=a)
    classifier.fit(X, y)
    scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = LogisticRegression(penalty="l1", C=val)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.626 (+/- 0.07)
# Prec = 0.493 (+/- 0.18)

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.740
# Prec = 0.652


##########################
# L2 - not SGD (baseline)
##########################
# See baseline


#######################
# Elastic net - SGD
######################

print "Elastic Net SGD"

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.001, 0.005, 0.01, 0.05, 0.1]
alphas = np.array(alphas)
ls = [0.10, 0.25, 0.50, 0.75, 0.90]
ls = np.array(ls)
val = alphas[0]
lbest = ls[0]
max_score = 0

for a in alphas:
    for l in ls:
        classifier = SGDClassifier(loss="log", penalty="elasticnet", alpha=a, 
                                   l1_ratio=l, random_state=0, n_iter=50)
        classifier.fit(X, y)
        scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
        print str(a) + '--' + str(l) + ":" + str(scores.mean())
        if scores.mean() > max_score:
            val = a
            lbest = l
            max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
print 'Fitting classifier with l1_ratio=' + str(lbest)
classifier = SGDClassifier(loss="log", penalty="elasticnet", alpha=val, 
                           l1_ratio=lbest, random_state=0, n_iter=50)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.635 (+/- 0.04)
# Prec = 0.518 (+/- 0.19)

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.732
# Prec = 0.692

########################
# Elastic net - Not SGD
########################
## Couldn't get this to run for some reason; let it run for > 1hr and it 
##      hadn't finished.
## - Tried ElasticNet and ElasticNetCV.

## Just used the estimates from Pablo's code in 
##  '~/code/04d-classifiers-summaryRBM.R'

"""
print "Elastic Net - Not SGD"
from sklearn.linear_model import ElasticNetCV
print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.001, 0.005, 0.01, 0.05, 0.1]
alphas = np.array(alphas)
ls = [0.10, 0.25, 0.50, 0.75, 0.90]
ls = np.array(ls)
val = alphas[0]
lbest = ls[0]
max_score = 0
classifier = ElasticNetCV(alphas=alphas, l1_ratio=ls, cv=5)
classifier.fit(X, y)
for a in alphas:
    for l in ls:
        classifier = ElasticNetCV(alpha=a, l1_ratio=l)
        classifier.fit(X, y)
        scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
        print str(a) + '--' + str(l) + ":" + str(scores.mean())
        if scores.mean() > max_score:
            val = a
            lbest = l
            max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
print 'Fitting classifier with l1_ratio=' + str(lbest)
classifier = ElasticNet(alpha=val, l1_ratio=lbest)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))
"""

#######################
# Naive Bayes
######################

from sklearn.naive_bayes import BernoulliNB

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.001, 0.005, 0.01, 0.05, 0.1, 0.2]
val = alphas[0]
max_score = 0

for a in alphas:
    classifier = BernoulliNB(alpha=a)
    classifier.fit(X, y)
    scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = BernoulliNB(alpha=val)

print "Bernoulli Naive Bayes"

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.596 (+/- 0.10)
# Prec = 0.478 (+/- 0.29)

classifier.fit(X, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(vectorizer.get_feature_names(), classifier, n=50)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.736
# Prec = 0.545

#######################
# SVM
######################

print "SVM"

from sklearn.svm import LinearSVC

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.10, 0.50, 1, 1.50, 2, 2.50]
val = alphas[0]
max_score = 0

for a in alphas:
    classifier = LinearSVC(C=a)
    classifier.fit(X, y)
    scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = LinearSVC(C=val)


scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.585 (+/- 0.05)
# Prec = 0.398 (+/- 0.06)

classifier.fit(X, y)


predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.628 
# Prec = 0.387


#######################
# Adaboost
######################

print "Adaboost"

### Adaboost
from sklearn.ensemble import AdaBoostClassifier

n_ests = [10,25,50,75,100,150]
rates = [0.10, 0.25, 0.50, 1, 1.50]
val_est = n_ests[0]
val_rate = rates[0]
max_score = 0

for n in n_ests:
    for r in rates:
        classifier = AdaBoostClassifier(n_estimators=n, learning_rate=r, random_state=0)
        classifier.fit(X, y)
        scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
        print str(n) + ' estimators & ' + str(r) + ' rate= ' + str(scores.mean())
        if scores.mean() > max_score:
            val_est = n
            val_rate = r
            max_score = scores.mean()

## running classifier
print 'Fitting classifier with n_estimators=' + str(val_est) + ' & ' + ' learning rate=' + str(val_rate) 

classifier = AdaBoostClassifier(n_estimators=val_est, learning_rate=val_rate, 
                                random_state=0)

scores = cross_validation.cross_val_score(classifier, X, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.641 (+/- 0.02)
# Prec = 0.627 (+/- 0.25)

classifier.fit(X, y)

predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.728
# Prec = 0.750


#######################
# Random Forest
#######################

print "Random Forest"

n_ests = [5,10,25,50]
n_depth = [5,10,15,20]

val_est = n_ests[0]
val_dep = n_depth[0]
max_score = 0

from sklearn.ensemble import RandomForestClassifier
for n in n_ests:
    for d in n_depth:
        classifier = RandomForestClassifier(n_estimators=n, random_state=0, 
                                            max_depth=d)
        classifier.fit(X, y)
        scores = cross_validation.cross_val_score(classifier, X, y, cv=5)
        print str(n) + ' estimators w/ ' + str(d) + ' depth= ' + str(scores.mean())
        if scores.mean() > max_score:
            val_est = n
            val_dep = d
            max_score = scores.mean()


## running classifier
print 'Fitting classifier with n_estimators=' + str(val_est) + ' and a max depth of ' + str(val_dep)

classifier = RandomForestClassifier(n_estimators=val_est, random_state=0, 
                                    max_depth=val_dep)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Acc = 0.633 (+/- 0.01)
# Prec = 0.627 (+/- 0.27)

classifier.fit(X, y)


predictions = classifier.predict(Xnew)
from collections import Counter
freqs = Counter(new_y)
from sklearn.metrics import accuracy_score
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
print("Accuracy: %0.3f" % accuracy_score(new_y, predictions))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(new_y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(new_y)))
print("Precision: %0.3f" % precision_score(new_y, predictions))
print("Recall: %0.3f" % recall_score(new_y, predictions))

# Acc = 0.720
# Prec = 1.000


