from multiprocessing import Pool, cpu_count
import chess
import chess.svg
from search import Search


cpdef show_board(chess_board):
    svg = chess.svg.board(chess_board)
    with open('chessboard.svg', 'w') as f:
        f.write(svg)

cpdef evaluate_move(board_fen_move_depth):
    board_fen, move, depth = board_fen_move_depth
    board = chess.Board(board_fen)
    search = Search()
    evaluation, best_move = search.minimax(board, depth, move=move)
    return evaluation, move

def main():
    chess_board = chess.Board()
    #chess_board.set_fen("8/k7/3p4/p2P1p2/P2P1P2/8/8/K7 w - - 0 1")
    depth = 4

    while True:
        print(chess.popcount(chess_board.occupied))
        if chess.popcount(chess_board.occupied) < 10:
            depth += 1
        if chess.popcount(chess_board.occupied) < 5:
            depth += 2

        # Generate possible moves
        moves = list(chess_board.legal_moves)
        board_fen = chess_board.fen()  # Use FEN string to avoid copying the entire board object
        board_move_depths = [(board_fen, move, depth) for move in moves]

        # Evaluate moves in parallel
        with Pool(processes=cpu_count()) as pool:
            results = pool.map(evaluate_move, board_move_depths)
        best_evaluation, best_move = max(results, key=lambda x: x[0])
        print("Evaluation", best_evaluation, chess_board.fen(), results)
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
