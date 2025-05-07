package;

import Axis2D;
import flash.display.BitmapData;
import font.FontStorage;
import font.GLGlyphData;
import font.bmf.BMFont.BMFontFactory;
import htext.Align;
import htext.TextLayouter;
import htext.h2d.H2dTextLayouter.H2dRichCharsLayouterFactory;
import htext.style.Padding;
import htext.style.Pivot;
import htext.style.Scale;
import htext.style.TextStyleContext;
import macros.AVConstructor;
import openfl.Vector;
import openfl.display.Sprite;

class TextDemo extends Sprite {
    public var fonts(default, null) = new FontStorage(new BMFontFactory());

    public function new() {
        super();
        fonts.initFont("", "Assets/RobotoSlab.fnt");
        // fonts.initFont("", "Assets/raster.fnt");
        fonts.initFont("bold", "Assets/RobotoSlab-bold.fnt");
        var lfac = new H2dRichCharsLayouterFactory(fonts);
        var pivot:AVector2D<TextPivot> = AVConstructor.create(new ForwardPivot(), new ForwardPivot());
        var padding:AVector2D<Padding> = AVConstructor.create(new SamePadding(0, new FitFontScale(horizontal)),
            new SamePadding(0, new FitFontScale(vertical)));
        var align:AVector2D<Align> = AVConstructor.create(Forward, Forward);

        var textStyleContext = new TextStyleContext(lfac, fonts, "", new FitFontScale(120), pivot, padding, align);
        var bd = openfl.utils.Assets.getBitmapData(@:privateAccess textStyleContext.font.texturePath);
        var l = textStyleContext.createLayouter();
        var rend = new OpenflTextRender(l, new Transformer(), bd);
        addChild(rend);
        rend.setText("ABCDEFGHIJabcdefghij <br/> <b>bar</b> <br/>baz ban");
    }
}

class OpenflTextRender extends Sprite {
    var layouter:TextLayouter<TileRecord>;
    var vertices = new Vector<Float>();
    var indices = new Vector<Int>();
    var uvtData = new Vector<Float>();
    var charPos = AVConstructor.create(Axis2D, 0., 0.);
    var transformer:Transformer;
    var bd:BitmapData;

    public function new(l, tr, bd) {
        super();
        this.layouter = l;
        this.bd = bd;
        this.transformer = tr;
    }

    public function setText(t:String) {
        layouter.setText(t);
        graphics.clear();
        vertices.length = 0;
        indices = forQuads(layouter.getTiles().length);

        for (tile in layouter.getTiles()) {
            setChar(tile);
        }

        graphics.beginBitmapFill(bd);
        graphics.drawTriangles(vertices, indices, uvtData);
        graphics.endFill();
    }

    public static function forQuads(count) {
        var ic = new Vector(count * 6);
        for (i in 0...count) {
            var j = i * 6;
            ic[j] = i * 4;
            ic[j + 1] = i * 4 + 1;
            ic[j + 2] = i * 4 + 2;
            ic[j + 3] = i * 4;
            ic[j + 4] = i * 4 + 3;
            ic[j + 5] = i * 4 + 2;
        }
        return ic;
    }

    function setChar(rec:TileRecord) {
        var glyph:GLGlyphData = rec.tile;
        charPos[horizontal] = rec.x;
        charPos[vertical] = rec.y;
        for (i in 0...4) {
            vertices.push(transformer.transformValue(horizontal, (charPos[horizontal] + rec.scale * glyph.getLocalPosOffset(i, 0))));
            vertices.push(transformer.transformValue(vertical, (charPos[vertical] + rec.scale * (glyph.getLocalPosOffset(i, 1)))));
            uvtData.push(glyph.getUV(i, 0));
            uvtData.push(glyph.getUV(i, 1));
        }
    }
}

class Transformer {
    public function new() {}

    public function transformValue(a, v:Float) {
        return 100 + v * 48;
    }
}
