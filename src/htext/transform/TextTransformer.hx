package htext.transform;
import al.al2d.Axis2D;
import al.al2d.Widget2D;
import htext.style.TextStyleContext;
import transform.TransformerBase;
//using transform.LiquidTransformer.BoundboxConverters;

class TextTransformer extends TransformerBase {
    var textStyleContext:TextStyleContext;

    function new(w, ar, ts) {
        super(ar);
        textStyleContext = ts;
    }

    override public function transformValue(c:Axis2D, input:Float):Float {
        var sign = c == 0 ? 1 : -1;
        var r = sign *
        (
            (textStyleContext.getPivot(c, this) +
            input * textStyleContext.getFontScale(this))
            / aspects.getFactor(c) // aspect ratio correction
            - 1); // gl offset
        return r;
    }

    public static function withTextTransform(w:Widget2D, aspectRatio, style) {
        var transformer = new TextTransformer(w, aspectRatio, style);
        for (a in Axis2D.keys) {
            var applier2 = transformer.getAxisApplier(a);
            w.axisStates[a].addSibling(applier2);
        }
        w.entity.addComponent(transformer);
        return w;
    }
}