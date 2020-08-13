import 'dart:math';

import 'package:intl/intl.dart';

class Token {
  String toString() {
    throw ("Not implemented");
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
  DUP,
  DEL,

  // Average and standard deviation as a single operation.
  AVG_AND_STDDEV,

  // Prefix minus (e.g. "-1")
  NEG,

  // Opposite / suffix minus (e.g. "1 -" => "-1")
  OPP,

  // Undo operationo
  CANCEL,
}

class Symbol extends Token {
  final Symbols value;
  Symbol(this.value);
  @override
  String toString() {
    switch (value) {
      case Symbols.DOT:
        return ",";
      case Symbols.MUL:
        return "*";
      case Symbols.ADD:
        return "+";
      case Symbols.SUB:
        return "-";
      case Symbols.DIV:
        return "/";
      case Symbols.AVG_AND_STDDEV:
        return "moyenne";
      case Symbols.NEG:
        return "négatif";
      case Symbols.DEL:
        return "supprimer";
      case Symbols.DUP:
        return "dupliquer";
      case Symbols.OPP:
        return "opposé";
      case Symbols.CANCEL:
        return "annuler";
      case Symbols.AVG_AND_STDDEV:
        return "statistiques";
    }
    return "?";
  }
}

class Value {
  Value(this.name, this.value);
  final String name;
  final double value;

  @override
  String toString() {
    if (this.name == null) {
      return "$value";
    } else {
      return "($name) $value";
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is Value) {
      return name == other.name && value == other.value;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}


class Parser {
  List<List<Value>> backups = [];
  List<Value> stack = [];
  final String _locale;
  NumberFormat _numberFormat;

  Parser(this._locale) {
    _numberFormat = Intl.withLocale(_locale, () => NumberFormat());
  }

  void flush() {}

  void binary(double Function(double, double) op, String name) {
    var a = stack[1];
    var b = stack[0];
    var result = op(a.value, b.value);
    stack[1] = Value(name, result);
    stack.removeAt(0);
    print("Binary: $a, $b => $result");
  }

  void unary(double Function(double) op, String name) {
    var a = stack[0].value;
    var result = op(a);
    stack[0] = Value(name, result);
  }

  void nary(double Function(List<dynamic> values) op, String name) {
    // Check that we're dealing with a number.
    var ceil = stack[0].value.ceil();
    var floor = stack[0].value.floor();
    if (ceil != floor) {
      throw ("${stack[0]} n'est pas un entier");
    }
    var arity = ceil;
    var values = [];
    for (var i = 1; i <= arity; ++i) {
      values.add(stack[i].value);
    }
    assert(values.length == arity);
    print("nary collected $arity values: $values");
    var result = op(values);
    stack[arity] = Value(name, result);
    stack.removeRange(0, arity);
  }

  List<Token> tokenize(Iterable<String> words) {
    print("Tokenizing with locale $_locale");
    List<Token> tokens = [];

    // Tokenize
    for (var word in words) {
      print("Parser: Tokenizing $word");
      word = word.toLowerCase();

      // Attempt to detect numbers.
      var asNumber;
      try {
        asNumber = _numberFormat.parse(word);
      } catch (_) {
        // Obviously, it's not a number.
      }
      if (asNumber == null) {
        // Some numbers are unfortunately recognized as non-numbers, try and patch them here.
        switch (word) {
          case "un":
          case "hein":
            asNumber = 1.0;
            break;
          case "de":
            asNumber = 2.0;
            break;
          case "cet":
          case "cette":
            asNumber = 7.0;
            break;
          case "neuf":
            asNumber = 9.0;
            break;
          default:
            break;
        }
      }
      if (asNumber == null) {
        // Speech recognition sometimes inserts a comma, trying to make this a list.

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
                throw ("$beforeSeparator n'est pas un nombre");
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
        case "par":
        case "égal":
        case "=":
        case "entrer":
        case "entrée":
        case "entrés":
        case "entrées":
        case "espace":
        case "espaces":
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
        case "x":
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
          asSymbol = Symbols.AVG_AND_STDDEV;
          break;
        case "supprime":
        case "supprimer":
          asSymbol = Symbols.DEL;
          break;
        case "dup":
        case "dupe":
        case "dupliquer":
        case "dupliqué":
        case "encore":
        case "copier":
        case "copié":
        case "recopier":
        case "recopié":
          asSymbol = Symbols.DUP;
          break;
        case "zut":
        case "annule":
        case "annulé":
        case "annuler":
          asSymbol = Symbols.CANCEL;
          break;
        default:
          throw ('Mot inconnu "$word"');
      }
      if (asSymbol != null) {
        print("Parser: Found symbol $asSymbol");
        tokens.add(Symbol(asSymbol));
      } else {
        print("Parser: skipping $word");
      }
    }
    print("Parser: tokenized $tokens");
    return tokens;
  }

  void handleWords(Iterable<String> words,
      {void Function(List<String>) onStatus}) {
    if (onStatus == null) {
      onStatus = (_) {};
    }
    var tokens;
    try {
      tokens = tokenize(words);
    } catch (ex) {
      onStatus(["Je ne comprends pas: ", "$ex"]);
      throw ex;
    }
    {
      List<String> status = [];
      for (var token in tokens) {
        status.add('$token');
      }
      print("Sending back status $status");
      onStatus(status);
    }

    // Register undo.
    backups.add(stack.toList());

    try {
      for (var token in tokens) {
        if (token is Number) {
          stack.insert(0, Value(null, token.value));
          continue;
        } else if (token is Symbol) {
          switch (token.value) {
            case Symbols.ADD:
              binary((a, b) {
                return a + b;
              }, "+");
              break;
            case Symbols.MUL:
              binary((a, b) {
                return a * b;
              }, "*");
              break;
            case Symbols.DIV:
              binary((a, b) {
                return a / b;
              }, "/");
              break;
            case Symbols.SUB:
              binary((a, b) {
                return a - b;
              }, "-");
              break;
            case Symbols.OPP:
              unary((a) {
                return -a;
              }, "~");
              break;
            case Symbols.DEL:
              stack.removeAt(0);
              break;
            case Symbols.DUP:
              stack.insert(0, stack[0]);
              break;
            case Symbols.AVG_AND_STDDEV:
              // Check that we're dealing with a number.
              var ceil = stack[0].value.ceil();
              var floor = stack[0].value.floor();
              if (ceil != floor) {
                throw ("${stack[0]} n'est pas un entier");
              }
              var arity = ceil;

              // Compute average.
              var average = 0.0;
              for (var i = 1; i <= arity; ++i) {
                average += stack[i].value;
              }
              average = average / arity;

              // Compute stddev.
              var stddev = 0.0;
              for (var i = 1; i <= arity; ++i) {
                var delta = (stack[i].value - average);
                stddev += delta * delta;
              }
              stddev = sqrt(stddev / (arity - 1));

              // Replace
              stack.removeRange(0, arity + 1);
              stack.insert(0, Value("moyenne de $arity", average));
              stack.insert(0, Value("écart-type de $arity", stddev));
              break;
            case Symbols.CANCEL:
              print("Canceling, here are my backups: $backups");
              stack = backups[backups.length - 2];
              backups.removeRange(backups.length - 2, backups.length);
              print("My new stack is $stack");
              break;
            case Symbols.DOT:
            case Symbols.NEG:
              throw ("Not implemented");
          }
        }
      }
    } catch (ex) {
      stack = backups.removeLast();
      throw ex;
    }
  }

  void handleText(String text, {void Function(List<String>) onStatus}) {
    print("Parser: handling text $text");
    var regexp = RegExp(r"\S+");
    var matches = regexp.allMatches(text);
    var words = matches.map((match) => text.substring(match.start, match.end));
    print("Words: $words");
    handleWords(words, onStatus: onStatus);
  }
}
