import random

import chess
import chess.svg


class Game:
    def __init__(self) -> None:
        self.b_w_knight = chess.BB_EMPTY
        self.b_w_king = chess.BB_EMPTY
        self.b_w_bishop = chess.BB_EMPTY
        self.b_w_queen = chess.BB_EMPTY
        self.b_w_rook = chess.BB_EMPTY
        self.b_w_pawn = chess.BB_EMPTY
        self.b_b_bishop = chess.BB_EMPTY
        self.b_b_queen = chess.BB_EMPTY
        self.b_b_rook = chess.BB_EMPTY
        self.b_b_knight = chess.BB_EMPTY
        self.b_b_king = chess.BB_EMPTY
        self.b_b_pawn = chess.BB_EMPTY
        self.KNIGHT_TABLE = [
            -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
            -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
            -0.3, 0, 0.1, 0.15, 0.15, 0.1, 0, -0.3,
            -0.3, 0.05, 0.15, 0.2, 0.2, 0.15, 0.05, -0.3,
            -0.3, 0, 0.15, 0.2, 0.2, 0.15, 0, -0.3,
            -0.3, 0.05, 0.1, 0.15, 0.15, 0.1, 0.05, -0.3,
            -0.4, -0.2, 0, 0.05, 0.05, 0, -0.2, -0.4,
            -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
        ]
        self.WHITE_PAWN_TABLE = [
            0, 0, 0, 0, 0, 0, 0, 0,  # 1st rank (not used for pawns)
            0, 0, 0, 0, 0, 0, 0, 0,  # 2nd rank
            0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2,  # 3rd rank
            0.3, 0.3, 0.3, 0.6, 0.6, 0.3, 0.3, 0.3,  # 4th rank
            0.4, 0.4, 0.4, 0.5, 0.5, 0.4, 0.4, 0.4,  # 5th rank
            1, 0.8, 0.6, 0.6, 0.6, 0.6, 0.8, 1,  # 6th rank
            2, 1.5, 1.2, 1, 1, 1.2, 1.5, 2,  # 7th rank
            9, 9, 9, 9, 9, 9, 9, 9,  # 8th rank
        ]
        self.KING_ENDGAME_CHECKMATE_TABLE = [
            4, 4, 4, 4, 4, 4, 4, 4,
            4, 2, 2, 2, 2, 2, 2, 4,
            4, 2, 0, 0, 0, 0, 2, 4,
            4, 2, 0, 0, 0, 0, 2, 4,
            4, 2, 0, 0, 0, 0, 2, 4,
            4, 2, 0, 0, 0, 0, 2, 4,
            4, 2, 2, 2, 2, 2, 2, 4,
            4, 4, 4, 4, 4, 4, 4, 4
        ]
        self.KING_ENDGAME_TABLE = [
            -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
            -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
            -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
            -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
            -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
            -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
            -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
            -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
        ]
        self.BLACK_PAWN_TABLE = list(reversed(self.WHITE_PAWN_TABLE))
        self.zobrist_piece_keys = {}
        self.zobrist_black_to_move = None
        self.zobrist_castling_rights = []
        self.zobrist_en_passant_file = []
        self.zobrist_keys = {}
        self.chess_board = chess.Board()
        #self.chess_board.set_fen("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3")
        self.update_bitboards()
        self.start()

    def initialise_zobrist(self):  # For transposition tables
        random.seed(42)
        self.zobrist_piece_keys = {(piece_color, piece_index, square_index): random.getrandbits(64)
                                   for piece_color in [True, False]
                                   for piece_index in range(8)  # Assuming 8 different types of pieces (including empty)
                                   for square_index in range(64)}
        self.zobrist_black_to_move = random.getrandbits(64)
        self.zobrist_castling_rights = [random.getrandbits(64) for _ in range(16)]
        self.zobrist_en_passant_file = [random.getrandbits(64) for _ in range(8)]

    def calculate_zobrist(self, board):
        zobrist_key = 0
        for square_index in range(64):
            if board.piece_at(square_index) is not None:  # If the square is not empty
                piece_type = board.piece_at(square_index).piece_type
                piece_color = board.piece_at(square_index).color  # Black: False, White: True
                zobrist_key ^= self.zobrist_piece_keys[piece_color, piece_type, square_index]
        if not board.turn:
            zobrist_key ^= self.zobrist_black_to_move
        for i in range(16):
            if (board.castling_rights >> i) & 1:
                zobrist_key ^= self.zobrist_castling_rights[i]
        if board.ep_square is not None:  # If there is an en passant
            ep_rank = chess.square_file(board.ep_square)
            zobrist_key ^= self.zobrist_en_passant_file[ep_rank]
        return zobrist_key

    def only_pawns_and_kings_left(self):
        pieces = [self.b_b_queen, self.b_b_knight, self.b_b_bishop, self.b_b_rook, self.b_w_bishop, self.b_w_knight,
                  self.b_w_rook, self.b_w_queen]
        if all(piece == chess.BB_EMPTY for piece in pieces):
            return True
        else:
            return False

    def get_king_into_corner(self, board):
        material = 0
        multiplicator = (32 - chess.popcount(board.occupied)) / 100
        if self.only_pawns_and_kings_left():
            multiplicator = 0
        for square_index in range(64):
            if self.b_b_king & (1 << square_index):
                material += self.KING_ENDGAME_CHECKMATE_TABLE[square_index]
        return material * multiplicator

    def get_king_into_center(self):
        white_material = 0
        black_material = 0
        if self.only_pawns_and_kings_left():
            for square_index in range(64):
                if self.b_b_king & (1 << square_index):
                    black_material += self.KING_ENDGAME_TABLE[square_index]
                elif self.b_w_king & (1 << square_index):
                    white_material += self.KING_ENDGAME_TABLE[square_index]
        return white_material - black_material

    def mobility_bonus(self):
        black_bonus = 0
        white_bonus = 0
        black_bishops = []
        white_bishops = []
        for square_index in range(64):
            if self.b_b_bishop & (1 << square_index):
                black_bishops.append(square_index)
            elif self.b_w_bishop & (1 << square_index):
                white_bishops.append(square_index)
        if not black_bishops and not white_bishops:
            return 0
        else:
            for black_bishop in black_bishops:
                for direction in [-9, -7, 7, 9]:
                    for distance in range(1, 8):
                        target_square = black_bishop + (direction * distance)
                        if 0 <= target_square < 64 and self.chess_board.piece_at(target_square) is None:
                            black_bonus += 0.2
            for white_bishop in white_bishops:
                for direction in [-9, -7, 7, 9]:
                    for distance in range(1, 8):
                        target_square = white_bishop + (direction * distance)
                        if 0 <= target_square < 64 and self.chess_board.piece_at(target_square) is None:
                            white_bonus += 0.2
        return white_bonus - black_bonus

    def eval(self, board=None):
        if board is None:
            board = self.chess_board
        if board.is_checkmate():
            return 1000 if board.turn == chess.WHITE else -1000
        if board.can_claim_threefold_repetition() or board.is_repetition() or board.is_variant_draw():
            print("------DRAW-----")
            return 0
        pawn_value = 1
        knight_value = 3
        bishop_value = 3
        rook_value = 5
        queen_value = 9
        white_material = (
                pawn_value * chess.popcount(self.b_w_pawn)
                + knight_value * chess.popcount(self.b_w_knight)
                + bishop_value * chess.popcount(self.b_w_bishop)
                + rook_value * chess.popcount(self.b_w_rook)
                + queen_value * chess.popcount(self.b_w_queen)
        )

        black_material = (
                pawn_value * chess.popcount(self.b_b_pawn)
                + knight_value * chess.popcount(self.b_b_knight)
                + bishop_value * chess.popcount(self.b_b_bishop)
                + rook_value * chess.popcount(self.b_b_rook)
                + queen_value * chess.popcount(self.b_b_queen)
        )
        for square_index in range(1, 64):  # Give bonus points if the knight/pawn is well-placed (middle, far up the
            # board)
            if self.b_w_knight & (1 << square_index):
                white_material += self.KNIGHT_TABLE[square_index]
            elif self.b_w_pawn & (1 << square_index):
                white_material += self.WHITE_PAWN_TABLE[square_index]
            elif self.b_b_knight & (1 << square_index):
                black_material += self.KNIGHT_TABLE[square_index]
            elif self.b_b_pawn & (1 << square_index):
                black_material += self.BLACK_PAWN_TABLE[square_index]
        print(white_material - black_material)
        print("2", white_material - black_material + self.get_king_into_corner(
            board) + self.get_king_into_center() + self.mobility_bonus())
        return white_material - black_material + self.get_king_into_corner(
            board) + self.get_king_into_center() + self.mobility_bonus()

    def update_bitboards(self, board=None):
        if board is None:
            board = self.chess_board
        self.b_w_knight = int(board.pieces(chess.KNIGHT, chess.WHITE))
        self.b_w_king = int(board.pieces(chess.KING, chess.WHITE))
        self.b_w_bishop = int(board.pieces(chess.BISHOP, chess.WHITE))
        self.b_w_queen = int(board.pieces(chess.QUEEN, chess.WHITE))
        self.b_w_rook = int(board.pieces(chess.ROOK, chess.WHITE))
        self.b_w_pawn = int(board.pieces(chess.PAWN, chess.WHITE))
        self.b_b_bishop = int(board.pieces(chess.BISHOP, chess.BLACK))
        self.b_b_queen = int(board.pieces(chess.QUEEN, chess.BLACK))
        self.b_b_rook = int(board.pieces(chess.ROOK, chess.BLACK))
        self.b_b_knight = int(board.pieces(chess.KNIGHT, chess.BLACK))
        self.b_b_king = int(board.pieces(chess.KING, chess.BLACK))
        self.b_b_pawn = int(board.pieces(chess.PAWN, chess.BLACK))

    def minimax(self, board, depth, maximizing_player, alpha=float("-inf"),
                beta=float("inf")):
        best_move = None
        if depth == 0 or board.is_game_over():
            self.update_bitboards(board)
            evaluation = self.eval(board)
            return evaluation, best_move

        zobrist_key = self.calculate_zobrist(board)
        if int(zobrist_key) in self.zobrist_keys:
            print("Transposition detected")
            return self.zobrist_keys[zobrist_key]

        moves = list(board.legal_moves)
        moves.sort(key=lambda move: not board.is_capture(move))

        if maximizing_player:
            max_eval = float("-inf")
            for move in moves:
                new_board = board.copy()
                new_board.push(move)
                self.update_bitboards(new_board)
                evaluation, _ = self.minimax(new_board, depth - 1, False, alpha, beta)
                if new_board.is_check():
                    evaluation += 0.2
                if evaluation > max_eval:
                    max_eval = evaluation
                    best_move = move
                zobrist_key = self.calculate_zobrist(new_board)
                alpha = max(alpha, evaluation)
                if beta <= alpha:
                    break  # Beta cutoff
            self.zobrist_keys[zobrist_key] = (max_eval, str(best_move))
            return max_eval, best_move
        else:
            minEval = float("inf")
            for move in moves:  # Generate all possible moves for MIN
                new_board = board.copy()
                new_board.push(move)
                self.update_bitboards(new_board)
                evaluation, _ = self.minimax(new_board, depth - 1, True, alpha, beta)
                if new_board.is_check():
                    evaluation -= 0.2
                if evaluation < minEval:
                    minEval = evaluation
                    best_move = move
                beta = min(beta, evaluation)
                if beta <= alpha:
                    break  # Alpha cutoff
            print(best_move)
            return minEval, best_move

    def show_board(self):
        svg = chess.svg.board(
            self.chess_board
        )
        with open('chessboard.svg', 'w') as f:
            f.write(svg)

    def start(self):
        self.initialise_zobrist()
        self.zobrist_keys[0] = self.calculate_zobrist(self.chess_board)
        while True:
            evaluation, best_move = self.minimax(self.chess_board, 3, True)
            print(evaluation, best_move)
            if evaluation == 1000:
                print("White got checkmated!")
                break
            elif evaluation == -1000:
                print("Black got checkmated")
                break
            self.chess_board.push(best_move)
            print(self.calculate_zobrist(self.chess_board))
            self.show_board()
            current_move = input(
                "Give me the move you want to make (Example: Nc6")
            self.chess_board.push_san(current_move)


game = Game()
