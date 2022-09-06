package htext.style;
interface Padding {
    function getMain():Float;

/**
*  Return padding from back side. Since the value given along the same axis with main padding, the sign is opposite.
**/
    function getSecondary():Float;

    function getTotal():Float;
}

class SamePadding implements Padding {
    var val:Float;

    public function new(v) {
        this.val = v;
    }

    public function getMain():Float {
        return val;
    }

    public function getSecondary():Float {
        return -val;
    }

    public function getTotal():Float {
        return val * 2;
    }
}
