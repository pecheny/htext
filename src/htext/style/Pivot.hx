package htext.style;

interface TextPivot {
    public function getPivot(a:Axis2D, transform:Location2D, style:TextStyleContext):Float;
}

class ForwardPivot implements TextPivot {
    public function new() {}

    public function getPivot(a:Axis2D, transform:Location2D, style:TextStyleContext):Float {
        var offset = 0.;
        if (a == vertical)
            offset += (style.getFont().getBaseline());
        return offset * style.getFontScale(transform);
    }
}

class BackwardPivot implements TextPivot {
    public function new() {}

    public function getPivot(a:Axis2D, transform:Location2D, style:TextStyleContext):Float {
        return 1;
    }
}

class MiddlePivot implements TextPivot {
    public function new() {}

    public function getPivot(a:Axis2D, transform:Location2D, style:TextStyleContext):Float {
        return 0.5;
    }
}
