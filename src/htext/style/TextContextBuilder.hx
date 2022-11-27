package htext.style;
import a2d.Stage;
import Axis2D;
import font.bmf.BMFont.BMFontFactory;
import font.FontStorage;
import htext.Align;
import htext.h2d.H2dTextLayouter.H2dRichCharsLayouterFactory;
import htext.style.Padding;
import htext.style.Pivot;
import htext.style.Scale;
import htext.TextLayouter.CharsLayouterFactory;
import macros.AVConstructor;


@:enum abstract ScreenMeasureUnit(Axis<ScreenMeasureUnit>) to Axis<ScreenMeasureUnit> to Int {
    /** Size inpixels */
    var px;
    /** Fraction of smallest screen side */
    var sfr;
    /** Fraction of the parent. */
    var pfr;
}

interface TextContextStorage {
    function getStyle(name:String):TextStyleContext;
}

class TextContextBuilder implements TextContextStorage {
    public static inline var DEFAULT_STYLE = 'default';
    var ar:Stage;
    var fonts(default, null) = new FontStorage(new BMFontFactory());
    var layouterFactory(default, null):CharsLayouterFactory;
    var fontScale:FontScale;
    var pivot:AVector2D<TextPivot>;
    var padding:AVector2D<Padding>;
    var align:AVector2D<Align>;
    var fontName = "";
    var identityMeasureUnits:AVector<ScreenMeasureUnit, FontScale>;


    public function new(fonts:FontStorage, ar) {
        this.fonts = fonts;
        this.ar = ar;
        this.layouterFactory = new H2dRichCharsLayouterFactory(fonts);
        this.fontScale = new FitFontScale(0.75);
        identityMeasureUnits = AVConstructor.factoryCreate(u -> createSizeApplier(u, 1));
        pivot = AVConstructor.create(new ForwardPivot(), new ForwardPivot());
        padding = AVConstructor.create(new SamePadding(0, identityMeasureUnits[sfr]), new SamePadding(0, identityMeasureUnits[sfr]));
        align = AVConstructor.create(Forward, Forward);
    }

    public function withPadding(a:Axis2D, units:ScreenMeasureUnit, v:Float) {
        padding[a] = new SamePadding(v, identityMeasureUnits[units]);
        return this;
    }

    public function withPivot(a:Axis2D, tp:TextPivot) {
        pivot[a] = tp;
        return this;
    }

    public function withAlign(axis:Axis2D, a:Align) {
        this.align[axis] = a;
        pivot[axis] =
        switch a {
            case Forward: new ForwardPivot();
            case Backward: new BackwardPivot();
            case Center: new MiddlePivot();
        }
        return this;
    }

    public function withScale(fs:FontScale) {
        this.fontScale = fs;
        return this;
    }

    public function withFont(name) {
        fontName = name;
        return this;
    }

    public function withSize(units:ScreenMeasureUnit, val) {
        fontScale = createSizeApplier(units, val);
        return this;
    }

    inline function createSizeApplier(units, val) {
        return switch units {
            case sfr:new ScreenPercentHeightFontHeightCalculator(ar.getAspectRatio(), val);
            case pfr:new FitFontScale(val);
            case px:new PixelFontHeightCalculator(ar.getAspectRatio(), cast ar.getWindowSize(), val);
        }
    }

//    public function withSizeInPixels(px:Int) {
//        fontScale = new PixelFontHeightCalculator(ar.getAspectRatio(), cast ar.getWindowSize(), px);
//        return this;
//    }
//
//    public function withPercentFontScale(p) {
//        fontScale = new ScreenPercentHeightFontHeightCalculator(ar.getAspectRatio(), p);
//        return this;
//    }
//
//    public function withFitFontScale(p) {
//        fontScale = new FitFontScale(p);
//        return this;
//    }


    // ===== storage ====

    var name = "";
    var styles = new Map<String, TextStyleContext>();

    public function newStyle(name) {
        this.name = name;
        return this;
    }

    public function withDefaultName() {
        name = DEFAULT_STYLE;
        return this;
    }

    public function build() {
        var tc = new TextStyleContext(layouterFactory, fonts, fontName, fontScale, pivot.copy(), padding.copy(), align.copy());
        if (name != "") {
            styles[name] = tc;
            name = "";
        }
        return tc;
    }

    public function getStyle(name) {
        return styles[name];
    }

    public function defaultStyle() {
        return getStyle(DEFAULT_STYLE);
    }

}