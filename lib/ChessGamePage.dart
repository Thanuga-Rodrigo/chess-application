import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChessGamePage extends StatefulWidget {
  @override
  _ChessGamePageState createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  final chess.Chess _chess = chess.Chess();
  final _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));
  int selectedSquare = -1;
  List<String> validMoves = [];
  bool isPlayerOne = true; // Change this for testing

  @override
  void initState() {
    super.initState();
    _channel.stream.listen((message) {
      final move = Uri.splitQueryString(message);
      if (_chess.move(move) != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chess Game (Player ${isPlayerOne ? "1" : "2"})'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                itemCount: 64,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) {
                  final rank = 8 - index ~/ 8;
                  final file = String.fromCharCode(97 + index % 8);
                  final square = '$file$rank';
                  final piece = _chess.get(square);

                  bool isHighlighted = validMoves.contains(square);

                  return GestureDetector(
                    onTap: () => _onSquareTapped(index, square),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? Colors.yellow.withOpacity(0.5)
                            : (index + index ~/ 8) % 2 == 0
                                ? Colors.brown[300]
                                : Colors.white,
                        border: isHighlighted
                            ? Border.all(color: Colors.yellow, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: piece != null
                            ? Text(
                                _getPieceSymbol(piece),
                                style: TextStyle(
                                  fontSize: 24,
                                  color: piece.color == chess.Color.WHITE
                                      ? Colors.white
                                      : Colors.black,
                                  shadows: piece.color == chess.Color.WHITE
                                      ? [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                            color: Colors.black,
                                          ),
                                        ]
                                      : null,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _chess.reset();
      selectedSquare = -1;
      validMoves = [];
    });
    _channel.sink.add(Uri.encodeQueryComponent('reset=true'));
  }

  void _onSquareTapped(int index, String square) {
    if ((_chess.turn == chess.Color.WHITE && isPlayerOne) ||
        (_chess.turn == chess.Color.BLACK && !isPlayerOne)) {
      setState(() {
        if (selectedSquare == -1) {
          selectedSquare = index;
          final moves = _chess.moves({'square': square});
          validMoves = moves.map((move) {
            if (move is String) {
              return move.replaceAll(RegExp(r'^[NBRQK]'), '');
            } else if (move is Map<String, dynamic> && move.containsKey('to')) {
              return move['to'] as String;
            }
            return '';
          }).where((move) => move.isNotEmpty).toList();
        } else {
          final fromRank = 8 - selectedSquare ~/ 8;
          final fromFile = String.fromCharCode(97 + selectedSquare % 8);
          final fromSquare = '$fromFile$fromRank';
          if (_chess.move({'from': fromSquare, 'to': square}) != null) {
            _channel.sink.add(Uri.encodeQueryComponent(
                'from=$fromSquare&to=$square'));
          }
          selectedSquare = -1;
          validMoves = [];
        }
      });
    }
  }

  String _getPieceSymbol(chess.Piece piece) {
    final symbols = {
      chess.Color.WHITE: {
        chess.PieceType.PAWN: '♙',
        chess.PieceType.KNIGHT: '♘',
        chess.PieceType.BISHOP: '♗',
        chess.PieceType.ROOK: '♖',
        chess.PieceType.QUEEN: '♕',
        chess.PieceType.KING: '♔',
      },
      chess.Color.BLACK: {
        chess.PieceType.PAWN: '♟',
        chess.PieceType.KNIGHT: '♞',
        chess.PieceType.BISHOP: '♝',
        chess.PieceType.ROOK: '♜',
        chess.PieceType.QUEEN: '♛',
        chess.PieceType.KING: '♚',
      },
    };
    return symbols[piece.color]![piece.type]!;
  }
}
