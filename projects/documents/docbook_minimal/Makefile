onechunk:
	xsltproc \
	--output mini_docbook.html \
	xhtml_onechunk \
	main.xml

catalog:
	xmllint --valid --noout catalog.xml

main:
	xmllint --valid --noout main.xml

upload:
	scp mini_docbook.html neoneye@rubyforge.org:/var/www/gforge-projects/aeditor/
