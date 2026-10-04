#!/usr/bin/env python3
"""Builds assets/fonts/EmojiSubset.ttf: only the emoji/symbols the app uses.

The web build cannot rely on the device's emoji font (Flutter draws text
itself) and would download Noto fonts from fonts.gstatic.com, which may be
unreachable in Iran and never works offline. Run again after adding emoji:

    pip install fonttools
    python3 tool/subset_emoji.py [path/to/NotoColorEmoji.ttf]
"""
import glob
import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = sys.argv[1] if len(sys.argv) > 1 else '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf'
OUT = ROOT / 'assets/fonts/EmojiSubset.ttf'

# Extra emoji the bot may use for new word categories.
EXTRA = '🎬🎵🎤🎸🐶🐱🦁🐘🍕🍔🍎🍉⚽🏀🏆🎮🎨📚✈️🚗🏠🌍🌳🌸☀️🌙⭐🔥💡❤️😀😂😎🤔🥳👑🎉🎁🎭🎲🧸🦸👻🤖👽🍿🎃🎄🕌🏰🗽🎪🧙🐉🦄🍦🍰☕🍵🧃'

text = EXTRA
for pattern in ('lib/**/*.dart', 'assets/words/*.json', 'assets/config/*.json'):
    for f in glob.glob(str(ROOT / pattern), recursive=True):
        text += pathlib.Path(f).read_text(encoding='utf-8')

base = TTFont(ROOT / 'assets/fonts/Vazirmatn-Regular.ttf').getBestCmap()
emoji_cmap = TTFont(SRC).getBestCmap()
wanted = sorted({ord(c) for c in text if ord(c) > 0x2000 and ord(c) not in base and ord(c) in emoji_cmap})
wanted += [0x200D, 0xFE0F, 0x20E3]  # ZWJ, emoji presentation, keycap

opts = subset.Options()
opts.layout_features = ['*']
opts.drop_tables += ['DSIG']
font = subset.load_font(SRC, opts)
s = subset.Subsetter(opts)
s.populate(unicodes=wanted)
s.subset(font)
font.save(OUT)
missing = sorted({c for c in text if ord(c) > 0x2000 and ord(c) not in base and ord(c) not in emoji_cmap and c not in '‌‍‎‏﻿'})
print(f'{OUT.relative_to(ROOT)}: {len(wanted)} code points, {OUT.stat().st_size // 1024} KB')
if missing:
    print('not in the emoji font:', ' '.join(f'{c} U+{ord(c):04X}' for c in missing))
