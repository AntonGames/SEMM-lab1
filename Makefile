TLC = java -cp /home/vscode/.vscode-server/extensions/tlaplus.vscode-ide-2026.3.122209/tools/tla2tools.jar tlc2.TLC

all: check-safety check-liveness check-abstract check-refinement

check-safety:
	cd Lab1a && $(TLC) Kerberos

check-liveness:
	cd Lab1a && $(TLC) KerberosLive

check-abstract:
	cd Lab1b && $(TLC) KerberosAbstract

check-refinement:
	cd Lab1b && $(TLC) KerberosRefinement

.PHONY: all check-safety check-liveness check-abstract check-refinement
