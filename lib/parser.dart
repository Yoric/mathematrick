class Token {
  String toString() {
    throw("Not implemented");
  }
}

class Number extends Token {
  final double value;
  Number(this.value);
  @override
  String toString() {
    return "$value";
  }
}

enum Symbols {
  DOT,
  MUL,
  ADD,
  SUB,
  DIV,
  AVG,
  NEG,
  DEL,

  // Opposite (operation)
  OPP,
  CANCEL,
}

class Symbol extends Token {
  final Symbols value;
  Symbol(this.value);
  @override
  String toString() {
    return "$value";
  }
}

class Parser {
  List<double> stack = [];
  void flush() {}

  void binary(double Function(double, double) op) {
    var a = stack[1];
    var b = stack[0];
    var result = op(a, b);
    stack[1] = result;
    stack.removeAt(0);
    print("Binary: $a, $b => $result");
  }

  void unary(double Function(double) op) {
    var a = stack[0];
    var result = op(a);
    stack[0] = result;
  }

  void nary(double Function(List<dynamic> values) op) {
    var arity = stack[0].round();
    if (arity != stack[0]) {
      throw ('Not an integer');
    }
    var values = [];
    for (var i = 1; i <= arity; ++i) {
      values.add(stack[i]);
    }
    assert(values.length == arity);
    print("nary collected $arity values: $values");
    var result = op(values);
    stack[arity] = result;
    stack.removeRange(0, arity);
  }

  List<Token> tokenize(Iterable<String> words) {
    List<Token> tokens = [];

    // Tokenize
    for (var word in words) {
      print("Parser: Tokenizing $word");
      word = word.toLowerCase();

      // Attempt to detect numbers.
      var asNumber = double.tryParse(word);
      if (asNumber == null) {
        // Some numbers are unfortunately recognized as non-numbers, try and patch them here.
        switch (word) {
          case "un":
            asNumber = 1;
            break;
          case "de":
            asNumber = 2;
            break;
          default:
            break;
        }
      }

      // Attempt to fix numbers
      if (asNumber != null) {
        print("Parser: Found number $asNumber");
        if (tokens.length > 1) {
          var previous = tokens[tokens.length - 1];
          if (previous is Symbol) {
            // Recover "1 point 2" => 1.2
            if (previous.value == Symbols.DOT) {
              var beforeSeparator = tokens[tokens.length - 2];
              print(
                  "Parser: Attempting to merge $beforeSeparator and $asNumber");
              if (beforeSeparator is Number) {
                var value =
                    Number(double.parse('${beforeSeparator.value}$asNumber'));
                tokens.removeAt(tokens.length - 2);
                tokens.add(value);
                continue;
              } else {
                throw ("Not a number: $beforeSeparator");
              }
            } else if (previous.value == Symbols.NEG) {
              tokens.removeAt(tokens.length - 1);
              tokens.add(Number(-asNumber));
              continue;
            }
          }
        }
        tokens.add(Number(asNumber));
        continue;
      }

      print("Parser: Not a number");

      var asSymbol;
      // At this stage, we're going to assume that the word is not a number.
      switch (word) {
        // FIXME: Move this to an external dictionary.
        case "virgule":
        case ",":
        case "point":
        case ".":
          asSymbol = Symbols.DOT;
          break;
        case "négatif":
          asSymbol = Symbols.NEG;
          break;
        case "opposé":
        case "opposée":
          asSymbol = Symbols.OPP;
          break;
        // Separators
        case "égal":
        case "=":
        case "entrée":
        case "entrés":
        case "entrées":
          break;
        case "addition":
        case "plus":
        case "+":
          asSymbol = Symbols.ADD;
          break;
        case "multiplication":
        case "multiplié":
        case "multiplier":
        case "fois":
        case "*":
          asSymbol = Symbols.MUL;
          break;
        case "soustraction":
        case "moins":
        case "-":
          asSymbol = Symbols.SUB;
          break;
        case "division":
        case "diviser":
        case "divisé":
        case "/":
          asSymbol = Symbols.DIV;
          break;
        case "moyenne":
          asSymbol = Symbols.AVG;
          break;
        case "supprime":
        case "supprimer":
          asSymbol = Symbols.DEL;
          break;
        case "zut":
          asSymbol = Symbols.CANCEL;
          break;
        default:
          throw ('Unknown word $word');
      }
      print("Parser: Found symbol $asSymbol");
      tokens.add(Symbol(asSymbol));
    }
    print("Parser: tokenized $tokens");
    return tokens;
  }

  void handleWords(Iterable<String> words) {
    var tokens = tokenize(words);

    // FIXME: Handle Undo.

    for (var token in tokens) {
      if (token is Number) {
        stack.insert(0, token.value);
        continue;
      } else if (token is Symbol) {
        switch (token.value) {
          case Symbols.ADD:
            binary((a, b) {
              return a + b;
            });
            break;
          case Symbols.MUL:
            binary((a, b) {
              return a * b;
            });
            break;
          case Symbols.DIV:
            binary((a, b) {
              return a / b;
            });
            break;
          case Symbols.SUB:
            binary((a, b) {
              return a - b;
            });
            break;
          case Symbols.OPP:
            unary((a) {
              return -a;
            });
            break;
          case Symbols.DEL:
            stack.removeAt(0);
            break;
          case Symbols.AVG:
            nary((values) {
              return values.fold(0, (acc, element) => acc + element) /
                  values.length;
            });
            break;
          case Symbols.CANCEL:
          case Symbols.DOT:
          case Symbols.NEG:
            throw ("Not implemented");
        }
      }
    }

/*
        switch (asCommand) { // FIXME: Move this to an external dictionary.
          // Fix numbers.
          case "deux":
          case "de":
            stack.insert(0, 2);
            break;
          case "virgule":
          case ",":
          case "point":
          case ".":
            hasPendingComma = true;
            break;
          // Separators
          case "égal":
          case "=":
          case "entrée":
          case "entrés":
          case "entrées":
            break;
          case "addition":
          case "plus":
          case "+":
            binary((a, b) { return a + b; });
            break;
          case "multiplication":
          case "multiplié":
          case "multiplier":
          case "fois":
          case "*":
            binary((a, b) { return a * b; });
            break;
          case "soustraction":
          case "moins":
          case "-":
            binary((a, b) { return a - b; });
            break;
          case "division":
          case "diviser":
          case "divisé":
          case "/":
            binary((a, b) { return a / b; });
            break;
          case "moyenne":
            nary((values) { return values.fold(0, (acc, element) => acc + element) / values.length; });
            break;
          default:
            throw('Unknown word $asCommand');
        }
*/
  }
}
