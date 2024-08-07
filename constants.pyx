cdef list KNIGHT_TABLE = [
    -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.3, 0, 0.1, 0.15, 0.15, 0.1, 0, -0.3,
    -0.3, 0.05, 0.15, 0.2, 0.2, 0.15, 0.05, -0.3,
    -0.3, 0, 0.15, 0.2, 0.2, 0.15, 0, -0.3,
    -0.3, 0.05, 0.1, 0.15, 0.15, 0.1, 0.05, -0.3,
    -0.4, -0.2, 0, 0.05, 0.05, 0, -0.2, -0.4,
    -0.5, -0.4, -0.3, -0.3, -0.3, -0.3, -0.4, -0.5,
]
cdef list WHITE_PAWN_TABLE = [
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2,
    0.3, 0.3, 0.3, 0.6, 0.6, 0.3, 0.3, 0.3,
    0.4, 0.4, 0.4, 0.5, 0.5, 0.4, 0.4, 0.4,
    1, 0.8, 0.6, 0.6, 0.6, 0.6, 0.8, 1,
    2, 1.5, 1.2, 1, 1, 1.2, 1.5, 2,
    9, 9, 9, 9, 9, 9, 9, 9,
]
cdef list KING_ENDGAME_CHECKMATE_TABLE = [
    2, 2, 2, 2, 2, 2, 2, 2,
    2, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, -1, -1, -1, -1, 0.5, 2,
    2, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2,
    2, 2, 2, 2, 2, 2, 2, 2
]

cdef list KING_ENDGAME_TABLE = [
    -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
    -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
    -0.2, 0, 0.3, 0.4, 0.4, 0.3, 0, -0.2,
    -0.3, 0, 0.2, 0.3, 0.3, 0.2, 0, -0.3,
    -0.4, -0.2, 0, 0, 0, 0, -0.2, -0.4,
    -0.5, -0.4, -0.3, -0.2, -0.2, -0.3, -0.4, -0.5,
]
cdef list BLACK_PAWN_TABLE = list(reversed(WHITE_PAWN_TABLE))

cdef list PASSED_PAWN_BONUSES = [0, 1.5, 1, 0.5, 0.3, 0.2, 0.1]

cdef list BLACK_KING_SAFETY_TABLE = [
    -8, -8, -8, -8, -8, -8, -8, -8,
    -7, -7, -7, -7, -7, -7, -7, -7,
    -6, -6, -6, -6, -6, -6, -6, -6,
    -5, -5, -5, -5, -5, -5, -5, -5,
    -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -1, -1, -1, -1, -1, -1, -1,
    0.3, 0.3, -0.1, -0.5, -0.3, -0.1, 0.3, 0.3,
    0.6, 0.5, 0.2, 0, 0, 0.2, 0.5, 0.6,
]
cdef list WHITE_KING_SAFETY_TABLE = list(reversed(BLACK_KING_SAFETY_TABLE))
cpdef tuple get_king_safety_table():
    return WHITE_KING_SAFETY_TABLE, BLACK_KING_SAFETY_TABLE

cpdef list get_passed_pawn_bonuses():
    return PASSED_PAWN_BONUSES

cpdef list get_knight_table():
    return KNIGHT_TABLE

cpdef list get_white_pawn_table():
    return WHITE_PAWN_TABLE

cpdef list get_black_pawn_table():
    return BLACK_PAWN_TABLE

cpdef list get_king_endgame_checkmate_table():
    return KING_ENDGAME_CHECKMATE_TABLE

cpdef list get_king_endgame_table():
    return KING_ENDGAME_TABLE
