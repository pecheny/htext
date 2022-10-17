package;

import Axis2D;
import macros.AVConstructor;
import htext.style.Pivot;
import htext.style.Padding;
import flash.display.BitmapData;
import font.bmf.BMFont.BMFontFactory;
import font.FontStorage;
import font.GLGlyphData;
import haxe.ds.ReadOnlyArray;
import haxe.io.Bytes;
import htext.Align;
import htext.h2d.H2dTextLayouter.H2dRichCharsLayouterFactory;
import htext.style.Padding;
import htext.style.Pivot;
import htext.style.Scale;
import htext.style.TextStyleContext;
import htext.TextLayouter;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Vector;

class TextDemo extends Sprite {
    public var fonts(default, null) = new FontStorage(new BMFontFactory());
    public var ar = new StageAspectKeeper(1);

    public function new() {
        super();
        fonts.initFont("", "Assets/RobotoSlab.fnt");
        var lfac = new H2dRichCharsLayouterFactory(fonts);
        var pivot:AVector2D<TextPivot> = AVConstructor.create(new ForwardPivot(), new ForwardPivot());
        var padding:AVector2D<Padding> = AVConstructor.create(new SamePadding(0), new SamePadding(0));
        var align:AVector2D<Align> = AVConstructor.create(Forward, Forward);

        var textStyleContext = new TextStyleContext(lfac, fonts, "", new FitFontScale(120), pivot, padding, align);
        var bd = openfl.utils.Assets.getBitmapData(@:privateAccess textStyleContext.font.texturePath);
        var l = textStyleContext.createLayouter();
        var rend = new OpenflTextRender(l, new Transformer(), bd);
        addChild(rend);
        rend.setText("Foo bar <br/>baz ban");
    }
}

class OpenflTextRender extends Sprite {
    var l:TextLayouter;
    var vertices = new Vector<Float>();
    var indices = new Vector<Int>();
    var uvtData = new Vector<Float>();
    var charPos = AVConstructor.create(Axis2D, 0., 0.);
    var transformer:Transformer;
    var bd:BitmapData;

    public function new(l, tr, bd) {
        super();
        this.l = l;
        this.bd = bd;
        this.transformer = tr;
    }

    public function setText(t:String) {
        l.setText(t);
        graphics.clear();
        vertices.length = 0;
        indices = forQuads(l.getTiles().length);

        for (tile in l.getTiles()) {
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
        return 100 + v * 24;
    }
}

class StageAspectKeeper {
    var base:Float;

    public var aspects = AVConstructor.create(Axis2D, 1., 1.);
    public var size = AVConstructor.create(Axis2D, 1, 1);
    public var pos = AVConstructor.create(Axis2D, 0., 0.);

    var width:Float;
    var height:Float;

    public function new(base:Float = 1) {
        this.base = base;
        openfl.Lib.current.stage.addEventListener(Event.RESIZE, onResize);
        onResize(null);
    }

    function onResize(e) {
        var stage = openfl.Lib.current.stage;
        width = stage.stageWidth;
        height = stage.stageHeight;
        size[horizontal] = stage.stageWidth;
        size[vertical] = stage.stageHeight;
        if (width > height) {
            aspects[horizontal] = (base * width / height);
            aspects[vertical] = base;
        } else {
            aspects[horizontal] = base;
            aspects[vertical] = (base * height / width);
        }
    }

    public inline function getFactor(cmp:Axis2D):Float {
        return aspects[cmp];
    }

    public function getFactorsRef():ReadOnlyAVector2D<Float> {
        return aspects;
    }

    public function getWindowSize():ReadOnlyAVector2D<Int> {
        return size;
    }

    public function getValue(a:Axis2D):Float {
        return if (a == horizontal) width else height;
    }
}
