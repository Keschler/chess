import chess

from constants import (
    get_knight_table, get_white_pawn_table, get_king_endgame_table,
    get_black_pawn_table, get_king_endgame_checkmate_table,
    get_passed_pawn_bonuses, get_king_safety_table
)
from libc.stdint cimport uint64_t

ctypedef unsigned long ulong

cdef class Eval:
    cdef:
        object board
        tuple bitboard_tables
        list KNIGHT_TABLE, WHITE_PAWN_TABLE, KING_ENDGAME_CHECKMATE_TABLE, KING_ENDGAME_TABLE, BLACK_PAWN_TABLE, passes_pawn_bonuses, WHITE_KING_SAFETY_TABLE, BLACK_KING_SAFETY_TABLE
        uint64_t b_w_knight, b_w_king, b_w_bishop, b_w_queen, b_w_rook, b_w_pawn, b_b_bishop, b_b_queen, b_b_rook, b_b_knight, b_b_king, b_b_pawn


    def __init__(self, bitboard_tables, board=None):
        self.board = board
        (
            self.b_w_knight, self.b_w_king, self.b_w_bishop,
            self.b_w_queen, self.b_w_rook, self.b_w_pawn,
            self.b_b_bishop, self.b_b_queen, self.b_b_rook,
            self.b_b_knight, self.b_b_king, self.b_b_pawn
        ) = bitboard_tables

        self.KNIGHT_TABLE = get_knight_table()
        self.WHITE_PAWN_TABLE = get_white_pawn_table()
        self.KING_ENDGAME_CHECKMATE_TABLE = get_king_endgame_checkmate_table()
        self.KING_ENDGAME_TABLE = get_king_endgame_table()
        self.BLACK_PAWN_TABLE = get_black_pawn_table()
        self.passes_pawn_bonuses = get_passed_pawn_bonuses()
        self.WHITE_KING_SAFETY_TABLE, self.BLACK_KING_SAFETY_TABLE = get_king_safety_table()

    cdef bint only_pawns_and_kings_left(self):
        pieces = [
            self.b_b_queen, self.b_b_knight, self.b_b_bishop, self.b_b_rook,
            self.b_w_bishop, self.b_w_knight, self.b_w_rook, self.b_w_queen
        ]
        return all(piece == chess.BB_EMPTY for piece in pieces)  # True: only pawns and kings left

    cdef int distance_between_kings(self):
        cdef int white_king_square = next(chess.scan_forward(self.b_w_king))
        cdef int black_king_square = next(chess.scan_forward(self.b_b_king))
        white_king_file, black_king_file = chess.square_file(white_king_square), chess.square_file(black_king_square)
        white_king_rank, black_king_rank = chess.square_rank(white_king_square), chess.square_rank(black_king_square)
        cdef int file_dst = abs(white_king_file - black_king_file)
        cdef int rank_dst = abs(white_king_rank - black_king_rank)
        cdef int dst_between_kings = file_dst + rank_dst
        return dst_between_kings

    cdef float force_king_into_corner(self, pre_score):
        cdef int evaluation = 0
        cdef float multiplication = ((32 - chess.popcount(self.board.occupied)) / 100) / 2
        if self.only_pawns_and_kings_left() or -2 <= pre_score <= 2:
            multiplication = 0
        for square_index in range(64):
            if self.b_b_king & (1 << square_index):
                evaluation += self.KING_ENDGAME_CHECKMATE_TABLE[square_index]
        cdef int dst_between_kings = self.distance_between_kings()
        evaluation += 14 - dst_between_kings
        return evaluation * multiplication

    cdef float get_king_into_center(self):
        cdef int bonus = 0
        if self.only_pawns_and_kings_left():
            for square_index in range(64):
                if self.b_b_king & (1 << square_index):
                    bonus -= self.KING_ENDGAME_TABLE[square_index]
                elif self.b_w_king & (1 << square_index):
                    bonus += self.KING_ENDGAME_TABLE[square_index]
        return bonus

    cdef float king_safety(self):
        cdef int bonus = 0
        cdef float multiplication = (chess.popcount(self.board.occupied) / 32)
        for square_index in range(64):
            if self.b_w_king & (1 << square_index):
                bonus += self.WHITE_KING_SAFETY_TABLE[square_index]
            elif self.b_b_king & (1 << square_index):
                bonus += self.BLACK_KING_SAFETY_TABLE[square_index]
        return bonus

    cdef float rook_mobility_bonus(self, rooks):
        cdef float bonus = 0
        cdef int direction
        cdef int distance
        cdef int target_square
        if not rooks:
            return 0
        for rook in rooks:
            for direction in [-8, -1, 8, 1]:
                for distance in range(1, 8):
                    target_square = rook + (direction * distance)
                    if (0 <= target_square < 64 and self.board.piece_at(target_square) is None) and (
                            chess.square_rank(target_square) == rook or chess.square_file(
                        target_square) == rook):  #Check if `target_square` is within the valid range (0-63), is empty, and is either in the same rank or file as the `rook`.
                        bonus += 0.2
        return bonus

    cdef float bishop_mobility_bonus(self, bishops):
        cdef float bonus = 0
        cdef int direction
        cdef int distance
        cdef int target_square
        if not bishops:
            return 0
        for bishop in bishops:
            for direction in [-9, -7, 7, 9]:
                for distance in range(1, 8):
                    target_square = bishop + (direction * distance)
                    if 0 <= target_square < 64 and self.board.piece_at(target_square) is None:
                        bonus += 0.2
        return bonus

    cdef float mobility_bonus(self):
        cdef float bonus = 0
        cdef list black_bishops = []
        cdef list white_bishops = []
        cdef list black_rooks = []
        cdef list white_rooks = []
        for square_index in range(64):
            if self.b_b_bishop & (1 << square_index):
                black_bishops.append(square_index)
            elif self.b_w_bishop & (1 << square_index):
                white_bishops.append(square_index)
            elif self.b_b_rook & (1 << square_index):
                black_rooks.append(square_index)
            elif self.b_w_rook & (1 << square_index):
                white_rooks.append(square_index)
        bonus += self.bishop_mobility_bonus(white_bishops) - self.bishop_mobility_bonus(black_bishops)
        bonus += self.rook_mobility_bonus(white_rooks) - self.rook_mobility_bonus(black_rooks)
        return bonus

    cdef tuple passed_pawn_mask(self):
        cdef list passed_pawns_white = []
        cdef list passed_pawns_black = []
        cdef list passed_pawns_masks_white = []
        cdef list passed_pawns_masks_black = []
        cdef ulong file_A = 0x0101010101010101
        cdef int rank_index
        cdef ulong file_mask
        cdef ulong file_mask_left
        cdef ulong file_mask_right
        cdef ulong file_triple_mask
        cdef ulong passed_pawn_mask
        for square_index in range(64):
            if self.b_w_pawn & (1 << square_index):
                passed_pawns_white.append(square_index)
                file_index = chess.square_file(square_index)
                file_mask = file_A << file_index
                file_mask_left = file_A << max(0, file_index - 1)
                file_mask_right = file_A << min(7, file_index + 1)
                triple_file_mask = file_mask | file_mask_left | file_mask_right

                rank_index = chess.square_rank(square_index)
                forward_mask = 0xFFFFFFFFFFFFFFFF << 8 * (rank_index + 1)

                passed_pawn_mask = forward_mask & triple_file_mask
                passed_pawns_masks_white.append(passed_pawn_mask)
            elif self.b_b_pawn & (1 << square_index):
                passed_pawns_black.append(square_index)
                file_index = chess.square_file(square_index)
                file_mask = file_A << file_index
                file_mask_left = file_A << max(0, file_index - 1)
                file_mask_right = file_A << min(7, file_index + 1)
                triple_file_mask = file_mask | file_mask_left | file_mask_right  # Get the files next to the pawn and the file the pawn is on

                rank_index = chess.square_rank(square_index)
                forward_mask = 0xFFFFFFFFFFFFFFFF << 8 * (7 - rank_index)

                passed_pawn_mask = forward_mask & triple_file_mask  # Get all the squares in front, 1 left and 1 right of the pawn
                passed_pawns_masks_black.append(passed_pawn_mask)
        return passed_pawns_masks_white, passed_pawns_masks_black, passed_pawns_black, passed_pawns_white

    cdef float passed_pawns(self):
        cdef float bonus = 0
        passed_pawns_masks_white, passed_pawns_masks_black, passed_pawns_black, passed_pawns_white = self.passed_pawn_mask()
        for i in range(len(passed_pawns_white)):
            if (self.b_b_pawn & passed_pawns_masks_white[i]) == 0:  # If it's a passed pawn
                rank = chess.square_rank(passed_pawns_white[i])
                num_squares_from_promotion = 7 - rank
                bonus += self.passes_pawn_bonuses[num_squares_from_promotion]
        for k in range(len(passed_pawns_black)):
            if (self.b_w_pawn & passed_pawns_masks_black[k]) == 0:  # If it's a passed pawn
                rank = chess.square_rank(passed_pawns_black[k])
                num_squares_from_promotion = rank
                bonus -= self.passes_pawn_bonuses[num_squares_from_promotion]
        return bonus

    cpdef float eval(self, depth, original_depth):
        # Checkmate and draw conditions
        if self.board.is_checkmate():
            if self.board.turn == chess.BLACK:  # If white checkmates
                return 1000 - abs((depth - original_depth))
            else:
                return -1000 + abs((depth - original_depth))
        if (self.board.can_claim_threefold_repetition() or self.board.is_repetition() or self.board.is_variant_draw()
                or self.board.is_stalemate()):
            return 0

        # Define piece values
        cdef int pawn_value = 1
        cdef float knight_value = 3.1
        cdef float bishop_value = 3.3
        cdef int rook_value = 5
        cdef int queen_value = 9

        # Calculate material balance
        cdef float white_material = (
                pawn_value * chess.popcount(self.b_w_pawn) +
                knight_value * chess.popcount(self.b_w_knight) +
                bishop_value * chess.popcount(self.b_w_bishop) +
                rook_value * chess.popcount(self.b_w_rook) +
                queen_value * chess.popcount(self.b_w_queen)
        )
        cdef float black_material = (
                pawn_value * chess.popcount(self.b_b_pawn) +
                knight_value * chess.popcount(self.b_b_knight) +
                bishop_value * chess.popcount(self.b_b_bishop) +
                rook_value * chess.popcount(self.b_b_rook) +
                queen_value * chess.popcount(self.b_b_queen)
        )

        # Positional evaluation using piece-square tables
        for square_index in range(64):
            if self.b_w_knight & (1 << square_index):
                white_material += self.KNIGHT_TABLE[square_index]
            if self.b_w_pawn & (1 << square_index):
                white_material += self.WHITE_PAWN_TABLE[square_index]
            if self.b_b_knight & (1 << square_index):
                black_material += self.KNIGHT_TABLE[square_index]
            if self.b_b_pawn & (1 << square_index):
                black_material += self.BLACK_PAWN_TABLE[square_index]

        # Additional bonuses
        white_material += self.get_king_into_center()
        black_material += self.get_king_into_center()
        cdef float king_corner_bonus = self.force_king_into_corner(white_material - black_material)
        cdef float mobility_bonus = self.mobility_bonus()
        cdef float passed_pawns_bonus = self.passed_pawns()
        cdef float king_safety = self.king_safety()

        # Final evaluation score
        cdef float total_score = white_material - black_material + king_corner_bonus + mobility_bonus + passed_pawns_bonus
        #print("Total score", total_score, "Pre score", white_material - black_material, self.board.fen(), mobility_bonus, king_corner_bonus, passed_pawns_bonus)
        return total_score
