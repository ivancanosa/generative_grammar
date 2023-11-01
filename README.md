# Generative grammar
This is a simple generative grammar implementation in zig. The rules have a single non-terminal symbols as head and multiple symbols in the body. The system apply a random rule when there are multiple rules with the same head symbol.

# Simple example
Given this simple example of grammar:
S <- T0 | T1 | S S

The generated solution could contain sentences of any length of T0 and T1 symbols.

# Possible extensions
This implementation only contains the bare bones and applies the rules in a random order. Something more useful would be to define a minimum and maximum lenght of the generated sentence, as well which symbols must exists in the result. The algorithm then would use a searching algorithm to generate a desired solution.
