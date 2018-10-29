# optimize-pdf-for-mobile

Bash script to ***optimize*** and/or ***resize*** PDFs from the command line into an iOS/PDFKit friendly format.
Uses poppler (`pdfinfo`) and (`pdfimages`) to analyze the pdf input.
Uses ghostscript (`gs`) to create an optimized and/or resized version of the pdf input.

---------------------------------------------- 
#### If you want to support this project, you can give me a cup of coffee :coffee:  
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=BGBMGDR5HDSZU)  

---------------------------------------------- 
  
## Example Runs

Better than explaining is showing it:

```
$ ./optimize-pdf-for-mobile.sh ../input.pdf
$ ./optimize-pdf-for-mobile.sh ../input.pdf 47200000
```
## Dependencies

The script uses `dirname`, `basename`, `grep`, `sed`, `bc`, `pdfinfo`, `pdfimages` and `gs` (ghostscript).

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