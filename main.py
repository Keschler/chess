import chess
import random
import chess.svg
from collections import defaultdict

uniDict = {"WHITE": {0: "♟", 1: "♖", 2: "♘", 3: "♗", 4: "♕", 5: "♔", 6: "."},
           "BLACK": {0: "♙", 1: "♜", 2: "♞", 3: "♝", 4: "♛", 5: "♚", 6: "."}}


class Game:
    def __init__(self) -> None:
        self.search_depth = 3
        self.v_pawn = 100
        self.v_k_b = 300
        self.v_rook = 500
        self.v_queen = 900
        self.chess_board = chess.Board()
        self.start()

    def eval(self, fen):
        piece_counts = {
            "n": 0,
            "b": 0,
            "q": 0,
            "r": 0,
            "p": 0,
            "N": 0,
            "B": 0,
            "Q": 0,
            "R": 0,
            "P": 0
        }

        for char in fen:
            if char in piece_counts:
                piece_counts[char] += 1
        self.evaluation = ((piece_counts['n'] * 300 + piece_counts['b'] * 300 +
                            piece_counts['q'] * 900 + piece_counts['r'] * 500 + piece_counts["p"] * 100) -
                           (piece_counts['N'] * 300 + piece_counts['B'] * 300 +
                            piece_counts['Q'] * 900 + piece_counts['R'] * 500 + piece_counts["P"] * 100))
        return self.evaluation
    def search(self, depth):
        # Go through every legal move and choose the one with the best eval
        for move in self.legal_moves:
            self.analyse_board.push_san(move)

            # All legal moves for the enemy
            self.enemy_legal_moves = [str(move)
                                      for move in self.analyse_board.legal_moves]
            if len(self.enemy_legal_moves) == 0:  # If the move results in checkmate
                return move
            for move2 in self.enemy_legal_moves:
                self.analyse_board.push_san(move2)
                analysed_eval = self.eval(self.analyse_board.fen().split()[0])
                self.all_moves[move].append(
                    (move2, analysed_eval))  # adds the move + eval
                self.analyse_board.pop()
            self.analyse_board.pop()
        for first_move, moves in self.all_moves.items():
            min_value = float('inf')
            self.worst_evals.append(first_move)
            for move, eval in moves:
                if eval < min_value:
                    min_value = eval
                if min_value != float('inf'):  # Check if any valid moves were found
                    self.worst_evals.append(min_value)
        worst_eval = float('inf')
        worst_evals_updated = []
        last_move = ""
        # Search the worst eval for each move for the enemy responses
        for i, move_eval in enumerate(self.worst_evals):
            if isinstance(move_eval, str):
                worst_evals_updated.append((last_move, worst_eval))
                last_move = move_eval
                worst_eval = float('inf')
            elif move_eval < worst_eval:
                worst_eval = move_eval

        # Add the last move and worst eval to worst_evals_updated
        worst_evals_updated.append((last_move, worst_eval))
        del worst_evals_updated[0]
        self.worst_evals = worst_evals_updated  # Update old list
        print(self.worst_evals)

    def engine(self):
        '''
        Find best move
        '''
        self.analyse_board = self.chess_board.copy()
        self.fen = self.chess_board.fen().split()[0]
        self.legal_moves = [str(move)
                            for move in self.analyse_board.legal_moves]
        self.all_moves = defaultdict(list)
        self.worst_evals = []
        self.search(0)

        self.move_chosen = max(self.worst_evals, key=lambda x: x[1])
        return self.move_chosen[0]  # Return best move

    def show_board(self):
        svg = chess.svg.board(
            self.chess_board
        )
        with open('chessboard.svg', 'w') as f:
            f.write(svg)

    def start(self):
        while True:
            try:

                self.show_board()
                self.current_move = input(
                    "Give me the move you want to make (Example: Nc6")
                self.chess_board.push_san(self.current_move)
                self.chess_board.push_san(self.engine())
                if self.chess_board.is_checkmate():
                    print("Checkmate!")
                    exit()
                self.show_board()
            except Exception as e:
                print(e)


game = Game()