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
    C1: Color('fdfe89'), # Yellow
    C2: Color('5efdf7'), # Cyan
    C3: Color('ff5dcc'), # Pink
    C4: Color('44ff5f'), # Green
    C5: Color('9576ff'), # Purple
    C6: Color('ff5a5a'), # Red
}
const ALL_COLORS = [C1, C2, C3, C4, C5, C6]
