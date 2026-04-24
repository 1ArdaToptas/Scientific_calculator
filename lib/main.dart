import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = "";
  String lastExpression = "";

  void onButtonPress(String value) {
    setState(() {
      if (value == "C") {
        display = "";
        lastExpression = "";
      } else if (value == "⌫") {
        if (display.isNotEmpty) {
          display = display.substring(0, display.length - 1);
        }
      } else if (value == "=") {
        try {
          final result = ExpressionParser(display).parse();
          lastExpression = display;
          display = result;
        } catch (e) {
          lastExpression = display;
          display = "Error";
        }
      } else {
        display = display == "Error" ? value : display + value;
      }
    });
  }

  Widget buildButton(String text, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => onButtonPress(text),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRow(List<Widget> children) {
    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Scientific Calculator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lastExpression,
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    display.isEmpty ? "0" : display,
                    style: const TextStyle(
                        fontSize: 40, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              buildRow([
                buildButton("sin(", Colors.blueGrey),
                buildButton("cos(", Colors.blueGrey),
                buildButton("tan(", Colors.blueGrey),
                buildButton("log(", Colors.blueGrey),
              ]),
              buildRow([
                buildButton("sqrt(", Colors.blueGrey),
                buildButton("^", Colors.blueGrey),
                buildButton("(", Colors.blueGrey),
                buildButton(")", Colors.blueGrey),
              ]),
              buildRow([
                buildButton("7", Colors.grey),
                buildButton("8", Colors.grey),
                buildButton("9", Colors.grey),
                buildButton("÷", Colors.orange),
              ]),
              buildRow([
                buildButton("4", Colors.grey),
                buildButton("5", Colors.grey),
                buildButton("6", Colors.grey),
                buildButton("×", Colors.orange),
              ]),
              buildRow([
                buildButton("1", Colors.grey),
                buildButton("2", Colors.grey),
                buildButton("3", Colors.grey),
                buildButton("-", Colors.orange),
              ]),
              buildRow([
                buildButton("0", Colors.grey),
                buildButton(".", Colors.grey),
                buildButton("⌫", Colors.red),
                buildButton("+", Colors.orange),
              ]),
              buildRow([
                buildButton("C", Colors.red),
                buildButton("=", Colors.green),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class ExpressionParser {
  final String input;
  late List<Token> tokens;
  int index = 0;

  ExpressionParser(this.input) {
    tokens = tokenize(input.replaceAll("×", "*").replaceAll("÷", "/"));
  }

  String parse() {
    final result = parseExpression();
    if (index != tokens.length) throw Exception();
    return result.toString();
  }

  Token? peek() => index < tokens.length ? tokens[index] : null;
  Token consume() => tokens[index++];

  double parseExpression() {
    double value = parseTerm();
    while (peek()?.value == "+" || peek()?.value == "-") {
      final op = consume().value;
      final next = parseTerm();
      value = op == "+" ? value + next : value - next;
    }
    return value;
  }

  double parseTerm() {
    double value = parsePower();
    while (peek()?.value == "*" || peek()?.value == "/") {
      final op = consume().value;
      final next = parsePower();
      value = op == "*" ? value * next : value / next;
    }
    return value;
  }

  double parsePower() {
    double value = parseUnary();
    if (peek()?.value == "^") {
      consume();
      value = pow(value, parsePower()).toDouble();
    }
    return value;
  }

  double parseUnary() {
    if (peek()?.value == "-") {
      consume();
      return -parseUnary();
    }
    return parsePrimary();
  }

  double parsePrimary() {
    final token = consume();

    if (token.type == "number") return token.value;

    if (token.type == "paren" && token.value == "(") {
      final val = parseExpression();
      if (consume().value != ")") throw Exception();
      return val;
    }

    if (token.type == "function") {
      consume(); // (
      final val = parseExpression();
      consume(); // )

      switch (token.value) {
        case "sin":
          return sin(val);
        case "cos":
          return cos(val);
        case "tan":
          return tan(val);
        case "log":
          return log(val) / ln10;
        case "sqrt":
          return sqrt(val);
      }
    }

    throw Exception();
  }

  List<Token> tokenize(String exp) {
    final tokens = <Token>[];
    int i = 0;

    while (i < exp.length) {
      final c = exp[i];

      if (c.trim().isEmpty) {
        i++;
        continue;
      }

      if (RegExp(r'[0-9.]').hasMatch(c)) {
        String num = c;
        i++;
        while (i < exp.length &&
            RegExp(r'[0-9.]').hasMatch(exp[i])) {
          num += exp[i++];
        }
        tokens.add(Token("number", double.parse(num)));
        continue;
      }

      if (RegExp(r'[a-z]').hasMatch(c)) {
        String func = c;
        i++;
        while (i < exp.length &&
            RegExp(r'[a-z]').hasMatch(exp[i])) {
          func += exp[i++];
        }
        tokens.add(Token("function", func));
        continue;
      }

      if ("+-*/^".contains(c)) {
        tokens.add(Token("operator", c));
        i++;
        continue;
      }

      if (c == "(" || c == ")") {
        tokens.add(Token("paren", c));
        i++;
        continue;
      }

      throw Exception();
    }

    return tokens;
  }
}

class Token {
  final String type;
  final dynamic value;

  Token(this.type, this.value);
}