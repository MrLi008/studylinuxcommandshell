function gcd(x,y,r){
    x = int(x)
    y = int(y)
    print x,y
    r = x % y
    return (r == 0) ? y : gcd(y, r)

    }

# test this function
    {
        g = gcd($1, $2);
        print "gcd(" $1 ", " $2 ") = ", g;
        }
