all: apiary.apib
	aglio -i apiary.apib -o "docs/`date +%G-%m-%d`-spec.html"