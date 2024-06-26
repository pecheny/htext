## htext
**htext** is the text layouting package extracted/decoupled from [heaps](https://github.com/HeapsIO/heaps) engine as independent library to use with any other (primarily GPU-based) engines.
### Features
* Original engine features to handle xml-based markup with support of `<b>`, `<p align="left|center|right|multiline-right|multiline-center">`, `<i>`, `<font face="font-name", scale="1">`, `<br/>`.
* Incapsulates font format details under IFont interface which make it able to deal with fonts in different formats. Provided implementations are fnt generated by [fontgen](https://github.com/Yanrishatum/fontgen) and [VALIS-software GPUtext](https://github.com/VALIS-software/GPUText)

### Usage
In few words, **htext** provides classes to take texture, font description and (optional marked up) text and generate quads with associated UVs. For more details see dummy example for openfl. More complex demo involved msdf-shader, complex layouts and interactivities depends on several other my libraries and awaits when them will be cleaned up and published.

### TODO
* provide api to handling custom tags
* demo with multi-page atlas

### See Also
* my fork of [fontgen](https://github.com/pecheny/fontgen) which was used to generate atlas in the demo


