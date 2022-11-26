package htext.style;
import htext.style.Scale;
interface Padding {
    function getMain(loc:Location2D):Float;

/**
*  Return padding from back side. Since the value given along the same axis with main padding, the sign is opposite.
**/
    function getSecondary(loc:Location2D):Float;

    function getTotal(loc:Location2D):Float;
}

class SamePadding implements Padding {
    var val:Float;
    var unitApplier:FontScale;

    public function new(v, ua) {
        this.val = v;
        this.unitApplier = ua;
    }

    public function getMain(loc:Location2D):Float {
        return unitApplier.getValue(loc) * val;
    }

    public function getSecondary(loc:Location2D):Float {
        return -val * unitApplier.getValue(loc);
    }

    public function getTotal(loc:Location2D):Float {
        return unitApplier.getValue(loc) * val * 2;
    }
}
