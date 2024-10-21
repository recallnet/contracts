// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @dev Implementation of the BLAKE2b hashing algorithm.
/// TODO: this is very costly and must be optimized, handled by WASM, or fully offchain.
library Blake2b {
    uint64 constant OUTBYTES = 64;
    uint64 constant BLOCKBYTES = 128;

    struct State {
        uint64[8] h;
        uint64[2] t;
        uint64[2] f;
        bytes32[4] buf; // 128 bytes (BLOCKBYTES) as fixed-size array
        uint64 buflen;
        uint8 outlen;
    }

    function IV() internal pure returns (uint64[8] memory) {
        return [
            0x6A09E667F3BCC908,
            0xBB67AE8584CAA73B,
            0x3C6EF372FE94F82B,
            0xA54FF53A5F1D36F1,
            0x510E527FADE682D1,
            0x9B05688C2B3E6C1F,
            0x1F83D9ABFB41BD6B,
            0x5BE0CD19137E2179
        ];
    }

    function init(uint8 outlen) internal pure returns (State memory) {
        require(outlen > 0 && outlen <= OUTBYTES, "Invalid output length");

        State memory state;
        state.h = IV();
        state.h[0] = state.h[0] ^ (uint64(outlen) | (0 << 8) | (1 << 16) | (1 << 24));
        state.outlen = outlen;
        state.buflen = 0;

        return state;
    }

    function update(State memory state, bytes memory input) internal pure {
        for (uint256 i = 0; i < input.length; i++) {
            if (state.buflen == BLOCKBYTES) {
                unchecked {
                    state.t[0] += BLOCKBYTES;
                    if (state.t[0] < BLOCKBYTES) {
                        state.t[1]++;
                    }
                }
                compress(state, false);
                state.buflen = 0;
            }
            setBufferByte(state, uint8(state.buflen), uint8(input[i]));
            state.buflen++;
        }
    }

    function finalize(State memory state) internal pure returns (bytes memory) {
        unchecked {
            state.t[0] += state.buflen;
            if (state.t[0] < state.buflen) {
                state.t[1]++;
            }
        }

        while (state.buflen < BLOCKBYTES) {
            setBufferByte(state, uint8(state.buflen), 0);
            state.buflen++;
        }

        compress(state, true);

        bytes memory out = new bytes(state.outlen);
        for (uint8 i = 0; i < state.outlen; i++) {
            out[i] = bytes1(uint8(state.h[i >> 3] >> (8 * (i & 7))));
        }

        return out;
    }

    function compress(State memory state, bool last) private pure {
        uint64[16] memory v;
        uint64[16] memory m;

        for (uint256 i = 0; i < 8; i++) {
            v[i] = state.h[i];
            v[i + 8] = IV()[i];
        }

        v[12] ^= state.t[0];
        v[13] ^= state.t[1];

        if (last) {
            v[14] = ~v[14];
        }

        for (uint256 i = 0; i < 16; i++) {
            m[i] = bytesToUint64(state.buf, i * 8);
        }

        uint8[16][12] memory sigma = SIGMA();

        for (uint256 r = 0; r < 12; r++) {
            G(v, m, 0, 4, 8, 12, /* 0, 1, */ r, 0, sigma);
            G(v, m, 1, 5, 9, 13, /* 2, 3, */ r, 1, sigma);
            G(v, m, 2, 6, 10, 14, /* 4, 5, */ r, 2, sigma);
            G(v, m, 3, 7, 11, 15, /* 6, 7, */ r, 3, sigma);
            G(v, m, 0, 5, 10, 15, /* 8, 9, */ r, 4, sigma);
            G(v, m, 1, 6, 11, 12, /* 10, 11, */ r, 5, sigma);
            G(v, m, 2, 7, 8, 13, /* 12, 13, */ r, 6, sigma);
            G(v, m, 3, 4, 9, 14, /* 14, 15, */ r, 7, sigma);
        }

        for (uint256 i = 0; i < 8; i++) {
            state.h[i] ^= v[i] ^ v[i + 8];
        }
    }

    function G(
        uint64[16] memory v,
        uint64[16] memory m,
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        /* uint256 x, */
        /* uint256 y, */
        uint256 r,
        uint256 i,
        uint8[16][12] memory sigma
    ) private pure {
        unchecked {
            v[a] = v[a] + v[b] + m[sigma[r][2 * i]];
            v[d] = rotr64(v[d] ^ v[a], 32);
            v[c] = v[c] + v[d];
            v[b] = rotr64(v[b] ^ v[c], 24);
            v[a] = v[a] + v[b] + m[sigma[r][2 * i + 1]];
            v[d] = rotr64(v[d] ^ v[a], 16);
            v[c] = v[c] + v[d];
            v[b] = rotr64(v[b] ^ v[c], 63);
        }
    }

    function rotr64(uint64 x, uint8 n) private pure returns (uint64) {
        unchecked {
            return (x >> n) | (x << (64 - n));
        }
    }

    function bytesToUint64(bytes32[4] memory b, uint256 offset) private pure returns (uint64) {
        uint64 result = 0;
        for (uint256 i = 0; i < 8; i++) {
            result |= uint64(uint8(b[offset / 32][offset % 32 + i])) << (8 * uint64(i));
        }
        return result;
    }

    function setBufferByte(State memory state, uint8 index, uint8 value) private pure {
        uint256 shift = 256 - 8 - 8 * uint256(index % 32);
        uint256 mask = 0xFF << shift;
        uint256 newValue = uint256(value) << shift;
        state.buf[index / 32] = bytes32((uint256(state.buf[index / 32]) & ~mask) | newValue);
    }

    function SIGMA() internal pure returns (uint8[16][12] memory) {
        return [
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
            [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
            [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
            [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
            [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
            [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
            [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
            [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
            [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
            [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
            [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3]
        ];
    }

    function hash(bytes memory input, uint8 outlen) internal pure returns (bytes memory) {
        State memory state = init(outlen);
        update(state, input);
        return finalize(state);
    }
}
