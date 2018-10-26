# optimize-pdf-for-mobile

Bash script to ***optimize*** and/or ***resize*** PDFs from the command line.
Uses poppler (`pdfinfo`) and (`pdfimages`) to analyze the pdf input.
Uses ghostscript (`gs`) to create an optimized and/or resized version of the pdf input.
  
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