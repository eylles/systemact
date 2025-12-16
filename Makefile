.POSIX:
NAME = systemact
VERSION = 0.3.0
PREFIX = $(HOME)/.local
MANPREFIX = $(PREFIX)/share/man
LOCALEPREFIX = $(PREFIX)/share/locale
EGPREFIX = $(PREFIX)/share/doc/$(NAME)
.PHONY: install uninstall clean

$(NAME):
	sed "s|@VERSION|$(VERSION)|; s|@examples|$(EGPREFIX)|; s|@localeprefix|$(LOCALEPREFIX)|" \
		systemact.sh > $(NAME)
	cp config.template  config.rc

install: $(NAME)
	chmod 755 $(NAME)
	mkdir -p $(DESTDIR)${PREFIX}/bin
	mkdir -p $(DESTDIR)$(EGPREFIX)
	mkdir -p $(DESTDIR)$(LOCALEPREFIX)/en/LC_MESSAGES
	msgfmt po/en.po -o $(DESTDIR)$(LOCALEPREFIX)/en/LC_MESSAGES/$(NAME).mo
	mkdir -p $(DESTDIR)$(LOCALEPREFIX)/es/LC_MESSAGES
	msgfmt po/es.po -o $(DESTDIR)$(LOCALEPREFIX)/es/LC_MESSAGES/$(NAME).mo
	cp -v $(NAME) $(DESTDIR)${PREFIX}/bin/
	cp -v config.rc $(DESTDIR)$(EGPREFIX)/
	sed "s!VERSION!$(VERSION)!g" systemact.1 > $(DESTDIR)$(MANPREFIX)/man1/$(NAME).1

uninstall:
	rm -vf $(DESTDIR)$(PREFIX)/bin/$(NAME)
	rm -vf $(DESTDIR)$(MANPREFIX)/man1/$(NAME).1
	rm -vf $(DESTDIR)$(EGPREFIX)/config.rc
	rm -rf $(DESTDIR)$(EGPREFIX)

clean:
	rm -rf $(NAME) config.rc
