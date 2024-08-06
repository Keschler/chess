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
    best_move, evaluation = search.iterative_deepening(chess_board, 3)
    return evaluation, best_move

def main():
    cdef str current_move
    cdef list moves
    cdef str board_fen
    chess_board = chess.Board()
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
