import sklearn as skl
import numpy as np
import pandas as pd

import os

#######################
## Read in the data:
#######################


#f1 = open('/home/perkypat/Dropbox/NBA/data/elo-plus-features/04-clean-sampled-elo-plus-538-method.csv')
#f2 = open('~/Dropbox/NBA/data/03-elo-plus-all-features-no-home-court-1516.csv')

os.chdir('C:\\Users\\rbm166\\Dropbox\\IST597k\\NBA\\data\\')
f1 = open('elo-plus-features\\04-clean-sampled-elo-plus-538-method.csv', 'rb')

elo538 = pd.read_csv(f1)
#eloNoHome = csv.reader(f2)

#print elo538[10:]

#######################
## Pre-processing:
#######################
from sklearn.preprocessing import MinMaxScaler
from sklearn.preprocessing import OneHotEncoder

# drop out NAs
elo538.dropna(axis=0, how='any', inplace=True)

# separate out our DV:
y = np.array(elo538.win_dum)

# remove the DV, game IDs, and ref IDs from the data frame:
elo538.drop(['win_dum', 'X_iscopy', 'game_id', 'date_game', 'ref_id1', 'ref_id2', 'ref_id3'], 
            axis=1, inplace=True)


# dummy out string variables:
elo538 = pd.get_dummies(elo538)
X = elo538


# normalize numeric data:
mms = MinMaxScaler()
X_norm = mms.fit_transform(X)
X_norm = pd.DataFrame(X_norm)
X_norm.columns = X.columns.values


#######################
## Logistic Regression:
#######################

from sklearn import cross_validation
from sklearn.linear_model import LogisticRegression

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.125, 0.15, 0.2]
val = alphas[0]
max_score = 0

for a in alphas:
    clf_logit1 = LogisticRegression(penalty="l1", C=a)
    clf_logit1.fit(X_norm, y)
    scores = cross_validation.cross_val_score(clf_logit1, X_norm, y, cv=10)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()
        
        
print 'Fitting classifier with alpha=' + str(val)
clf_logit1 = LogisticRegression(penalty="l1", C=val)

scores = cross_validation.cross_val_score(clf_logit1, X_norm, y, cv=10)
precision = cross_validation.cross_val_score(clf_logit1, X_norm, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(clf_logit1, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))

# Fitting classifier with alpha=0.125
# Accuracy: 0.700 (+/- 0.07)
# Baseline accuracy (all 0's): 0.50
# Baseline accuracy (all 1's): 0.50
# Precision: 0.697 (+/- 0.09)

clf_logit1.fit(X_norm, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)
        
show_most_informative_features(X_norm.columns.values, clf_logit1, n=25)

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
    classifier.fit(X_norm, y)
    scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=5)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = BernoulliNB(alpha=val)

print "\nBernoulli Naive Bayes\n"

scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X_norm, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Fitting classifier with alpha=0.001
# Bernoulli Naive Bayes
# Accuracy: 0.651 (+/- 0.10)
# Baseline accuracy (all 0's): 0.50
# Baseline accuracy (all 1's): 0.50
# Precision: 0.652 (+/- 0.11)

classifier.fit(X_norm, y)

def show_most_informative_features(words, clf, n=20):
    c_f = sorted(zip(clf.coef_[0], words))
    top = zip(c_f[:n], c_f[:-(n+1):-1])
    print "\t%.4s\t%-20s\t\t%.4s\t%-20s" % ("","NEGATIVE","","POSITIVE")
    for (c1,f1),(c2,f2) in top:
        print "\t%.4f\t%-25s\t\t%.4f\t%-25s" % (c1,f1,c2,f2)

show_most_informative_features(X_norm.columns.values, classifier, n=25)




#######################
# SVM
######################

print "\nSVM\n"

from sklearn.svm import LinearSVC

print 'Estimating regularization parameter via cross-validation...'
## choosing regularization parameter with cross-validation
alphas = [0.01, 0.05, 0.10, 0.50, 0.75, 1, 1.50]
val = alphas[0]
max_score = 0

# l2 penalty has better cross-validated performance
for a in alphas:
    classifier = LinearSVC(C=a, penalty='l2')
    classifier.fit(X_norm, y)
    scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=10)
    print str(a) + ':' + str(scores.mean())
    if scores.mean() > max_score:
        val = a
        max_score = scores.mean()

## running classifier
print 'Fitting classifier with alpha=' + str(val)
classifier = LinearSVC(C=val)


scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X_norm, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Fitting classifier with alpha=0.01
# Accuracy: 0.682 (+/- 0.06)
# Baseline accuracy (all 0's): 0.50
# Baseline accuracy (all 1's): 0.50
# Precision: 0.685 (+/- 0.09)

classifier.fit(X_norm, y)



#######################
# Adaboost
######################

print "\nAdaboost\n"

### Adaboost
from sklearn.ensemble import AdaBoostClassifier

n_ests = [5, 10, 25, 50, 100, 250]
rates = [0.01, 0.05, 0.10, 0.25, 0.50]
val_est = n_ests[0]
val_rate = rates[0]
max_score = 0

for n in n_ests:
    for r in rates:
        classifier = AdaBoostClassifier(n_estimators=n, learning_rate=r, random_state=0)
        classifier.fit(X_norm, y)
        scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=10)
        print str(n) + ' estimators & ' + str(r) + ' rate= ' + str(scores.mean())
        if scores.mean() > max_score:
            val_est = n
            val_rate = r
            max_score = scores.mean()

## running classifier
print 'Fitting classifier with n_estimators=' + str(val_est) + ' & ' + ' learning rate=' + str(val_rate) 

classifier = AdaBoostClassifier(n_estimators=val_est, learning_rate=val_rate, 
                                random_state=0)

scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=10)
precision = cross_validation.cross_val_score(classifier, X_norm, y, cv=10, scoring='precision')
#recall = cross_validation.cross_val_score(classifier, X, y, cv=10, scoring='recall', n_jobs=10)

from collections import Counter
freqs = Counter(y)

print("Accuracy: %0.3f (+/- %0.2f)" % (scores.mean(), scores.std() * 2))
print("Baseline accuracy (all 0's): %0.2f" % (float(freqs[0]) / len(y)))
print("Baseline accuracy (all 1's): %0.2f" % (float(freqs[1]) / len(y)))
print("Precision: %0.3f (+/- %0.2f)" % (precision.mean(), precision.std() * 2))
#print("Recall: %0.3f (+/- %0.2f)" % (recall.mean(), recall.std() * 2))

# Fitting classifier with n_estimators=10 &  learning rate=0.1
# Accuracy: 0.688 (+/- 0.06)
# Baseline accuracy (all 0's): 0.50
# Baseline accuracy (all 1's): 0.50
# Precision: 0.682 (+/- 0.07)



#######################
# Random Forest
#######################

print "\nRandom Forest\n"

n_ests = [250, 500, 1000, 2000]
n_depth = [2, 3, 4, 5, 8, 10]

val_est = n_ests[0]
val_dep = n_depth[0]
max_score = 0

from sklearn.ensemble import RandomForestClassifier
for n in n_ests:
    for d in n_depth:
        classifier = RandomForestClassifier(n_estimators=n, random_state=0, 
                                            max_depth=d)
        classifier.fit(X_norm, y)
        scores = cross_validation.cross_val_score(classifier, X_norm, y, cv=5)
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

# Fitting classifier with n_estimators=250 and a max depth of 3
# Accuracy: 0.665 (+/- 0.04)
# Baseline accuracy (all 0's): 0.50
# Baseline accuracy (all 1's): 0.50
# Precision: 0.682 (+/- 0.07)

classifier.fit(X_norm, y)


