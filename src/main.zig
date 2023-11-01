const std = @import("std");
const RndGen = std.rand.DefaultPrng;

const Symbol = enum {
    T0,
    T1,
    T2,
    T3,
    S,
};

const Symbols = std.ArrayList(Symbol);

// The first symbol of the slice is the head
const Rule = struct {
    symbols: []const Symbol,
};

const Rules = std.ArrayList(Rule);

pub fn hasSymbol(symbols: Symbols, symbol: Symbol) bool {
    for (symbols.items) |it| {
        if (it == symbol) {
            return true;
        }
    }
    return false;
}

pub fn generateSentence(rules: Rules, s: Symbol) !Symbols {
    var allocator = std.heap.page_allocator;

    var rnd = RndGen.init(@intCast(std.time.milliTimestamp()));

    var nonterminals = Symbols.init(allocator);
    defer nonterminals.deinit();

    var result = Symbols.init(allocator);
    try result.append(s);

    // Compute the nonterminal symbols
    for (rules.items) |rule| {
        const head = rule.symbols[0];
        if (!hasSymbol(nonterminals, head)) {
            try nonterminals.append(head);
        }
    }

    // Check if the result only has terminal symbols
    var finished = true;
    for (result.items) |symbol| {
        if (hasSymbol(nonterminals, symbol)) {
            finished = false;
            break;
        }
    }

    var correctRulesPos = std.ArrayList(usize).init(allocator);
    defer correctRulesPos.deinit();

    while (!finished) {
        // Get next nonterminal pos
        var nonterminalPos: usize = 0;
        var nonterminalSymbol: Symbol = undefined;
        for (result.items, 0..) |symbol, i| {
            if (hasSymbol(nonterminals, symbol)) {
                nonterminalPos = i;
                nonterminalSymbol = symbol;
                break;
            }
        }

        // Compute the current correct rules
        correctRulesPos.clearRetainingCapacity();
        for (rules.items, 0..) |rule, i| {
            if (rule.symbols[0] == nonterminalSymbol) {
                try correctRulesPos.append(i);
            }
        }

        // Apply a random rule
        const rulePos = rnd.random().int(usize) % correctRulesPos.items.len;
        const rule = rules.items[rulePos];
        _ = result.orderedRemove(nonterminalPos);
        for (rule.symbols[1..rule.symbols.len]) |bodyS| {
            try result.insert(nonterminalPos, bodyS);
            nonterminalPos += 1;
        }

        // Check if the result only has terminal symbols
        finished = true;
        for (result.items) |symbol| {
            if (hasSymbol(nonterminals, symbol)) {
                finished = false;
                break;
            }
        }
    }

    return result;
}

pub fn print(symbols: Symbols) void {
    for (symbols.items) |symbol| {
        var str = @tagName(symbol);
        std.debug.print("{s} ", .{str});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var rules = Rules.init(allocator);
    defer rules.deinit();

    // S <- T0
    {
        var rule = Rule{ .symbols = &[_]Symbol{ Symbol.S, Symbol.T0 } };
        try rules.append(rule);
    }

    // S <- T1
    {
        var rule = Rule{ .symbols = &[_]Symbol{ Symbol.S, Symbol.T1 } };
        try rules.append(rule);
    }

    // S <- S S
    {
        var rule = Rule{ .symbols = &[_]Symbol{ Symbol.S, Symbol.S, Symbol.S } };
        try rules.append(rule);
    }

    var result = try generateSentence(rules, Symbol.S);
    defer result.deinit();

    print(result);
}
