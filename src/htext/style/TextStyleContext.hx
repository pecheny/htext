package htext.style;
import Axis2D;
import font.FontInstance;
import font.FontStorage;
import font.IFont;
import htext.Align;
import htext.style.Pivot;
import htext.style.Scale;
import htext.TextLayouter.CharsLayouterFactory;

class TextStyleContext {
    var layouterFactory(default, null):CharsLayouterFactory;
    var font:FontInstance<IFont>;
    var defaultFontName:String;
    var fontScale:FontScale;
    var pivot:AVector2D<TextPivot>;
    var padding:AVector2D<Padding>;
    var align:AVector2D<Align>;

    public function new(lf, fonts:FontStorage, defaultFont:String, scale, pivot, padding, align) {
        this.layouterFactory = lf;
        this.defaultFontName = defaultFont;
        this.font = fonts.getFont(defaultFont);
        this.fontScale = scale;
        this.pivot = pivot;
        this.padding = padding;
        this.align = align;
    }

    public function createLayouter() {
        var l = layouterFactory.create(defaultFontName);
        l.setTextAlign(align[horizontal], align[vertical]) ;
        return l;
    }

    public function getDrawcallName() {
        return font.getId();
    }

    public function getFont():IFont {
        return font.font;
    }

    public function getFontScale(tr) {
        return fontScale.getValue(tr);
    }

    public function getPivot(a:Axis2D, transform:Location2D) {
        var offset = switch align[a] {
            case Forward : padding[a].getMain(transform);
            case Backward : padding[a].getSecondary(transform);
            case Center : 0;
        }
        return offset + pivot[a].getPivot(a, transform, this);
    }

    public function getContentSize(a:Axis2D, transform:Location2D) {
        return transform.size[a] - padding[a].getTotal(transform);
    }

}