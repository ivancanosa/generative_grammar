const std = @import("std");

const T0 = struct {};
const T1 = struct {};
const T2 = struct {};

const S = struct {};

const Symbol = union(enum) {
    T0: void,
    T1: void,
    T2: void,
    T3: void,
    S: void,
};

const Symbols = std.ArrayList(Symbol);

const Rule = struct {
    head: Symbol,
    body: Symbols,
};

const Rules = std.ArrayList(Rule);

pub fn hasSymbol(symbols: Symbols, symbol: Symbol) bool {
    for (symbols.items) |it| {
        return std.meta.eql(it, symbol);
    }
    return false;
}

pub fn generateSentence(rules: Rules, s: Symbol) !Symbols {
    var allocator = std.heap.page_allocator;

    var nonterminals = Symbols.init(allocator);
    defer nonterminals.deinit();

    var result = Symbols.init(allocator);
    try result.append(s);

    // Compute the nonterminal symbols
    for (rules.items) |rule| {
        const head = rule.head;
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

        // Apply a rule and expand the symbol
        for (rules.items) |rule| {
            if (std.meta.eql(rule.head, nonterminalSymbol)) {
                _ = result.orderedRemove(nonterminalPos);
                for (rule.body.items) |bodyS| {
                    try result.insert(nonterminalPos, bodyS);
                    nonterminalPos += 1;
                }
            }
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
        std.debug.print("{s}", .{str});
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var rule: Rule = .{ //
        .head = .{ .S = {} },
        .body = Symbols.init(allocator),
    };

    try rule.body.append(.{ .T1 = {} });

    var rules = Rules.init(allocator);
    defer rules.deinit();
    try rules.append(rule);

    var result = try generateSentence(rules, .{ .S = {} });
    defer result.deinit();

    print(result);
}
