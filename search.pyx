import random

import chess

from bitboards import Bitboards
from evaluation import Eval
from libc.stdint cimport uint64_t


cdef class Search:
    cdef:
        object bitboard
        uint64_t zobrist_black_to_move
        dict zobrist_piece_keys
        list zobrist_castling_rights
        list zobrist_en_passant_file
        dict zobrist_keys
    def __init__(self):  # For transposition tables
        self.bitboard = Bitboards()
        random.seed(42)
        self.zobrist_piece_keys = {(piece_color, piece_index, square_index): random.getrandbits(64)
                                   for piece_color in [True, False]
                                   for piece_index in range(1, 7)  # From 1 to 6 for piece types (excluding empty)
                                   for square_index in range(64)}
        self.zobrist_black_to_move = random.getrandbits(64)
        self.zobrist_castling_rights = [random.getrandbits(64) for _ in range(16)]
        self.zobrist_en_passant_file = [random.getrandbits(64) for _ in range(8)]
        self.zobrist_keys = {}

    cdef uint64_t calculate_zobrist(self, board):
        cdef uint64_t zobrist_key = 0
        cdef int ep_rank
        cdef bint piece_color
        cdef int piece_type
        for square_index in range(64):
            piece = board.piece_at(square_index)
            if piece is not None:  # If the square is not empty
                piece_type = piece.piece_type
                piece_color = piece.color  # Black: False, White: True
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
    cdef list sort_by_capture(self, moves, board):
        sorted_moves = moves
        for count, move in enumerate(moves):
            if board.is_capture(move):
                sorted_moves.insert(0, sorted_moves.pop(count))
        return sorted_moves
    cdef list sort_by_check(self, moves, board):
        sorted_moves = moves
        for count, move in enumerate(moves):
            if board.gives_check(move):
                sorted_moves.insert(0, sorted_moves.pop(count))
        return sorted_moves
    cpdef minimax(self, object board, int depth, float alpha=float("-inf"), float beta=float("inf"), bint maximizing_player=True,
                int original_depth=-100, move=None):
        cdef float evaluation
        best_move = None
        if original_depth == -100:
            original_depth = depth
        cdef uint64_t zobrist_key = self.calculate_zobrist(board)
        if zobrist_key in self.zobrist_keys:  # If there is a transposition
            stored_eval, stored_depth, flag = self.zobrist_keys[zobrist_key]
            if stored_depth >= depth:
                if flag == 'exact':
                    return stored_eval, best_move
                elif flag == 'lowerbound' and stored_eval > alpha:
                    alpha = stored_eval
                elif flag == 'upperbound' and stored_eval < beta:
                    beta = stored_eval
                if alpha >= beta:
                    return stored_eval, best_move

        if depth == 0 or board.is_game_over():
            self.bitboard.update_bitboards(board)
            bitboard_tables = self.bitboard.return_tables()
            curr_eval = Eval(bitboard_tables, board)
            evaluation = curr_eval.eval(depth, original_depth)
            self.zobrist_keys[zobrist_key] = (evaluation, depth, 'exact')
            return evaluation, best_move
        if move is not None:
            moves = [move]
        else:
            moves = list(board.legal_moves)
            moves = self.sort_by_capture(moves, board)
            moves = self.sort_by_check(moves, board)
        if maximizing_player:
            max_eval = float("-inf")
            for move in moves:
                new_board = board.copy()
                new_board.push(move)
                self.bitboard.update_bitboards(new_board)
                evaluation, _ = self.minimax(new_board, depth - 1, alpha, beta, False, original_depth)
                if new_board.is_check():
                    evaluation += 0.1
                if evaluation > max_eval:
                    max_eval = evaluation
                    best_move = move
                alpha = max(alpha, evaluation)
                if beta <= alpha:
                    break
            flag = 'exact' if max_eval > alpha else 'lowerbound'
            self.zobrist_keys[zobrist_key] = (max_eval, depth, flag)
            return max_eval, best_move
        else:
            min_eval = float("inf")
            for move in moves:
                new_board = board.copy()
                new_board.push(move)
                self.bitboard.update_bitboards(new_board)
                evaluation, _ = self.minimax(new_board, depth - 1, alpha, beta, True, original_depth)
                if new_board.is_check():
                    evaluation -= 0.1
                if evaluation < min_eval:
                    min_eval = evaluation
                    best_move = move
                beta = min(beta, evaluation)
                if beta <= alpha:
                    break
            flag = 'exact' if min_eval < beta else 'upperbound'
            self.zobrist_keys[zobrist_key] = (min_eval, depth, flag)
            return min_eval, best_move

