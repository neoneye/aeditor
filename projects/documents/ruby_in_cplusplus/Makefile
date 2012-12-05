XHTML_CSS=--stringparam html.stylesheet  style.css

onechunk:
	xsltproc \
	--output index.html \
	$(XHTML_CSS) \
	xhtml_onechunk \
	main.xml

catalog:
	xmllint --valid --noout catalog.xml

main:
	xmllint --valid --noout main.xml

upload:
	scp index.html style.css neoneye@rubyforge.org:/var/www/gforge-projects/aeditor/ruby_cplusplus/

upload_data:
	scp *.png neoneye@rubyforge.org:/var/www/gforge-projects/aeditor/ruby_cplusplus/
