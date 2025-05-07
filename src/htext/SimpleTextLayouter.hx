package htext;

import font.GLGlyphData;
import font.IFont;
import haxe.ds.ReadOnlyArray;
import htext.TextLayouter;

class Layouter implements TextLayouter {
    var tiles:Glyphs;
    var text:SimpleTextLayouter;
    public function new(font){
        tiles = new Glyphs();
        text = new SimpleTextLayouter(font, tiles);
    }

    public function setText(val:String):Void {
        text.text = val;
    }

    public function getTiles():ReadOnlyArray<TileRecord> {
        return tiles.tiles;
    }
}

class SimpleCharsLayouterFactory implements CharsLayouterFactory{
    var font:IFont;

    public function new(f) {
        this.font = f;
    }

    public function create():TextLayouter {
        return new Layouter(font);
    }
}

class SimpleTextLayouter {
    public var text(default, set):String;
    var x:Float = 0.;
    var y = 0.;
    var glyphs:Glyphs<TileRecord>;
    var font:IFont;


    static var newLine = ~/[\r\n]/;

    public function new(f, g) {
        font = f;
        glyphs = g;
    }


    function set_text(s:String):String {
        glyphs.clear();
//        if (s.length > maxTextLen)
//            trace('warn len of string $s greater tham max of label $maxTextLen');
        x = 0; y = 0;

        for (at in 0...s.length) {
            var letter = s.charAt(at);
            if (letter == " ") {
                x += 0.4;
            }
            else if (newLine.match(letter)) {
                x = 0;
                y += font.getLineHeight();
            } else {
                var glyph = font.getChar(letter);
                glyphs.add(glyph, x, y);
//                setChar(at, glyph);
                x += glyph.getAdvance();
            }
        }
        return s;
    }
}
