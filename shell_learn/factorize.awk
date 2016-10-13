#! /bin/bash

# Grammar:
#       awk -f factorize.awk data
{
    n = int($1)
    m = n = (n >= 2) ? n : 2
    factors= ""
    for (k = 2; (m > 1) && (k^2 <= n); ){
        if (int(m % k) != 0){
            k++
            continue
            }
        m /= k
        factors = (factors == "") ? ("" k) : (factors " * " k)
    }
    if ((1 < m) && (m < n)){
        factors = factors " * " m
    }
    print n, (factors == "") ? "is prime" : ("= " factors)
}

