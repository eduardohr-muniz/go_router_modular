.PHONY: install-doc run-doc build-doc

install-doc:
	cd nextra_docs && npm install

run-doc: install-doc
	cd nextra_docs && npm run dev

build-doc: install-doc
	cd nextra_docs && npm run build
