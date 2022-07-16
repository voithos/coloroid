extends Node

# Color system for color powerups.

enum {
    # Special default color
    CWHITE = 0,
    C1,
    C2,
    C3,
    C4,
    C5,
    C6,
}

const COLORS = {
    CWHITE: Color('ffffff'),
    C1: Color('fdfe89'),
    C2: Color('5efdf7'),
    C3: Color('ff5dcc'),
    C4: Color('44ff5f'),
    C5: Color('9576ff'),
    C6: Color('ff5a5a'),
}
const ALL_COLORS = [C1, C2, C3, C4, C5, C6]
