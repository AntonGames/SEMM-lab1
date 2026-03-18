TLAPS_LIB = /home/vscode/.opam/5.4.0/lib/tlapm/stdlib
TLC = java -cp $(shell find /home/vscode/.vscode-server/extensions/ -name tla2tools.jar -path '*/tools/*' | head -1) tlc2.TLC
TLC_TLAPS = java -DTLA-Library=$(TLAPS_LIB) -cp $(shell find /home/vscode/.vscode-server/extensions/ -name tla2tools.jar -path '*/tools/*' | head -1) tlc2.TLC

all: check-safety check-liveness check-abstract check-refinement

check-safety:
	cd Lab1a && $(TLC) Kerberos

check-liveness:
	cd Lab1a && $(TLC) KerberosLive

check-abstract:
	cd Lab1b && $(TLC) KerberosAbstract

check-refinement:
	cd Lab1b && $(TLC_TLAPS) KerberosRefinement

.PHONY: all check-safety check-liveness check-abstract check-refinement
