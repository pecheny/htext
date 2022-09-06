package ;
import Axis;
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
        fonts.initFont("", "Assets/Cardo-36-df2.fnt");
        var lfac = new H2dRichCharsLayouterFactory(fonts);
        var pivot:AxisCollection2D<TextPivot> = new AxisCollection2D();
        var padding:AxisCollection2D<Padding> = new AxisCollection2D();
        var align:AxisCollection2D<Align> = new AxisCollection2D();
        pivot[horizontal] = new ForwardPivot();
        pivot[vertical] = new ForwardPivot();

        padding[horizontal] = new SamePadding(0);
        padding[vertical] = new SamePadding(0);

        align[horizontal] = Forward;
        align[vertical] = Forward;

        var textStyleContext = new TextStyleContext(lfac, fonts, "", new FitFontScale(120), pivot, padding, align);
        var bd = openfl.utils.Assets.getBitmapData(@:privateAccess textStyleContext.font.texturePath);
        var ttr = new TextTransformer(ar, textStyleContext);
        var l = textStyleContext.createLayouter();
        var rend = new OpenflTextRender(l, ttr, bd);
        addChild(rend);
        rend.setText("FFooFooFooFooFooFooFooFooFooFooFooFooFooFooFoooo");
    }
}

class OpenflTextRender extends Sprite {
    var l:TextLayouter;
    var vertices = new Vector<Float>();
    var indices = new Vector<Int>();
    var uvtData = new Vector<Float>();
    var charPos:AxisCollection2D<Float> = new AxisCollection2D();
//    var transformer:TransformerBase;
    var transformer:Transformer = new Transformer();
    var bd:BitmapData;

    public function new(l, tr, bd) {
        super();
        this.l = l;
        this.bd = bd;
//        this.transformer = tr;
    }

    public function setText(t:String) {
        l.setText(t);
        trace(t + " " + l.getTiles().length);
        graphics.clear();
        vertices.length = 0;
        indices.length = 0;
        uvtData.length = 0;
        var inds = IndexCollection.forQuads(l.getTiles().length);
        for (ind in inds)
            indices.push(ind);

        for (tile in l.getTiles()) {
            setChar(tile);
        }
        graphics.beginBitmapFill(bd);
        graphics.drawTriangles(vertices, indices, uvtData);
        graphics.endFill();
        trace(vertices);
        trace(indices);
    }

    function setChar(rec:TileRecord) {
        var glyph:GLGlyphData = rec.tile;
        charPos[horizontal] = rec.x;
        charPos[vertical] = rec.y;
        for (i in 0...4) {
            vertices.push(transformer.transformValue(horizontal, (charPos[horizontal] + rec.scale * glyph.getLocalPosOffset(i, 0))));
            vertices.push(100 + transformer.transformValue(vertical, (charPos[vertical] + rec.scale * ( glyph.getLocalPosOffset(i, 1) ) )));
//            vertices.push(charPos[horizontal] + rec.scale * glyph.getLocalPosOffset(i, 0));
//            vertices.push(charPos[vertical] + rec.scale * ( glyph.getLocalPosOffset(i, 1) ));
            uvtData.push(glyph.getUV(i, 0));
            uvtData.push(glyph.getUV(i, 1));
        }


//        var sssize = Math.abs(posWriter[vertical].getValue(targ, vertOfs + 1) - posWriter[vertical].getValue(targ, vertOfs));
//        var screenDy = sssize * stageHeight / 2;// gl screen space (?)
//        var smoothness = DummyEditorField.value;//calculateGradientSize(rec, screenDy);

    }
}

class Transformer {
    public function new() {}

    public function transformValue(a, v:Float) {
        return 100 + v * 100;
    }
}

class StageAspectKeeper {
    var base:Float;
    public var aspects:Array<Float> = [1, 1];
    public var size:Array<Float> = [1, 1];
    public var pos:Array<Float> = [0, 0];

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
        size[0] = stage.stageWidth;
        size[1] = stage.stageHeight;
        if (width > height) {
            aspects[0] = (base * width / height);
            aspects[1] = base;
        } else {
            aspects[0] = base;
            aspects[1] = (base * height / width);
        }
    }

    public inline function getFactor(cmp:Int):Float {
        return aspects[cmp];
    }

    public function getFactorsRef():ReadOnlyArray<Float> {
        return aspects;
    }

    public function getWindowSize():ReadOnlyArray<Float> {
        return size;
    }

    public function getValue(a:Axis2D):Float {
        return if (a == horizontal) width else height;
    }
}

class TextTransformer {
    var textStyleContext:TextStyleContext;
    var tr:Location2D;

    public function new(tr:Location2D, ts) {
        textStyleContext = ts;
        this.tr = tr;
    }

    public function transformValue(c:Axis2D, input:Float):Float {
        var sign = 1;// c == 0 ? 1 : -1;
        var r = sign *
        (
            (textStyleContext.getPivot(c, tr) +
            input * textStyleContext.getFontScale(tr))
            / tr.aspects[c] // aspect ratio correction
            - 1); // gl offset
        return r;
    }
}


abstract IndexCollection(Bytes) from Bytes to Bytes {
    public static inline var ELEMENT_SIZE = 2;

    public function new(size) {
        this = Bytes.alloc(ELEMENT_SIZE * size);
    }

    @:arrayAccess
    public inline function get(i) {
        return this.getUInt16(i * ELEMENT_SIZE);
    }

    @:arrayAccess
    public inline function set(i, val) {
        return this.setUInt16(i * ELEMENT_SIZE, val);
    }

    public var length(get, never):Int;

    inline function get_length():Int {
        return Std.int(this.length / ELEMENT_SIZE);
    }

    public static function forQuads(count) {
        var ic = new IndexCollection(count * 6);
        for (i in 0...count) {
            var j = i * 6;
            ic[j] = i * 4;
            ic[j + 1] = i * 4 + 1;
            ic[j + 2] = i * 4 + 2;
            ic[j + 3] = i * 4 ;
            ic[j + 4] = i * 4 + 3;
            ic[j + 5] = i * 4 + 2;
        }
        return ic;
    }

    public static function forQuadsOdd(count) {
        var ic = new IndexCollection(count * 6);
        for (i in 0...count) {
            var j = i * 6;
            ic[j] = i * 4;
            ic[j + 1] = i * 4 + 1;
            ic[j + 2] = i * 4 + 3;
            ic[j + 3] = i * 4 ;
            ic[j + 4] = i * 4 + 3;
            ic[j + 5] = i * 4 + 2;
        }
        return ic;
    }

    public static function qGrid(w, h) {
        var qCount = (w - 1) * (h - 1);
        var triCount = qCount * 2;
        var ic = new IndexCollection(triCount * 3);
        var idx = 0;

        for (line in 0...h - 1) {
            for (q in 0...w - 1) {
                ic[idx++] = line * w + q;
                ic[idx++] = line * w + q + 1;
                ic[idx++] = (line + 1) * w + q ;

                ic[idx++] = (line + 1) * w + q ;
                ic[idx++] = line * w + q + 1;
                ic[idx++] = (line + 1) * w + q + 1;
            }
        }

        return ic;
    }

    public function toString() {
        return "" + [for (i in 0...length) get(i)];
    }
}



