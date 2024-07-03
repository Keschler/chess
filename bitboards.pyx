import chess
from libc.stdint cimport uint64_t

cdef class Bitboards:
    cdef public uint64_t b_w_knight, b_w_king, b_w_bishop, b_w_queen, b_w_rook, b_w_pawn
    cdef public uint64_t b_b_bishop, b_b_queen, b_b_rook, b_b_knight, b_b_king, b_b_pawn

    def __init__(self):
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

    cpdef void update_bitboards(self, board):
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

    cpdef tuple return_tables(self):
        return (self.b_w_knight, self.b_w_king, self.b_w_bishop, self.b_w_queen, self.b_w_rook, self.b_w_pawn,
                self.b_b_bishop, self.b_b_queen, self.b_b_rook, self.b_b_knight, self.b_b_king, self.b_b_pawn)