"""Generate Reef Runner's two original NES pattern tables."""

from pathlib import Path


BACKGROUND = {
    # Index 1 is the base water, index 2 is the ripple, and index 3 is foam.
    0x01: "11111111 11111111 11122111 12211111 11111111 11111111 11111122 21111111",
    0x02: "11111111 11111122 22212211 11111111 11222111 22111122 11111111 11111111",
    0x03: "11111111 11111111 11112222 12233333 33332222 22111111 11111111 11111111",
    0x04: "11111111 11111123 11112333 11123322 11233211 12332111 23321111 33211111",
    0x05: "11111111 11111111 11111111 11111122 11112332 11123222 11222222 12221122",
    0x06: "11111111 11111111 11111111 21111111 22331111 23223111 22222211 21122221",
    0x07: "00000000 00000000 00000110 00013321 00132210 01332100 01110000 00000000",
    0x08: "22222222 22222222 22222322 22222222 23222222 22222222 22222232 22222222",
    0x09: "11111111 11122111 22222222 33332333 22222222 22222222 11122211 11111111",
    0x0A: "11111111 11111111 11111111 11111111 11111111 11111111 11111111 11111111",
    0x0B: "11133111 11333311 13333331 13333331 13222231 11333311 11133111 11111111",
    0x0C: "00000000 03333330 03111130 03121230 03222230 03333330 00000000 00000000",
}

# Each two-digit hexadecimal row describes five pixels of ink.
FONT = {
    "!": "04 04 04 04 04 00 04",
    "'": "04 04 08 00 00 00 00",
    "+": "00 04 04 1F 04 04 00",
    "-": "00 00 00 1F 00 00 00",
    ".": "00 00 00 00 00 00 04",
    "/": "01 01 02 04 08 10 10",
    "0": "0E 11 13 15 19 11 0E",
    "1": "04 0C 04 04 04 04 0E",
    "2": "0E 11 01 02 04 08 1F",
    "3": "1E 01 01 0E 01 01 1E",
    "4": "02 06 0A 12 1F 02 02",
    "5": "1F 10 10 1E 01 11 0E",
    "6": "06 08 10 1E 11 11 0E",
    "7": "1F 01 02 04 08 08 08",
    "8": "0E 11 11 0E 11 11 0E",
    "9": "0E 11 11 0F 01 02 0C",
    ":": "00 04 00 00 04 00 00",
    "=": "00 00 1F 00 1F 00 00",
    "?": "0E 11 01 02 04 00 04",
    "A": "0E 11 11 1F 11 11 11",
    "B": "1E 11 11 1E 11 11 1E",
    "C": "0E 11 10 10 10 11 0E",
    "D": "1C 12 11 11 11 12 1C",
    "E": "1F 10 10 1E 10 10 1F",
    "F": "1F 10 10 1E 10 10 10",
    "G": "0E 11 10 17 11 11 0F",
    "H": "11 11 11 1F 11 11 11",
    "I": "0E 04 04 04 04 04 0E",
    "J": "07 02 02 02 12 12 0C",
    "K": "11 12 14 18 14 12 11",
    "L": "10 10 10 10 10 10 1F",
    "M": "11 1B 15 15 11 11 11",
    "N": "11 19 19 15 13 13 11",
    "O": "0E 11 11 11 11 11 0E",
    "P": "1E 11 11 1E 10 10 10",
    "Q": "0E 11 11 11 15 12 0D",
    "R": "1E 11 11 1E 14 12 11",
    "S": "0F 10 10 0E 01 01 1E",
    "T": "1F 04 04 04 04 04 04",
    "U": "11 11 11 11 11 11 0E",
    "V": "11 11 11 0A 0A 04 04",
    "W": "11 11 11 15 15 1B 11",
    "X": "11 11 0A 04 0A 11 11",
    "Y": "11 11 0A 04 04 04 04",
    "Z": "1F 01 02 04 08 10 1F",
}

# Surfer faces right on a board with a violet stripe. Color 1 is the hair and
# outline, color 2 is the wetsuit, and color 3 is the skin and board highlights.
SURFER = """
0000 0000 0000 0000
0000 0011 1000 0000
0000 0113 3100 0000
0000 1113 3300 0000
0001 1133 1000 0000
0011 1122 1000 0000
0111 1132 2110 0000
0013 3222 1233 3100
0001 1222 2111 1000
0000 1222 1110 0000
0000 0111 3321 0000
0000 0132 1331 0000
0001 3331 0133 1000
0011 1111 1111 1110
0133 3322 2333 3310
0011 1111 1111 1100
"""

REEF = """
0000 0000 0000 0000
0000 0000 0000 0000
0000 0001 1000 0000
0000 0012 2100 0000
0000 0132 2210 0000
0000 1322 1221 0000
0001 3222 1221 0000
0012 2221 2221 1000
0123 2211 2232 2100
1232 2221 2322 2210
1222 1221 2221 2221
1221 2222 2212 2221
1122 2222 1122 2211
0111 1221 1112 1110
0000 1111 0011 0000
0000 0000 0000 0000
"""

SPRITES = {
    0x05: "00010000 00131000 01332100 13332210 01322100 00121000 00010000 00000000",
    0x0A: "33333300 32000000 30000000 30000000 30000000 30000000 00000000 00000000",
    0x0B: "00000000 00000000 00033300 00322230 03222203 32220000 00000000 00000000",
}


def tile_bytes(rows):
    if len(rows) != 8 or any(len(row) != 8 or set(row) - set("0123") for row in rows):
        raise ValueError(f"Invalid 8x8 NES tile: {rows}")
    # NES CHR tiles store the eight low-bit rows followed by the eight high-bit rows.
    return bytes(
        sum(((int(pixel) >> plane) & 1) << (7 - column) for column, pixel in enumerate(row))
        for plane in range(2)
        for row in rows
    )


def put_tile(table, number, rows):
    offset = number * 16
    table[offset:offset + 16] = tile_bytes(rows)


def put_metasprite(table, first_tile, art):
    rows = ["".join(row.split()) for row in art.strip().splitlines()]
    if len(rows) != 16 or any(len(row) != 16 for row in rows):
        raise ValueError("Expected a 16x16 metasprite")
    for row in range(2):
        for column in range(2):
            put_tile(table, first_tile + row * 2 + column, [
                pixels[column * 8:column * 8 + 8] for pixels in rows[row * 8:row * 8 + 8]
            ])


def generate():
    background, sprites = bytearray(4096), bytearray(4096)
    for number, art in BACKGROUND.items():
        put_tile(background, number, art.split())
    for glyph, art in FONT.items():
        rows = ["0" + f"{int(row, 16):05b}".replace("1", "3") + "00" for row in art.split()]
        put_tile(background, ord(glyph), [*rows, "00000000"])
    put_metasprite(sprites, 0x01, SURFER)
    put_metasprite(sprites, 0x06, REEF)
    for number, art in SPRITES.items():
        put_tile(sprites, number, art.split())
    return bytes(background + sprites)


if __name__ == "__main__":
    Path(__file__).with_name("reef-runner.chr").write_bytes(generate())
