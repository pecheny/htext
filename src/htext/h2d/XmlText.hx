package htext.h2d;

import htext.h2d.Text;
import font.bmf.h2d.Tile;
import Xml;

/**
	The `HtmlText` line height calculation rules.
**/
enum LineHeightMode {
    /**
		Accurate line height calculations. Each line will adjust it's height according to it's contents.
	**/
    Accurate;
    /**
		Only text adjusts line heights, and `<img>` tags do not affect it (partial legacy behavior).
	**/
    TextOnly;
    /**
		Legacy line height mode. When used, line heights remain constant based on `Text.font` variable.
	**/
    Constant;
}

/**
	`HtmlText` img tag vertical alignment rules.
**/
enum ImageVerticalAlign {
    /**
		Align images along the top of the text line.
	**/
    Top;
    /**
		Align images to sit on the base line of the text.
	**/
    Bottom;
    /**
		Align images to the middle between the top of the text line its base line.
	**/
    Middle;
}
typedef XmlNodeProcessor = {
    public function pushNode(e:Xml) :Void;
    public function popNode(e:Xml) :Void;
}

typedef XmlTileGroup<T:FontChar2> = TileGroup<T> & XmlNodeProcessor;

/**
	A simple HTML text renderer.

	See the [Text](https://github.com/HeapsIO/heaps/wiki/Text) section of the manual for more details and a list of the supported HTML tags.
**/
class XmlText<T:FontChar2> extends Text<T, XmlTileGroup<T>> {

    /**
		A default method HtmlText uses to load images for `<img>` tag. See `HtmlText.loadImage` for details.
	**/
    public dynamic function defaultLoadImage(url:String):Tile {
        return null;
    }

    /**
		A default method HtmlText uses to load fonts for `<font>` tags with `face` attribute. See `HtmlText.loadFont` for details.
	**/
    public dynamic function defaultLoadFont(name:String):IFont {
        return null;
    }

    /**
		A default method HtmlText uses to format assigned text. See `HtmlText.formatText` for details.
	**/
    public dynamic function defaultFormatText(text:String):String {
        return text;
    }

    /**
		When enabled, condenses extra spaces (carriage-return, line-feed, tabulation and space character) to one space.
		If not set, uncondensed whitespace is left as is, as well as line-breaks.
	**/
    public var condenseWhite(default, set):Bool = true;
    /**
		The spacing after `<img>` tags in pixels.
	**/
    public var imageSpacing(default, set):Float = 1;

    /**
		Line height calculation mode controls how much space lines take up vertically.
		Changing mode to `Constant` restores the legacy behavior of HtmlText.
	**/
    public var lineHeightMode(default, set):LineHeightMode = Accurate;

    /**
		Vertical alignment of the images in `<img>` tag relative to the text.
	**/
    public var imageVerticalAlign(default, set):ImageVerticalAlign = Bottom;

    public var numLines (default, null):Int = 0;
    var xPos:Float;
    var yPos:Float;
    var xMax:Float;
    var xMin:Float;
    var textXml:Xml;
    var sizePos:Int;
    var prevChar:Char = CharAccess.EMPTY;
    var newLine:Bool;
    var aHrefs:Array<String>;
    
//	var aInteractive : Interactive;

    /**
		Method that should return an `h2d.Tile` instance for `<img>` tags. By default calls `HtmlText.defaultLoadImage` method.

		HtmlText does not cache tile instances.
		Due to internal structure, method should be deterministic and always return same Tile on consequent calls with same `url` input.
		@param url A value contained in `src` attribute.
	**/
    public dynamic function loadImage(url:String):Tile {
        return defaultLoadImage(url);
    }

    /**
		Method that should return an `h2d.Font` instance for `<font>` tags with `face` attribute. By default calls `HtmlText.defaultLoadFont` method.

		HtmlText does not cache font instances and it's recommended to perform said caching from outside.
		Due to internal structure, method should be deterministic and always return same Font instance on consequent calls with same `name` input.
		@param name A value contained in `face` attribute.
		@returns Method should return loaded font instance or `null`. If `null` is returned - currently active font is used.
	**/
    public dynamic function loadFont(name:String):IFont {
        var f = defaultLoadFont(name);
        if (f == null) return this.font;
        else return f;
    }

    /**
		Called on a <a> tag click
	**/
    public dynamic function onHyperlink(url:String):Void {
    }

    /**
		Called when text is assigned, allowing to process arbitrary text to a valid XHTML.
	**/
    public dynamic function formatText(text:String):String {
        return defaultFormatText(text);
    }

    override function set_text(t:String) {
        super.set_text(formatText(t));
        return t;
    }

    function parseText(text:String) {
        var doc = try Xml.parse(text) catch (e:Dynamic) throw "Could not parse " + text + " (" + e + ")";
        var comments = [for (ch in doc) if (ch.nodeType == Xml.Comment) ch];
        for (c in comments)
            doc.removeChild(c);
        return doc;
    }

    inline function makeLineInfo(width:Float, height:Float, baseLine:Float):LineInfo {
        return { width: width, height: height, baseLine: baseLine };
    }

    override function validateText() {
        textXml = parseText(text);
//		validateNodes(textXml);
    }

    override function initGlyphs(text:CharAccess, rebuild = true) {
        if (rebuild) {
            glyphs.clear();
//			for( e in elements ) e.remove();
//			elements = [];
        }
//		glyphs.setDefaultColor(textColor);

        var doc:Xml;
        if (textXml == null) {
            doc = parseText(text);
        } else {
            doc = textXml;
        }

        yPos = 0;
        xMax = 0;
        xMin = Math.POSITIVE_INFINITY;
        sizePos = 0;
        calcYMin = 0;

        var metrics:Array<LineInfo> = [ makeLineInfo(0, font.getLineHeight(), font.getBaseline()) ];
        prevChar = CharAccess.EMPTY;
        newLine = true;
        var splitNode:SplitNode = {
            node: null, pos: 0, font: font, prevChar: CharAccess.EMPTY,
            width: 0, height: 0, baseLine: 0
        };
        for (e in doc)
            buildSizes(e, font, metrics, splitNode);

        var max = 0.;
        for (info in metrics) {
            if (info.width > max) max = info.width;
        }
        calcWidth = max;

        prevChar = CharAccess.EMPTY;
        newLine = true;
        nextLine(textAlign, metrics[0].width);
        for (e in doc)
            addNode(e, font, textAlign, 1., rebuild, metrics);

        if (xPos > xMax) xMax = xPos;

        textXml = null;

        var y:Float = yPos;
        calcXMin = xMin;
        calcWidth = xMax - xMin;
        calcHeight = y + metrics[sizePos].height;
        calcSizeHeight = y + metrics[sizePos].baseLine;//(font.baseLine > 0 ? font.baseLine : font.lineHeight);
        numLines = metrics.length;
        calcDone = true;
        if (rebuild) needsRebuild = false;
    }

    function buildSizes(e:Xml, font:IFont, metrics:Array<LineInfo>, splitNode:SplitNode) {
        function wordSplit() {
            var fnt = splitNode.font;
            var str:CharAccess = splitNode.node.nodeValue;
            var info = metrics[metrics.length - 1];
            var w = info.width;
            var cc = str.at(splitNode.pos);
            // Restore line metrics to ones before split.
            // Potential bug: `Text<split> [Image] text<split>text` - third line will use metrics as if image is present in the line.
            info.width = splitNode.width;
            info.height = splitNode.height;
            info.baseLine = splitNode.baseLine;
            var char = fnt.getChar(cc);
            if (lineBreak && charset.isSpace(cc)) {
                // Space characters are converted to \n
                w -= (splitNode.width + letterSpacing + char.getAdvance() + fnt.getKerningOffset(splitNode.prevChar, cc));
                splitNode.node.nodeValue = str.substr(0, splitNode.pos) + "\n" + str.substr(splitNode.pos + 1);
            } else {
                w -= (splitNode.width + letterSpacing + fnt.getKerningOffset(splitNode.prevChar, cc));
                splitNode.node.nodeValue = str.substr(0, splitNode.pos + 1) + "\n" + str.substr(splitNode.pos + 1);
            }
            splitNode.node = null;
            return w;
        }
        inline function lineFont() {
            return lineHeightMode == Constant ? this.font : font;
        }
        if (e.nodeType == Xml.Element) {

            // var lineHeight = 0.;
            inline function makeLineBreak() {
                var fontInfo = lineFont();
                // var h = lineHeight != 0 ? lineHeight : fontInfo.getLineHeight();
                metrics.push(makeLineInfo(0, fontInfo.getLineHeight(), fontInfo.getBaseline()));
                splitNode.node = null;
                newLine = true;
                prevChar = CharAccess.EMPTY;
            }

            var nodeName = e.nodeName.toLowerCase();
            switch( nodeName ) {
                case "p":
                    if (!newLine) {
                        makeLineBreak();
                    }
                case "br":
                    makeLineBreak();
                case "font":
                    for (a in e.attributes()) {
                        var v = e.get(a);
                        switch( a.toLowerCase() ) {
                            case "face": font = loadFont(v);
                            // case "lineheight": lineHeight = Std.parseFloat(v);
                            default:
                        }
                    }
                case "b", "bold":
                    font = loadFont("bold");
                case "i", "italic":
                    font = loadFont("italic");
                default:
            }
            for (child in e)
                buildSizes(child, font, metrics, splitNode);
            switch( nodeName ) {
                case "p":
                    if (!newLine) {
                        makeLineBreak();
                    }
                default:
            }
        } else if (e.nodeValue.length != 0) {
            newLine = false;
            var text:CharAccess = htmlToText(e.nodeValue);
            var fontInfo:IFont = lineFont();
            var info:LineInfo = metrics.pop();
            var leftMargin = info.width;
            var maxWidth = realMaxWidth < 0 ? Math.POSITIVE_INFINITY : realMaxWidth;
            var textSplit = [], restPos = 0;
            var x = leftMargin;
            var breakChars = 0;
            for (i in 0...text.length) {
                var cc = text.at(i);
                var g = font.getChar(cc);
                var newline = cc == '\n'.code;
                var esize = g.getAdvance() + font.getKerningOffset(prevChar, cc);
                var nc = text.at(i + 1);
                if (charset.isBreakChar(cc) && (nc == null || !charset.isComplementChar(nc) )) {
                    // Case: Very first word in text makes the line too long hence we want to start it off on a new line.
                    if (x > maxWidth && textSplit.length == 0 && splitNode.node != null) {
                        metrics.push(makeLineInfo(x, info.height, info.baseLine));
                        x = wordSplit();
                    }

                    var size = x + esize + letterSpacing;
                    var k = i + 1, max = text.length;
                    var prevChar = prevChar;
                    while (size <= maxWidth && k < max) {
                        var cc = text.at(k++);
                        if (lineBreak && (charset.isSpace(cc) || cc == '\n'.code )) break;
                        var e = font.getChar(cc);
                        size += e.getAdvance() + letterSpacing + font.getKerningOffset(prevChar, cc);
                        prevChar = cc;
                        var nc = text.at(k + 1);
                        if (charset.isBreakChar(cc) && (nc == null || !charset.isComplementChar(nc))) break;
                    }
                    // Avoid empty line when last char causes line-break while being CJK
                    if (lineBreak && size > maxWidth && i != max - 1) {
                        // Next word will reach maxWidth
                        newline = true;
                        if (charset.isSpace(cc)) {
                            textSplit.push(text.substr(restPos, i - restPos));
                            g = null;
                        } else {
                            textSplit.push(text.substr(restPos, i + 1 - restPos));
                            breakChars++;
                        }
                        splitNode.node = null;
                        restPos = i + 1;
                    } else {
                        splitNode.node = e;
                        splitNode.pos = i + breakChars;
                        splitNode.prevChar = this.prevChar;
                        splitNode.width = x;
                        splitNode.height = info.height;
                        splitNode.baseLine = info.baseLine;
                        splitNode.font = font;
                    }
                }
                if (g != null && cc != '\n'.code)
                    x += esize + letterSpacing;
                if (newline) {
                    metrics.push(makeLineInfo(x, info.height, info.baseLine));
                    info.height = fontInfo.getLineHeight();
                    info.baseLine = fontInfo.getBaseline();
                    x = 0;
                    prevChar = CharAccess.EMPTY;
                    newLine = true;
                } else {
                    prevChar = cc;
                    newLine = false;
                }
            }

            if (restPos < text.length) {
                if (x > maxWidth) {
                    if (splitNode.node != null && splitNode.node != e) {
                        metrics.push(makeLineInfo(x, info.height, info.baseLine));
                        x = wordSplit();
                    }
                }
                textSplit.push(text.substr(restPos));
                metrics.push(makeLineInfo(x, info.height, info.baseLine));
            }

            if (newLine || metrics.length == 0) {
                metrics.push(makeLineInfo(0, fontInfo.getLineHeight(), fontInfo.getBaseline()));
                textSplit.push("");
            }
            // Save node value
            e.nodeValue = textSplit.join("\n");
        }
    }

    static var REG_SPACES = ~/[\r\n\t ]+/g;

    function htmlToText(t:String) {
        if (condenseWhite)
            t = REG_SPACES.replace(t, " ");
        return t;
    }

    inline function nextLine(align:Align, size:Float) {
        switch( align ) {
            case Left:
                xPos = 0;
                if (xMin > 0) xMin = 0;
            case Right:
                xPos = -size;
                if (xPos < xMin) xMin = xPos;
            case Center:
                xPos = -size / 2;
                if (xPos < xMin) xMin = xPos;
            case _ : throw "Not implemented";
//                Center, MultilineCenter, MultilineRight:
//            var max = 0;// if (align == MultilineCenter || align == MultilineRight) Math.ceil(calcWidth) else calcWidth < 0 ? 0 : Math.ceil(realMaxWidth);
//            var k = align == Center || align == MultilineCenter ? 0.5 : 1;
//            xPos = ((max - size) * k);
//            trace("Max: " + max + " size: " + size + " xPos: " + xPos);
//            if (xPos < xMin) xMin = xPos;
        }
    }

    override function splitText(text:String):String {
        if (realMaxWidth < 0)
            return text;
        yPos = 0;
        xMax = 0;
        sizePos = 0;
        calcYMin = 0;

        var doc = parseText(text);

        /*
			This might require a global refactoring at some point.
			We would need a way to somehow build an AST from the XML representation
			with all sizes and word breaks so analysis is much more easy.
		*/

        var splitNode:SplitNode = { node: null, font: font, width: 0, height: 0, baseLine: 0, pos: 0, prevChar: CharAccess.EMPTY };
        var metrics = [makeLineInfo(0, font.getLineHeight(), font.getBaseline())];
        prevChar = CharAccess.EMPTY;
        newLine = true;

        for (e in doc)
            buildSizes(e, font, metrics, splitNode);
        xMax = 0;
        function addBreaks(e:Xml) {
            if (e.nodeType == Xml.Element) {
                for (x in e)
                    addBreaks(x);
            } else {
                var text = e.nodeValue;
                var startI = 0;
                var index = Lambda.indexOf(e.parent, e);
                for (i in 0...text.length) {
                    if (text.charCodeAt(i) == '\n'.code) {
                        var pre = text.substring(startI, i);
                        if (pre != "") e.parent.insertChild(Xml.createPCData(pre), index++);
                        e.parent.insertChild(Xml.createElement("br"), index++);
                        startI = i + 1;
                    }
                }
                if (startI < text.length) {
                    e.nodeValue = text.substr(startI);
                } else {
                    e.parent.removeChild(e);
                }
            }
        }
        for (d in doc)
            addBreaks(d);
        return doc.toString();
    }

    function addNode(e:Xml, font:IFont, align:Align, scale:Float, rebuild:Bool, metrics:Array<LineInfo>) {
//		inline function createInteractive() {
//			if(aHrefs == null || aHrefs.length == 0)
//				return;
//			aInteractive = new Interactive(0, metrics[sizePos].height, this);
//			var href = aHrefs[aHrefs.length-1];
//			aInteractive.onClick = function(event) {
//				onHyperlink(href);
//			}
//			aInteractive.x = xPos;
//			aInteractive.y = yPos;
//			elements.push(aInteractive);
//		}

        inline function finalizeInteractive() {
//			if(aInteractive != null) {
//				aInteractive.width = xPos - aInteractive.x;
//				aInteractive = null;
//			}
        }

        inline function makeLineBreak() {
            finalizeInteractive();
            if (xPos > xMax) xMax = xPos;
            yPos += metrics[sizePos].height + lineSpacing;
            nextLine(align, metrics[++sizePos].width);
//			createInteractive();
        }
        if (e.nodeType == Xml.Element) {
            var prevColor = null;
            // var  prevGlyphs = null;
            var oldAlign = align;
            var oldScale = scale;
            var nodeName = e.nodeName.toLowerCase();
            inline function revertState() {
                align = oldAlign;
                scale = oldScale;
                switch( nodeName ) {
                    case "p":
                        if (newLine) {
                            nextLine(align, metrics[sizePos].width);
                        } else if (sizePos < metrics.length - 2 || metrics[sizePos + 1].width != 0) {
                            // Condition avoid extra empty line if <p> was the last tag.
                            makeLineBreak();
                            newLine = true;
                            prevChar = CharAccess.EMPTY;
                        }
                    case "a":
                        if (aHrefs.length > 0) {
                            finalizeInteractive();
                            aHrefs.pop();
//					createInteractive();
                        }
                    default:
                        glyphs.popNode(e);
                }
                // if (prevGlyphs != null)
                //     glyphs = prevGlyphs;
//			if( prevColor != null )
//				@:privateAccess glyphs.curColor.load(prevColor);
            }
            inline function setFont(v:String) {
                font = loadFont(v);
                // if (prevGlyphs == null) prevGlyphs = glyphs;
                // var prev = glyphs;
                // init drawcall was here
//				@:privateAccess glyphs.curColor.load(prev.curColor);
//				elements.push(glyphs);
            }
            switch( nodeName ) {
                case "font":
                    for (a in e.attributes()) {
                        var v = e.get(a);
                        switch( a.toLowerCase() ) {
//					case "color":
//						if( prevColor == null ) prevColor = @:privateAccess glyphs.curColor.clone();
//						if( v.charCodeAt(0) == '#'.code && v.length == 4 )
//							v = "#" + v.charAt(1) + v.charAt(1) + v.charAt(2) + v.charAt(2) + v.charAt(3) + v.charAt(3);
//						glyphs.setDefaultColor(Std.parseInt("0x" + v.substr(1)));
//					case "opacity":
//						if( prevColor == null ) prevColor = @:privateAccess glyphs.curColor.clone();
//						@:privateAccess glyphs.curColor.a *= Std.parseFloat(v);
                            case "face":
                                setFont(v);
                            case "scale":
                                var s = Std.parseFloat(v);
                                if (!Math.isNaN(s))
                                    scale = s;
                            default:
                        }
                    }
                case "p":
                    for (a in e.attributes()) {
                        switch( a.toLowerCase() ) {
                            case "align":
                                var v = e.get(a);
                                if (v != null)
                                    switch( v.toLowerCase() ) {
                                        case "left":
                                            align = Left;
                                        case "center":
                                            align = Center;
                                        case "right":
                                            align = Right;
                                        case "multiline-center":
                                            align = MultilineCenter;
                                        case "multiline-right":
                                            align = MultilineRight;
                                        //?justify
                                    }
                            default:
                        }
                    }
                    if (!newLine) {
                        makeLineBreak();
                        newLine = true;
                        prevChar = CharAccess.EMPTY;
                    } else {
                        nextLine(align, metrics[sizePos].width);
                    }
                case "b", "bold":
                    setFont("bold");
                case "i", "italic":
                    setFont("italic");
                case "br":
                    makeLineBreak();
                    newLine = true;
                    prevChar = CharAccess.EMPTY;
                case "img":
                default:
                    glyphs.pushNode(e);
            }
            for (child in e)
                addNode(child, font, align, scale, rebuild, metrics);
            revertState();
        } else if (e.nodeValue.length != 0) {
            newLine = false;
            var t:CharAccess = e.nodeValue;
            var dy = ( metrics[sizePos].baseLine - font.getBaseline() ) * scale;
            for (i in 0...t.length) {
                var cc = t.at(i);
                if (cc == "\n".code) {
                    makeLineBreak();
                    //todo why commented
					// dy = metrics[sizePos].baseLine - font.getBaseline();
                    prevChar = CharAccess.EMPTY;
                    continue;
                }
                else {
                    var fc = font.getChar(cc);
                    var fcdy = scale * fc.dy;
                    if (fc != null) {
                        xPos += font.getKerningOffset(prevChar, cc) * scale;
                        if (rebuild && !charset.isSpace(cc)) glyphs.add(cast fc, xPos, yPos + dy, scale, font.getDFSize());
                        if (yPos == 0 && fcdy + dy < calcYMin) calcYMin = fcdy + dy;
                        xPos += (fc.getAdvance() + letterSpacing) * scale;
                    }
                    prevChar = cc;
                }
            }
        }
    }

    function set_imageSpacing(s) {
        if (imageSpacing == s) return s;
        imageSpacing = s;
        rebuild();
        return s;
    }

    function set_condenseWhite(value:Bool) {
        if (this.condenseWhite != value) {
            this.condenseWhite = value;
            rebuild();
        }
        return value;
    }

    function set_imageVerticalAlign(align) {
        if (this.imageVerticalAlign != align) {
            this.imageVerticalAlign = align;
            rebuild();
        }
        return align;
    }

    function set_lineHeightMode(v) {
        if (this.lineHeightMode != v) {
            this.lineHeightMode = v;
            rebuild();
        }
        return v;
    }


}

private typedef LineInfo = {
    var width:Float;
    var height:Float;
    var baseLine:Float;
}

private typedef SplitNode = {
    var node:Xml;
    var prevChar:Char;
    var pos:Int;
    var width:Float;
    var height:Float;
    var baseLine:Float;
    var font:IFont;
}