

build:
		swift build

clean:
		rm .build/debug/fasti

install:
		cp .build/debug/fasti ~/bin
