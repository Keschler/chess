import chess
import chess.svg
from search import Search
from time import time

cdef void show_board(object chess_board):
    svg = chess.svg.board(chess_board)
    with open('chessboard.svg', 'w') as f:
        f.write(svg)

cpdef tuple evaluate_move(object chess_board):
    search = Search()
    best_move, evaluation = search.iterative_deepening(chess_board, 8)
    return evaluation, best_move

def main():
    cdef str current_move
    cdef list moves
    cdef str board_fen
    chess_board = chess.Board()
    # r1bq1rk1/pp3ppp/2n1pn2/3p4/1b1PP3/2NB1N2/PP3PPP/R1BQ1RK1 w - - 0 1 | time limit 10 | 5 depth | 50.6 sec | 6 depth | 166 sec
    # Optimized version 36 sec (depth 5)
    chess_board.set_fen("r1bq1rk1/pp3ppp/2n1pn2/3p4/1b1PP3/2NB1N2/PP3PPP/R1BQ1RK1 w - - 0 1")
    search = Search()
    while True:
        start = time()
        best_move, best_eval = evaluate_move(chess_board)
        end = time()
        print("Evaluation", best_eval, chess_board.fen(), best_move, end - start)
        chess_board.push(best_move)
        if chess_board.is_checkmate():
            print("checkmate")
            break
        elif chess_board.is_stalemate():
            print("stalemate")
            break
        show_board(chess_board)
        current_move = input("Move: ")
        if current_move is None:
            print("error")
            break
        try:
            # noinspection PyTypeChecker
            chess_board.push_san(current_move)
        except ValueError:
            print("Invalid move, try again.", ValueError)
        if chess_board.is_checkmate():
            print("checkmate")
            break
        elif chess_board.is_stalemate():
            print("stalemate")
            break
        elif chess_board.is_repetition() or chess_board.is_variant_draw():
            print("draw")
            break
    return chess_board

if __name__ == "__main__":
    main()
