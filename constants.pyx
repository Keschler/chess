cdef float[64] KNIGHT_TABLE = [
    -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.3, 0, 0.1, 0.15, 0.15, 0.1, 0, -0.3,
    -0.3, 0.05, 0.15, 0.2, 0.2, 0.15, 0.05, -0.3,
    -0.3, 0, 0.15, 0.2, 0.2, 0.15, 0, -0.3,
    -0.3, 0.05, 0.1, 0.15, 0.15, 0.1, 0.05, -0.3,
    -0.4, -0.2, 0, 0.05, 0.05, 0, -0.2, -0.4,
    -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
]

cdef float[64] WHITE_PAWN_TABLE = [
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2,
    0.3, 0.3, 0.3, 0.6, 0.6, 0.3, 0.3, 0.3,
    0.4, 0.4, 0.4, 0.5, 0.5, 0.4, 0.4, 0.4,
    1, 0.8, 0.6, 0.6, 0.6, 0.6, 0.8, 1,
    2, 1.5, 1.2, 1, 1, 1.2, 1.5, 2,
    9, 9, 9, 9, 9, 9, 9, 9,
]

cdef float[64] BLACK_PAWN_TABLE
for i in range(64):
    BLACK_PAWN_TABLE[i] = WHITE_PAWN_TABLE[63 - i]

cdef float[64] KING_ENDGAME_CHECKMATE_TABLE = [
    2, 2, 2, 2, 2, 2, 2, 2,
    2, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2,
    2, 2, 2, 2, 2, 2, 2, 2,
]

cdef float[64] KING_ENDGAME_TABLE = [
    -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
    -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
    -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
    -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
]

cdef float[7] PASSED_PAWN_BONUSES = [0, 1.5, 1, 0.5, 0.3, 0.2, 0.1]

cdef float[64] BLACK_KING_SAFETY_TABLE = [
    -8, -8, -8, -8, -8, -8, -8, -8,
    -7, -7, -7, -7, -7, -7, -7, -7,
    -6, -6, -6, -6, -6, -6, -6, -6,
    -5, -5, -5, -5, -5, -5, -5, -5,
    -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -1, -1, -1, -1, -1, -1, -1,
    0.3, 0.3, -0.1, -0.5, -0.3, -0.1, 0.3, 0.3,
    0.6, 0.5, 0.2, 0, 0, 0.2, 0.5, 0.6,
]

cdef float[64] WHITE_KING_SAFETY_TABLE
for i in range(64):
    WHITE_KING_SAFETY_TABLE[i] = BLACK_KING_SAFETY_TABLE[63 - i]



cpdef float[:] get_knight_table():
    return KNIGHT_TABLE

cpdef float[:] get_white_pawn_table():
    return WHITE_PAWN_TABLE

cpdef float[:] get_black_pawn_table():
    return BLACK_PAWN_TABLE

cpdef float[:] get_king_endgame_checkmate_table():
    return KING_ENDGAME_CHECKMATE_TABLE

cpdef float[:] get_king_endgame_table():
    return KING_ENDGAME_TABLE

cpdef float[:] get_passed_pawn_bonuses():
    return PASSED_PAWN_BONUSES

cpdef tuple get_king_safety_table():
    return WHITE_KING_SAFETY_TABLE, BLACK_KING_SAFETY_TABLE
