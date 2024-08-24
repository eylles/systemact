.POSIX:
NAME = systemact
VERSION = 0.0.0
PREFIX = $(HOME)/.local
MANPREFIX = $(PREFIX)/share/man
EGPREFIX = $(PREFIX)/share/doc/$(NAME)
.PHONY: install uninstall

$(NAME):
	sed "s|@VERSION|$(VERSION)|; s|examples-placeholder|$(EGPREFIX)|" systemact.sh > $(NAME)
	cp config.template  config.rc

install: $(NAME)
	chmod 755 $(NAME)
	mkdir -p $(DESTDIR)${PREFIX}/bin
	mkdir -p $(DESTDIR)$(EGPREFIX)
	cp -v $(NAME) $(DESTDIR)${PREFIX}/bin/
	cp -v config.rc $(DESTDIR)$(EGPREFIX)/
	sed "s!VERSION!$(VERSION)!g" systemact.1 > $(DESTDIR)$(MANPREFIX)/man1/$(NAME).1
	rm $(NAME)
	rm config.rc

uninstall:
	rm -vf $(DESTDIR)$(PREFIX)/bin/$(NAME)
	rm -vf $(DESTDIR)$(MANPREFIX)/man1/$(NAME).1
	rm -vf $(DESTDIR)$(EGPREFIX)/config.rc
	rm -rf $(DESTDIR)$(EGPREFIX)

