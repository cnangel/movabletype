BUILD_LANGUAGE ?= en_US
BUILD_PACKAGE ?= MTOS

-include build/mt-dists/default.mk
-include build/mt-dists/$(BUILD_PACKAGE).mk
-include build/mt-dists/$(BUILD_LANGUAGE).mk

BUILD_VERSION_ID ?= $(PRODUCT_VERSION)

local_js = mt-static/mt_de.js \
        mt-static/mt_fr.js \
        mt-static/mt_nl.js \
        mt-static/mt_ja.js \
        mt-static/mt_es.js

core_js = mt-static/js/common/Core.js \
          mt-static/js/common/JSON.js \
          mt-static/js/common/Timer.js \
          mt-static/js/common/Cookie.js \
          mt-static/js/common/DOM.js \
          mt-static/js/common/Observable.js \
          mt-static/js/common/Autolayout.js \
          mt-static/js/common/Component.js \
          mt-static/js/common/List.js \
          mt-static/js/common/App.js \
          mt-static/js/common/Cache.js \
          mt-static/js/common/Client.js \
          mt-static/js/common/Template.js \
          mt-static/js/tc.js \
          mt-static/js/tc/tableselect.js

main_css = mt-static/css/reset.css \
	mt-static/css/structure.css \
	mt-static/css/form.css \
	mt-static/css/listing.css \
	mt-static/css/sortable.css \
	mt-static/css/dialog.css \
	mt-static/css/messaging.css \
	mt-static/css/utilities.css \
	mt-static/css/icons.css

simple_css = mt-static/css/reset.css \
	mt-static/css/chromeless.css \
	mt-static/css/form.css \
	mt-static/css/messaging.css \
	mt-static/css/utilities.css

all: code

mt-static/js/mt_core_compact.js: $(core_js)
	cat $(core_js) > mt-static/js/mt_core_compact.js
	./build/minifier.pl mt-static/js/mt_core_compact.js

mt-static/css/main.css: $(main_css)
	cat $(main_css) > mt-static/css/main.css
	./build/minifier.pl mt-static/css/main.css

mt-static/css/simple.css: $(simple_css)
	cat $(simple_css) > mt-static/css/simple.css
	./build/minifier.pl mt-static/css/simple.css

.PHONY: code-common code code-en_US code-de code-fr code-nl \
	code-es code-ja
code_common = lib/MT.pm php/mt.php mt-check.cgi \
        mt-static/js/mt_core_compact.js \
        mt-static/css/main.css \
        mt-static/css/simple.css

code: check code-$(BUILD_LANGUAGE)
code-en_US code-de code-fr code-nl code-es: check $(code_common) \
	$(local_js)
code-ja: check $(code_common) mt-static/mt_ja.js

build-language-stamp:

check:
	@(test $(BUILD_LANGUAGE) || echo You must define BUILD_LANGUAGE)
	@test $(BUILD_LANGUAGE)
	@(test $(BUILD_PACKAGE) || echo You must define BUILD_PACKAGE)
	@test $(BUILD_PACKAGE)
	@(test $(BUILD_VERSION_ID) || echo You must define BUILD_VERSION_ID)
	@test $(BUILD_VERSION_ID)
	-@if [ "`cat build-language-stamp`" != ${BUILD_LANGUAGE} ] ;  \
	then                                                   \
		echo ${BUILD_LANGUAGE} > build-language-stamp; \
		echo updated build-language-stamp;             \
	fi

lib/MT.pm: build-language-stamp build/mt-dists/$(BUILD_PACKAGE).mk build/mt-dists/default.mk
	mv lib/MT.pm lib/MT.pm.pre
	sed -e 's!__PRODUCT_NAME__!$(PRODUCT_NAME)!g' \
	    -e 's!__BUILD_ID__!$(BUILD_VERSION_ID)!g' \
	    -e 's!__PORTAL_URL__!$(PORTAL_URL)!g' \
	    -e 's!__PRODUCT_VERSION_ID__!$(BUILD_VERSION_ID)!g' \
	    lib/MT.pm.pre > lib/MT.pm
	rm lib/MT.pm.pre

php/mt.php: build-language-stamp build/mt-dists/$(BUILD_PACKAGE).mk
	mv php/mt.php php/mt.php.pre
	sed -e 's!__PRODUCT_NAME__!$(PRODUCT_NAME)!g' \
	php/mt.php.pre > php/mt.php
	rm php/mt.php.pre

mt-check.cgi: build-language-stamp build/mt-dists/$(BUILD_PACKAGE).mk
	mv mt-check.cgi mt-check.cgi.pre
	sed -e 's!__PRODUCT_VERSION_ID__!$(BUILD_VERSION_ID)!g' \
	mt-check.cgi.pre > mt-check.cgi
	rm mt-check.cgi.pre
	chmod +x mt-check.cgi

$(local_js): mt-static/mt_%.js: mt-static/mt.js lib/MT/L10N/%.pm
	perl build/mt-dists/make-js

##### Other useful targets

.PHONY: test cover clean all

cover:
	-cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV' t/*.t

covertags:
	-cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover \
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV' t/*tags*.t
	-cover

tags:
	-rm -rf t/db/*
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV' t/*tags*.t

test: code
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV' t/*.t

testall: code
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV' t/*.t addons/*/t/*.t plugins/*/t/*.t

quick-test: code
	perl -Ilib -Iextlib -It/lib -MTest::Harness -e 'runtests @ARGV'  \
		t/00-compile.t t/01-serialize.t t/04-config.t \
		t/05-errorhandler.t t/07-builder.t t/08-util.t           \
		t/09-image.t t/10-filemgr.t t/11-sanitize.t t/12-dsa.t   \
		t/13-dirify.t t/20-setup.t t/21-callbacks.t t/22-author.t\
		t/23-entry.t t/26-pings.t t/27-context.t t/28-xmlrpc.t   \
		t/29-cleanup.t t/32-mysql.t t/33-postgres.t   \
		t/34-sqlite.t t/35-tags.t t/45-datetime.t t/46-i18n-en.t \
		t/47-i18n-ja.t t/48-cache.t

dist:
	perl build/exportmt.pl --local

me:
	perl build/exportmt.pl --make

clean:
	-rm -rf $(local_js)
	-rm -rf mt-static/js/mt_core_compact.js
	-rm -rf mt-static/css/main.css mt-static/css/simple.css
	-rm -rf MANIFEST
	-rm -rf build-language-stamp
	-git checkout lib/MT.pm php/mt.php
