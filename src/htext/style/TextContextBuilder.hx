package htext.style;
import al.al2d.Axis2D;
import al.al2d.Widget2D.AxisCollection2D;
import font.bmf.BMFont.BMFontFactory;
import font.FontStorage;
import htext.Align;
import htext.h2d.H2dTextLayouter.H2dRichCharsLayouterFactory;
import htext.style.Padding;
import htext.style.Pivot;
import htext.style.Scale;
import htext.TextLayouter.CharsLayouterFactory;

interface TextContextStorage {
    function getStyle(name:String):TextStyleContext;
}

class TextContextBuilder implements TextContextStorage {
    public static inline var DEFAULT_STYLE = 'default';
    var ar:StageAspectKeeper;
    var fonts(default, null) = new FontStorage(new BMFontFactory());
    var layouterFactory(default, null):CharsLayouterFactory;
    var fontScale:FontScale;
    var pivot:AxisCollection2D<TextPivot> = new AxisCollection2D();
    var padding:AxisCollection2D<Padding> = new AxisCollection2D();
    var align:AxisCollection2D<Align> = new AxisCollection2D();
    var fontName = "";

    public function new(fonts:FontStorage, ar) {
        this.fonts = fonts;
        this.ar = ar;
        this.layouterFactory = new H2dRichCharsLayouterFactory(fonts);
        this.fontScale = new FitFontScale(0.75);
        pivot[horizontal] = new ForwardPivot();
        pivot[vertical] = new ForwardPivot();

        padding[horizontal] = new SamePadding(0);
        padding[vertical] = new SamePadding(0);

        align[horizontal] = Forward;
        align[vertical] = Forward;
    }

    public function withPadding(a:Axis2D, v) {
        padding[a] = new SamePadding(v);
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

    public function withSizeInPixels(px:Int) {
        fontScale = new PixelFontHeightCalculator(ar.getFactorsRef(), cast ar.getWindowSize(), px);
        return this;
    }

    public function withPercentFontScale(p) {
        fontScale = new ScreenPercentHeightFontHeightCalculator(ar.getFactorsRef(), p);
        return this;
    }

    public function withFitFontScale(p) {
        fontScale = new FitFontScale(p);
        return this;
    }


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