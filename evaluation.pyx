import chess
from libc.stdint cimport uint64_t

from constants import (
    get_knight_table, get_white_pawn_table, get_king_endgame_table,
    get_black_pawn_table, get_king_endgame_checkmate_table,
    get_passed_pawn_bonuses, get_king_safety_table
)

ctypedef unsigned long ulong

cdef class Eval:
    cdef:
        object board
        tuple bitboard_tables
        list WHITE_KING_SAFETY_TABLE, BLACK_KING_SAFETY_TABLE
        float[64] KNIGHT_TABLE, WHITE_PAWN_TABLE, KING_ENDGAME_CHECKMATE_TABLE, KING_ENDGAME_TABLE, BLACK_PAWN_TABLE
        float[7] passed_pawn_bonuses
        uint64_t b_w_knight, b_w_king, b_w_bishop, b_w_queen, b_w_rook, b_w_pawn, b_b_bishop, b_b_queen, b_b_rook, b_b_knight, b_b_king, b_b_pawn, \
            file_index, file_mask_left, file_mask_right, triple_file_mask, adjacent_file_mask

    def __init__(self, tuple bitboard_tables, object board=None):
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
        self.passed_pawn_bonuses = get_passed_pawn_bonuses()
        self.WHITE_KING_SAFETY_TABLE, self.BLACK_KING_SAFETY_TABLE = get_king_safety_table()
    cpdef print_bitboard(self, bitboard):
        print("\n")
        # Iterate from rank 8 to rank 1 (top to bottom of the chessboard)
        for rank in range(7, -1, -1):
            row = ""
            for file in range(8):
                # Calculate the bit position: rank * 8 + file gives the correct bit index
                square = rank * 8 + file
                # Check if the bit at `square` is set in `bitboard`
                if (bitboard >> square) & 1:
                    row += "1 "
                else:
                    row += ". "  # Use '.' for empty squares for better readability
            print(row)
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

    cdef float force_king_into_corner(self, float pre_score):
        cdef float evaluation = 0
        cdef float bonus = 0
        cdef float multiplication = ((32 - chess.popcount(self.board.occupied)) / 100) / 2
        cdef bint only_pawns_and_kings_left = False
        if self.only_pawns_and_kings_left() or -2 <= pre_score <= 2:
            multiplication = 0
        if self.only_pawns_and_kings_left():
            only_pawns_and_kings_left = True
        for square_index in range(64):
            if self.b_b_king & (1 << square_index):
                evaluation += self.KING_ENDGAME_CHECKMATE_TABLE[square_index]
                if only_pawns_and_kings_left:
                    bonus -= self.KING_ENDGAME_TABLE[square_index]
            elif self.b_w_king & (1 << square_index) and only_pawns_and_kings_left:
                bonus += self.KING_ENDGAME_TABLE[square_index]
        cdef int dst_between_kings = self.distance_between_kings()
        evaluation += 14 - dst_between_kings
        return (evaluation * multiplication) + bonus

    cdef float king_safety(self):
        cdef float bonus = 0
        cdef float multiplication = (chess.popcount(self.board.occupied) / 32)
        cdef int black_king_pos = 0
        cdef int white_king_pos = 0
        for square_index in range(64):
            if self.b_w_king & (1 << square_index):
                white_king_pos = square_index
                bonus += self.WHITE_KING_SAFETY_TABLE[square_index]
            elif self.b_b_king & (1 << square_index):
                black_king_pos = square_index
                bonus -= self.BLACK_KING_SAFETY_TABLE[square_index]
        king_attack_score = self.king_attack_zone(white_king_pos, black_king_pos)
        return bonus * multiplication + king_attack_score

    cdef float king_attack_zone(self, white_king_pos, black_king_pos):
        cdef int value_of_attacks = 0
        cdef uint64_t white_king_attack_zone
        cdef uint64_t black_king_attack_zone
        white_king_attack_zone = self.king_attack_zone_bitboard(self.b_w_king, white_king_pos)
        black_king_attack_zone = self.king_attack_zone_bitboard(self.b_b_king, black_king_pos)
        cdef list[int] white_king_attack_zone_sq = []
        cdef list[int] black_king_attack_zone_sq = []
        for square_index in range(64):
            if (white_king_attack_zone >> square_index) & 1:
                white_king_attack_zone_sq.append(square_index)
            elif (black_king_attack_zone >> square_index) & 1:
                black_king_attack_zone_sq.append(square_index)
        king_attack_score_white = self.identify_king_attackers(white_king_attack_zone, white_king_attack_zone_sq,
                                                               chess.WHITE)
        king_attack_score_black = self.identify_king_attackers(black_king_attack_zone, black_king_attack_zone_sq,
                                                               chess.BLACK)
        return king_attack_score_white - king_attack_score_black

    cdef identify_king_attackers(self, king_attack_zone, king_attack_zone_sq, color):
        cdef int value_of_attacks = 0
        cdef int attacking_pieces_count = 0
        cdef float king_attack_score = 0
        cdef int[7] attack_weight = [0, 50, 75, 88, 94, 97, 99]
        cdef set unique_attackers = set()
        cdef dict piece_values = {"q": 80, "r": 40, "b": 20, "n": 20}
        for i in range(bin(king_attack_zone).count("1")):
            attackers = list(self.board.attackers(not color, king_attack_zone_sq[i]))
            for attacker in attackers:
                if attacker not in unique_attackers:
                    unique_attackers.add(attacker)
            for attacking_piece in attackers:
                piece = self.board.piece_at(attacking_piece)
                piece_type = str(piece).lower()
                value_of_attacks += piece_values.get(piece_type, 0)
        attacking_pieces_count += len(unique_attackers)
        attacking_pieces_count = min(attacking_pieces_count, len(attack_weight) - 1)  # To avoid buffer overflow
        king_attack_score = value_of_attacks * attack_weight[attacking_pieces_count] / 10000
        return king_attack_score

    cdef uint64_t king_attack_zone_bitboard(self, uint64_t king, int pos):
        cdef uint64_t attack_zone = king
        cdef uint64_t not_a_file = 0xfefefefefefefefe
        cdef uint64_t not_h_file = 0x7f7f7f7f7f7f7f7f
        file_index = chess.square_file(pos)

        attack_zone |= (king << 7)
        attack_zone |= (king << 8)
        attack_zone |= (king << 9)
        attack_zone |= (king >> 7)
        attack_zone |= (king >> 8)
        attack_zone |= (king >> 9)
        attack_zone |= (king << 1)
        attack_zone |= (king >> 1)
        if file_index == 0:
            attack_zone = attack_zone & not_h_file
        elif file_index == 7:
            attack_zone = attack_zone & not_a_file

        return attack_zone

    cdef float piece_mobility_bonus(self, list[int] pieces, list[int] directions):
        cdef float bonus = 0
        cdef int direction
        cdef int target_square
        cdef bint is_bishop = (directions == [-9, -7, 7, 9])
        if not pieces:
            return 0
        for piece in pieces:
            for direction in directions:
                for distance in range(1, 8):
                    target_square = piece + (direction * distance)
                    if not (0 <= target_square < 64) or self.board.piece_at(
                            target_square) is not None:  # If there is a piece on the square or the target_square is out of bound
                        break
                    if is_bishop:
                        if abs(target_square % 8 - piece % 8) != abs(
                                target_square // 8 - piece // 8):  # If the target_square is not on the same diagonal
                            break
                    else:  # Rook
                        if not (((chess.square_rank(target_square) == chess.square_rank(piece)) or (
                                chess.square_file(target_square) == chess.square_file(
                            piece)))):  # If the target_square is not on the same file/rank as the rook
                            break
                    bonus += 0.1

    cdef float mobility_bonus(self):
        cdef float bonus = 0
        cdef list[int] black_bishops = []
        cdef list[int] white_bishops = []
        cdef list[int] black_rooks = []
        cdef list[int] white_rooks = []
        for square_index in range(64):
            if self.b_b_bishop & (1 << square_index):
                black_bishops.append(square_index)
            elif self.b_w_bishop & (1 << square_index):
                white_bishops.append(square_index)
            elif self.b_b_rook & (1 << square_index):
                black_rooks.append(square_index)
            elif self.b_w_rook & (1 << square_index):
                white_rooks.append(square_index)
        # noinspection PyTypeChecker
        bonus += self.piece_mobility_bonus(white_rooks, [-8, -1, 8, 1]) - self.piece_mobility_bonus(black_rooks,
                                                                                                    [-8, -1, 8, 1])
        # noinspection PyTypeChecker
        bonus += self.piece_mobility_bonus(white_bishops, [-9, -7, 7, 9]) - self.piece_mobility_bonus(black_bishops,
                                                                                                      [-9, -7, 7, 9])
        return bonus
    cdef tuple file_mask(self, int square_index, uint64_t file_a):
        file_index = chess.square_file(square_index)
        file_mask = file_a << file_index
        file_mask_left = file_a << max(0, file_index - 1)
        file_mask_right = file_a << min(7, file_index + 1)
        triple_file_mask = file_mask | file_mask_left | file_mask_right
        adjacent_file_mask = file_mask_left | file_mask_right
        return file_mask, triple_file_mask, adjacent_file_mask
    cdef tuple passed_pawn_mask(self):
        cdef list[int] passed_pawns_white = []
        cdef list[int] passed_pawns_black = []
        cdef list[uint64_t] passed_pawns_masks_white = []
        cdef list[uint64_t] passed_pawns_masks_black = []
        cdef list[uint64_t] isolated_pawns_white = []
        cdef list[uint64_t] isolated_pawns_black = []
        cdef list[uint64_t] file_masks_white = []
        cdef list[uint64_t] file_masks_black = []

        cdef uint64_t file_a = 0x0101010101010101
        cdef int rank_index
        for square_index in range(64):
            if self.b_w_pawn & (1 << square_index):
                passed_pawns_white.append(square_index)
                file_mask, triple_file_mask, adjacent_file_mask = self.file_mask(square_index, file_a)
                isolated_pawns_white.append(adjacent_file_mask)
                file_masks_white.append(file_mask)

                rank_index = chess.square_rank(square_index)
                forward_mask = 0xFFFFFFFFFFFFFFFF << 8 * (rank_index + 1)

                passed_pawn_mask = forward_mask & triple_file_mask  # Get all the squares in front, 1 left and 1 right of the pawn
                passed_pawns_masks_white.append(passed_pawn_mask)
            elif self.b_b_pawn & (1 << square_index):
                passed_pawns_black.append(square_index)
                file_mask, triple_file_mask, adjacent_file_mask = self.file_mask(square_index, file_a)
                isolated_pawns_black.append(adjacent_file_mask)
                file_masks_black.append(file_mask)

                rank_index = chess.square_rank(square_index)
                forward_mask = 0xFFFFFFFFFFFFFFFF << 8 * (7 - rank_index)

                passed_pawn_mask = forward_mask & triple_file_mask  # Get all the squares in front, 1 left and 1 right of the pawn
                passed_pawns_masks_black.append(passed_pawn_mask)
        return passed_pawns_masks_white, passed_pawns_masks_black, passed_pawns_black, passed_pawns_white, isolated_pawns_black, isolated_pawns_white, file_masks_white, file_masks_black

    cdef float pawns(self):
        cdef float bonus = 0
        cdef int num_isolated_pawns = 0
        cdef int num_doubled_pawns = 0
        cdef int rank
        cdef int num_squares_from_promotion
        (passed_pawns_masks_white, passed_pawns_masks_black, passed_pawns_black,
         passed_pawns_white, isolated_pawns_black, isolated_pawns_white, file_masks_white,
         file_mask_black) = self.passed_pawn_mask()
        for i in range(len(passed_pawns_white)):
            if (self.b_b_pawn & passed_pawns_masks_white[i]) == 0:  # If it's a passed white pawn
                rank = chess.square_rank(passed_pawns_white[i])
                num_squares_from_promotion = 7 - rank
                bonus += self.passed_pawn_bonuses[num_squares_from_promotion]
            if (self.b_w_pawn & isolated_pawns_white[i]) == 0:  # If it's an isolated pawn
                num_isolated_pawns += 1
            pawns_on_file = self.b_w_pawn & file_masks_white[i]
            if bin(pawns_on_file).count('1') > 1:  # If it's a doubled pawn
                num_doubled_pawns += 1
        for k in range(len(passed_pawns_black)):
            if (self.b_w_pawn & passed_pawns_masks_black[k]) == 0:  # If it's a passed black pawn
                rank = chess.square_rank(passed_pawns_black[k])
                num_squares_from_promotion = rank
                bonus -= self.passed_pawn_bonuses[num_squares_from_promotion]
            if (self.b_b_pawn & isolated_pawns_black[k]) == 0:  # If it's an isolated pawn
                num_isolated_pawns -= 1
            pawns_on_file = self.b_w_pawn & file_mask_black[k]
            if bin(pawns_on_file).count('1') > 1:  # If it's a doubled pawn
                num_doubled_pawns -= 1
        bonus = (num_isolated_pawns * 0.3) * -1
        bonus = (num_doubled_pawns * 0.3) * -1
        return bonus
    cdef void positional_bonus(self):
        cdef int bonus = 0
        for square_index in range(64):
            if self.b_w_knight & (1 << square_index):
                bonus += self.KNIGHT_TABLE[square_index]
            if self.b_w_pawn & (1 << square_index):
                bonus += self.WHITE_PAWN_TABLE[square_index]
            if self.b_b_knight & (1 << square_index):
                bonus += self.KNIGHT_TABLE[square_index]
            if self.b_b_pawn & (1 << square_index):
                bonus -= self.BLACK_PAWN_TABLE[square_index]
    cpdef float eval(self, int depth, int original_depth):
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
        cdef int knight_value = 3
        cdef float bishop_value = 3.3
        cdef float rook_value = 4.9
        cdef float queen_value = 9.1

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

        # Additional bonuses
        cdef float positional_bonus = self.positional_bonus()
        cdef float king_corner_bonus = self.force_king_into_corner(white_material - black_material)
        cdef float mobility_bonus = self.mobility_bonus()
        cdef float pawns_bonus = self.pawns()
        cdef float king_safety = self.king_safety()
        # Final evaluation score
        cdef float total_score = white_material - black_material + king_corner_bonus + mobility_bonus + pawns_bonus + king_safety
        #print(
        #    "Total score", total_score, "Pre score", white_material - black_material, self.board.fen(), mobility_bonus,
        #    king_corner_bonus, pawns_bonus, king_safety)
        return total_score
