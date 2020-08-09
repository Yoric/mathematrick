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
  test('Push numbers', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3.0", "4"]);
    expect(parser.stack, equals([4.0, 3.0, 2.0, 1.0]));
  });


  test('Addition', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3.0", "4", "plus"]);
    expect(parser.stack, equals([7.0, 2.0, 1.0]));
    parser.handleWords(["plus", "plus"]);
    expect(parser.stack.length, 1);
    almost(parser.stack[0], 10.0, 0.001);
  });

  test('Subtraction', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3.0", "4", "moins"]);
    expect(parser.stack, equals([-1.0, 2.0, 1.0]));
    parser.handleWords(["moins", "moins"]);
    expect(parser.stack.length, 1);
    almost(parser.stack[0], -2.0, 0.001);
  });

  test('Division', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3.0", "4", "division"]);
    expect(parser.stack, equals([3.0/4.0, 2.0, 1.0]));
  });

  test('Average', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3.0", "4", "3", "moyenne"]);
    expect(parser.stack, equals([(2.0 + 3.0 + 4.0) / 3.0, 1.0]));
  });

  test('Cancel', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["1", "2", "3", "4", "5"]);
    expect(parser.stack, equals([5.0, 4.0, 3.0, 2.0, 1.0]));
    parser.handleWords(["5", "moyenne"]);
    expect(parser.stack, equals([3.0]));
    parser.handleWords(["zut"]);
    expect(parser.stack, equals([5.0, 4.0, 3.0, 2.0, 1.0]));
  });

  test('cet', () {
    Parser parser = new Parser('en_US');
    parser.handleWords(["5", "espace", "cet", "espace", "moins"]);
    expect(parser.stack.length, 1);
    almost(parser.stack[0], -2.0, 0.01);
  });


  test('French comma notation', () {
    Parser parser = new Parser('fr_FR');
    parser.handleWords(["5,2"]);
    expect(parser.stack, [5.2]);
  });
}