module random.markovchain;

import std.array: Appender, isArray;
import std.random: randomSample, uniform;
import std.range: ElementEncodingType;

// Represents a Markov chain as a stochastic matrix internally using a 2-D
// associative array.
// TODO: nothrow attribute to constructor/createMap when idup becomes nothrow.
class MarkovChain(T) if (isArray!T)
{
    alias E = ElementEncodingType!T; // element type
    alias iT = immutable(T);
    alias iE = immutable(E);

    int order;
    double[iE][iT] probMap; // keys must be immutable

    // T seqData => An array type which represents sequential data.
    // int order => The intended order of the Markov chain.
    this(T seqData, int order) @safe pure
    {
        this.order = order;
        probMap = createMap(seqData);
    }

    // Creates a structure similar to a stochastic matrix, but uses
    // associative arrays to save space.
    double[iE][iT] createMap(T seqData) @safe pure
    {
        // probMap is first used to hold the frequencies of transitions
        // occurring, but later holds the probabilities of transitions
        // occurring. This is done to save memory.
        double[iE][iT] probMap;
        int[iT] srcFreq;

        for(int i = 0; i < seqData.length-order; i++)
        {
            auto cur = seqData[i..i+order];
            auto next = seqData[i+order];

            // Pointers to the entries in the associative arrays.
            // These are preferable for performance reasons.
            auto probMapPtr = cur in probMap;
            auto srcFreqPtr = cur in srcFreq;

            if(probMapPtr) // probMap[cur] exists
            {
                (*srcFreqPtr)++;
                auto nextEnt = next in (*probMapPtr);
                if(nextEnt) // probMap[cur][next] exists
                    (*nextEnt)++;
                else
                    (*probMapPtr)[next] = 1;
            }
            else
            {
                // Using this pointer-based approach, the number of idups can
                // be reduced by not calling it for keys that already exist.
                auto icur = cur.idup;
                srcFreq[icur] = 1;
                probMap[icur][next] = 1;
            }
        }

        // Turn transition frequencies into transition probabilities.
        foreach(src, dstMap; probMap)
            foreach(dst, ref freq; dstMap)
                freq = freq/srcFreq[src]; // freq being replaced with prob

        return probMap;
    }
}

unittest
{
    string charSource = "abacadda";
    auto charChain = new MarkovChain!(string)(charSource, 1);
    assert(charChain.probMap["a"]['b'] == 1.0/3);
    assert(charChain.probMap["a"]['c'] == 1.0/3);
    assert(charChain.probMap["a"]['c'] == 1.0/3);
    assert(charChain.probMap["b"]['a'] == 1.0);
    assert(charChain.probMap["c"]['a'] == 1.0);
    assert(charChain.probMap["d"]['d'] == 1.0/2);
    assert(charChain.probMap["d"]['a'] == 1.0/2);

    int[] intSource = [ 1, 2, 1, 2, 2, 3, 3, 2, 2, 1, 2, 1, 5 ];
    auto intChain = new MarkovChain!(int[])(intSource, 2);
    assert(intChain.probMap[[1, 2]][1] == 2.0/3);
    assert(intChain.probMap[[1, 2]][2] == 1.0/3);
    assert(intChain.probMap[[2, 1]][2] == 2.0/3);
    assert(intChain.probMap[[2, 1]][5] == 1.0/3);
    assert(intChain.probMap[[2, 2]][1] == 1.0/2);
    assert(intChain.probMap[[2, 2]][3] == 1.0/2);
    assert(intChain.probMap[[2, 3]][3] == 1.0);
    assert(intChain.probMap[[3, 2]][2] == 1.0);
    assert(intChain.probMap[[3, 3]][2] == 1.0);
}
