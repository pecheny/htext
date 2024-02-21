package htext.style;
import Axis2D;

interface FontScale {
    function getValue(tr:Location2D):Float;
}

class ScreenPercentSmallSideFontHeightCalculator implements FontScale {
    var ar:ReadOnlyAVector2D<Float>;
    var base:Float;

    public function new(ar, base = 0.25) {
        this.ar = ar;
        this.base = base;
    }

    public function getValue(tr) {
        return base * Math.min(ar[vertical], ar[horizontal]);
    }
}

class ScreenPercentHeightFontHeightCalculator implements FontScale {
    var ar:ReadOnlyAVector2D<Float>;
    var base:Float;

    public function new(ar, base = 0.25) {
        this.ar = ar;
        this.base = base;
    }

    public function getValue(tr) {
        return base * ar[vertical];
    }
}

class PixelFontHeightCalculator implements FontScale {
    var ar:ReadOnlyAVector2D<Float>;
    var windowSize:ReadOnlyAVector2D<Int>;
    var px:Float;

    public function new(ar, ws, px) {
        this.ar = ar;
        this.windowSize = ws;
        this.px = px;
    }

    public function getValue(tr):Float {
        return 2 * px * ar[vertical] / windowSize[ vertical ];
    }
}

class FitFontScale implements FontScale {
    var base:Float;

    public function new(base) {
        this.base = base;
    }

    public function getValue(tr:Location2D):Float {
        return tr.size[vertical] * base;
    }
}
