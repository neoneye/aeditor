onechunk:
	xsltproc \
	--output index.html \
	xhtml_onechunk \
	main.xml

chunks:
	xsltproc \
	--output index.html \
	xhtml_chunks \
	main.xml

catalog:
	xmllint --valid --noout catalog.xml

main:
	xmllint --valid --noout main.xml
