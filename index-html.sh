#!/bin/sh

# Usage ls | index-html.sh > index.html 

echo '<html><body>'
sed 's/^.*/<a href="&">&<\/a><br\/>/'
echo '</body></html>'