package htext.h2d;

import font.FontStorage;
import font.GLGlyphData.Glyphs;
import font.GLGlyphData.TileRecord;
import font.GLGlyphData;
import font.IFont;
import haxe.ds.ReadOnlyArray;
import htext.h2d.Text;
import htext.h2d.XmlText;
import htext.TextLayouter;
import htext.h2d.Text.Align as H2dAlign;
import htext.Align;

class H2dTextLayouter implements TextLayouter<TileRecord> {
    var text:Text<GLGlyphData>;
    var glyphs:Glyphs<TileRecord>;
    public function new(f) {
        glyphs = new Glyphs();
        text = new Text(f, glyphs);
    }
    public function setText(val:String):Void {
        text.text = val;
        @:privateAccess text.updateSize();
    }
    public function getTiles():ReadOnlyArray<TileRecord> {
        return glyphs.tiles;
    }
    public function setWidthConstraint(val:Float):Void {
        text.constraintSize(val, -1);
    }
    public function setTextAlign(align:Align, ?valign) {
        text.textAlign = switch align {
            case Forward: H2dAlign.Left;
            case Backward: H2dAlign.Right;
            case Center: H2dAlign.Center;
        };
    }
    public function calculateVertOffset() {
        // todo copy impl from H2dRich impl or extract it to common base class.
        return 0.;
    }
}
class H2dCharsLayouterFactory implements CharsLayouterFactory {
    var font:IFont;
    public function new(f) {
        this.font = f;
    }
    public function create<T:TileRecord>(fname = "", _:Void->Glyphs<T> = null):TextLayouter<T>{
        // todo do not ignore fname
        return cast new H2dTextLayouter(font);
    }
}

class H2dRichTextLayouter<T:TileRecord> implements TextLayouter<T> {
    var text:XmlText<GLGlyphData>;
    var glyphs:Glyphs<T>;
    var fonts:FontStorage;
    var lineHeight:Float;
    var valign:Align = Center;

    public function new(f, defaultFont = "", glyphs) {
        fonts = f;
        this.glyphs = glyphs;
        var ifont = fonts.getFont(defaultFont);
        lineHeight = ifont.font.getLineHeight();
        text = new XmlText(ifont.font, glyphs);
        text.defaultLoadFont = loadFont;
    }

    function loadFont(name) {
        var finst = fonts.getFont(name);
        if (finst == null)
            return null;
        return finst.font;
    }

    public function setText(val:String):Void {
        text.text = val;
        @:privateAccess text.updateSize();
    }

    public function getTiles():ReadOnlyArray<T> {
        return glyphs.tiles;
    }

    public function setWidthConstraint(val:Float):Void {
        text.constraintSize(val, -1);
    }

    public function setTextAlign(align:Align, ?valign:Align) {
        text.textAlign = switch align {
            case Forward: H2dAlign.Left;
            case Backward: H2dAlign.Right;
            case Center: H2dAlign.Center;
        };
        if (valign != null)
            this.valign = valign;
    }

    function ascent() {
        return 0.8;
    }

    public function calculateVertOffset() {
        var ln = text.numLines;
        return switch valign {
            case Forward: 0;
            // pivot of the text lays on baseline of the first line.
            // Desired behavior for odd num of lines is the middle of letters of central line lyes on the center of placeholder
            // for even lines = center of the placeholder is somewhere between lrtters of two crntral lines
            // not sure in this formula but it provides acceptable visual result on hardcoded ascent value (for Roboto Slab font)
            // In proper way the ascent shoulld be in the IFont api but since BMF format doesnt store this data for now i'd keep it that way.
            // I'l be back for this when other font i use will require other ascent val.
            // also variable lineHeighs supported by XmlText would not look nice.

            case Center:
                var oddLinesMp = (ln % 2);
                var evenLinesMp = (1 - ln % 2);
                (( 0.25 * evenLinesMp) + (ascent() * oddLinesMp) + Math.floor(ln / 2) - 1) * lineHeight;
            case Backward: lineHeight * (ln - 1);
        }
    }
}

class H2dRichCharsLayouterFactory implements CharsLayouterFactory {
    var fonts:FontStorage;

    public function new(f) {
        this.fonts = f;
    }

    public function create<T:TileRecord>(f = "", fac:Void->Glyphs<T>=null):TextLayouter<T> {
        var glyphs = if (fac == null) new Glyphs() else fac();
        return new H2dRichTextLayouter(fonts, f, glyphs);
    }
}
