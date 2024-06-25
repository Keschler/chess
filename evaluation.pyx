import chess

from constants import KNIGHT_TABLE, WHITE_PAWN_TABLE, BLACK_PAWN_TABLE, KING_ENDGAME_CHECKMATE_TABLE, KING_ENDGAME_TABLE


class Eval:
    def __init__(self, bitboard_tables, board=None):
        self.board = board
        self.b_w_knight, self.b_w_king, self.b_w_bishop, self.b_w_queen, self.b_w_rook, self.b_w_pawn, self.b_b_bishop, self.b_b_queen, self.b_b_rook, self.b_b_knight, self.b_b_king, self.b_b_pawn = bitboard_tables

    def only_pawns_and_kings_left(self):
        pieces = [self.b_b_queen, self.b_b_knight, self.b_b_bishop, self.b_b_rook, self.b_w_bishop, self.b_w_knight,
                  self.b_w_rook, self.b_w_queen]
        return all(piece == chess.BB_EMPTY for piece in pieces)

    def distance_between_kings(self):
        cdef int white_king_square = next(chess.scan_forward(self.b_w_king))
        cdef int black_king_square = next(chess.scan_forward(self.b_b_king))
        white_king_file, black_king_file = chess.square_file(white_king_square), chess.square_file(black_king_square)
        white_king_rank, black_king_rank = chess.square_rank(white_king_square), chess.square_rank(black_king_square)
        cdef int file_dst = abs(white_king_file - black_king_file)
        cdef int rank_dst = abs(white_king_rank - black_king_rank)
        cdef int dst_between_kings = file_dst + rank_dst
        return dst_between_kings

    def force_king_into_corner(self, board):  # Incentivize forcing the enemy king into corner and using his own king
        cdef int evaluation = 0
        cdef float multiplicator = (32 - chess.popcount(board.occupied)) / 100 * 2
        if self.only_pawns_and_kings_left():
             multiplicator = 0
        for square_index in range(64):
            if self.b_b_king & (1 << square_index):
                evaluation += KING_ENDGAME_CHECKMATE_TABLE[square_index]
        cdef int dst_between_kings = self.distance_between_kings()
        evaluation += 14 - dst_between_kings
        return evaluation * multiplicator

    def get_king_into_center(self):
        cdef int bonus_white = 0
        cdef int bonus_black = 0
        if self.only_pawns_and_kings_left():
            for square_index in range(64):
                if self.b_b_king & (1 << square_index):
                    bonus_black += KING_ENDGAME_TABLE[square_index]
                elif self.b_w_king & (1 << square_index):
                    bonus_white += KING_ENDGAME_TABLE[square_index]
        return bonus_white - bonus_black

    def mobility_bonus(self):
        cdef float black_bonus = 0
        cdef float white_bonus = 0
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
                        if 0 <= target_square < 64 and self.board.piece_at(target_square) is None:
                            black_bonus += 0.2
            for white_bishop in white_bishops:
                for direction in [-9, -7, 7, 9]:
                    for distance in range(1, 8):
                        target_square = white_bishop + (direction * distance)
                        if 0 <= target_square < 64 and self.board.piece_at(target_square) is None:
                            white_bonus += 0.2
        return white_bonus - black_bonus


    def eval(self):
        # Checkmate and draw conditions
        if self.board.is_checkmate():
            if self.board.turn == chess.BLACK:
                return 1000
            else:
                return -1000
        if (self.board.can_claim_threefold_repetition() or self.board.is_repetition() or self.board.is_variant_draw()
                or self.board.is_stalemate()):
            print("draw", self.board)
            return 0

        # Define piece values
        cdef int pawn_value = 1
        cdef int knight_value = 3
        cdef int bishop_value = 3
        cdef int rook_value = 5
        cdef int queen_value = 9

        # Calculate material balance
        cdef int white_material = (
                pawn_value * chess.popcount(self.b_w_pawn) +
                knight_value * chess.popcount(self.b_w_knight) +
                bishop_value * chess.popcount(self.b_w_bishop) +
                rook_value * chess.popcount(self.b_w_rook) +
                queen_value * chess.popcount(self.b_w_queen)
        )
        cdef int black_material = (
                pawn_value * chess.popcount(self.b_b_pawn) +
                knight_value * chess.popcount(self.b_b_knight) +
                bishop_value * chess.popcount(self.b_b_bishop) +
                rook_value * chess.popcount(self.b_b_rook) +
                queen_value * chess.popcount(self.b_b_queen)
        )

        # Positional evaluation using piece-square tables
        for square_index in range(64):
            if self.b_w_knight & (1 << square_index):
                white_material += KNIGHT_TABLE[square_index]
            if self.b_w_pawn & (1 << square_index):
                white_material += WHITE_PAWN_TABLE[square_index]
            if self.b_b_knight & (1 << square_index):
                black_material += KNIGHT_TABLE[square_index]
            if self.b_b_pawn & (1 << square_index):
                black_material += BLACK_PAWN_TABLE[square_index]

        # Additional bonuses
        white_material += self.get_king_into_center()
        black_material += self.get_king_into_center()
        cdef float king_corner_bonus = self.force_king_into_corner(self.board)
        cdef float mobility_bonus = self.mobility_bonus()
        # Final evaluation score
        cdef float total_score = white_material - black_material + king_corner_bonus + mobility_bonus
        print("Total score", total_score, "Pre score", white_material - black_material, self.board.fen())
        return total_score
