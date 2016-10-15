function join(array, n, fs, k, s){
# array[0]fsarray[1]...

    if (n >= 1){
        s = array[1]
        for (k = 2; k <= n; k++){
            s = s fs array[k]
            }
        }
    return (s)
    }

# test 
result = join($1,$2,$3)
echo $1 " >>join>> " $2;

