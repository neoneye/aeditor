XHTML_ROOT=/usr/local/share/xsl/docbook/xhtml

all: xhtml

valid:
	xmllint --valid --noout main.xml

xhtml:
	xsltproc --catalogs --novalid --nonet $(XHTML_ROOT)/docbook.xsl main.xml > index.html

xhtml_chunk:
	xsltproc --catalogs --novalid --nonet $(XHTML_ROOT)/chunk.xsl main.xml > out.html

#upload:
#	scp -r index.html data neoneye@shell.sourceforge.net:/home/groups/m/me/metaeditor/htdocs/source3/.
