# macOCR

macOCR is a command line app that runs OCR on text on your secreen.

Takes file, stdin, or screencapture as input.

![How it works](https://github.com/adam-zethraeus/macOCR/blob/main/screen-recording.gif?raw=true)

## Installation

```
> git clone git@github.com:adam-zethraeus/macOCR.git
> cd macOCR
> swift build -c release
> .build/release/ocr -h                                                                                      
USAGE: ocr [--capture] [-r <r>] [--stdin] [-i <i>] [-l <language>] [-o <output>] [-m <mode>]

OPTIONS:
  -c, --capture           Capture screenshot. 
  -r <r>                  Rectangle to unattendedly capture (-r x,y,w,h), needs --capture.
  -s, --stdin             Read stdin binary data. 
  -i <i>                  Path to input image. 
  -l, --language <language>
                          Recognition language (e.g., en-US, zh-CN, ja-JP, auto). Supports macOS 11+ only. (default: auto)
  -o, --output <output>   Output format: text or json. (default: text)
  -m, --mode <mode>       Recognition mode: fast or accurate. (default: fast)
  -h, --help              Show help information.

# You can place the binary in a folder in your $PATH
> PATH=$PATH:~/bin
> cp .build/release/ocr ~/bin
> cat test.png | ocr
Some text in your image

# Use with specific language (macOS 11+ only)
> ocr -c -l zh-CN        # Capture and recognize Chinese text
> ocr -i image.png -l ja-JP # Recognize Japanese text from image

# Output as JSON with position information
> ocr -c -o json         # Capture and output as JSON
> ocr -i image.png -o json -l zh-CN # Chinese text with position data

# Use different recognition modes
> ocr -c -m fast         # Fast recognition (default)
> ocr -c -m accurate     # More accurate but slower recognition
```

When running the app the first time, you will be asked to allow the app access to your screen.

Enable it in: `System Preferences > Security & Privacy > Privacy > Screen Recording`. 

## Language Support

Starting from macOS 11 (Big Sur), you can specify the recognition language using the `-l` or `--language` option. Common language codes include:

- `en-US` - English (United States) 
- `zh-CN` - Chinese (Simplified)
- `zh-TW` - Chinese (Traditional)
- `ja-JP` - Japanese
- `ko-KR` - Korean
- `fr-FR` - French
- `de-DE` - German
- `es-ES` - Spanish
- `it-IT` - Italian
- `pt-BR` - Portuguese (Brazil)
- `ru-RU` - Russian
- `ar-SA` - Arabic

**Note**: Language support is only available on macOS 11 or later. On older versions, the language parameter will be ignored.

## Output Formats

### Text Output (default)
Returns plain text with recognized content joined by spaces.

### JSON Output
Returns a JSON array with text positioning information:

```json
[
  {
    "id": "1",
    "text": "Hello World",
    "position": {
      "left": 100,
      "top": 200,
      "width": 150,
      "height": 25
    }
  },
  {
    "id": "2", 
    "text": "Another text block",
    "position": {
      "left": 100,
      "top": 230,
      "width": 200,
      "height": 25
    }
  }
]
```

**Position Object Format**:
- `left`: X coordinate from the left edge of the image (integer, pixels)
- `top`: Y coordinate from the top edge of the image (integer, pixels)
- `width`: Width of the text bounding box (integer, pixels)
- `height`: Height of the text bounding box (integer, pixels)

All position values are rounded to the nearest integer and given in pixels relative to the original image dimensions.

## Recognition Modes

### Fast Mode (default)
- Prioritizes speed over accuracy
- Suitable for real-time applications
- Lower computational requirements

### Accurate Mode  
- Prioritizes accuracy over speed
- More computationally intensive
- Better for high-quality text recognition

**Note**: Recognition mode settings are available on macOS 11+ for basic functionality, with enhanced automatic language detection available on macOS 15+.

## OS Support

The Swift package is enabled for Big Sur / macOS v11.

## MIT License 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

