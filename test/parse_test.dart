import 'package:flutter_test/flutter_test.dart';
import 'package:mathematrick/parser.dart';

void almost(a, b, max) {
  var delta = (a - b).abs();
  if (delta > max) {
    expect(a, b);
  } else {
    expect(true, true);
  }
}

void main() {
  test('Parser.handleWords can push numbers to the stack', () {
    Parser parser = new Parser();
    parser.handleWords(["1", "2", "3.0", "4"]);
    expect(parser.stack, equals([4.0, 3.0, 2.0, 1.0]));
  });


  test('Parser.handleWords addition performs as expected', () {
    Parser parser = new Parser();
    parser.handleWords(["1", "2", "3.0", "4", "plus"]);
    expect(parser.stack, equals([7.0, 2.0, 1.0]));
    parser.handleWords(["plus", "plus"]);
    expect(parser.stack.length, 1);
    almost(parser.stack[0], 10.0, 0.001);
  });

  test('Parser.handleWords subtraction performs as expected', () {
    Parser parser = new Parser();
    parser.handleWords(["1", "2", "3.0", "4", "moins"]);
    expect(parser.stack, equals([-1.0, 2.0, 1.0]));
    parser.handleWords(["moins", "moins"]);
    expect(parser.stack.length, 1);
    almost(parser.stack[0], -2.0, 0.001);
  });

  test('Parser.handleWords division performs as expected', () {
    Parser parser = new Parser();
    parser.handleWords(["1", "2", "3.0", "4", "division"]);
    expect(parser.stack, equals([3.0/4.0, 2.0, 1.0]));
  });

  test('Parser.handleWords moyenne performs as expected', () {
    Parser parser = new Parser();
    parser.handleWords(["1", "2", "3.0", "4", "3", "moyenne"]);
    expect(parser.stack, equals([(2.0 + 3.0 + 4.0) / 3.0, 1.0]));
  });
}