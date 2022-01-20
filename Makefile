ACME=acme
C1541=c1541

TARGETS=bit-test.d81

.PHONY: all clean

all: $(TARGETS)

clean:
	-rm -f $(TARGETS) $(TARGETS:.d81=.prg) $(TARGETS:.d81=.lst) $(TARGETS:.d81=.lbl)

bit-test.d81: bit-test.prg
	$(C1541) -format 'bit test,bs' d81 "$(PWD)/$@"
	$(C1541) "$(PWD)/$@" -write "$<" "bit test"

%.prg: %.asm
	$(ACME) -Wtype-mismatch --color --cpu 4502 --format cbm --outfile "$@" --report "$*.lst" --symbollist "$*.sym" $^
