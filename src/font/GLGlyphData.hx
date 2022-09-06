package font;
class GLGlyphData {
    var advance:Float;
    var atlasScale:Float;
    var uv:Array<Float>;
    var offset:Array<Float>;
    public var dy(default, null):Float;

    public function new(pos:Rect, uvs:Rect, advance, atlasScale = 0.) {
        this.dy = pos.y;
        this.offset = rectToArray(pos);
        this.uv = rectToArray(uvs);
        this.atlasScale = atlasScale;
        this.advance = advance;
    }

    public inline function getLocalPosOffset(vertIdx, cmpIdx) {
        return offset[vertIdx * 2 + cmpIdx];
    }

    public function getUV(vertIdx:Int, cmpIdx:Int) {
        return uv[vertIdx * 2 + cmpIdx];
    }

    static function rectToArray(rect:Rect) {
        return [
            rect.x, rect.y + rect.h,
            rect.x, rect.y,
            rect.x + rect.w, rect.y,
            rect.x + rect.w, rect.y + rect.h,
        ];
    }

    public function getAdvance() {
        return advance;
    }
}

typedef Rect = {
    x:Float,
    y:Float,
    w:Float,
    h:Float,
}


class TileRecord {
    public var x:Float;
    public var y:Float;
    public var scale = 1.;
    public var tile:GLGlyphData;
    public var dfSize:Int = 1;  // cant be 0 for msdf and for use in TextGraphicElement

    public function new(t, x, y, s, df) {
        this.y = y;
        this.x = x;
        this.scale = s;
        this.tile = t;
        this.dfSize = df;
    }
}

class Glyphs {
    public var tiles(default, null):Array<TileRecord> = [];

    public function new() {}

    public function add(v, x, y, scale = 1., dfSize = 2) {
        tiles.push(new TileRecord(v, x, y,  scale, dfSize));
    }

    public function clear() {
        tiles.resize(0);
    }

    public var visible = true;
}


