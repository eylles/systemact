.POSIX:
NAME = systemact
PREFIX = ~/.local
EGPREFIX = $(PREFIX)/share/doc/$(NAME)
.PHONY: install uninstall

$(NAME):
	cp systemact.sh  $(NAME)
	cp config.template  config.rc

install: $(NAME)
	chmod 755 $(NAME)
	mkdir -p $(DESTDIR)${PREFIX}/bin
	mkdir -p $(DESTDIR)$(EGPREFIX)
	cp -v $(NAME) $(DESTDIR)${PREFIX}/bin
	cp -v config.rc $(DESTDIR)$(EGPREFIX)/
	rm $(NAME)
	rm config.rc

uninstall:
	rm -vf $(DESTDIR)$(PREFIX)/bin/$(NAME)
	rm -vf $(DESTDIR)$(EGPREFIX)/config.rc
	rm -rf $(DESTDIR)$(EGPREFIX)

