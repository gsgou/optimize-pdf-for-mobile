# optimize-pdf-for-mobile

Bash script to ***optimize*** and/or ***resize*** PDFs into an iOS/PDFKit friendly format.

Uses poppler (`pdfinfo`) (`pdfimages`) (`pdfseparate`) and (`pdfunite`) to analyze and manipulate the pdf input. Uses ghostscript (`gs`) to create an optimized and/or resized version of the pdf input.

----------------------------------------------
#### If you want to support this project, you can give me a cup of coffee :coffee:
<a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=BGBMGDR5HDSZU">
  <img src="https://ubuntubudgie.org/storage/Budgiess/support_paypal.svg" width="25%">
</a>

----------------------------------------------

## Reduce Image Size

Mobile devices are limited when it comes to resources and processing power, so optimizing PDF documents can be beneficial for both performance and battery.

Furthermore pdf documents with 15 or more pages where each has an image with a resolution above 47200000 pixels (45.01MB uncompressed) can crash PDFKit in iOS devices with high resolution and little RAM as an iPad 2018 (2048/1536 resolution and 3GB RAM).

## Avoid Using JPEG 2000

JPEG 2000 has slightly better image quality then JPEG when two files of the same size are compared. However decompressing these images is much more complex which is the root cause for pages taking a very long time to render in mobile devices.
  
## Example Runs

```
$ ./optimize-pdf-for-mobile.sh ../input.pdf
$ ./optimize-pdf-for-mobile.sh ../input.pdf 47200000
```
## Dependencies

The script uses `dirname`, `basename`, `grep`, `sed`, `awk`, `echo`, `mv`, `rm`,  `bc`, `pdfinfo`, `pdfimages`, `pdfseparate`, `pdfunite` and `gs` (ghostscript).

##### apt-get
```
sudo apt-get install ghostscript bc poppler
```
##### yum
```
sudo yum install ghostscript bc poppler
```
##### homebrew MacOS
```
 brew install ghostscript poppler
``` 