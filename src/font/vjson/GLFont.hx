package font.vjson;
import utils.LazyMap;
import font.vjson.FontDescr;
class GLFont implements IFont {
    var map(default, null):LazyMap<String, GLGlyphData>;
    public var font(default, null):FontDescr;

    public function new(font:FontDescr) {
        this.font = font;
        map = new LazyMap(createGlyph);
    }

    public function getKerningOffset(ch1:String, ch2:String):Float {
        return 0;
    }


    function createGlyph(char:String) {
        var fontCharacter:CharDescr = font.characters[char];
        // skip null-glyphs
        if (fontCharacter == null)
            throw "there is no character " + char + " + at font descr";
        var glyph = fontCharacter.glyph;
        // quad dimensions
        var px = -glyph.offset.x;
        // y = 0 in the glyph corresponds to the baseline, which is font.ascender from the top of the glyph
        var w = glyph.atlasRect.w / glyph.atlasScale; // convert width to normalized font units
        var h = glyph.atlasRect.h / glyph.atlasScale;
        var py =  glyph.offset.y  - h;
        // uv
        // add half-text offset to map to texel centers
        var ux = (glyph.atlasRect.x + 0.5) / font.textureSize.w;
        var uy = (glyph.atlasRect.y + 0.5) / font.textureSize.h;
        var uw = (glyph.atlasRect.w - 1.0) / font.textureSize.w;
        var uh = (glyph.atlasRect.h - 1.0) / font.textureSize.h;
        // flip glyph uv y, this is different from flipping the glyph y _position_
//        uy = uy + uh;
//        uh = -uh;
        var asc = font.ascender;

        var pos = {x:px, y:py, w:w, h:h};
        var uvs = {x:ux, y:uy, w:uw, h:uh};

        return new GLGlyphData(pos, uvs, fontCharacter.advance, glyph.atlasScale);
    }

    public function getChar(key:String) {
        return map.get(key);
    }

    public function getLineHeight():Float {
        return font.ascender;
    }

    public function getDFSize():Int {
        return font.fieldRange_px;
    }
}
