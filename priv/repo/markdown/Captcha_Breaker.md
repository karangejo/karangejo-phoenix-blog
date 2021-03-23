I recently heard about OCR (optical character recognition) from one of my friends. He said he was getting a machine for his company and that it would save time processing all the paperwork over there. I was curious and sure enough found the tesseract library in python for OCR. The first use case I thought of was for breaking captchas.

It turns out the tesseract library doesn't do too well with captchas right out of the box but with a little help from imagemagick It could do OK. Still not 100% accurate, but even humans sometimes can't read captchas properly. I think with the right imagemagick uh... magic you could easily break most captchas found on the internet (not google recaptcha though).

Here is some sample code:

```python
import pytesseract
import sys
import argparse
try:
    import Image
except ImportError:
    from PIL import Image
from subprocess import check_output


def resolve(path):
	print("Resampling the Image",path)
	new_path = "new"+path
	# image processing with imagemagick
	out = check_output(['convert', path, '-resample', '600', new_path])
	# the above line is where you need to get creative a try to process the image so it is easy to perform OCR
	return pytesseract.image_to_string(Image.open(new_path))

if __name__=="__main__":
	argparser = argparse.ArgumentParser()
	argparser.add_argument('path',help = 'Captcha file path')
	args = argparser.parse_args()
	path = args.path
	print('Resolving Captcha')
	captcha_text = resolve(path)
	print('Extracted Text',captcha_text)
```

Here is the github repo where you can try it out with a sample captcha: https://github.com/karangejo/captcha-breaker