function rindex(string, find, k, ns,nf){
# return the index of string found in $string

    ns = length(string)
    nf = length(find)

    for (k = ns + 1 - nf; k >= 1; k--)
        if (substr(string, k, nf) == find)
            return k
    return 0
}

# test 

result = rindex($1,$2);
echo $2 " is " $1 ",index: "$result
