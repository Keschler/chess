import chess
import chess.svg

from search import Search



def show_board(chess_board):
    svg = chess.svg.board(
        chess_board
    )
    with open('chessboard.svg', 'w') as f:
        f.write(svg)


def main():
    chess_board = chess.Board()
    search = Search()
    while True:
        evaluation, best_move = search.minimax(chess_board, 4)
        print("Evaluation", evaluation, chess_board.fen())
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
            print("Invalid move, try again.")
            continue
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
