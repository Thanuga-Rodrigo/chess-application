import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

class ChessGamePage extends StatefulWidget {
  @override
  _ChessGamePageState createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  final chess.Chess _chess = chess.Chess();
  int selectedSquare = -1;
  List<String> validMoves = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chess Game'),
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

                  // Check if square should be highlighted
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
  }

void _onSquareTapped(int index, String square) {
  setState(() {
    if (selectedSquare == -1) {
      // Select a square
      selectedSquare = index;

      // Log the piece on the square
      final piece = _chess.get(square);
      if (piece == null) {
        print('No piece on $square'); // Debugging output
        validMoves = [];
        return;
      }

      print('Selected piece: ${piece.type} at $square');

      // Fetch valid moves for the selected square
      final moves = _chess.moves({'square': square});
      print('Moves returned for $square: $moves'); // Debugging output

      // Extract valid move destinations and strip piece notation
      validMoves = moves
          .map<String>((move) {
            if (move is String) {
              // Strip any leading piece notation (e.g., 'N' from 'Na3')
              return move.replaceAll(RegExp(r'^[NBRQK]'), '');
            } else if (move is Map<String, dynamic> && move.containsKey('to')) {
              return move['to'] as String;
            }
            return '';
          })
          .where((move) => move.isNotEmpty)
          .toList();

      print('Valid moves extracted for $square: $validMoves'); // Debugging output
    } else {
      // Attempt to make a move
      final fromRank = 8 - selectedSquare ~/ 8;
      final fromFile = String.fromCharCode(97 + selectedSquare % 8);
      final fromSquare = '$fromFile$fromRank';

      print('Attempting move from $fromSquare to $square'); // Debugging output

      if (_chess.move({'from': fromSquare, 'to': square}) != null) {
        print('Move successful from $fromSquare to $square'); // Debugging
        selectedSquare = -1;
        validMoves = [];
      } else {
        print('Move failed from $fromSquare to $square'); // Debugging
        selectedSquare = -1;
        validMoves = [];
      }
    }
  });
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
