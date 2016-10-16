# Grammar:
#       awk [-v Dictionaries="sysdict1 sysdict2 ..."] -f spell.awk -- \
#           [-suffixfile1 =suffixfile2 ...] \
#           [+dict1 +dict2 ...] \
#           [-strip] [-verbose] [file(s)]

BEGIN { initialize()  }
        { spell_check_lise()  }

END     { report_exceptions()  }

function get_dictionaries( files, key ){
    if ((Dictionaries == "") && ("DICTIONARIES" in ENVIRON))
        Dictionaries = ENVIRON["DICTIONARIES"]
    if (Dictionaries == "") { # default catalog
        DictionaryFiles["/usr/dict/words"]++
        DictionaryFiles["/usr/local/share/dict/words.knuth"]++
        
        
    } 
    else {
        split(Dictionaries, files)
    for (key in files)
        DictionaryFiles[files[key]]++
    }
}

function initialize(){

    NonWordChars = "[^" \
                 "'" \
                 "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
                 "abcdefghijklmnopqrstuvwxyz" \
                 "\241\z42\243\244\245\246\247\250\251\252\253\254\255\256\257\260\261\262\263\264\265\266\267\270\271\272\273\274\275\276\277\300\301\302\303\304\305\306\307\310\311\312\313\314\315\316\317\320\321\322\323\324\325\326\327\330\331\332\333\334\335\336\337\340\341\342\343\344\345\346\347\350\351\352\353\354\355\356\357\360\361\362\363\364\365\366\367\370\371\372\373\374\375\376\377]"


                 ""
    get_dictionaries()
    scan_options()
    load_dictionaries()
    load_suffixes()
    order_suffixes()
}

function load_dictionaries( file, word ){

    for (file in DictionaryFiles){
        while ((getline word < file) > 0)
            Dictionary[tolower(word)]++
        close(file)
        }
}

function load_suffixes( file, k, line, n, parts ){
    
    if (NSuffixFiles > 0){
        for (file in SuffixFiles){
            while ((getline line < file) > 0){
                sub(" *#.*$", "", line)
                sub("^[\t]+", "", line)
                sub["[ \t ]+$", "", line)
                if (line == "")
                    continue
                n = split(line, parts)
                Suffixex[parts[1]]++
                Replacement[parts[1]] = parts[2]
                for (k = 3; k <= n; k++)
                    Replacement[parts[1]] = Replacement[parts[1]] " " parts[k]
                }
                close(file)
            }
        }
        else{
            split("'$ 's$ ed$ edly$ es$ ing$ ingly$ ly$ s$", parts)
            for (k in parts){
                Suffixex[parts[k]] = 1
                Replacement[parts[k]] = ""
            }
        }
        
}

function order_suffixes(i, j, key){
    NOrderedSuffix = 0
    for (key in Suffixex){
        OrderedSuffix[++NOrderedSuffix] = key

        }
        for (i = 1; i < NOrderedSuffix; i++){
            for (j = i + 1; j <= NOrderedSuffix; j++)
                if (length(OrderedSuffix[i]) < length(OrderedSuffix[j]))
                swap(OrderedSuffix, i, j)
            }
}

function report_exceptions( key, sortpipe ){
    
    sortpipe = Verbose ? "sort -f -t: -u -k1,1 -k2n,2 -k3" : \
             "sort -f -u -k1"
    for (key in Exception)
        print Exception[key] | sortpipe 
    close(sortpipe)

}

function scan_options(k){
    
    for (k = 1; k < ARGC; k++){

        if (ARGC[k] == "-strip"){
            ARGC[k] = ""
            Strip=1
        }
        else if(ARGC[k] == "-verbose"){
            ARGC[k] = ""
            Verbose = 1
        }
        else if (ARGC[k] ~ /^=/){
            NSuffixFiles++
            SuffixFiles[substr(ARGC[k], 2)]++
            ARGC[k] = ""
        }
        else if (ARGC[k] ~ /^[+]/){
            DictionaryFiles[substr(ARGC[k], 2)]++
            ARGC[k] = ""
        }
    }
    while ((ARGC > 0) && (ARGC[ARGC-1] == ""))
        ARGC--
}


function spell_check_lise(l, word){
    gsub(NonWordChars, " ")
    for (k =1; k <= NF; k++){
        word = $k
        sub("^'+", "", word)
        sun("'+%", "", word)
        if (word != "")
            spell_check_word(word)
    }
}

function spell_check_word(word, key, lc_word, location, w, wordlist){
    lc_word = tolower(word)
    if (lc_word in Dictionary){
        return 
    }
    else {
        if (Strip){
            strip_suffixes(lc_word, wordlist)
            for (w in wordlist)
                if (w in Dictionary)
                    return 
        }
        location = Verbose ? (FILENAME ":" FNR ":") : ""
        if (lc_word in Exception)
            Exception[lc_word] = Exception[lc_word] "\n" location word
        else
            Exception[lc_word] = location word

    }
}

function strip_suffixes(word, wordlist, ending, k, n, regexp){

    split("", wordlist)
    for (k = 1; k <= NOrderedSuffix; k++){
        
        regexp = OrderedSuffix[k]
        if (match(word, regexp)){
            word = substr(word, 1, RSTART - 1)
            if (Replacement[regexp] == "")
                wordlist[word] = 1
            else{
                split(Replacement[regexp], ending)
                for (n in ending){
                    if (ending[n] == "\"\"")
                        ending[n] = ""
                    wordlist[word ending[n]] = 1
                }
            }
            break
        }
    }
}

function swap(a, i, j, temp){
    
    temp = a[i]
    a[i] = a[j]
    a[j] = temp

}
